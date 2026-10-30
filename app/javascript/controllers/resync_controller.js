import { Controller } from "@hotwired/stimulus"

// Broadcasts missed while the socket was down are not replayed: re-fetch the page when the
// stream reconnects, and when a phone wakes up.
export default class extends Controller {
  #observer
  #lost = false

  connect() {
    this.#observer = new MutationObserver(() => this.#check())
    this.#observer.observe(this.element, { subtree: true, attributes: true, attributeFilter: [ "connected" ] })
  }

  disconnect() {
    this.#observer.disconnect()
  }

  refresh() {
    if (document.visibilityState === "visible") Turbo.session.refresh(location.href)
  }

  #check() {
    const source = this.element.querySelector("turbo-cable-stream-source")
    if (!source) return

    if (!source.hasAttribute("connected")) {
      this.#lost = true
    } else if (this.#lost) {
      this.#lost = false
      this.refresh()
    }
  }
}
