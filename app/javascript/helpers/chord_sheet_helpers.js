import { ChordLyricsPair, ChordProFormatter, ChordProParser, HtmlDivFormatter, Tag, UltimateGuitarParser } from "chordsheetjs"

// Ultimate Guitar wraps chords in [ch]..[/ch] and tab blocks in [tab]..[/tab]; the layout is what matters.
const UG_MARKUP = /\[\/?(ch|tab)\]/g
// A chord symbol (G, F#m7b5, A7sus4, C/G). Section labels such as [Chorus] or [Verse 1] don't match.
const CHORD = /^[A-G][#b]?(?:m|maj|min|dim|aug|sus|add|M)?\d*(?:(?:add|sus|maj|b|#)\d+)*(?:\/[A-G][#b]?)?$/
const ESCAPES = { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }

const escapeHtml = (text) => (typeof text === "string" ? text.replace(/[&<>"']/g, (character) => ESCAPES[character]) : text)

// ChordPro has {directives} or chords in brackets; anything else reads as chords over lyrics.
export function detectFormat(sheet) {
  if (/^\s*\{\w+/m.test(sheet)) return "chordpro"

  const bracketed = [ ...sheet.matchAll(/\[([^\]\n]+)\]/g) ].map((match) => match[1])
  return bracketed.some((token) => CHORD.test(token)) ? "chordpro" : "ultimate_guitar"
}

function parse(sheet, format) {
  if (format === "ultimate_guitar") {
    return new UltimateGuitarParser({ preserveWhitespace: false }).parse(sheet.replace(UG_MARKUP, ""))
  }
  return new ChordProParser().parse(sheet)
}

// HtmlDivFormatter writes lyrics, chords and labels into the page as HTML, unescaped.
function escaped(song) {
  return song.mapItems((item) => {
    if (item instanceof ChordLyricsPair) {
      return item.set({ chords: escapeHtml(item.chords), lyrics: escapeHtml(item.lyrics), annotation: escapeHtml(item.annotation) })
    }
    if (item instanceof Tag) return item.set({ value: escapeHtml(item.value) })
    return item
  })
}

// The sheet as written, moved to the sounding key, then to the room key, then down by the viewer's capo.
// A sheet that can't be read is shown as plain text rather than not at all.
export function renderSheet({ sheet, format, writtenKey, writtenCapo = 0, key, capo = 0 }) {
  try {
    const song = parse(sheet, format)
    if (!writtenKey) {
      return { html: new HtmlDivFormatter().format(escaped(song)), shownKey: null, transposed: false }
    }

    let shown = song.setKey(writtenKey).setCapo(writtenCapo).decapo()
    if (key) shown = shown.changeKey(key)
    if (capo > 0) shown = shown.transpose(-capo)
    return { html: new HtmlDivFormatter().format(escaped(shown.setCapo(null))), shownKey: shown.key, transposed: true }
  } catch (error) {
    console.warn("Showing the sheet as plain text, it couldn't be read:", error.message)
    return { html: `<pre class="sheet-plain">${escapeHtml(sheet)}</pre>`, shownKey: null, transposed: false }
  }
}

export function toChordPro({ sheet, format }) {
  const song = parse(sheet, format)
  return { chordpro: new ChordProFormatter().format(song), key: song.key, capo: song.capo ? Number(song.capo) : null }
}
