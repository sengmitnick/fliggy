import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
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

  static values = {
    selectedPassengers: Array,
    selectedPassengerNames: Array,
    adults: { type: Number, default: 1 },
    children: { type: Number, default: 0 },
    infants: { type: Number, default: 0 }
  }

  declare readonly modalTarget: HTMLElement
  declare readonly hasModalTarget: boolean
  declare readonly modalTitleTarget: HTMLElement
  declare readonly selectedDisplayTarget: HTMLElement
  declare readonly passengerTabTarget: HTMLButtonElement
  declare readonly countTabTarget: HTMLButtonElement
  declare readonly passengerListPanelTarget: HTMLElement
  declare readonly countPanelTarget: HTMLElement
  declare readonly adultsCountTarget: HTMLElement
  declare readonly childrenCountTarget: HTMLElement
  declare readonly infantsCountTarget: HTMLElement
  
  declare selectedPassengersValue: string[]
  declare selectedPassengerNamesValue: string[]
  declare adultsValue: number
  declare childrenValue: number
  declare infantsValue: number

  private currentTab: 'passengers' | 'count' = 'passengers'

  connect(): void {
    console.log("PassengerSelector connected")
    this.switchToPassengerTab()
    this.updateDisplay()
    
    // Check if we should auto-open the modal (e.g., after adding a passenger)
    const urlParams = new URLSearchParams(window.location.search)
    const shouldOpenModal = urlParams.get('open_passenger_modal') === 'true'
    console.log('Should open modal:', shouldOpenModal)
    
    if (shouldOpenModal) {
      // Open the modal after a short delay to ensure DOM is ready
      setTimeout(() => {
        console.log('Opening modal now...')
        console.log('Modal target exists:', !!this.modalTarget)
        if (this.hasModalTarget) {
          this.openModal()
          console.log('Modal opened successfully')
        } else {
          console.error('Modal target not found!')
        }
      }, 300)
      
      // Clean up URL parameter
      urlParams.delete('open_passenger_modal')
      const newUrl = `${window.location.pathname}${urlParams.toString() ? `?${urlParams.toString()}` : ''}`
      window.history.replaceState({}, '', newUrl)
    }
  }

  openModal(): void {
    console.log('openModal called, modalTarget:', this.modalTarget)
    this.modalTarget.classList.remove("hidden")
    document.body.style.overflow = "hidden"
    console.log('Modal classes after open:', this.modalTarget.classList.toString())
  }

  closeModal(): void {
    this.modalTarget.classList.add("hidden")
    document.body.style.overflow = ""
  }

  switchToPassengerTab(): void {
    this.currentTab = 'passengers'
    
    // Clear count tab selections (reset to default: 1 adult, 0 children, 0 infants)
    this.adultsValue = 1
    this.childrenValue = 0
    this.infantsValue = 0
    this.updateCountDisplay()
    
    // Update tab styles
    this.passengerTabTarget.classList.add("border-primary", "font-medium")
    this.passengerTabTarget.classList.remove("border-transparent")
    this.passengerTabTarget.querySelector<HTMLElement>('.text-xs')!.style.color = "#00A0E9"
    
    this.countTabTarget.classList.remove("border-primary", "font-medium")
    this.countTabTarget.classList.add("border-transparent")
    this.countTabTarget.querySelector<HTMLElement>('.text-xs')!.style.color = "#9CA3AF"
    
    // Show/hide panels
    this.passengerListPanelTarget.classList.remove("hidden")
    this.countPanelTarget.classList.add("hidden")
  }

  switchToCountTab(): void {
    this.currentTab = 'count'
    
    // Clear passenger list selections
    this.selectedPassengersValue = []
    this.selectedPassengerNamesValue = []
    const checkboxes = this.passengerListPanelTarget.querySelectorAll<HTMLInputElement>('input[type="checkbox"]')
    checkboxes.forEach(checkbox => {
      checkbox.checked = false
    })
    
    // Update tab styles
    this.countTabTarget.classList.add("border-primary", "font-medium")
    this.countTabTarget.classList.remove("border-transparent")
    this.countTabTarget.querySelector<HTMLElement>('.text-xs')!.style.color = "#00A0E9"
    
    this.passengerTabTarget.classList.remove("border-primary", "font-medium")
    this.passengerTabTarget.classList.add("border-transparent")
    this.passengerTabTarget.querySelector<HTMLElement>('.text-xs')!.style.color = "#9CA3AF"
    
    // Show/hide panels
    this.countPanelTarget.classList.remove("hidden")
    this.passengerListPanelTarget.classList.add("hidden")
  }

  togglePassenger(event: Event): void {
    const checkbox = event.currentTarget as HTMLInputElement
    const passengerId = checkbox.value
    const label = checkbox.closest('label')
    const passengerName = label?.querySelector('.font-bold')?.textContent || ''
    
    if (checkbox.checked) {
      if (!this.selectedPassengersValue.includes(passengerId)) {
        this.selectedPassengersValue = [...this.selectedPassengersValue, passengerId]
        this.selectedPassengerNamesValue = [...this.selectedPassengerNamesValue, passengerName]
      }
    } else {
      const index = this.selectedPassengersValue.indexOf(passengerId)
      if (index > -1) {
        this.selectedPassengersValue = this.selectedPassengersValue.filter(id => id !== passengerId)
        this.selectedPassengerNamesValue = this.selectedPassengerNamesValue.filter((_, i) => i !== index)
      }
    }
    
    this.updateDisplay()
  }

  incrementAdults(): void {
    this.adultsValue++
    this.updateCountDisplay()
  }

  decrementAdults(): void {
    if (this.adultsValue > 1) {
      this.adultsValue--
      this.updateCountDisplay()
    }
  }

  incrementChildren(): void {
    this.childrenValue++
    this.updateCountDisplay()
  }

  decrementChildren(): void {
    if (this.childrenValue > 0) {
      this.childrenValue--
      this.updateCountDisplay()
    }
  }

  incrementInfants(): void {
    this.infantsValue++
    this.updateCountDisplay()
  }

  decrementInfants(): void {
    if (this.infantsValue > 0) {
      this.infantsValue--
      this.updateCountDisplay()
    }
  }

  confirm(): void {
    this.updateDisplay()
    this.closeModal()
  }

  reset(): void {
    this.selectedPassengersValue = []
    this.selectedPassengerNamesValue = []
    this.adultsValue = 1
    this.childrenValue = 0
    this.infantsValue = 0
    
    const checkboxes = this.passengerListPanelTarget.querySelectorAll<HTMLInputElement>('input[type="checkbox"]')
    checkboxes.forEach(checkbox => {
      checkbox.checked = false
    })
    
    this.updateDisplay()
    this.updateCountDisplay()
  }

  stopPropagation(event: Event): void {
    event.stopPropagation()
  }

  private updateDisplay(): void {
    // Update modal title
    this.modalTitleTarget.textContent = `当前已选: ${this.adultsValue}成人 ${this.childrenValue}儿童 ${this.infantsValue}婴儿`
    
    // Update main display (passenger selection button in flights page)
    if (this.selectedPassengerNamesValue.length > 0) {
      // If specific passengers are selected, show their names (single line, no label)
      this.selectedDisplayTarget.innerHTML = `<div class="text-base text-gray-800">${this.selectedPassengerNamesValue.join('、')}</div>`
    } else if (this.adultsValue > 1 || this.childrenValue > 0 || this.infantsValue > 0) {
      // If passenger count is set (but no specific passengers selected), show count summary (single line, no label)
      // Always show all three categories including zeros
      this.selectedDisplayTarget.innerHTML = `<div class="text-base text-gray-800">${this.adultsValue}成人 ${this.childrenValue}儿童 ${this.infantsValue}婴儿</div>`
    } else {
      // Default state: 1 adult, no children/infants, no passengers selected (two-line layout with label)
      this.selectedDisplayTarget.innerHTML = `
        <div class="text-base text-gray-800">选择乘机人</div>
        <div class="text-sm" style="color: #00A0E9;">快速找到低价票</div>
      `
    }
  }

  private updateCountDisplay(): void {
    this.adultsCountTarget.textContent = this.adultsValue.toString()
    this.childrenCountTarget.textContent = this.childrenValue.toString()
    this.infantsCountTarget.textContent = this.infantsValue.toString()
    
    // Update modal title
    this.modalTitleTarget.textContent = `当前已选: ${this.adultsValue}成人 ${this.childrenValue}儿童 ${this.infantsValue}婴儿`
  }
}
