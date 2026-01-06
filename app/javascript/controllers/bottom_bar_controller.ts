import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect(): void {
    console.log("Bottom bar controller connected")
  }

  openModal(): void {
    // Trigger modal open via CustomEvent
    const event = new CustomEvent("bottom-bar:open-modal")
    window.dispatchEvent(event)
  }
}
