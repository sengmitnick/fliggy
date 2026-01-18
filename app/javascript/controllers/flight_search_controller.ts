import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = ["departureInput", "destinationInput"]
  
  declare readonly departureInputTarget: HTMLInputElement
  declare readonly destinationInputTarget: HTMLInputElement
  declare readonly hasDepartureInputTarget: boolean
  declare readonly hasDestinationInputTarget: boolean

  // Validate form before submission
  validateForm(event: Event): void {
    if (!this.hasDepartureInputTarget || !this.hasDestinationInputTarget) {
      return
    }

    const departureCity = this.departureInputTarget.value.trim()
    const destinationCity = this.destinationInputTarget.value.trim()

    // Check if departure and destination are the same
    if (departureCity && destinationCity && departureCity === destinationCity) {
      event.preventDefault()
      alert('出发地与目的地不能相同')
      return
    }
  }
}
