import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "domesticButton", 
    "internationalButton", 
    "swapToggle", 
    "swapIndicator",
    "returnLocationSection",
    "cityDisplay",
    "pickupLocationDisplay",
    "returnLocationDisplay",
    "pickupDateDisplay",
    "returnDateDisplay",
    "durationDisplay",
    "cityInput",
    "pickupLocationInput",
    "returnLocationInput",
    "pickupDateInput",
    "returnDateInput"
  ]

  static values = {
    city: String,
    pickupLocation: String,
    returnLocation: String,
    pickupDate: String,
    returnDate: String
  }

  declare readonly domesticButtonTarget: HTMLButtonElement
  declare readonly internationalButtonTarget: HTMLButtonElement
  declare readonly swapToggleTarget: HTMLElement
  declare readonly swapIndicatorTarget: HTMLElement
  declare readonly returnLocationSectionTarget: HTMLElement
  declare readonly cityDisplayTarget: HTMLElement
  declare readonly pickupLocationDisplayTarget: HTMLElement
  declare readonly returnLocationDisplayTarget: HTMLElement
  declare readonly pickupDateDisplayTarget: HTMLElement
  declare readonly returnDateDisplayTarget: HTMLElement
  declare readonly durationDisplayTarget: HTMLElement
  declare readonly cityInputTarget: HTMLInputElement
  declare readonly pickupLocationInputTarget: HTMLInputElement
  declare readonly returnLocationInputTarget: HTMLInputElement
  declare readonly pickupDateInputTarget: HTMLInputElement
  declare readonly returnDateInputTarget: HTMLInputElement
  declare cityValue: string
  declare pickupLocationValue: string
  declare returnLocationValue: string
  declare pickupDateValue: string
  declare returnDateValue: string

  private isDomestic: boolean = true
  private isSwapEnabled: boolean = false
  private currentSelectionType: 'city' | 'pickup' | 'return' | null = null

  connect(): void {
    console.log("CarRentalTabs connected")
    this.updateDomesticView()
    this.initializeDefaults()
    
    // Listen for events
    document.addEventListener('city-selector:city-selected', this.handleCitySelected.bind(this))
    document.addEventListener('location-selector:location-selected', this.handleLocationSelected.bind(this))
    document.addEventListener('car-datetime-picker:datetime-selected', this.handleDateTimeSelected.bind(this))
  }

  disconnect(): void {
    document.removeEventListener('city-selector:city-selected', this.handleCitySelected.bind(this))
    document.removeEventListener('location-selector:location-selected', this.handleLocationSelected.bind(this))
    document.removeEventListener('car-datetime-picker:datetime-selected', this.handleDateTimeSelected.bind(this))
  }

  // Initialize default values
  private initializeDefaults(): void {
    // Get city from DOM (set by Rails view)
    const cityDisplay = this.cityDisplayTarget.textContent?.trim()
    if (cityDisplay && cityDisplay !== '') {
      this.updateCity(cityDisplay)
    }
    
    // Do not set default pickup location - user must select
    
    // Set default dates if not set
    if (!this.pickupDateValue || !this.returnDateValue) {
      const today = new Date()
      today.setHours(13, 55, 0, 0)
      const returnDate = new Date(today)
      returnDate.setDate(returnDate.getDate() + 2)
      
      this.updatePickupDate(today)
      this.updateReturnDate(returnDate)
    }
  }

  selectDomestic(): void {
    this.isDomestic = true
    this.updateDomesticView()
  }

  selectInternational(): void {
    this.isDomestic = false
    this.updateInternationalView()
  }

  toggleSwap(): void {
    this.isSwapEnabled = !this.isSwapEnabled
    this.updateSwapToggle()
    
    // Show/hide return location section
    if (this.isSwapEnabled) {
      this.returnLocationSectionTarget.classList.remove('hidden')
    } else {
      this.returnLocationSectionTarget.classList.add('hidden')
      this.returnLocationValue = ''
      this.returnLocationDisplayTarget.textContent = '同取车地点'
      this.returnLocationInputTarget.value = ''
    }
  }

  // Open city selector
  openCitySelector(): void {
    this.currentSelectionType = 'city'
    const modal = document.querySelector('[data-city-selector-target="modal"]') as HTMLElement
    if (modal) {
      modal.classList.remove('hidden')
      document.body.style.overflow = 'hidden'
    }
  }

  // Open pickup location selector
  openPickupLocationSelector(): void {
    console.log('[CarRentalTabs] openPickupLocationSelector called')
    this.currentSelectionType = 'pickup'
    const controller = this.application.getControllerForElementAndIdentifier(
      document.querySelector('[data-controller="location-selector"]') as Element,
      'location-selector'
    ) as any
    console.log('[CarRentalTabs] location-selector controller:', controller)
    if (controller && controller.openModal) {
      console.log('[CarRentalTabs] Calling controller.openModal()')
      controller.openModal()
    } else {
      console.error('[CarRentalTabs] location-selector controller or openModal method not found')
    }
  }

  // Open return location selector
  openReturnLocationSelector(): void {
    if (!this.isSwapEnabled) {
      if (window.showToast) {
        window.showToast('请先开启异地还车')
      }
      return
    }
    console.log('[CarRentalTabs] openReturnLocationSelector called')
    this.currentSelectionType = 'return'
    const controller = this.application.getControllerForElementAndIdentifier(
      document.querySelector('[data-controller="location-selector"]') as Element,
      'location-selector'
    ) as any
    console.log('[CarRentalTabs] location-selector controller:', controller)
    if (controller && controller.openModal) {
      console.log('[CarRentalTabs] Calling controller.openModal()')
      controller.openModal()
    } else {
      console.error('[CarRentalTabs] location-selector controller or openModal method not found')
    }
  }

  // Open pickup date selector
  openPickupDateSelector(): void {
    const controller = this.application.getControllerForElementAndIdentifier(
      document.querySelector('[data-controller="car-datetime-picker"]') as Element,
      'car-datetime-picker'
    ) as any
    if (controller && controller.openModal) {
      controller.openModal('pickup')
    }
  }

  // Open return date selector
  openReturnDateSelector(): void {
    const controller = this.application.getControllerForElementAndIdentifier(
      document.querySelector('[data-controller="car-datetime-picker"]') as Element,
      'car-datetime-picker'
    ) as any
    if (controller && controller.openModal) {
      controller.openModal('return')
    }
  }

  // Handle city selection from city selector
  private handleCitySelected(event: Event): void {
    const customEvent = event as CustomEvent
    const { cityName } = customEvent.detail
    
    if (this.currentSelectionType === 'city') {
      this.updateCity(cityName)
      // Clear pickup and return locations when city changes
      this.clearPickupLocation()
      if (this.isSwapEnabled) {
        this.clearReturnLocation()
      }
      this.currentSelectionType = null
    }
  }

  // Handle location selection from location selector
  private handleLocationSelected(event: Event): void {
    const customEvent = event as CustomEvent
    const { locationName } = customEvent.detail
    
    if (this.currentSelectionType === 'pickup') {
      this.updatePickupLocation(locationName)
      this.currentSelectionType = null
    } else if (this.currentSelectionType === 'return') {
      this.updateReturnLocation(locationName)
      this.currentSelectionType = null
    }
  }

  // Handle datetime selection from car-datetime-picker
  private handleDateTimeSelected(event: Event): void {
    const customEvent = event as CustomEvent
    const { pickerType, dateTime } = customEvent.detail
    
    if (pickerType === 'pickup') {
      this.updatePickupDate(new Date(dateTime))
      this.ensureReturnDateValid()
    } else if (pickerType === 'return') {
      this.updateReturnDate(new Date(dateTime))
      this.ensureReturnDateValid()
    }
  }

  // Update city
  private updateCity(cityName: string): void {
    this.cityValue = cityName
    this.cityDisplayTarget.textContent = cityName
    this.cityInputTarget.value = cityName
  }

  // Update pickup location
  private updatePickupLocation(location: string): void {
    this.pickupLocationValue = location
    this.pickupLocationDisplayTarget.textContent = location
    this.pickupLocationDisplayTarget.classList.remove('text-gray-400')
    this.pickupLocationInputTarget.value = location
  }

  // Clear pickup location
  private clearPickupLocation(): void {
    this.pickupLocationValue = ''
    this.pickupLocationDisplayTarget.textContent = '请选择地点'
    this.pickupLocationDisplayTarget.classList.add('text-gray-400')
    this.pickupLocationInputTarget.value = ''
  }

  // Update return location
  private updateReturnLocation(location: string): void {
    this.returnLocationValue = location
    this.returnLocationDisplayTarget.textContent = location
    this.returnLocationDisplayTarget.classList.remove('text-gray-400')
    this.returnLocationInputTarget.value = location
  }

  // Clear return location
  private clearReturnLocation(): void {
    this.returnLocationValue = ''
    this.returnLocationDisplayTarget.textContent = '同取车地点'
    this.returnLocationDisplayTarget.classList.add('text-gray-400')
    this.returnLocationInputTarget.value = ''
  }

  // Update pickup date
  private updatePickupDate(date: Date): void {
    this.pickupDateValue = date.toISOString()
    this.pickupDateInputTarget.value = this.formatDateForInput(date)
    this.pickupDateDisplayTarget.innerHTML = this.formatDateDisplay(date)
    this.updateDuration()
  }

  // Update return date
  private updateReturnDate(date: Date): void {
    this.returnDateValue = date.toISOString()
    this.returnDateInputTarget.value = this.formatDateForInput(date)
    this.returnDateDisplayTarget.innerHTML = this.formatDateDisplay(date)
    this.updateDuration()
  }

  // Ensure return date is after pickup date
  private ensureReturnDateValid(): void {
    if (!this.pickupDateValue || !this.returnDateValue) return
    
    const pickupDate = new Date(this.pickupDateValue)
    const returnDate = new Date(this.returnDateValue)
    
    if (returnDate <= pickupDate) {
      const newReturnDate = new Date(pickupDate)
      newReturnDate.setDate(newReturnDate.getDate() + 1)
      this.updateReturnDate(newReturnDate)
    }
  }

  // Update duration display
  private updateDuration(): void {
    if (!this.pickupDateValue || !this.returnDateValue) return
    
    const pickupDate = new Date(this.pickupDateValue)
    const returnDate = new Date(this.returnDateValue)
    const diffTime = Math.abs(returnDate.getTime() - pickupDate.getTime())
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24))
    
    this.durationDisplayTarget.textContent = `${diffDays}天`
  }

  // Format date for input (YYYY-MM-DD)
  private formatDateForInput(date: Date): string {
    const year = date.getFullYear()
    const month = String(date.getMonth() + 1).padStart(2, '0')
    const day = String(date.getDate()).padStart(2, '0')
    return `${year}-${month}-${day}`
  }

  // Format date for display
  private formatDateDisplay(date: Date): string {
    const weekdays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六']
    const weekday = weekdays[date.getDay()]
    const month = date.getMonth() + 1
    const day = date.getDate()
    const hours = String(date.getHours()).padStart(2, '0')
    const minutes = String(date.getMinutes()).padStart(2, '0')
    
    return `${month}月${day}日 <span class="text-sm">${hours}:${minutes}</span>`
  }

  private updateDomesticView(): void {
    this.domesticButtonTarget.classList.add("bg-white", "shadow-sm", "font-bold")
    this.domesticButtonTarget.classList.remove("text-gray-500")
    
    this.internationalButtonTarget.classList.remove("bg-white", "shadow-sm", "font-bold")
    this.internationalButtonTarget.classList.add("text-gray-500")
  }

  private updateInternationalView(): void {
    this.internationalButtonTarget.classList.add("bg-white", "shadow-sm", "font-bold")
    this.internationalButtonTarget.classList.remove("text-gray-500")
    
    this.domesticButtonTarget.classList.remove("bg-white", "shadow-sm", "font-bold")
    this.domesticButtonTarget.classList.add("text-gray-500")
  }

  private updateSwapToggle(): void {
    if (this.isSwapEnabled) {
      this.swapIndicatorTarget.classList.remove("left-1")
      this.swapIndicatorTarget.classList.add("left-5")
      this.swapToggleTarget.classList.remove("bg-gray-200")
      this.swapToggleTarget.classList.add("bg-blue-500")
    } else {
      this.swapIndicatorTarget.classList.add("left-1")
      this.swapIndicatorTarget.classList.remove("left-5")
      this.swapToggleTarget.classList.add("bg-gray-200")
      this.swapToggleTarget.classList.remove("bg-blue-500")
    }
  }
}

// Extend Window interface for showToast
declare global {
  interface Window {
    showToast: (message: string) => void
  }
}
