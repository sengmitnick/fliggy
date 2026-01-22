import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = [
    "modal",
    "contactNameInput",
    "contactPhoneInput"
  ]

  declare readonly modalTarget: HTMLElement
  declare readonly contactNameInputTarget: HTMLInputElement
  declare readonly contactPhoneInputTarget: HTMLInputElement

  connect(): void {
    console.log("ContactSelector connected")
  }

  disconnect(): void {
    console.log("ContactSelector disconnected")
  }

  // Open modal
  openModal(event: Event): void {
    event.preventDefault()
    console.log("Opening contact selector modal")
    
    this.modalTarget.classList.remove('hidden')
    document.body.style.overflow = 'hidden'
  }

  // Close modal
  closeModal(): void {
    this.modalTarget.classList.add('hidden')
    document.body.style.overflow = ''
  }

  // Select a passenger as contact
  selectPassenger(event: Event): void {
    const target = event.currentTarget as HTMLElement
    const passengerName = target.dataset.passengerName || ''
    const passengerPhone = target.dataset.passengerPhone || ''

    console.log("Selected contact:", { passengerName, passengerPhone })

    // Update form inputs
    this.contactNameInputTarget.value = passengerName
    this.contactPhoneInputTarget.value = passengerPhone

    // Close modal
    this.closeModal()
  }

  // Stop propagation for inner clicks
  stopPropagation(event: Event): void {
    event.stopPropagation()
  }
}
