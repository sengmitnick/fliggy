import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = [
    "modal",
    "passengerItem",
    "passengerIdInput",
    "nameDisplay",
    "idNumberDisplay",
    "phoneDisplay"
  ]

  static values = {
    selectedPassengerId: Number
  }

  declare readonly modalTarget: HTMLElement
  declare readonly passengerItemTargets: HTMLElement[]
  declare readonly passengerIdInputTarget: HTMLInputElement
  declare readonly nameDisplayTarget: HTMLElement
  declare readonly idNumberDisplayTarget: HTMLElement
  declare readonly phoneDisplayTarget: HTMLElement
  declare readonly hasIdNumberDisplayTarget: boolean
  declare readonly hasPhoneDisplayTarget: boolean
  declare selectedPassengerIdValue: number

  connect(): void {
    console.log("PolicyholderSelector connected", { 
      selectedPassengerId: this.selectedPassengerIdValue 
    })
    
    // Update initial selection UI
    if (this.selectedPassengerIdValue) {
      this.updateSelectedUI(this.selectedPassengerIdValue)
    }
  }

  disconnect(): void {
    console.log("PolicyholderSelector disconnected")
  }

  openModal(): void {
    this.modalTarget.classList.remove('hidden')
    document.body.style.overflow = 'hidden'
  }

  closeModal(): void {
    this.modalTarget.classList.add('hidden')
    document.body.style.overflow = ''
  }

  closeOnBackdrop(event: Event): void {
    if (event.target === event.currentTarget) {
      this.closeModal()
    }
  }

  selectPassenger(event: Event): void {
    const button = event.currentTarget as HTMLElement
    const passengerId = button.dataset.passengerId
    const passengerName = button.dataset.passengerName
    const passengerIdNumber = button.dataset.passengerIdNumber
    const passengerPhone = button.dataset.passengerPhone

    if (!passengerId) return

    // Update hidden input
    this.passengerIdInputTarget.value = passengerId
    this.selectedPassengerIdValue = parseInt(passengerId)

    // Update display
    this.nameDisplayTarget.textContent = passengerName || '未设置'
    
    if (this.hasIdNumberDisplayTarget && passengerIdNumber) {
      // Mask ID number: show first 6 and last 4, hide middle 8
      const maskedIdNumber = passengerIdNumber.replace(/(.{6})(.{8})(.*)/, '$1********$3')
      this.idNumberDisplayTarget.textContent = maskedIdNumber
    }
    
    if (this.hasPhoneDisplayTarget && passengerPhone) {
      this.phoneDisplayTarget.textContent = passengerPhone
    }

    // Update UI selection
    this.updateSelectedUI(parseInt(passengerId))

    // Close modal
    this.closeModal()
  }

  private updateSelectedUI(passengerId: number): void {
    // Remove all check icons
    this.passengerItemTargets.forEach(item => {
      const checkIcon = item.querySelector('.check-icon')
      if (checkIcon) {
        checkIcon.classList.add('hidden')
      }
      item.classList.remove('border-primary')
      item.classList.add('border-gray-200')
    })

    // Add check icon to selected item
    const selectedItem = this.passengerItemTargets.find(item => {
      return item.dataset.passengerId === passengerId.toString()
    })

    if (selectedItem) {
      const checkIcon = selectedItem.querySelector('.check-icon')
      if (checkIcon) {
        checkIcon.classList.remove('hidden')
      }
      selectedItem.classList.add('border-primary')
      selectedItem.classList.remove('border-gray-200')
    }
  }
}
