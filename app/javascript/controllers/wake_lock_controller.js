import { Controller } from "@hotwired/stimulus"

// Keeps a phone's screen on while it shows the room, so nobody's chords go dark mid-song.
export default class extends Controller {
  #lock = null

  connect() {
    this.acquire()
  }

  disconnect() {
    this.#lock?.release()
    this.#lock = null
  }

  async acquire() {
    if (!("wakeLock" in navigator) || document.visibilityState !== "visible") return

    try {
      this.#lock = await navigator.wakeLock.request("screen")
    } catch (error) {
      console.info("Screen wake lock unavailable:", error.message)
    }
  }
}
