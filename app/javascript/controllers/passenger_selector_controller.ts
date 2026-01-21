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
    "infantsCount",
    "count",
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

  declare readonly modalTarget: HTMLElement
  declare readonly hasModalTarget: boolean
  declare readonly modalTitleTarget: HTMLElement
  declare readonly hasModalTitleTarget: boolean
  declare readonly selectedDisplayTarget: HTMLElement
  declare readonly selectedDisplayTargets: HTMLElement[]
  declare readonly hasSelectedDisplayTarget: boolean
  declare readonly passengerTabTarget: HTMLElement
  declare readonly hasPassengerTabTarget: boolean
  declare readonly countTabTarget: HTMLElement
  declare readonly hasCountTabTarget: boolean
  declare readonly passengerListPanelTarget: HTMLElement
  declare readonly hasPassengerListPanelTarget: boolean
  declare readonly countPanelTarget: HTMLElement
  declare readonly hasCountPanelTarget: boolean
  declare readonly adultsCountTarget: HTMLElement
  declare readonly hasAdultsCountTarget: boolean
  declare readonly childrenCountTarget: HTMLElement
  declare readonly hasChildrenCountTarget: boolean
  declare readonly infantsCountTarget: HTMLElement
  declare readonly hasInfantsCountTarget: boolean
  declare readonly countTarget: HTMLElement
  declare readonly hasCountTarget: boolean
  declare readonly nameTarget: HTMLElement
  declare readonly hasNameTarget: boolean
  declare readonly idTypeTarget: HTMLElement
  declare readonly hasIdTypeTarget: boolean
  declare readonly idNumberTarget: HTMLElement
  declare readonly hasIdNumberTarget: boolean
  declare readonly phoneTarget: HTMLElement
  declare readonly hasPhoneTarget: boolean
  declare readonly driverNameTarget: HTMLElement
  declare readonly hasDriverNameTarget: boolean
  declare readonly driverIdNumberTarget: HTMLElement
  declare readonly hasDriverIdNumberTarget: boolean
  declare readonly contactPhoneTarget: HTMLElement
  declare readonly hasContactPhoneTarget: boolean

  declare selectedIdValue: number
  declare readonly hasSelectedIdValue: boolean

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
    
    // Only open modal if it exists (not needed for visa order simple +/- mode)
    if (!this.hasModalTarget) return
    
    this.modalTarget.classList.remove("hidden")
    document.body.style.overflow = "hidden"
    
    // Show passenger list panel by default (only if tabs exist - flight booking mode)
    if (this.hasPassengerTabTarget && this.hasCountTabTarget) {
      this.switchToPassengerTab(event)
    }
    
    // Highlight the selected passenger in the modal (car rental mode)
    this.highlightSelectedPassenger()
  }

  closeModal(event: Event): void {
    event.preventDefault()
    event.stopPropagation()
    
    // Only close modal if it exists (not needed for visa order simple +/- mode)
    if (!this.hasModalTarget) return
    
    // Only restore state if we have the full modal with passenger list
    if (this.hasPassengerListPanelTarget) {
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
    }
    
    this.modalTarget.classList.add("hidden")
    document.body.style.overflow = ""
  }

  stopPropagation(event: Event): void {
    event.stopPropagation()
  }

  switchToPassengerTab(event: Event): void {
    event.preventDefault()
    event.stopPropagation()
    
    // Only update tab styles if tabs exist (flight booking mode)
    if (this.hasPassengerTabTarget && this.hasCountTabTarget) {
      this.passengerTabTarget.classList.add("border-blue-500")
      this.passengerTabTarget.classList.remove("border-transparent")
      this.countTabTarget.classList.remove("border-blue-500")
      this.countTabTarget.classList.add("border-transparent")
    }
    
    // Show passenger list panel, hide count panel (only if both panels exist)
    if (this.hasPassengerListPanelTarget && this.hasCountPanelTarget) {
      this.passengerListPanelTarget.classList.remove("hidden")
      this.countPanelTarget.classList.add("hidden")
    }
  }

  switchToCountTab(event: Event): void {
    event.preventDefault()
    event.stopPropagation()
    
    // Only update tab styles if tabs exist (flight booking mode)
    if (this.hasPassengerTabTarget && this.hasCountTabTarget) {
      this.countTabTarget.classList.add("border-blue-500")
      this.countTabTarget.classList.remove("border-transparent")
      this.passengerTabTarget.classList.remove("border-blue-500")
      this.passengerTabTarget.classList.add("border-transparent")
    }
    
    // Show count panel, hide passenger list panel (only if both panels exist)
    if (this.hasPassengerListPanelTarget && this.hasCountPanelTarget) {
      this.countPanelTarget.classList.remove("hidden")
      this.passengerListPanelTarget.classList.add("hidden")
    }
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
    
    // Uncheck all checkboxes (only if passengerListPanel exists)
    if (this.hasPassengerListPanelTarget) {
      const checkboxes = this.passengerListPanelTarget.querySelectorAll('input[type="checkbox"]')
      checkboxes.forEach((checkbox: Element) => {
        (checkbox as HTMLInputElement).checked = false
      })
    }
    
    this.updateCounters()
    this.updateDisplay()
  }

  confirm(event: Event): void {
    event.preventDefault()
    event.stopPropagation()
    
    // Check if we have the full modal with count panel
    if (this.hasCountPanelTarget) {
      // Check if we're on the count panel (not passenger list panel)
      const isCountPanelActive = !this.countPanelTarget.classList.contains("hidden")
      
      // Mutually exclusive modes: clear opposite mode data
      if (isCountPanelActive) {
        // Count mode: clear passenger names/IDs
        this.selectedPassengerIds.clear()
        this.selectedPassengerNames.clear()
        
        // Uncheck all checkboxes in passenger list (if it exists)
        if (this.hasPassengerListPanelTarget) {
          const checkboxes = this.passengerListPanelTarget.querySelectorAll('input[type="checkbox"]')
          checkboxes.forEach((checkbox: Element) => {
            (checkbox as HTMLInputElement).checked = false
          })
        }
      } else {
        // Passenger name mode: clear counts
        this.adults = 0
        this.children = 0
        this.infants = 0
      }
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

  toggleEdit(): void {
    // This method is used in views to toggle between edit and display modes
    const event = new Event('click')
    this.openModal(event)
  }

  selectPassenger(event: Event): void {
    // For car rental: simple click selection on div elements
    const target = event.currentTarget as HTMLElement
    
    // Check if this is a div-based selection (car rental) vs checkbox (flight booking)
    if (target.tagName === 'DIV' && target.hasAttribute('data-passenger-id')) {
      // Car rental mode: update display fields and close modal
      const passengerId = target.getAttribute('data-passenger-id')
      const passengerName = target.getAttribute('data-passenger-name') || ''
      const passengerIdType = target.getAttribute('data-passenger-id-type') || ''
      const passengerIdNumber = target.getAttribute('data-passenger-id-number') || ''
      const passengerPhone = target.getAttribute('data-passenger-phone') || ''
      
      // Update display fields (name, idType, idNumber, phone targets)
      if (this.hasNameTarget) {
        this.nameTarget.textContent = passengerName
      }
      if (this.hasIdTypeTarget) {
        this.idTypeTarget.textContent = passengerIdType
      }
      if (this.hasIdNumberTarget) {
        this.idNumberTarget.textContent = passengerIdNumber
      }
      if (this.hasPhoneTarget) {
        this.phoneTarget.textContent = passengerPhone || '未填写'
      }
      
      // Update hidden form fields
      if (this.hasDriverNameTarget) {
        const driverNameField = this.driverNameTarget as HTMLInputElement
        driverNameField.value = passengerName
      }
      if (this.hasDriverIdNumberTarget) {
        const driverIdNumberField = this.driverIdNumberTarget as HTMLInputElement
        driverIdNumberField.value = passengerIdNumber
      }
      if (this.hasContactPhoneTarget) {
        const contactPhoneField = this.contactPhoneTarget as HTMLInputElement
        contactPhoneField.value = passengerPhone
      }
      
      // Save the selected passenger ID to the value
      if (this.hasSelectedIdValue && passengerId) {
        this.selectedIdValue = parseInt(passengerId)
      }
      
      // Close modal
      this.modalTarget.classList.add('hidden')
      document.body.style.overflow = ''
      
      return
    }
    
    // Flight booking mode: delegate to togglePassenger for checkbox handling
    // This should only be reached if the event comes from a checkbox
    this.togglePassenger(event)
  }

  decrease(event: Event): void {
    // General decrease method that can be used for any count
    this.decrementAdults(event)
  }

  increase(event: Event): void {
    // General increase method that can be used for any count
    this.incrementAdults(event)
  }

  private updateCounters(): void {
    // Only update counter displays if they exist (flight booking mode)
    if (this.hasAdultsCountTarget) {
      this.adultsCountTarget.textContent = this.adults.toString()
    }
    if (this.hasChildrenCountTarget) {
      this.childrenCountTarget.textContent = this.children.toString()
    }
    if (this.hasInfantsCountTarget) {
      this.infantsCountTarget.textContent = this.infants.toString()
    }
    // Update simple count target for visa order mode
    if (this.hasCountTarget) {
      this.countTarget.textContent = this.adults.toString()
    }
    this.updateModalTitle()
  }

  private updateModalTitle(): void {
    // Only update modal title if it exists (flight booking mode)
    if (this.hasModalTitleTarget) {
      this.modalTitleTarget.textContent = `当前已选: ${this.adults}成人 ${this.children}儿童 ${this.infants}婴儿`
    }
  }

  private updateDisplay(): void {
    // Only update display if it exists (flight booking mode)
    if (!this.hasSelectedDisplayTarget) return
    
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

  private highlightSelectedPassenger(): void {
    // Only run in car rental mode where selectedIdValue exists
    if (!this.hasSelectedIdValue) return
    
    // Find all passenger div elements in the modal
    const passengerDivs = this.element.querySelectorAll('[data-passenger-id]')
    
    passengerDivs.forEach((div: Element) => {
      const passengerId = parseInt((div as HTMLElement).getAttribute('data-passenger-id') || '0')
      const isSelected = passengerId === this.selectedIdValue
      
      // Update div border and background
      if (isSelected) {
        div.classList.add('border-blue-500', 'bg-blue-50')
        div.classList.remove('border-gray-200')
      } else {
        div.classList.remove('border-blue-500', 'bg-blue-50')
        if (!div.classList.contains('border')) {
          // Ensure it has a border class if it was originally border-less
        }
      }
      
      // Update the radio-style indicator circle
      const indicatorCircle = div.querySelector('.w-5.h-5.rounded-full')
      if (indicatorCircle) {
        if (isSelected) {
          indicatorCircle.classList.add('border-blue-500', 'bg-blue-500')
          indicatorCircle.classList.remove('border-gray-300')
          
          // Ensure checkmark icon exists
          let checkmark = indicatorCircle.querySelector('svg')
          if (!checkmark) {
            checkmark = document.createElementNS('http://www.w3.org/2000/svg', 'svg')
            checkmark.setAttribute('class', 'w-3 h-3 text-white')
            checkmark.setAttribute('fill', 'currentColor')
            checkmark.setAttribute('viewBox', '0 0 20 20')
            const path = document.createElementNS('http://www.w3.org/2000/svg', 'path')
            path.setAttribute('fill-rule', 'evenodd')
            path.setAttribute('d', 'M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z')
            path.setAttribute('clip-rule', 'evenodd')
            checkmark.appendChild(path)
            indicatorCircle.appendChild(checkmark)
          }
        } else {
          indicatorCircle.classList.remove('border-blue-500', 'bg-blue-500')
          indicatorCircle.classList.add('border-gray-300')
          
          // Remove checkmark icon
          const checkmark = indicatorCircle.querySelector('svg')
          if (checkmark) {
            checkmark.remove()
          }
        }
      }
    })
  }
}
