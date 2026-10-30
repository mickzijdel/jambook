import { Controller } from "@hotwired/stimulus"
import { renderSheet } from "helpers/chord_sheet_helpers"
import { recall, remember } from "helpers/device_store"
import { wrapTab } from "helpers/tab_wrap"

const MIN_TAB_SIZE = 14

// Renders a chord sheet in the given key, shifted down by this viewer's own capo for this song.
export default class extends Controller {
  static targets = [ "output", "status", "capo" ]
  static values = {
    sheet: String,
    format: { type: String, default: "chordpro" },
    writtenKey: String,
    writtenCapo: { type: Number, default: 0 },
    key: String,
    songId: Number
  }

  // Firefox and Safari scroll a focused control to the nearest edge: keep it clear of the pinned header.
  #header = new ResizeObserver(([ entry ]) => {
    document.documentElement.style.scrollPaddingTop = `${entry.target.offsetHeight}px`
  })

  connect() {
    const head = this.element.querySelector(".song-head")
    if (head) this.#header.observe(head)
    this.render()
  }

  disconnect() {
    this.#header.disconnect()
    document.documentElement.style.scrollPaddingTop = ""
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
    this.fitTabs()
    // The first fit measures the fallback font if Chivo Mono is still loading.
    document.fonts.ready.then(() => this.fitTabs())
    if (this.hasCapoTarget) this.capoTarget.textContent = capo
    this.statusTarget.textContent = transposed ? `you play ${shownKey} shapes` : "Key unknown, chords as written"
  }

  // A tab that fits the screen at 14px or more shrinks to fit; a wider one breaks at its bar lines
  // first, and any part still too wide shrinks (down to 8px, Mick's call over a size floor).
  fitTabs() {
    if (!this.hasOutputTarget) return

    for (const block of this.outputTarget.querySelectorAll(".tab-block")) {
      block.dataset.staff ??= block.textContent
      block.textContent = block.dataset.staff
      block.style.fontSize = ""
      const size = parseFloat(getComputedStyle(block).fontSize)
      if (size * block.clientWidth < MIN_TAB_SIZE * block.scrollWidth) {
        const lines = block.dataset.staff.split("\n")
        const columns = Math.floor(block.clientWidth * Math.max(...lines.map((line) => line.length)) / block.scrollWidth)
        block.textContent = wrapTab(lines, columns).join("\n")
      }
      if (block.scrollWidth > block.clientWidth) {
        block.style.fontSize = `${Math.max(8, Math.floor(size * block.clientWidth / block.scrollWidth * 10) / 10)}px`
      }
    }
  }

  get #capo() {
    const stored = recall(`capo:${this.songIdValue}`)
    return stored === null ? this.writtenCapoValue : Number(stored)
  }

  #setCapo(capo) {
    remember(`capo:${this.songIdValue}`, Math.min(11, Math.max(0, capo)))
    this.render()
  }
}
