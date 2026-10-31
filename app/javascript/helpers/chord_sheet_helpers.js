import { ChordLyricsPair, ChordProFormatter, ChordProParser, HtmlDivFormatter, Tag, UltimateGuitarParser } from "chordsheetjs"
import { isChordSymbol } from "helpers/chord_shapes"

// Ultimate Guitar wraps chords in [ch]..[/ch] and tab blocks in [tab]..[/tab]; the layout is what matters.
const UG_MARKUP = /\[\/?(ch|tab)\]/g
// A chord symbol (G, F#m7b5, A7sus4, C/G). Section labels such as [Chorus] or [Verse 1] don't match.
const CHORD = /^[A-G][#b]?(?:m|maj|min|dim|aug|sus|add|M)?\d*(?:(?:add|sus|maj|b|#)\d+)*(?:\/[A-G][#b]?)?$/
// A tab staff line: an optional string name, a bar, then mostly dashes (long ones too) and fret marks
// (e|--0--|, A||-3-|, F: 1-3-3-2-1-1), ending in a bar, a dash or a fret; then maybe a note ("x8", "let ring").
const STAFF = /^\s*(?:[A-Ga-g][#b]?\s*)?[|:](?=(?:[^-]*-){3})[-—–0-9hpbrsx~/\\|().*^<>=\s]*[-—–|0-9](?:\s+\S.*)?\s*$/
const TAB_START = /^\s*\{(?:start_of_tab|sot)(?::\s*([^}]*))?\}\s*$/
const SECTION_LABEL = /^\s*\[([^\]]+)\]\s*$/
const TAB_END = /^\s*\{(?:end_of_tab|eot)\}\s*$/
const ESCAPES = { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }

const escapeHtml = (text) => (typeof text === "string" ? text.replace(/[&<>"']/g, (character) => ESCAPES[character]) : text)

// ChordPro has {directives} or chords in brackets; anything else reads as chords over lyrics.
export function detectFormat(sheet) {
  if (/^\s*\{\w+/m.test(sheet)) return "chordpro"

  const bracketed = [ ...sheet.matchAll(/\[([^\]\n]+)\]/g) ].map((match) => match[1])
  return bracketed.some((token) => CHORD.test(token)) ? "chordpro" : "ultimate_guitar"
}

// The Ultimate Guitar parser takes any line of words starting with A to G for chords ("From",
// "Californication") and transposes them. A line is chords only if each such word is a chord symbol,
// or a quick run of them joined by dashes (Em-G7-C-B7).
const chordWord = (word) => !/^[A-G]/.test(word) || isChordSymbol(word) || word.split("-").filter(Boolean).every(isChordSymbol)

class SheetParser extends UltimateGuitarParser {
  parseNonEmptyLine(line) {
    if (line.trim().split(/\s+/).every(chordWord)) return super.parseNonEmptyLine(line)

    // What chordsheetjs 18 does with a line that isn't chords.
    this.chordLyricsPair = this.songLine.addChordLyricsPair()
    this.chordLyricsPair.lyrics = line
  }
}

function parse(sheet, format) {
  if (format === "ultimate_guitar") {
    return new SheetParser({ preserveWhitespace: false }).parse(sheet.replace(UG_MARKUP, ""))
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

// Splits a sheet into text and tab parts: ChordPro {start_of_tab}..{end_of_tab} sections, and runs of
// two or more tab staff lines. Tabs are fret numbers, so they're shown as written, never transposed.
export function splitTabs(sheet) {
  const lines = sheet.replace(UG_MARKUP, "").split(/\r?\n/)
  const segments = []
  let text = []
  // A section heading right above a tab ([Solo]) belongs to the tab, so it can't drift into another column.
  const takeLabel = () => {
    const last = text.findLastIndex((line) => line.trim())
    const match = last === -1 ? null : text[last].match(SECTION_LABEL)
    if (!match || CHORD.test(match[1])) return null
    text = text.slice(0, last)
    return match[1].trim()
  }
  const flushText = () => {
    if (text.some((line) => line.trim())) segments.push({ type: "text", text: text.join("\n") })
    text = []
  }

  for (let i = 0; i < lines.length;) {
    const start = lines[i].match(TAB_START)
    if (start) {
      const end = lines.findIndex((line, j) => j > i && TAB_END.test(line))
      const stop = end === -1 ? lines.length : end
      const label = start[1]?.trim() || takeLabel()
      flushText()
      segments.push({ type: "tab", lines: lines.slice(i + 1, stop), label })
      i = stop + 1
      continue
    }

    let j = i
    while (j < lines.length && STAFF.test(lines[j])) j++
    if (j - i >= 2) {
      const label = takeLabel()
      flushText()
      segments.push({ type: "tab", lines: lines.slice(i, j), label })
      i = j
    } else {
      text.push(lines[i])
      i++
    }
  }
  flushText()
  return segments
}

// The sheet as written, moved to the sounding key, then to the room key, then down by the viewer's capo.
function transform(song, { writtenKey, writtenCapo, key, capo }) {
  let shown = song.setKey(writtenKey).setCapo(writtenCapo).decapo()
  if (key) shown = shown.changeKey(key)
  if (capo > 0) shown = shown.transpose(-capo)
  return shown.setCapo(null)
}

function textHtml(text, format, options) {
  const song = parse(text, format)
  return new HtmlDivFormatter().format(escaped(options ? transform(song, options) : song))
}

function tabHtml({ lines, label }, note) {
  const heading = label ? `<h3 class="label">${escapeHtml(label)}</h3>` : ""
  const asWritten = note ? `<p class="tab-note">${escapeHtml(note)}</p>` : ""
  return `<div class="tab-block-wrap">${heading}${asWritten}<pre class="tab-block">${escapeHtml(lines.join("\n"))}</pre></div>`
}

// A sheet that can't be read is shown as plain text rather than not at all.
export function renderSheet({ sheet, format, writtenKey, writtenCapo = 0, key, capo = 0 }) {
  try {
    const options = writtenKey ? { writtenKey, writtenCapo, key, capo } : null
    const shownKey = options ? transform(new ChordProParser().parse(`[${writtenKey}]`), options).key : null
    const note = shownKey && shownKey !== writtenKey ? `Tab as written: ${writtenKey}${writtenCapo ? `, capo ${writtenCapo}` : ""}` : null
    const html = splitTabs(sheet)
      .map((segment) => (segment.type === "tab" ? tabHtml(segment, note) : textHtml(segment.text, format, options)))
      .join("")
    return { html, shownKey, transposed: Boolean(options) }
  } catch (error) {
    console.warn("Showing the sheet as plain text, it couldn't be read:", error.message)
    return { html: `<pre class="sheet-plain">${escapeHtml(sheet)}</pre>`, shownKey: null, transposed: false }
  }
}

// "Capo 4th fret" near the top: Ultimate Guitar sheets give the capo as text, which the parser skips.
// Further down, sheets chart the same chords at other capos. The importer uses the same rule.
const CAPO_LINE = /^[^\w\n]*capo(?![a-z])[^\w\n]*(?:(?:on|at|the)\s+)*(\d{1,2})(?!\d)/im

function capoLine(sheet) {
  const capo = Number(sheet.split(/\r?\n/).slice(0, 10).join("\n").match(CAPO_LINE)?.[1] ?? 0)
  return capo >= 1 && capo <= 11 ? capo : null
}

// Tab parts become ChordPro tab sections, so they survive the conversion untouched.
export function toChordPro({ sheet, format }) {
  let key = null
  let capo = null
  const parts = splitTabs(sheet).map((segment) => {
    if (segment.type === "tab") return `{start_of_tab${segment.label ? `: ${segment.label}` : ""}}\n${segment.lines.join("\n")}\n{end_of_tab}`

    const song = parse(segment.text, format)
    key ??= song.key
    capo ??= song.capo ? Number(song.capo) : null
    return new ChordProFormatter().format(song).trim()
  })
  return { chordpro: parts.join("\n\n"), key, capo: capo ?? capoLine(sheet) }
}
