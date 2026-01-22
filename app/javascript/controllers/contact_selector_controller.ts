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

  // Select a contact
  selectContact(event: Event): void {
    const target = event.currentTarget as HTMLElement
    const contactName = target.dataset.contactName || ''
    const contactPhone = target.dataset.contactPhone || ''

    console.log("Selected contact:", { contactName, contactPhone })

    // Update form inputs
    this.contactNameInputTarget.value = contactName
    this.contactPhoneInputTarget.value = contactPhone

    // Close modal
    this.closeModal()
  }

  // Stop propagation for inner clicks
  stopPropagation(event: Event): void {
    event.stopPropagation()
  }
}
