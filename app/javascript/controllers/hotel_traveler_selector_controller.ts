import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = [
    "modal",
    "guestNameInput",
    "guestPhoneInput",
    "selectedPassenger",
    "checkbox"
  ]

  static values = {
    selectedPassengerId: String,
    selectedPassengerName: String,
    selectedPassengerPhone: String
  }

  declare readonly modalTarget: HTMLElement
  declare readonly guestNameInputTarget: HTMLInputElement
  declare readonly guestPhoneInputTarget: HTMLInputElement
  declare readonly selectedPassengerTarget: HTMLElement
  declare readonly hasSelectedPassengerTarget: boolean
  declare readonly checkboxTargets: HTMLInputElement[]

  declare selectedPassengerIdValue: string
  declare selectedPassengerNameValue: string
  declare selectedPassengerPhoneValue: string

  connect(): void {
    console.log("HotelTravelerSelector connected")
  }

  // Open modal
  openModal(): void {
    console.log("Opening traveler selector modal")
    this.modalTarget.classList.remove('hidden')
    document.body.style.overflow = 'hidden'
  }

  // Close modal
  closeModal(): void {
    this.modalTarget.classList.add('hidden')
    document.body.style.overflow = ''
  }

  // Toggle passenger selection via checkbox
  togglePassenger(event: Event): void {
    const checkbox = event.currentTarget as HTMLInputElement
    const passengerId = checkbox.dataset.passengerId || ''
    const passengerName = checkbox.dataset.passengerName || ''
    const passengerPhone = checkbox.dataset.passengerPhone || ''

    if (checkbox.checked) {
      // Uncheck all other checkboxes (only allow one selection)
      this.checkboxTargets.forEach(cb => {
        if (cb !== checkbox) {
          cb.checked = false
        }
      })

      console.log("Selected passenger:", { passengerId, passengerName, passengerPhone })

      // Store selected values
      this.selectedPassengerIdValue = passengerId
      this.selectedPassengerNameValue = passengerName
      this.selectedPassengerPhoneValue = passengerPhone

      // Update form inputs
      this.guestNameInputTarget.value = passengerName
      this.guestPhoneInputTarget.value = passengerPhone

      // Update selected display if exists
      if (this.hasSelectedPassengerTarget) {
        this.selectedPassengerTarget.textContent = passengerName
      }

      // Close modal after selection
      this.closeModal()
    } else {
      // Unchecked - clear form inputs
      console.log("Unselected passenger")
      
      this.selectedPassengerIdValue = ''
      this.selectedPassengerNameValue = ''
      this.selectedPassengerPhoneValue = ''

      // Clear form inputs
      this.guestNameInputTarget.value = ''
      this.guestPhoneInputTarget.value = ''

      // Clear selected display if exists
      if (this.hasSelectedPassengerTarget) {
        this.selectedPassengerTarget.textContent = ''
      }
    }
  }

  // Manual input - clear selection
  clearSelection(): void {
    this.selectedPassengerIdValue = ''
    this.selectedPassengerNameValue = ''
    this.selectedPassengerPhoneValue = ''
  }

  // Stop propagation for inner clicks
  stopPropagation(event: Event): void {
    event.stopPropagation()
  }
}
