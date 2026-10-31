import { Controller } from "@hotwired/stimulus"
import { diagramSvg, findShapes } from "helpers/chord_shapes"
import { recall, remember } from "helpers/device_store"

// Chord boxes for the chords on screen, so they follow the room key and this viewer's capo: a bar of
// every chord in the song, and a card with the other voicings for a chord tapped in the sheet or the bar.
export default class extends Controller {
  static targets = [ "bar", "toggle", "card", "name", "diagram", "note", "voicings", "count" ]
  static values = { shapesUrl: String }

  #shapes = null
  #bar = []
  #voicing = new Map()
  #shown = null
  #opener = null

  connect() {
    this.refresh()
  }

  // After every render: the chords may have moved, so redraw the bar and close the card.
  async refresh() {
    if (this.cardTarget.matches(":popover-open")) this.cardTarget.hidePopover()
    const chords = await this.#data()
    const names = [ ...new Set([ ...this.element.querySelectorAll("#sheet-output .chord") ].map((chord) => chord.textContent.trim()).filter(Boolean)) ]
    this.#bar = names.flatMap((name) => {
      const found = findShapes(name, chords)
      return found ? [ { name, found } ] : []
    })
    this.#drawBar()
  }

  // A bar too long for the screen scrolls sideways; this phone can choose to see every chord instead.
  toggleBar() {
    remember("chord-bar", this.#expanded ? "scroll" : "expanded")
    this.fitBar()
  }

  fitBar() {
    this.barTarget.classList.toggle("expanded", this.#expanded)
    this.toggleTarget.hidden = !this.#expanded && this.barTarget.scrollWidth <= this.barTarget.clientWidth
    this.toggleTarget.setAttribute("aria-expanded", this.#expanded)
    this.toggleTarget.textContent = this.#expanded ? "Show fewer chords" : "Show all chords"
  }

  get #expanded() {
    return recall("chord-bar") === "expanded"
  }

  openFromBar({ currentTarget, params: { name } }) {
    this.#open(name, currentTarget)
  }

  openFromSheet({ target }) {
    const name = target.closest(".chord")?.textContent.trim()
    if (name) this.#open(name, null)
  }

  next() {
    this.#turn(1)
  }

  previous() {
    this.#turn(-1)
  }

  // Closed with Esc or Close while the keyboard was in the card: give focus back to the bar.
  closing({ newState }) {
    if (newState === "closed" && this.cardTarget.contains(document.activeElement)) this.#opener?.focus({ preventScroll: true })
  }

  async #open(name, opener) {
    this.#shown = { name, found: findShapes(name, await this.#data()) }
    this.#opener = opener
    this.nameTarget.textContent = name
    this.#drawCard()
    if (!this.cardTarget.matches(":popover-open")) this.cardTarget.showPopover()
    this.cardTarget.focus()
  }

  #turn(step) {
    const { name, found } = this.#shown
    this.#voicing.set(name, (this.#index(name) + step + found.positions.length) % found.positions.length)
    this.#drawCard()
    this.#drawBar()
  }

  #drawBar() {
    this.barTarget.innerHTML = this.#bar.map(({ name, found }) => `
      <li><button type="button" class="chord-bar-item" data-action="chord-diagrams#openFromBar" data-chord-diagrams-name-param="${escape(name)}">
        <span class="chord-name">${escape(name)}</span><span aria-hidden="true">${diagramSvg(name, found.positions[this.#index(name)])}</span>
      </button></li>`).join("")
    this.fitBar()
  }

  #drawCard() {
    const { name, found } = this.#shown
    this.diagramTarget.innerHTML = found ? diagramSvg(name, found.positions[this.#index(name)]) : ""
    this.noteTarget.textContent = found ? found.note ?? "" : "No chord diagram for this one."
    this.voicingsTarget.hidden = !found || found.positions.length < 2
    this.countTarget.textContent = found ? `${this.#index(name) + 1} of ${found.positions.length}` : ""
  }

  #index(name) {
    return this.#voicing.get(name) ?? 0
  }

  #data() {
    this.#shapes ??= fetch(this.shapesUrlValue).then((response) => response.json()).catch((error) => {
      console.warn("Chord shapes didn't load:", error.message)
      return {}
    })
    return this.#shapes
  }
}

const escape = (text) => text.replace(/[&<>"']/g, (character) => `&#${character.charCodeAt(0)};`)
