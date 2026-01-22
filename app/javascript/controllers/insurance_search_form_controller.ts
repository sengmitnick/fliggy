import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = ["destinationInput"]

  declare readonly destinationInputTarget: HTMLInputElement

  connect(): void {
    console.log("InsuranceSearchForm connected")
  }

  // Validate form on submit
  validateSubmit(event: Event): void {
    const destination = this.destinationInputTarget.value.trim()
    
    if (!destination) {
      event.preventDefault()
      this.showAlert("请选择目的地")
    }
  }

  private showAlert(message: string): void {
    // Use window.showToast if available, otherwise use alert
    if (typeof (window as any).showToast === 'function') {
      (window as any).showToast(message)
    } else {
      alert(message)
    }
  }
}
