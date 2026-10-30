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

  // A refresh must never throw away what someone is typing: leave a form or frame with unsaved input alone.
  keepUnsavedInput(event) {
    const element = event.target
    if (element.matches?.("form, turbo-frame") && this.#hasUnsavedInput(element)) event.preventDefault()
  }

  #hasUnsavedInput(container) {
    return [ ...container.querySelectorAll("input, textarea, select") ].some((field) => {
      if (field.type === "checkbox" || field.type === "radio") return field.checked !== field.defaultChecked
      if (field.tagName === "SELECT") return [ ...field.options ].some((option) => option.selected !== option.defaultSelected)
      return field.value !== field.defaultValue
    })
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
