import { Controller } from "@hotwired/stimulus"
import { renderSheet } from "helpers/chord_sheet_helpers"

// Renders a chord sheet in the given key, shifted down by this viewer's own capo for this song.
export default class extends Controller {
  static targets = [ "output", "status" ]
  static values = {
    sheet: String,
    format: { type: String, default: "chordpro" },
    writtenKey: String,
    writtenCapo: { type: Number, default: 0 },
    key: String,
    songId: Number,
    label: { type: String, default: "Key" }
  }

  #memory = new Map()

  connect() {
    this.render()
  }

  sheetValueChanged() {
    this.render()
  }

  keyValueChanged() {
    this.render()
  }

  songIdValueChanged(_current, previous) {
    if (previous) window.scrollTo(0, 0)
    this.render()
  }

  capoUp() {
    this.#setCapo(this.#capo + 1)
  }

  capoDown() {
    this.#setCapo(this.#capo - 1)
  }

  render() {
    if (!this.hasOutputTarget) return

    const capo = this.#capo
    const { html, shownKey, transposed } = renderSheet({
      sheet: this.sheetValue, format: this.formatValue, writtenKey: this.writtenKeyValue,
      writtenCapo: this.writtenCapoValue, key: this.keyValue, capo
    })
    this.outputTarget.innerHTML = html
    this.statusTarget.textContent = transposed ? `${this.labelValue} ${this.keyValue} · your capo ${capo} · ${shownKey} shapes` : "Key unknown"
  }

  get #capo() {
    const stored = this.#read()
    return stored === null ? this.writtenCapoValue : Number(stored)
  }

  #setCapo(capo) {
    this.#write(Math.min(11, Math.max(0, capo)))
    this.render()
  }

  get #storageKey() {
    return `capo:${this.songIdValue}`
  }

  // Private browsing can make localStorage throw; the in-memory copy then lasts the page's lifetime.
  #read() {
    try {
      return localStorage.getItem(this.#storageKey) ?? this.#memory.get(this.#storageKey) ?? null
    } catch {
      return this.#memory.get(this.#storageKey) ?? null
    }
  }

  #write(capo) {
    this.#memory.set(this.#storageKey, String(capo))
    try {
      localStorage.setItem(this.#storageKey, capo)
    } catch {
      console.info("Capo kept for this page only: browser storage is blocked.")
    }
  }
}
