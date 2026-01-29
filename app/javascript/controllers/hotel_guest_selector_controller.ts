import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = [
    // stimulus-validator: disable-next-line
    "modal",
    // stimulus-validator: disable-next-line
    "roomsCount",
    // stimulus-validator: disable-next-line
    "adultsCount",
    // stimulus-validator: disable-next-line
    "childrenCount",
    "roomsInput",
    "adultsInput",
    "childrenInput",
    "displayText"
  ]

  declare readonly hasRoomsInputTarget: boolean
  declare readonly hasAdultsInputTarget: boolean
  declare readonly hasChildrenInputTarget: boolean
  declare readonly hasDisplayTextTarget: boolean

  static values = {
    // stimulus-validator: disable-next-line
    rooms: Number,
    // stimulus-validator: disable-next-line
    adults: Number,
    // stimulus-validator: disable-next-line
    children: Number
  }

  // stimulus-validator: disable-next-line
  declare readonly modalTarget: HTMLElement
  // stimulus-validator: disable-next-line
  declare readonly roomsCountTarget: HTMLElement
  // stimulus-validator: disable-next-line
  declare readonly adultsCountTarget: HTMLElement
  // stimulus-validator: disable-next-line
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
    
    // Try to read initial values from URL parameters first
    const urlParams = new URLSearchParams(window.location.search)
    const roomsParam = urlParams.get('rooms')
    const adultsParam = urlParams.get('adults')
    const childrenParam = urlParams.get('children')
    
    // Only initialize if input targets exist (modal view)
    if (this.hasRoomsInputTarget && this.hasAdultsInputTarget && this.hasChildrenInputTarget) {
      // Prioritize URL parameters, fall back to hidden input values
      this.roomsValue = roomsParam && roomsParam !== '' ? parseInt(roomsParam) : (parseInt(this.roomsInputTarget.value) || 1)
      this.adultsValue = adultsParam && adultsParam !== '' ? parseInt(adultsParam) : (parseInt(this.adultsInputTarget.value) || 1)
      this.childrenValue = childrenParam && childrenParam !== '' ? parseInt(childrenParam) : (parseInt(this.childrenInputTarget.value) || 0)
      
      // Update modal display and hidden inputs
      this.updateCounts()
      this.updateDisplay()
    }
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
    // Dispatch event to notify hotel-search controller
    this.dispatchGuestUpdateEvent()
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
    if (this.hasDisplayTextTarget) {
      this.displayTextTarget.textContent = `${this.roomsValue}间房 ${this.adultsValue}成人 ${this.childrenValue}儿童`
    }
  }

  // Dispatch event to notify hotel-search controller
  private dispatchGuestUpdateEvent(): void {
    const guestUpdateEvent = new CustomEvent('hotel-guest-selector:guests-updated', {
      detail: {
        rooms: this.roomsValue,
        adults: this.adultsValue,
        children: this.childrenValue
      },
      bubbles: true
    })
    document.dispatchEvent(guestUpdateEvent)
    console.log('Hotel guest selector: Dispatched guest update event', {
      rooms: this.roomsValue,
      adults: this.adultsValue,
      children: this.childrenValue
    })
  }
}
