import { Controller } from "@hotwired/stimulus"

const DISMISSED = "install-hint-dismissed"

// iOS Safari has no install prompt, so tell iPhone users how to add Jambook to the home screen.
export default class extends Controller {
  connect() {
    const iOS = /iPad|iPhone|iPod/.test(navigator.userAgent)
    const installed = window.navigator.standalone === true
    this.element.hidden = !iOS || installed || this.#dismissed
  }

  dismiss() {
    this.element.hidden = true
    try {
      localStorage.setItem(DISMISSED, "1")
    } catch {
      console.info("Install hint hidden for this page only: browser storage is blocked.")
    }
  }

  get #dismissed() {
    try {
      return localStorage.getItem(DISMISSED) === "1"
    } catch {
      return false
    }
  }
}
