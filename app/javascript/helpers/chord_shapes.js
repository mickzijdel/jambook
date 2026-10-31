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
  5: "5"
}
const CHORD = /^([A-G][#b]?)([^/]*)(?:\/([A-G][#b]?))?$/
// What an unlisted chord type may be made of; anything else ("Ah-Ah", "From") is a word, not a chord.
const CHORD_TYPE = /^(?:maj|min|mi|ma|dim|aug|sus|add|alt|no|[mMΔø°+#b0-9()*,.-])*$/
const NOTES = { C: 0, "B#": 0, "C#": 1, Db: 1, D: 2, "D#": 3, Eb: 3, E: 4, Fb: 4, F: 5, "E#": 5, "F#": 6, Gb: 6, G: 7, "G#": 8, Ab: 8,
  A: 9, "A#": 10, Bb: 10, B: 11, Cb: 11 }
const STRINGS = [ "low E", "A", "D", "G", "B", "high E" ]

// { positions, note }, where note says what to do when the exact chord isn't in the data;
// null for anything that isn't a chord.
export function findShapes(symbol, chords) {
  // Ultimate Guitar marks a particular voicing with asterisks (C*, Cadd9**); some sheets write A\C# for A/C#.
  const match = symbol.trim().replace(/\*+$/, "").replace("\\", "/").match(CHORD)
  const byType = match && chords[ROOTS[match[1]]]
  if (!byType) return null

  const [ , root, , bass ] = match
  const written = match[2].replace(/\(([#b]\d+)\)/g, "$1") // m7(b5) is m7b5
  if (!(written in TYPES || CHORD_TYPE.test(written))) return null
  if (written === "5") return { positions: powerShapes(root), note: bass ? `Play ${bass} in the bass.` : null }
  const minor = /^(m|min|mi|-)(?!aj|a\d)/.test(written) // ma7, ma9: major
  const type = TYPES[written] ?? (minor ? "minor" : "major")
  const notes = []
  if (!(written in TYPES)) notes.push(`Shown as ${root}${minor ? "m" : ""}, the nearest chord in the chord book.`)
  if (bass) {
    const slash = type === "major" || type === "minor" ? byType[`${minor ? "m" : ""}/${BASSES[bass]}`] : null
    if (slash) return { positions: slash, note: notes.join(" ") || null }
    notes.push(`Play ${bass} in the bass.`)
  }
  return byType[type] ? { positions: byType[type], note: notes.join(" ") || null } : null
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
