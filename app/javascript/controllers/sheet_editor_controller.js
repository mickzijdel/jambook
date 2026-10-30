import { Controller } from "@hotwired/stimulus"
import { detectFormat, renderSheet, toChordPro } from "helpers/chord_sheet_helpers"

// Previews a pasted sheet, picks up its key and capo, and saves new text as ChordPro.
// The server still validates; this only fills in what the paste already says.
export default class extends Controller {
  static targets = [ "sheet", "format", "writtenKey", "writtenCapo", "preview" ]

  #original

  connect() {
    this.#original = this.sheetTarget.value
  }

  preview() {
    const sheet = this.sheetTarget.value
    const format = detectFormat(sheet)
    this.formatTarget.value = format

    try {
      const { key, capo } = toChordPro({ sheet, format })
      if (key && !this.writtenKeyTarget.value) this.writtenKeyTarget.value = key
      if (capo && Number(this.writtenCapoTarget.value || 0) === 0) this.writtenCapoTarget.value = capo
    } catch (error) {
      console.info(`Not readable as ${format} yet:`, error.message)
    }
    this.previewTarget.innerHTML = renderSheet({ sheet, format }).html
  }

  // Untouched text keeps its stored format; new text is converted to ChordPro when it can be.
  submit() {
    const sheet = this.sheetTarget.value
    if (!sheet.trim() || sheet === this.#original) return

    try {
      this.sheetTarget.value = toChordPro({ sheet, format: detectFormat(sheet) }).chordpro
      this.formatTarget.value = "chordpro"
    } catch (error) {
      this.formatTarget.value = "ultimate_guitar"
      console.info("Saved the sheet as chords over lyrics, it isn't valid ChordPro:", error.message)
    }
  }
}
