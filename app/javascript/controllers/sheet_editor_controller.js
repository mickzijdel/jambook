import { Controller } from "@hotwired/stimulus"
import { renderSheet, toChordPro } from "helpers/chord_sheet_helpers"

// Previews a pasted sheet, picks up its key and capo, and saves it as ChordPro.
// The server still validates; this only fills in what the paste already says.
export default class extends Controller {
  static targets = [ "sheet", "format", "writtenKey", "writtenCapo", "preview" ]

  preview() {
    const sheet = this.sheetTarget.value
    const format = this.#format(sheet)
    const { key, capo } = toChordPro({ sheet, format })

    this.formatTarget.value = format
    if (key && !this.writtenKeyTarget.value) this.writtenKeyTarget.value = key
    if (capo && Number(this.writtenCapoTarget.value || 0) === 0) this.writtenCapoTarget.value = capo
    this.previewTarget.innerHTML = renderSheet({ sheet, format }).html
  }

  submit() {
    const sheet = this.sheetTarget.value
    if (!sheet.trim()) return

    this.sheetTarget.value = toChordPro({ sheet, format: this.#format(sheet) }).chordpro
    this.formatTarget.value = "chordpro"
  }

  #format(sheet) {
    return /\{\w+:|\[[A-G][^\]]*\]/.test(sheet) ? "chordpro" : "ultimate_guitar"
  }
}
