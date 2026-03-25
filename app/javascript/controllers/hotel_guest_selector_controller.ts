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
    "displayText",
    "roomsDisplay",
    "adultsDisplay",
    "childrenDisplay",
    "childrenBadge"
  ]

  declare readonly hasRoomsInputTarget: boolean
  declare readonly hasAdultsInputTarget: boolean
  declare readonly hasChildrenInputTarget: boolean
  declare readonly hasDisplayTextTarget: boolean
  declare readonly hasRoomsDisplayTarget: boolean
  declare readonly hasAdultsDisplayTarget: boolean
  declare readonly hasChildrenDisplayTarget: boolean
  declare readonly hasChildrenBadgeTarget: boolean

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
  declare readonly roomsDisplayTarget: HTMLElement
  declare readonly adultsDisplayTarget: HTMLElement
  declare readonly childrenDisplayTarget: HTMLElement
  declare readonly childrenBadgeTarget: HTMLElement

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

  // Close modal when clicking on backdrop (not content)
  closeOnBackdrop(event: Event): void {
    if (event.target === event.currentTarget) {
      this.closeModal()
    }
  }

  // Stop event propagation to prevent closing when clicking inside content
  stopPropagation(event: Event): void {
    event.stopPropagation()
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
    this.updateFormFields()
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
    
    // Update badge displays if they exist (for booking form)
    if (this.hasRoomsDisplayTarget) {
      this.roomsDisplayTarget.textContent = this.roomsValue.toString()
    }
    if (this.hasAdultsDisplayTarget) {
      this.adultsDisplayTarget.textContent = this.adultsValue.toString()
    }
    if (this.hasChildrenDisplayTarget) {
      this.childrenDisplayTarget.textContent = this.childrenValue.toString()
    }
    if (this.hasChildrenBadgeTarget) {
      // Show/hide children badge based on count
      if (this.childrenValue > 0) {
        this.childrenBadgeTarget.style.display = ''
      } else {
        this.childrenBadgeTarget.style.display = 'none'
      }
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

  // Update form hidden fields (for booking form)
  private updateFormFields(): void {
    // Update the main form hidden fields if they exist
    const roomsField = document.querySelector('#hotel_booking_rooms_count') as HTMLInputElement
    const adultsField = document.querySelector('#hotel_booking_adults_count') as HTMLInputElement
    const childrenField = document.querySelector('#hotel_booking_children_count') as HTMLInputElement
    
    if (roomsField) roomsField.value = this.roomsValue.toString()
    if (adultsField) adultsField.value = this.adultsValue.toString()
    if (childrenField) childrenField.value = this.childrenValue.toString()
  }
}
