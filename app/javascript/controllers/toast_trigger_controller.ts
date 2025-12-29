import { Controller } from "@hotwired/stimulus"

// Automatically displays a toast message when the controller connects
// Used with Turbo Stream responses to show validation errors
export default class extends Controller {
  static values = {
    message: String
  }

  declare messageValue: string

  connect() {
    // Show the toast immediately when element is inserted
    if (this.messageValue && window.showToast) {
      window.showToast(this.messageValue)
    }
    
    // Remove the trigger element from DOM
    this.element.remove()
  }
}
