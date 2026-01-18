import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = ["modal", "name", "phone", "address", "selectedInfo"]
  static values = {
    addressId: String
  }

  declare readonly modalTarget: HTMLElement
  declare readonly nameTarget: HTMLElement
  declare readonly phoneTarget: HTMLElement
  declare readonly addressTarget: HTMLElement
  declare readonly selectedInfoTarget: HTMLElement
  declare addressIdValue: string

  connect(): void {
    console.log("AddressSelector connected")
  }

  openModal(): void {
    this.modalTarget.classList.remove('hidden')
  }

  closeModal(): void {
    this.modalTarget.classList.add('hidden')
  }

  selectAddress(event: Event): void {
    const target = event.currentTarget as HTMLElement
    const addressId = target.dataset.addressId || ''
    const name = target.dataset.name || ''
    const phone = target.dataset.phone || ''
    const address = target.dataset.address || ''

    // Update hidden field
    this.addressIdValue = addressId
    
    // Update display
    this.nameTarget.textContent = name
    this.phoneTarget.textContent = phone
    this.addressTarget.textContent = address
    
    // Update order controller's delivery address
    const visaOrderElement = document.querySelector('[data-controller*="visa-order"]')
    if (visaOrderElement) {
      const input = visaOrderElement.querySelector('[data-visa-order-target="deliveryAddress"]') as HTMLInputElement
      if (input) {
        input.value = address
      }
    }
    
    this.closeModal()
  }
}
