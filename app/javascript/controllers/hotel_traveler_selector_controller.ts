import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = [
    "modal",
    "guestNameInput",
    "guestPhoneInput",
    "selectedPassenger"
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

  // Select a passenger from the list
  selectPassenger(event: Event): void {
    const target = event.currentTarget as HTMLElement
    const passengerId = target.dataset.passengerId || ''
    const passengerName = target.dataset.passengerName || ''
    const passengerPhone = target.dataset.passengerPhone || ''

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

    // Close modal
    this.closeModal()
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
