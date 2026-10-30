import { ChordProFormatter, ChordProParser, HtmlDivFormatter, UltimateGuitarParser } from "chordsheetjs"

// Ultimate Guitar wraps chords in [ch]..[/ch] and tab blocks in [tab]..[/tab]; the layout is what matters.
const UG_MARKUP = /\[\/?(ch|tab)\]/g

function parse(sheet, format) {
  if (format === "ultimate_guitar") {
    return new UltimateGuitarParser({ preserveWhitespace: false }).parse(sheet.replace(UG_MARKUP, ""))
  }
  return new ChordProParser().parse(sheet)
}

// The sheet as written, moved to the sounding key, then to the room key, then down by the viewer's capo.
export function renderSheet({ sheet, format, writtenKey, writtenCapo = 0, key, capo = 0 }) {
  const song = parse(sheet, format)
  if (!writtenKey) {
    return { html: new HtmlDivFormatter().format(song), shownKey: null, transposed: false }
  }

  let shown = song.setKey(writtenKey).setCapo(writtenCapo).decapo()
  if (key) shown = shown.changeKey(key)
  if (capo > 0) shown = shown.transpose(-capo)
  return { html: new HtmlDivFormatter().format(shown.setCapo(null)), shownKey: shown.key, transposed: true }
}

export function toChordPro({ sheet, format }) {
  const song = parse(sheet, format)
  return { chordpro: new ChordProFormatter().format(song), key: song.key, capo: song.capo ? Number(song.capo) : null }
}
