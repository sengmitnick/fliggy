import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  connect(): void {
    // Auto-dismiss after 2 seconds
    setTimeout(() => {
      this.element.classList.add('animate-fade-out')
      setTimeout(() => {
        if (this.element.parentNode) {
          this.element.parentNode.removeChild(this.element)
        }
      }, 300)
    }, 2000)
  }
}
