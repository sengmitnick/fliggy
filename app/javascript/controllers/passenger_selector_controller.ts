import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "display",
    "modal", 
    "name",
    "idType",
    "idNumber",
    "phone",
    "driverName",
    "driverIdNumber",
    "contactPhone"
  ]

  static values = {
    selectedId: Number
  }

  declare readonly displayTarget: HTMLElement
  declare readonly modalTarget: HTMLElement
  declare readonly nameTarget: HTMLElement
  declare readonly idTypeTarget: HTMLElement
  declare readonly idNumberTarget: HTMLElement
  declare readonly phoneTarget: HTMLElement
  declare readonly driverNameTarget: HTMLInputElement
  declare readonly driverIdNumberTarget: HTMLInputElement
  declare readonly contactPhoneTarget: HTMLInputElement
  declare selectedIdValue: number

  toggleEdit(event: Event): void {
    event.preventDefault()
    event.stopPropagation()
    this.modalTarget.classList.remove("hidden")
    document.body.style.overflow = "hidden"
  }

  closeModal(event: Event): void {
    event.preventDefault()
    event.stopPropagation()
    this.modalTarget.classList.add("hidden")
    document.body.style.overflow = ""
  }

  selectPassenger(event: Event): void {
    event.preventDefault()
    event.stopPropagation()
    
    const target = event.currentTarget as HTMLElement
    const passengerId = target.dataset.passengerId
    const name = target.dataset.passengerName || ""
    const idType = target.dataset.passengerIdType || ""
    const idNumber = target.dataset.passengerIdNumber || ""
    const phone = target.dataset.passengerPhone || "未填写"

    // Update display
    this.nameTarget.textContent = name
    this.idTypeTarget.textContent = idType
    this.idNumberTarget.textContent = idNumber
    this.phoneTarget.textContent = phone

    // Update hidden form fields
    this.driverNameTarget.value = name
    this.driverIdNumberTarget.value = idNumber
    this.contactPhoneTarget.value = phone === "未填写" ? "" : phone

    // Update selected state in modal
    const allItems = this.modalTarget.querySelectorAll('[data-passenger-id]')
    allItems.forEach(item => {
      const itemElement = item as HTMLElement
      if (itemElement.dataset.passengerId === passengerId) {
        itemElement.classList.add('border-blue-500', 'bg-blue-50')
        const circle = itemElement.querySelector('.w-5.h-5') as HTMLElement
        circle.classList.remove('border-gray-300')
        circle.classList.add('border-blue-500', 'bg-blue-500')
        const checkIcon = '<svg class="w-3 h-3 text-white" fill="currentColor" viewBox="0 0 20 20">' +
          '<path fill-rule="evenodd" ' +
          'd="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" ' +
          'clip-rule="evenodd"></path>' +
          '</svg>'
        circle.innerHTML = checkIcon
      } else {
        itemElement.classList.remove('border-blue-500', 'bg-blue-50')
        const circle = itemElement.querySelector('.w-5.h-5') as HTMLElement
        circle.classList.remove('border-blue-500', 'bg-blue-500')
        circle.classList.add('border-gray-300')
        circle.innerHTML = ''
      }
    })

    // Store selected ID
    this.selectedIdValue = parseInt(passengerId || "0")

    // Close modal
    this.closeModal(event)
  }
}
