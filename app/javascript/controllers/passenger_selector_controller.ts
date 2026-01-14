import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "modal",
    "modalTitle",
    "selectedDisplay",
    "passengerTab",
    "countTab",
    "passengerListPanel",
    "countPanel",
    "adultsCount",
    "childrenCount",
    "infantsCount"
  ]

  declare readonly modalTarget: HTMLElement
  declare readonly modalTitleTarget: HTMLElement
  declare readonly selectedDisplayTarget: HTMLElement
  declare readonly passengerTabTarget: HTMLElement
  declare readonly countTabTarget: HTMLElement
  declare readonly passengerListPanelTarget: HTMLElement
  declare readonly countPanelTarget: HTMLElement
  declare readonly adultsCountTarget: HTMLElement
  declare readonly childrenCountTarget: HTMLElement
  declare readonly infantsCountTarget: HTMLElement

  private adults: number = 1
  private children: number = 0
  private infants: number = 0
  private selectedPassengerIds: Set<number> = new Set()
  private hasSelection: boolean = false

  // Backup of confirmed state
  private confirmedAdults: number = 1
  private confirmedChildren: number = 0
  private confirmedInfants: number = 0
  private confirmedPassengerIds: Set<number> = new Set()

  connect(): void {
    // Don't update display on initial load - keep the default "选择乘机人" text
  }

  openModal(event: Event): void {
    event.preventDefault()
    event.stopPropagation()
    this.modalTarget.classList.remove("hidden")
    document.body.style.overflow = "hidden"
    
    // Show passenger list panel by default
    this.switchToPassengerTab(event)
  }

  closeModal(event: Event): void {
    event.preventDefault()
    event.stopPropagation()
    
    // Restore to confirmed state when closing without confirming
    this.adults = this.confirmedAdults
    this.children = this.confirmedChildren
    this.infants = this.confirmedInfants
    this.selectedPassengerIds = new Set(this.confirmedPassengerIds)
    
    // Restore checkbox states
    const checkboxes = this.passengerListPanelTarget.querySelectorAll('input[type="checkbox"]')
    checkboxes.forEach((checkbox: Element) => {
      const cb = checkbox as HTMLInputElement
      const passengerId = parseInt(cb.value)
      cb.checked = this.confirmedPassengerIds.has(passengerId)
    })
    
    // Update counters to show confirmed values
    this.updateCounters()
    
    this.modalTarget.classList.add("hidden")
    document.body.style.overflow = ""
  }

  stopPropagation(event: Event): void {
    event.stopPropagation()
  }

  switchToPassengerTab(event: Event): void {
    event.preventDefault()
    event.stopPropagation()
    
    // Update tab styles
    this.passengerTabTarget.classList.add("border-blue-500")
    this.passengerTabTarget.classList.remove("border-transparent")
    this.countTabTarget.classList.remove("border-blue-500")
    this.countTabTarget.classList.add("border-transparent")
    
    // Show passenger list panel, hide count panel
    this.passengerListPanelTarget.classList.remove("hidden")
    this.countPanelTarget.classList.add("hidden")
  }

  switchToCountTab(event: Event): void {
    event.preventDefault()
    event.stopPropagation()
    
    // Update tab styles
    this.countTabTarget.classList.add("border-blue-500")
    this.countTabTarget.classList.remove("border-transparent")
    this.passengerTabTarget.classList.remove("border-blue-500")
    this.passengerTabTarget.classList.add("border-transparent")
    
    // Show count panel, hide passenger list panel
    this.countPanelTarget.classList.remove("hidden")
    this.passengerListPanelTarget.classList.add("hidden")
  }

  togglePassenger(event: Event): void {
    const checkbox = event.target as HTMLInputElement
    const passengerId = parseInt(checkbox.value)
    
    if (checkbox.checked) {
      this.selectedPassengerIds.add(passengerId)
    } else {
      this.selectedPassengerIds.delete(passengerId)
    }
  }

  incrementAdults(event: Event): void {
    event.preventDefault()
    event.stopPropagation()
    
    if (this.adults < 9) {
      this.adults++
      this.updateCounters()
    }
  }

  decrementAdults(event: Event): void {
    event.preventDefault()
    event.stopPropagation()
    
    if (this.adults > 1) {
      this.adults--
      this.updateCounters()
    }
  }

  incrementChildren(event: Event): void {
    event.preventDefault()
    event.stopPropagation()
    
    if (this.children < 8) {
      this.children++
      this.updateCounters()
    }
  }

  decrementChildren(event: Event): void {
    event.preventDefault()
    event.stopPropagation()
    
    if (this.children > 0) {
      this.children--
      this.updateCounters()
    }
  }

  incrementInfants(event: Event): void {
    event.preventDefault()
    event.stopPropagation()
    
    if (this.infants < this.adults) {
      this.infants++
      this.updateCounters()
    }
  }

  decrementInfants(event: Event): void {
    event.preventDefault()
    event.stopPropagation()
    
    if (this.infants > 0) {
      this.infants--
      this.updateCounters()
    }
  }

  reset(event: Event): void {
    event.preventDefault()
    event.stopPropagation()
    
    this.adults = 1
    this.children = 0
    this.infants = 0
    this.selectedPassengerIds.clear()
    this.hasSelection = false
    
    // Also reset confirmed state
    this.confirmedAdults = 1
    this.confirmedChildren = 0
    this.confirmedInfants = 0
    this.confirmedPassengerIds.clear()
    
    // Uncheck all checkboxes
    const checkboxes = this.passengerListPanelTarget.querySelectorAll('input[type="checkbox"]')
    checkboxes.forEach((checkbox: Element) => {
      (checkbox as HTMLInputElement).checked = false
    })
    
    this.updateCounters()
    this.updateDisplay()
  }

  confirm(event: Event): void {
    event.preventDefault()
    event.stopPropagation()
    
    // Save current state as confirmed state
    this.confirmedAdults = this.adults
    this.confirmedChildren = this.children
    this.confirmedInfants = this.infants
    this.confirmedPassengerIds = new Set(this.selectedPassengerIds)
    
    this.hasSelection = true
    this.updateDisplay()
    this.closeModal(event)
  }

  private updateCounters(): void {
    this.adultsCountTarget.textContent = this.adults.toString()
    this.childrenCountTarget.textContent = this.children.toString()
    this.infantsCountTarget.textContent = this.infants.toString()
    this.updateModalTitle()
  }

  private updateModalTitle(): void {
    this.modalTitleTarget.textContent = `当前已选: ${this.adults}成人 ${this.children}儿童 ${this.infants}婴儿`
  }

  private updateDisplay(): void {
    const total = this.adults + this.children + this.infants
    
    // Update the button display
    const displayDiv = this.selectedDisplayTarget.querySelector('.text-base') as HTMLElement
    if (displayDiv) {
      // If user hasn't made a selection or is back to initial state (1 adult, 0 children, 0 infants)
      // show the default text
      if (!this.hasSelection || (this.adults === 1 && this.children === 0 && this.infants === 0)) {
        displayDiv.textContent = '选择乘机人'
      } else {
        displayDiv.textContent = `${total}位乘机人`
      }
    }
    
    this.updateModalTitle()
  }
}
