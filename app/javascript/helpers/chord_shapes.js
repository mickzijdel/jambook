// Guitar shapes for a chord symbol, from the chords-db data in app/assets/data/guitar_chords.json
// (keyed by root, then by chord type), and an SVG chord box to show one.

// The data has one spelling per root; slash chords spell the bass with sharps except Bb.
const ROOTS = { "B#": "C", C: "C", "C#": "C#", Db: "C#", D: "D", "D#": "Eb", Eb: "Eb", Fb: "E", E: "E", "E#": "F", F: "F",
  "F#": "F#", Gb: "F#", G: "G", "G#": "Ab", Ab: "Ab", A: "A", "A#": "Bb", Bb: "Bb", Cb: "B", B: "B" }
const BASSES = { ...ROOTS, "D#": "D#", Eb: "D#", "G#": "G#", Ab: "G#" }
const TYPES = {
  "": "major", maj: "major", M: "major", m: "minor", min: "minor", mi: "minor", "-": "minor",
  7: "7", m7: "m7", min7: "m7", mi7: "m7", "-7": "m7", maj7: "maj7", M7: "maj7", Maj7: "maj7", ma7: "maj7", "Δ": "maj7", "Δ7": "maj7",
  dim: "dim", o: "dim", "°": "dim", dim7: "dim7", o7: "dim7", "°7": "dim7",
  m7b5: "m7b5", min7b5: "m7b5", "-7b5": "m7b5", "ø": "m7b5", "ø7": "m7b5", aug: "aug", "+": "aug", aug7: "aug7", "+7": "aug7", "7#5": "aug7",
  sus: "sus4", sus4: "sus4", sus2: "sus2", 2: "sus2", "7sus": "7sus4", "7sus4": "7sus4",
  6: "6", m6: "m6", 69: "69", "6/9": "69", m69: "m69", 9: "9", m9: "m9", maj9: "maj9", add9: "add9", add2: "add9", madd9: "madd9",
  11: "11", m11: "m11", 13: "13", "7b9": "7b9", "7#9": "7#9", "7b5": "7b5", mmaj7: "mmaj7", mM7: "mmaj7", "m(maj7)": "mmaj7",
  // Spellings seen in Ultimate Guitar sheets.
  Dim: "dim", sus7: "7sus4", "m(ma7)": "mmaj7", "(9)": "add9", "(2)": "add9", "(4)": "sus4", ma9: "maj9", mmaj9: "mmaj9", m2: "madd9",
  "m7-5": "m7b5", "7-5": "7b5", "7-9": "7b9",
  5: "5"
}
const CHORD = /^([A-G][#b]?)([^/]*)(?:\/([A-G][#b]?))?$/
// What an unlisted chord type may be made of; anything else ("Ah-Ah", "From") is a word, not a chord.
const CHORD_TYPE = /^(?:maj|min|mi|ma|dim|aug|sus|add|alt|no|[mMΔø°+#b0-9()*,.-])*$/
const NOTES = { C: 0, "B#": 0, "C#": 1, Db: 1, D: 2, "D#": 3, Eb: 3, E: 4, Fb: 4, F: 5, "E#": 5, "F#": 6, Gb: 6, G: 7, "G#": 8, Ab: 8,
  A: 9, "A#": 10, Bb: 10, B: 11, Cb: 11 }
const STRINGS = [ "low E", "A", "D", "G", "B", "high E" ]
const OPEN = [ 4, 9, 2, 7, 11, 4 ] // standard tuning, low E to high E, as pitch classes

// Whether a word is a chord symbol (Am7, F#m7(b5), D/F#), not a word that starts with A to G.
export function isChordSymbol(symbol) {
  return parse(symbol) !== null
}

// Root, chord type and bass of a symbol, or null. Ultimate Guitar marks a particular voicing with
// asterisks (C*, Cadd9**); some sheets write A\C# for A/C#.
function parse(symbol) {
  const match = symbol.trim().replace(/\*+$/, "").replace("\\", "/").match(CHORD)
  if (!match) return null
  const written = match[2].replace(/\(([#b]\d+)\)/g, "$1") // m7(b5) is m7b5
  return written in TYPES || CHORD_TYPE.test(written) ? { root: match[1], written, bass: match[3] } : null
}

// { positions, note }, where note says what to do when the exact chord isn't in the data;
// null for anything that isn't a chord.
export function findShapes(symbol, chords) {
  const parts = parse(symbol)
  const byType = parts && chords[ROOTS[parts.root]]
  if (!byType) return null

  const { root, written, bass } = parts
  if (written === "5") return { positions: powerShapes(root), note: bass ? `${bass} in the bass` : null }
  const minor = /^(m|min|mi|-)(?!aj|a\d)/.test(written) // ma7, ma9: major
  const type = TYPES[written] ?? (minor ? "minor" : "major")
  const shapes = byType[type]
  if (!shapes) return null

  const notes = written in TYPES ? [] : [ `Shown as ${root}${minor ? "m" : ""}` ]
  if (bass) {
    // The data's own slash shapes are checked too: a few have the wrong lowest note or an extra one.
    const tones = new Set(shapes.flatMap(sounding))
    const own = (type === "major" || type === "minor" ? byType[`${minor ? "m" : ""}/${BASSES[bass]}`] ?? [] : [])
      .filter((shape) => sounding(shape)[0] === NOTES[bass] && sounding(shape).every((note) => note === NOTES[bass] || tones.has(note)))
    const slash = own.length ? own : withBass(shapes, NOTES[bass])
    if (slash.length) return { positions: slash, note: notes.join(", ") || null }
    notes.push(`${bass} in the bass`)
  }
  return { positions: shapes, note: notes.join(", ") || null }
}

const sounding = ({ frets, baseFret }) => frets.flatMap((fret, string) => (fret < 0 ? [] : [ (OPEN[string] + (fret && baseFret + fret - 1)) % 12 ]))

// The data has slash chords for only a few roots. Build the rest: put the bass on the low E, A or D string
// of each shape, muting the strings below it, where the shape keeps its notes and fits four frets and
// four fingers. The easiest option (smallest stretch, then lowest string) wins for each shape.
function withBass(shapes, bass) {
  const built = shapes.flatMap((shape) => {
    const options = [ 0, 1, 2 ].flatMap((string) => [ 0, 12 ].map((octave) => bassOn(shape, string, (bass - OPEN[string] + 12) % 12 + octave)))
    const keeps = (option) => sounding(shape).every((note) => sounding(option.shape).includes(note))
    return options.filter((option) => option && keeps(option)).sort((a, b) => a.span - b.span || a.string - b.string).slice(0, 1).map((option) => option.shape)
  })
  return built.filter((shape, i) => built.findIndex((other) => `${other.frets}@${other.baseFret}` === `${shape.frets}@${shape.baseFret}`) === i)
}

function bassOn({ frets, fingers, baseFret, barres }, string, fret) {
  const absolute = frets.map((each, s) => (s < string ? -1 : s === string ? fret : each > 0 ? baseFret + each - 1 : each))
  const fingered = fingers.map((each, s) => (s <= string ? 0 : each))
  const barreFrets = barres.map((barre) => baseFret + barre - 1)
  const fretted = absolute.filter((each) => each > 0)
  const span = fretted.length ? Math.max(...fretted) - Math.min(...fretted) : 0
  const fingersNeeded = new Set(fingered.filter(Boolean)).size + (fret > 0 ? 1 : 0)
  // A new note on a barre's fret would stretch the drawn barre to it.
  if (span > 3 || fingersNeeded > 4 || (fret > 0 && barreFrets.includes(fret))) return null

  const base = fretted.length && Math.max(...fretted) > 4 ? Math.min(...fretted) : 1
  const relative = absolute.map((each) => (each > 0 ? each - base + 1 : each))
  const kept = barreFrets.map((barre) => barre - base + 1).filter((barre) => relative.filter((each) => each === barre).length > 1)
  return { string, span, shape: { frets: relative, fingers: fingered, baseFret: base, barres: kept } }
}

// The data has no power chords: root and fifth (plus the octave), with the root on the low E or the A string.
function powerShapes(root) {
  const onE = (NOTES[root] + 8) % 12
  const onA = (NOTES[root] + 3) % 12
  return [
    onE === 0 ? { frets: [ 0, 2, 2, -1, -1, -1 ], fingers: [ 0, 1, 2, 0, 0, 0 ], baseFret: 1, barres: [] }
      : { frets: [ 1, 3, 3, -1, -1, -1 ], fingers: [ 1, 3, 4, 0, 0, 0 ], baseFret: onE, barres: [] },
    onA === 0 ? { frets: [ -1, 0, 2, 2, -1, -1 ], fingers: [ 0, 0, 1, 2, 0, 0 ], baseFret: 1, barres: [] }
      : { frets: [ -1, 1, 3, 3, -1, -1 ], fingers: [ 0, 1, 3, 4, 0, 0 ], baseFret: onA, barres: [] }
  ].sort((a, b) => a.baseFret - b.baseFret)
}

// Strings run low E to high E from left to right, frets down from the nut (or from baseFret).
export function diagramSvg(name, { frets, fingers, baseFret, barres }) {
  const x = (string) => 22 + string * 12
  const y = (fret) => 18 + fret * 15
  const parts = []
  for (let string = 0; string < 6; string++) parts.push(`<line class="cd-line" x1="${x(string)}" y1="${y(0)}" x2="${x(string)}" y2="${y(4)}"/>`)
  for (let fret = 0; fret <= 4; fret++) {
    parts.push(`<line class="cd-line${fret === 0 && baseFret === 1 ? " cd-nut" : ""}" x1="${x(0)}" y1="${y(fret)}" x2="${x(5)}" y2="${y(fret)}"/>`)
  }
  if (baseFret > 1) parts.push(`<text class="cd-base" x="${x(0) - 4}" y="${y(0.5) + 3}" text-anchor="end">${baseFret}fr</text>`)

  for (const barre of barres) {
    const on = frets.flatMap((fret, string) => (fret === barre ? [ string ] : []))
    parts.push(`<rect class="cd-barre" x="${x(on[0]) - 5}" y="${y(barre - 0.5) - 5}" width="${x(on.at(-1)) - x(on[0]) + 10}" height="10" rx="5"/>`)
  }
  frets.forEach((fret, string) => {
    if (fret === -1) parts.push(`<text class="cd-muted" x="${x(string)}" y="${y(0) - 5}" text-anchor="middle">×</text>`)
    else if (fret === 0) parts.push(`<circle class="cd-open" cx="${x(string)}" cy="${y(0) - 8}" r="3.5"/>`)
    else if (!barres.includes(fret)) {
      parts.push(`<circle class="cd-dot" cx="${x(string)}" cy="${y(fret - 0.5)}" r="5"/>`)
      if (fingers[string]) parts.push(`<text class="cd-finger" x="${x(string)}" y="${y(fret - 0.5) + 3}" text-anchor="middle">${fingers[string]}</text>`)
    }
  })

  const words = frets.map((fret, string) => `${STRINGS[string]} ${fret === -1 ? "muted" : fret === 0 ? "open" : `fret ${baseFret + fret - 1}`}`)
  return `<svg class="chord-diagram" viewBox="0 0 92 82" role="img" aria-label="${escape(name)}: ${words.join(", ")}">${parts.join("")}</svg>`
}

const escape = (text) => text.replace(/[&<>"]/g, (character) => `&#${character.charCodeAt(0)};`)
