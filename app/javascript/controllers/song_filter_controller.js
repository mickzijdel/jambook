import { Controller } from "@hotwired/stimulus"

// Filters the song list as you type, without leaving the page; Enter still searches on the server.
export default class extends Controller {
  static targets = [ "query", "list", "empty" ]

  filter() {
    const words = this.queryTarget.value.toLowerCase().split(/\s+/).filter(Boolean)
    let shown = 0
    for (const row of this.listTarget.children) {
      const match = words.every((word) => row.dataset.search.includes(word))
      row.hidden = !match
      if (match) shown++
    }
    this.emptyTarget.hidden = shown > 0
  }

  submit() {
    this.element.requestSubmit()
  }
}
