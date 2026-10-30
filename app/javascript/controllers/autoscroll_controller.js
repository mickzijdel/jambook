import { Controller } from "@hotwired/stimulus"
import { recall, remember } from "helpers/device_store"

const DEFAULT_SPEED = 4
const MAX_SPEED = 10
// Pixels a second per speed step: at 4, about one chord-and-lyric line every four seconds.
const PIXELS_PER_STEP = 4

// Scrolls this device's page down at its own speed, like Ultimate Guitar's auto-scroll. Never synced:
// each phone keeps its own speed per song, and a new song from the host stops it.
export default class extends Controller {
  static targets = [ "toggle", "speed" ]
  static values = { songId: Number }

  #frame = null
  #last = null
  #y = 0
  #lock = null

  connect() {
    this.sync()
  }

  disconnect() {
    this.stop()
  }

  songIdValueChanged(_current, previous) {
    if (previous) this.stop()
  }

  // A host refresh morphs the page back to the server's "Scroll" and an empty speed: put ours back.
  sync() {
    if (!this.hasToggleTarget) return
    this.toggleTarget.textContent = this.#frame ? "Pause" : "Scroll"
    this.speedTarget.textContent = this.#speed
  }

  toggle() {
    this.#frame ? this.stop() : this.start()
  }

  start() {
    this.#y = window.scrollY
    this.#last = null
    this.#frame = requestAnimationFrame((time) => this.#step(time))
    this.sync()
    // Keep the screen on while it scrolls (the room page already does; a song page doesn't).
    navigator.wakeLock?.request("screen").then((lock) => (this.#frame ? (this.#lock = lock) : lock.release()), () => {})
  }

  stop() {
    cancelAnimationFrame(this.#frame)
    this.#frame = null
    this.#lock?.release()
    this.#lock = null
    this.sync()
  }

  faster() {
    this.#setSpeed(this.#speed + 1)
  }

  slower() {
    this.#setSpeed(this.#speed - 1)
  }

  #step(time) {
    // A swipe moved the page: carry on from where it is now.
    if (Math.abs(window.scrollY - this.#y) > 2) this.#y = window.scrollY
    if (this.#last !== null) this.#y += this.#speed * PIXELS_PER_STEP * (time - this.#last) / 1000
    this.#last = time
    window.scrollTo(0, this.#y)

    if (this.#y >= document.documentElement.scrollHeight - window.innerHeight) return this.stop()
    this.#frame = requestAnimationFrame((next) => this.#step(next))
  }

  get #speed() {
    return Number(recall(`scroll-speed:${this.songIdValue}`) ?? DEFAULT_SPEED)
  }

  #setSpeed(speed) {
    remember(`scroll-speed:${this.songIdValue}`, Math.min(MAX_SPEED, Math.max(1, speed)))
    this.sync()
  }
}
