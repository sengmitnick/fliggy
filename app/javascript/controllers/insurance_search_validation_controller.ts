import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = ["destinationInput", "submitButton"]

  declare readonly destinationInputTarget: HTMLInputElement
  declare readonly submitButtonTarget: HTMLButtonElement

  connect(): void {
    console.log("InsuranceSearchValidation connected")
  }

  // Validate destination when clicking submit button
  validateDestination(event: Event): void {
    const destination = this.destinationInputTarget.value.trim()
    console.log("Checking destination:", destination)
    
    if (!destination) {
      event.preventDefault()
      event.stopPropagation()
      
      // Use window.showToast
      if (typeof (window as any).showToast === 'function') {
        (window as any).showToast('请选择目的地')
      } else {
        alert('请选择目的地')
      }
    }
  }
}
