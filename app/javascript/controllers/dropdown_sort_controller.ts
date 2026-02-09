import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]
  
  declare readonly menuTarget: HTMLElement
  
  toggle(event: Event) {
    event.preventDefault()
    event.stopPropagation()
    this.menuTarget.classList.toggle('hidden')
  }
  
  close(event: Event) {
    if (!this.element.contains(event.target as Node)) {
      this.menuTarget.classList.add('hidden')
    }
  }
  
  connect() {
    document.addEventListener('click', this.close.bind(this))
  }
  
  disconnect() {
    document.removeEventListener('click', this.close.bind(this))
  }
}
