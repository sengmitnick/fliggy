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
  declare readonly selectedDisplayTargets: HTMLElement[]
  declare readonly passengerTabTarget: HTMLElement
  declare readonly countTabTarget: HTMLElement
  declare readonly passengerListPanelTarget: HTMLElement
  declare readonly countPanelTarget: HTMLElement
  declare readonly adultsCountTarget: HTMLElement
  declare readonly childrenCountTarget: HTMLElement
  declare readonly infantsCountTarget: HTMLElement

  private adults: number = 0
  private children: number = 0
  private infants: number = 0
  private selectedPassengerIds: Set<number> = new Set()
  private selectedPassengerNames: Map<number, string> = new Map()
  private hasSelection: boolean = false

  // Backup of confirmed state
  private confirmedAdults: number = 0
  private confirmedChildren: number = 0
  private confirmedInfants: number = 0
  private confirmedPassengerIds: Set<number> = new Set()
  private confirmedPassengerNames: Map<number, string> = new Map()

  connect(): void {
    // Load saved state from localStorage
    this.loadFromLocalStorage()
    // Update display if there's a saved selection
    if (this.hasSelection) {
      this.updateDisplay()
    }
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
    this.selectedPassengerNames = new Map(this.confirmedPassengerNames)
    
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
    const passengerName = checkbox.dataset.passengerName || ''
    
    if (checkbox.checked) {
      this.selectedPassengerIds.add(passengerId)
      this.selectedPassengerNames.set(passengerId, passengerName)
    } else {
      this.selectedPassengerIds.delete(passengerId)
      this.selectedPassengerNames.delete(passengerId)
    }
    
    // Auto-update adults count based on number of selected passengers
    const selectedCount = this.selectedPassengerNames.size
    this.adults = selectedCount
    
    // Update modal title and counters to reflect current selection
    this.updateCounters()
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
    
    if (this.adults > 0) {
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
    
    this.adults = 0
    this.children = 0
    this.infants = 0
    this.selectedPassengerIds.clear()
    this.selectedPassengerNames.clear()
    this.hasSelection = false
    
    // Also reset confirmed state
    this.confirmedAdults = 0
    this.confirmedChildren = 0
    this.confirmedInfants = 0
    this.confirmedPassengerIds.clear()
    this.confirmedPassengerNames.clear()
    
    // Clear localStorage
    localStorage.removeItem('passenger_selection')
    
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
    
    // Check if we're on the count panel (not passenger list panel)
    const isCountPanelActive = !this.countPanelTarget.classList.contains("hidden")
    
    // Mutually exclusive modes: clear opposite mode data
    if (isCountPanelActive) {
      // Count mode: clear passenger names/IDs
      this.selectedPassengerIds.clear()
      this.selectedPassengerNames.clear()
      
      // Uncheck all checkboxes in passenger list
      const checkboxes = this.passengerListPanelTarget.querySelectorAll('input[type="checkbox"]')
      checkboxes.forEach((checkbox: Element) => {
        (checkbox as HTMLInputElement).checked = false
      })
    } else {
      // Passenger name mode: clear counts
      this.adults = 0
      this.children = 0
      this.infants = 0
    }
    
    // Save current state as confirmed state
    this.confirmedAdults = this.adults
    this.confirmedChildren = this.children
    this.confirmedInfants = this.infants
    this.confirmedPassengerIds = new Set(this.selectedPassengerIds)
    this.confirmedPassengerNames = new Map(this.selectedPassengerNames)
    
    this.hasSelection = true
    this.saveToLocalStorage()
    this.updateDisplay()
    
    // Close modal directly without triggering restore logic
    this.modalTarget.classList.add("hidden")
    document.body.style.overflow = ""
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
    const total = this.confirmedAdults + this.confirmedChildren + this.confirmedInfants
    
    // Update all button displays on the page
    this.selectedDisplayTargets.forEach((displayContainer) => {
      const mainDiv = displayContainer.querySelector('.text-base') as HTMLElement
      const subtitleDiv = displayContainer.querySelector('.text-sm') as HTMLElement
      
      if (mainDiv && subtitleDiv) {
        // Mode 1: Passenger Name Mode - show names, hide count
        if (this.confirmedPassengerNames.size > 0) {
          const names = Array.from(this.confirmedPassengerNames.values())
          mainDiv.textContent = names.join('、')
          subtitleDiv.textContent = `${names.length}位乘机人` // Hide detailed count breakdown
        } 
        // Mode 2: Count Mode - show count breakdown, no names
        else if (this.hasSelection && total > 0) {
          mainDiv.textContent = `${this.confirmedAdults}成人 ${this.confirmedChildren}儿童 ${this.confirmedInfants}婴儿`
          subtitleDiv.textContent = `共${total}位乘机人`
        }
        // Default: No selection
        else {
          mainDiv.textContent = '选择乘机人'
          subtitleDiv.textContent = '快速找到低价票'
        }
      }
    })
    
    this.updateModalTitle()
  }

  private saveToLocalStorage(): void {
    const state = {
      adults: this.confirmedAdults,
      children: this.confirmedChildren,
      infants: this.confirmedInfants,
      passengerIds: Array.from(this.confirmedPassengerIds),
      passengerNames: Array.from(this.confirmedPassengerNames.entries()),
      hasSelection: this.hasSelection
    }
    localStorage.setItem('passenger_selection', JSON.stringify(state))
  }

  private loadFromLocalStorage(): void {
    const savedState = localStorage.getItem('passenger_selection')
    if (savedState) {
      try {
        const state = JSON.parse(savedState)
        this.adults = state.adults || 0
        this.children = state.children || 0
        this.infants = state.infants || 0
        this.confirmedAdults = state.adults || 0
        this.confirmedChildren = state.children || 0
        this.confirmedInfants = state.infants || 0
        this.selectedPassengerIds = new Set(state.passengerIds || [])
        this.confirmedPassengerIds = new Set(state.passengerIds || [])
        this.selectedPassengerNames = new Map(state.passengerNames || [])
        this.confirmedPassengerNames = new Map(state.passengerNames || [])
        this.hasSelection = state.hasSelection || false
      } catch (e) {
        console.error('Failed to load passenger selection from localStorage:', e)
      }
    }
  }
}
