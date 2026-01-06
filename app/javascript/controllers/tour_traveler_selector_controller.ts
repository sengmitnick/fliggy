import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = [
    "modal",
    "travelerNameInput",
    "travelerIdInput"
  ]

  static values = {
    selectedPassengerId: String,
    selectedPassengerName: String,
    selectedPassengerIdNumber: String,
    travelerIndex: Number
  }

  declare readonly modalTarget: HTMLElement
  declare readonly travelerNameInputTargets: HTMLInputElement[]
  declare readonly travelerIdInputTargets: HTMLInputElement[]

  declare selectedPassengerIdValue: string
  declare selectedPassengerNameValue: string
  declare selectedPassengerIdNumberValue: string
  declare travelerIndexValue: number

  connect(): void {
    console.log("TourTravelerSelector connected")
  }

  disconnect(): void {
    console.log("TourTravelerSelector disconnected")
  }

  // Open modal for specific traveler
  openModal(event: Event): void {
    const target = event.currentTarget as HTMLElement
    const travelerIndex = parseInt(target.dataset.travelerIndex || '0')
    
    console.log("Opening traveler selector modal for index:", travelerIndex)
    
    this.travelerIndexValue = travelerIndex
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
    const passengerIdNumber = target.dataset.passengerIdNumber || ''

    console.log("Selected passenger:", { passengerId, passengerName, passengerIdNumber, travelerIndex: this.travelerIndexValue })

    // Store selected values
    this.selectedPassengerIdValue = passengerId
    this.selectedPassengerNameValue = passengerName
    this.selectedPassengerIdNumberValue = passengerIdNumber

    // Update form inputs for specific traveler
    if (this.travelerNameInputTargets[this.travelerIndexValue]) {
      this.travelerNameInputTargets[this.travelerIndexValue].value = passengerName
    }
    if (this.travelerIdInputTargets[this.travelerIndexValue]) {
      this.travelerIdInputTargets[this.travelerIndexValue].value = passengerIdNumber
    }

    // Close modal
    this.closeModal()
  }

  // Stop propagation for inner clicks
  stopPropagation(event: Event): void {
    event.stopPropagation()
  }
}
