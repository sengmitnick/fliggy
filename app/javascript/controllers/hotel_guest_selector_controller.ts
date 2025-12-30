import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = [
    "modal",
    "roomsCount",
    "adultsCount",
    "childrenCount",
    "roomsInput",
    "adultsInput",
    "childrenInput",
    "displayText"
  ]

  static values = {
    rooms: Number,
    adults: Number,
    children: Number
  }

  declare readonly modalTarget: HTMLElement
  declare readonly roomsCountTarget: HTMLElement
  declare readonly adultsCountTarget: HTMLElement
  declare readonly childrenCountTarget: HTMLElement
  declare readonly roomsInputTarget: HTMLInputElement
  declare readonly adultsInputTarget: HTMLInputElement
  declare readonly childrenInputTarget: HTMLInputElement
  declare readonly displayTextTarget: HTMLElement

  declare roomsValue: number
  declare adultsValue: number
  declare childrenValue: number

  connect(): void {
    console.log("HotelGuestSelector connected")
    // Initialize values from inputs or defaults
    this.roomsValue = parseInt(this.roomsInputTarget.value) || 1
    this.adultsValue = parseInt(this.adultsInputTarget.value) || 1
    this.childrenValue = parseInt(this.childrenInputTarget.value) || 0
    this.updateDisplay()
  }

  disconnect(): void {
    console.log("HotelGuestSelector disconnected")
  }

  // Open modal
  openModal(): void {
    this.modalTarget.classList.remove('hidden')
    document.body.style.overflow = 'hidden'
  }

  // Close modal
  closeModal(): void {
    this.modalTarget.classList.add('hidden')
    document.body.style.overflow = ''
  }

  // Increment rooms
  incrementRooms(): void {
    if (this.roomsValue < 10) {
      this.roomsValue++
      this.updateCounts()
    }
  }

  // Decrement rooms
  decrementRooms(): void {
    if (this.roomsValue > 1) {
      this.roomsValue--
      this.updateCounts()
    }
  }

  // Increment adults
  incrementAdults(): void {
    if (this.adultsValue < 20) {
      this.adultsValue++
      this.updateCounts()
    }
  }

  // Decrement adults
  decrementAdults(): void {
    if (this.adultsValue > 1) {
      this.adultsValue--
      this.updateCounts()
    }
  }

  // Increment children
  incrementChildren(): void {
    if (this.childrenValue < 10) {
      this.childrenValue++
      this.updateCounts()
    }
  }

  // Decrement children
  decrementChildren(): void {
    if (this.childrenValue > 0) {
      this.childrenValue--
      this.updateCounts()
    }
  }

  // Reset to defaults
  reset(): void {
    this.roomsValue = 1
    this.adultsValue = 1
    this.childrenValue = 0
    this.updateCounts()
  }

  // Confirm and close
  confirm(): void {
    this.updateDisplay()
    this.closeModal()
  }

  // Update count displays and hidden inputs
  private updateCounts(): void {
    this.roomsCountTarget.textContent = this.roomsValue.toString()
    this.adultsCountTarget.textContent = this.adultsValue.toString()
    this.childrenCountTarget.textContent = this.childrenValue.toString()
    
    this.roomsInputTarget.value = this.roomsValue.toString()
    this.adultsInputTarget.value = this.adultsValue.toString()
    this.childrenInputTarget.value = this.childrenValue.toString()
  }

  // Update display text
  private updateDisplay(): void {
    this.displayTextTarget.textContent = `${this.roomsValue}间房 ${this.adultsValue}成人 ${this.childrenValue}儿童`
  }
}
