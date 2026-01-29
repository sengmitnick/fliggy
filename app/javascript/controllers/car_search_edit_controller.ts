import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    // stimulus-validator: disable-next-line
    "modal",
    // stimulus-validator: disable-next-line
    "domesticButton",
    // stimulus-validator: disable-next-line
    "internationalButton",
    // stimulus-validator: disable-next-line
    "swapToggle",
    // stimulus-validator: disable-next-line
    "swapIndicator",
    // stimulus-validator: disable-next-line
    "returnLocationSection",
    "cityDisplay",
    // stimulus-validator: disable-next-line
    "modalCityDisplay",
    // stimulus-validator: disable-next-line
    "pickupLocationDisplay",
    // stimulus-validator: disable-next-line
    "returnCityDisplay",
    // stimulus-validator: disable-next-line
    "returnLocationDisplay",
    // stimulus-validator: disable-next-line
    "pickupDateDisplay",
    // stimulus-validator: disable-next-line
    "returnDateDisplay",
    // stimulus-validator: disable-next-line
    "durationDisplay",
    // stimulus-validator: disable-next-line
    "cityInput",
    // stimulus-validator: disable-next-line
    "pickupLocationInput",
    // stimulus-validator: disable-next-line
    "returnCityInput",
    // stimulus-validator: disable-next-line
    "returnLocationInput",
    // stimulus-validator: disable-next-line
    "pickupDateInput",
    // stimulus-validator: disable-next-line
    "returnDateInput",
    // stimulus-validator: disable-next-line
    "searchButton"
  ]

  // stimulus-validator: disable-next-line
  declare readonly modalTarget: HTMLElement
  // stimulus-validator: disable-next-line
  declare readonly domesticButtonTarget: HTMLButtonElement
  // stimulus-validator: disable-next-line
  declare readonly internationalButtonTarget: HTMLButtonElement
  // stimulus-validator: disable-next-line
  declare readonly swapToggleTarget: HTMLElement
  // stimulus-validator: disable-next-line
  declare readonly swapIndicatorTarget: HTMLElement
  // stimulus-validator: disable-next-line
  declare readonly returnLocationSectionTarget: HTMLElement
  declare readonly cityDisplayTarget: HTMLElement
  // stimulus-validator: disable-next-line
  declare readonly modalCityDisplayTarget: HTMLElement
  // stimulus-validator: disable-next-line
  declare readonly pickupLocationDisplayTarget: HTMLElement
  // stimulus-validator: disable-next-line
  declare readonly returnCityDisplayTarget: HTMLElement
  // stimulus-validator: disable-next-line
  declare readonly returnLocationDisplayTarget: HTMLElement
  // stimulus-validator: disable-next-line
  declare readonly pickupDateDisplayTarget: HTMLElement
  // stimulus-validator: disable-next-line
  declare readonly returnDateDisplayTarget: HTMLElement
  // stimulus-validator: disable-next-line
  declare readonly durationDisplayTarget: HTMLElement
  // stimulus-validator: disable-next-line
  declare readonly cityInputTarget: HTMLInputElement
  // stimulus-validator: disable-next-line
  declare readonly pickupLocationInputTarget: HTMLInputElement
  // stimulus-validator: disable-next-line
  declare readonly returnCityInputTarget: HTMLInputElement
  // stimulus-validator: disable-next-line
  declare readonly returnLocationInputTarget: HTMLInputElement
  // stimulus-validator: disable-next-line
  declare readonly pickupDateInputTarget: HTMLInputElement
  // stimulus-validator: disable-next-line
  declare readonly returnDateInputTarget: HTMLInputElement
  // stimulus-validator: disable-next-line
  declare readonly searchButtonTarget: HTMLInputElement

  private isDomestic: boolean = true
  private isSwapEnabled: boolean = false
  private currentSelectionType: 'city' | 'pickup' | 'return' | 'return-city' | null = null
  
  // Current values
  private cityValue: string = ''
  private pickupLocationValue: string = ''
  private returnCityValue: string = ''
  private returnLocationValue: string = ''
  private pickupDateValue: string = ''
  private returnDateValue: string = ''

  connect(): void {
    console.log("CarSearchEdit connected")
    this.loadCurrentSearchParams()
    
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

  // Load current search parameters from URL
  private loadCurrentSearchParams(): void {
    const params = new URLSearchParams(window.location.search)
    
    // Load city
    this.cityValue = params.get('city') || '深圳'
    
    // Load pickup location
    this.pickupLocationValue = params.get('pickup_location') || ''
    
    // Load return city and location (if different location enabled)
    this.returnCityValue = params.get('return_city') || ''
    this.returnLocationValue = params.get('return_location') || ''
    
    // Load dates
    this.pickupDateValue = params.get('pickup_date') || ''
    this.returnDateValue = params.get('return_date') || ''
    
    // Enable swap toggle if return location is set
    if (this.returnLocationValue) {
      this.isSwapEnabled = true
    }
  }

  // Open the complete search form modal
  openLocationEditor(): void {
    console.log('[CarSearchEdit] Opening search form modal')
    
    // Update modal form values with current search params
    this.updateModalDisplay()
    
    // Show modal
    this.modalTarget.classList.remove("hidden")
    document.body.style.overflow = "hidden"
  }

  closeModal(): void {
    this.modalTarget.classList.add("hidden")
    document.body.style.overflow = ""
  }

  stopPropagation(event: Event): void {
    event.stopPropagation()
  }

  // Update modal display with current values
  private updateModalDisplay(): void {
    // Update city in modal
    if (this.modalCityDisplayTarget) {
      this.modalCityDisplayTarget.textContent = this.cityValue
    }
    if (this.cityInputTarget) {
      this.cityInputTarget.value = this.cityValue
    }
    
    // Update pickup location
    if (this.pickupLocationDisplayTarget) {
      if (this.pickupLocationValue) {
        this.pickupLocationDisplayTarget.textContent = this.pickupLocationValue
        this.pickupLocationDisplayTarget.classList.remove('text-gray-400')
        this.pickupLocationDisplayTarget.classList.add('text-text-primary')
      } else {
        this.pickupLocationDisplayTarget.textContent = '请选择地点'
        this.pickupLocationDisplayTarget.classList.add('text-gray-400')
      }
    }
    if (this.pickupLocationInputTarget) {
      this.pickupLocationInputTarget.value = this.pickupLocationValue
    }
    
    // Update return location section
    if (this.isSwapEnabled) {
      this.returnLocationSectionTarget.classList.remove('hidden')
      this.updateSwapToggle()
      
      if (this.returnCityDisplayTarget) {
        this.returnCityDisplayTarget.textContent = this.returnCityValue || this.cityValue
      }
      if (this.returnCityInputTarget) {
        this.returnCityInputTarget.value = this.returnCityValue || this.cityValue
      }
      
      if (this.returnLocationDisplayTarget) {
        if (this.returnLocationValue) {
          this.returnLocationDisplayTarget.textContent = this.returnLocationValue
          this.returnLocationDisplayTarget.classList.remove('text-gray-400')
        } else {
          this.returnLocationDisplayTarget.textContent = '请选择地点'
          this.returnLocationDisplayTarget.classList.add('text-gray-400')
        }
      }
      if (this.returnLocationInputTarget) {
        this.returnLocationInputTarget.value = this.returnLocationValue
      }
    }
    
    // Update dates
    if (this.pickupDateValue && this.returnDateValue) {
      this.updateDateDisplays()
    } else {
      // Set default dates
      const today = new Date()
      today.setHours(13, 55, 0, 0)
      const returnDate = new Date(today)
      returnDate.setDate(returnDate.getDate() + 2)
      
      this.pickupDateValue = today.toISOString()
      this.returnDateValue = returnDate.toISOString()
      this.updateDateDisplays()
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

  private updateDomesticView(): void {
    this.domesticButtonTarget.classList.add('bg-white', 'shadow-sm', 'font-bold')
    this.domesticButtonTarget.classList.remove('text-gray-500')
    this.internationalButtonTarget.classList.remove('bg-white', 'shadow-sm', 'font-bold')
    this.internationalButtonTarget.classList.add('text-gray-500')
  }

  private updateInternationalView(): void {
    this.internationalButtonTarget.classList.add('bg-white', 'shadow-sm', 'font-bold')
    this.internationalButtonTarget.classList.remove('text-gray-500')
    this.domesticButtonTarget.classList.remove('bg-white', 'shadow-sm', 'font-bold')
    this.domesticButtonTarget.classList.add('text-gray-500')
    
    if (window.showToast) {
      window.showToast('国际租车功能即将上线')
    }
  }

  toggleSwap(): void {
    this.isSwapEnabled = !this.isSwapEnabled
    this.updateSwapToggle()
    
    if (this.isSwapEnabled) {
      this.returnLocationSectionTarget.classList.remove('hidden')
      this.returnCityValue = this.cityValue
      this.returnCityDisplayTarget.textContent = this.cityValue
      this.returnCityInputTarget.value = this.cityValue
    } else {
      this.returnLocationSectionTarget.classList.add('hidden')
      this.returnCityValue = ''
      this.returnLocationValue = ''
      this.returnCityDisplayTarget.textContent = '深圳'
      this.returnLocationDisplayTarget.textContent = '请选择地点'
      this.returnLocationDisplayTarget.classList.add('text-gray-400')
      this.returnCityInputTarget.value = ''
      this.returnLocationInputTarget.value = ''
    }
  }

  private updateSwapToggle(): void {
    if (this.isSwapEnabled) {
      this.swapToggleTarget.classList.remove('bg-gray-200')
      this.swapToggleTarget.classList.add('bg-blue-500')
      this.swapIndicatorTarget.classList.remove('left-1')
      this.swapIndicatorTarget.classList.add('left-5')
    } else {
      this.swapToggleTarget.classList.add('bg-gray-200')
      this.swapToggleTarget.classList.remove('bg-blue-500')
      this.swapIndicatorTarget.classList.add('left-1')
      this.swapIndicatorTarget.classList.remove('left-5')
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
    console.log('[CarSearchEdit] openPickupLocationSelector called')
    this.currentSelectionType = 'pickup'
    const controller = this.application.getControllerForElementAndIdentifier(
      document.querySelector('[data-controller="location-selector"]') as Element,
      'location-selector'
    ) as any
    console.log('[CarSearchEdit] location-selector controller:', controller)
    if (controller && controller.openModal) {
      // Sync current city to location selector
      controller.currentCityValue = this.cityValue
      console.log('[CarSearchEdit] Calling controller.openModal()')
      controller.openModal()
    } else {
      console.error('[CarSearchEdit] location-selector controller or openModal method not found')
    }
  }

  // Open return city selector
  openReturnCitySelector(): void {
    if (!this.isSwapEnabled) {
      if (window.showToast) {
        window.showToast('请先开启异地还车')
      }
      return
    }
    this.currentSelectionType = 'return-city'
    const modal = document.querySelector('[data-city-selector-target="modal"]') as HTMLElement
    if (modal) {
      modal.classList.remove('hidden')
      document.body.style.overflow = 'hidden'
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
    console.log('[CarSearchEdit] openReturnLocationSelector called')
    this.currentSelectionType = 'return'
    const controller = this.application.getControllerForElementAndIdentifier(
      document.querySelector('[data-controller="location-selector"]') as Element,
      'location-selector'
    ) as any
    console.log('[CarSearchEdit] location-selector controller:', controller)
    if (controller && controller.openModal) {
      // Sync return city to location selector
      controller.currentCityValue = this.returnCityValue || this.cityValue
      console.log('[CarSearchEdit] Calling controller.openModal()')
      controller.openModal()
    } else {
      console.error('[CarSearchEdit] location-selector controller or openModal method not found')
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
      // Clear pickup location when city changes
      this.clearPickupLocation()
      if (this.isSwapEnabled) {
        this.clearReturnLocation()
      }
      this.currentSelectionType = null
      
      // Auto-jump to pickup location selector
      setTimeout(() => {
        this.openPickupLocationSelector()
      }, 300)
    } else if (this.currentSelectionType === 'return-city') {
      this.updateReturnCity(cityName)
      this.clearReturnLocation()
      this.currentSelectionType = null
      
      // Auto-jump to return location selector
      setTimeout(() => {
        this.openReturnLocationSelector()
      }, 300)
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

  // Handle datetime selection from datetime picker
  private handleDateTimeSelected(event: Event): void {
    const customEvent = event as CustomEvent
    const { type, date } = customEvent.detail
    
    if (type === 'pickup') {
      this.pickupDateValue = date
      this.pickupDateInputTarget.value = date
    } else if (type === 'return') {
      this.returnDateValue = date
      this.returnDateInputTarget.value = date
    }
    
    this.updateDateDisplays()
  }

  private updateCity(cityName: string): void {
    this.cityValue = cityName
    this.cityDisplayTarget.textContent = cityName
    this.cityInputTarget.value = cityName
  }

  private updatePickupLocation(locationName: string): void {
    this.pickupLocationValue = locationName
    this.pickupLocationDisplayTarget.textContent = locationName
    this.pickupLocationDisplayTarget.classList.remove('text-gray-400')
    this.pickupLocationDisplayTarget.classList.add('text-text-primary')
    this.pickupLocationInputTarget.value = locationName
  }

  private updateReturnCity(cityName: string): void {
    this.returnCityValue = cityName
    this.returnCityDisplayTarget.textContent = cityName
    this.returnCityInputTarget.value = cityName
  }

  private updateReturnLocation(locationName: string): void {
    this.returnLocationValue = locationName
    this.returnLocationDisplayTarget.textContent = locationName
    this.returnLocationDisplayTarget.classList.remove('text-gray-400')
    this.returnLocationDisplayTarget.classList.add('text-text-primary')
    this.returnLocationInputTarget.value = locationName
  }

  private clearPickupLocation(): void {
    this.pickupLocationValue = ''
    this.pickupLocationDisplayTarget.textContent = '请选择地点'
    this.pickupLocationDisplayTarget.classList.add('text-gray-400')
    this.pickupLocationDisplayTarget.classList.remove('text-text-primary')
    this.pickupLocationInputTarget.value = ''
  }

  private clearReturnLocation(): void {
    this.returnLocationValue = ''
    this.returnLocationDisplayTarget.textContent = '请选择地点'
    this.returnLocationDisplayTarget.classList.add('text-gray-400')
    this.returnLocationDisplayTarget.classList.remove('text-text-primary')
    this.returnLocationInputTarget.value = ''
  }

  private updateDateDisplays(): void {
    if (!this.pickupDateValue || !this.returnDateValue) return
    
    const pickupDate = new Date(this.pickupDateValue)
    const returnDate = new Date(this.returnDateValue)
    
    // Format: "1月10日 13:55"
    const formatDate = (date: Date): string => {
      const month = date.getMonth() + 1
      const day = date.getDate()
      const hours = date.getHours().toString().padStart(2, '0')
      const minutes = date.getMinutes().toString().padStart(2, '0')
      return `${month}月${day}日 <span class="text-sm">${hours}:${minutes}</span>`
    }
    
    this.pickupDateDisplayTarget.innerHTML = formatDate(pickupDate)
    this.returnDateDisplayTarget.innerHTML = formatDate(returnDate)
    
    // Calculate duration
    const duration = Math.ceil((returnDate.getTime() - pickupDate.getTime()) / (1000 * 60 * 60 * 24))
    this.durationDisplayTarget.textContent = `${duration}天`
  }
}
