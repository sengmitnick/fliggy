import { Controller } from "@hotwired/stimulus"

// Declare Turbo global type
declare const Turbo: any

export default class extends Controller<HTMLElement> {
  static targets = [
    // stimulus-validator: disable-next-line
    "modal",
    "departure",
    "destination",
    "departureCityInput",
    "destinationCityInput",
    // stimulus-validator: disable-next-line
    "tabDeparture",
    // stimulus-validator: disable-next-line
    "tabDestination",
    // stimulus-validator: disable-next-line
    "tabDomestic",
    // stimulus-validator: disable-next-line
    "tabInternational",
    // stimulus-validator: disable-next-line
    "searchInput",
    // stimulus-validator: disable-next-line
    "domesticList",
    // stimulus-validator: disable-next-line
    "internationalList",
    // stimulus-validator: disable-next-line
    "historySection",
    // stimulus-validator: disable-next-line
    "currentCity",
    // stimulus-validator: disable-next-line
    "locationStatus",
    // stimulus-validator: disable-next-line
    "locationButton",
    // stimulus-validator: disable-next-line
    "locationText",
    // stimulus-validator: disable-next-line
    "locationSpinner",
    // stimulus-validator: disable-next-line
    "locatedCity",
    // stimulus-validator: disable-next-line
    "locatedCityButton",
    // stimulus-validator: disable-next-line
    "currentRegionTab"
  ]

  static values = {
    departureCity: String,
    destinationCity: String,
    enableMultiSelect: { type: Boolean, default: true },
    modalTitle: { type: String, default: '' }
  }

  private selectionType: 'departure' | 'destination' = 'departure'
  private isMultiSelectMode: boolean = false
  private selectedCities: string[] = []

  declare readonly departureTarget: HTMLElement
  declare readonly destinationTarget: HTMLElement
  declare readonly departureCityInputTarget: HTMLInputElement
  declare readonly destinationCityInputTarget: HTMLInputElement
  // Optional target checkers - these mark targets as optional
  declare readonly hasDepartureTarget: boolean
  declare readonly hasDestinationTarget: boolean
  declare readonly hasDepartureCityInputTarget: boolean
  declare readonly hasDestinationCityInputTarget: boolean
  // Modal-related targets - all optional for pages without modal
  declare readonly hasModalTarget: boolean
  declare readonly modalTarget: HTMLElement
  declare readonly hasTabDepartureTarget: boolean
  declare readonly tabDepartureTarget: HTMLElement
  declare readonly hasTabDestinationTarget: boolean
  declare readonly tabDestinationTarget: HTMLElement
  declare readonly hasTabDomesticTarget: boolean
  declare readonly tabDomesticTarget: HTMLElement
  declare readonly hasTabInternationalTarget: boolean
  declare readonly tabInternationalTarget: HTMLElement
  declare readonly hasSearchInputTarget: boolean
  declare readonly searchInputTarget: HTMLInputElement
  declare readonly hasDomesticListTarget: boolean
  declare readonly domesticListTarget: HTMLElement
  declare readonly hasInternationalListTarget: boolean
  declare readonly internationalListTarget: HTMLElement
  declare readonly hasHistorySectionTarget: boolean
  declare readonly historySectionTarget: HTMLElement
  declare readonly hasCurrentCityTarget: boolean
  declare readonly currentCityTarget: HTMLElement
  declare readonly hasLocationStatusTarget: boolean
  declare readonly locationStatusTarget: HTMLElement
  declare readonly hasLocationButtonTarget: boolean
  declare readonly locationButtonTarget: HTMLButtonElement
  declare readonly hasLocationTextTarget: boolean
  declare readonly locationTextTarget: HTMLElement
  declare readonly hasLocationSpinnerTarget: boolean
  declare readonly locationSpinnerTarget: HTMLElement
  declare readonly hasLocatedCityTarget: boolean
  declare readonly locatedCityTarget: HTMLElement
  declare readonly hasLocatedCityButtonTarget: boolean
  declare readonly locatedCityButtonTarget: HTMLButtonElement
  declare readonly hasCurrentRegionTabTarget: boolean
  declare readonly currentRegionTabTarget: HTMLElement
  declare departureCityValue: string
  declare destinationCityValue: string
  declare enableMultiSelectValue: boolean
  declare modalTitleValue: string

  private currentMultiCitySegmentId: string | null = null
  private currentMultiCityCityType: string | null = null

  connect(): void {
    console.log("CitySelector connected", { enableMultiSelect: this.enableMultiSelectValue })
    // Initialize default values
    if (!this.departureCityValue) this.departureCityValue = "北京"
    if (!this.destinationCityValue) this.destinationCityValue = "杭州"
    
    // Set initial values to hidden inputs (only if targets exist)
    if (this.hasDepartureCityInputTarget) {
      this.departureCityInputTarget.value = this.departureCityValue
    }
    if (this.hasDestinationCityInputTarget) {
      this.destinationCityInputTarget.value = this.destinationCityValue
    }
    
    // Hide multi-select UI if disabled
    if (!this.enableMultiSelectValue) {
      this.hideMultiSelectUI()
    }
    
    // Listen for multi-city events
    this.element.addEventListener('multi-city:open-city-selector', this.handleMultiCityOpen.bind(this))
  }

  disconnect(): void {
    this.element.removeEventListener('multi-city:open-city-selector', this.handleMultiCityOpen.bind(this))
  }

  // Handle multi-city city selector request
  private handleMultiCityOpen(event: Event): void {
    const customEvent = event as CustomEvent
    const { segmentId, cityType } = customEvent.detail
    console.log('City selector: Received multi-city open request', { segmentId, cityType })
    this.currentMultiCitySegmentId = segmentId
    this.currentMultiCityCityType = cityType
    this.selectionType = cityType === 'departure' ? 'departure' : 'destination'
    this.updateModalTitle()
    this.showModal()
  }

  // Open modal for departure city selection
  openDeparture(): void {
    this.selectionType = 'departure'
    this.isMultiSelectMode = false
    this.selectedCities = []
    this.updateModalTitle()
    this.updateMultiSelectUI()
    this.showModal()
  }

  // Open modal for destination city selection
  openDestination(): void {
    this.selectionType = 'destination'
    this.isMultiSelectMode = false
    this.selectedCities = []
    this.updateModalTitle()
    this.updateMultiSelectUI()
    this.showModal()
  }

  // Show modal
  showModal(): void {
    if (!this.hasModalTarget) return
    this.modalTarget.classList.remove('hidden')
    document.body.style.overflow = 'hidden'
  }

  // Close modal
  closeModal(): void {
    if (!this.hasModalTarget) return
    this.modalTarget.classList.add('hidden')
    document.body.style.overflow = ''
    this.clearSearch()
  }

  // Select city
  selectCity(event: Event): void {
    const button = event.currentTarget as HTMLElement
    const cityName = button.dataset.cityName || ''
    const isInternational = button.dataset.international === 'true'
    
    console.log('City selector: City selected:', cityName, 'international:', isInternational)
    
    // Multi-select mode
    if (this.isMultiSelectMode) {
      if (this.selectedCities.includes(cityName)) {
        this.selectedCities = this.selectedCities.filter(city => city !== cityName)
      } else {
        this.selectedCities.push(cityName)
      }
      this.updateSelectedCitiesDisplay()
      this.updateCityButtonStates()
      return
    }
    
    // Check if this is for multi-city
    if (this.currentMultiCitySegmentId && this.currentMultiCityCityType) {
      console.log('City selector: Multi-city mode, dispatching event', {
        segmentId: this.currentMultiCitySegmentId,
        cityType: this.currentMultiCityCityType,
        cityName: cityName
      })
      
      // Trigger event to update multi-city segment - dispatch on document for better propagation
      const updateEvent = new CustomEvent('city-selector:city-selected', {
        detail: {
          segmentId: this.currentMultiCitySegmentId,
          cityType: this.currentMultiCityCityType,
          cityName: cityName
        },
        bubbles: true
      })
      document.dispatchEvent(updateEvent)
      
      // Reset multi-city state
      this.currentMultiCitySegmentId = null
      this.currentMultiCityCityType = null
    } else {
      console.log('City selector: Regular mode')
      // Regular single/round trip selection
      if (this.selectionType === 'departure') {
        this.departureCityValue = cityName
        if (this.hasDepartureTarget) {
          this.departureTarget.textContent = cityName
        }
        if (this.hasDepartureCityInputTarget) {
          this.departureCityInputTarget.value = cityName
        }
        
        // Special handling for special_hotels page - reload with new city parameter
        if (window.location.pathname === '/special_hotels') {
          Turbo.visit(`/special_hotels?city=${encodeURIComponent(cityName)}`)
          return
        }
        
        // Dispatch city-changed event for tour-group-filter and hotel-services-search to listen
        this.dispatchCityChangedEvent(cityName)
        
        // Dispatch hotel-specific event for hotel-search controller
        this.dispatchHotelCityUpdateEvent(cityName)
        
        // If international city selected in hotels context, switch to international tab
        if (isInternational) {
          this.switchToInternationalTab()
        }
      } else {
        this.destinationCityValue = cityName
        if (this.hasDestinationTarget) {
          this.destinationTarget.textContent = cityName
        }
        if (this.hasDestinationCityInputTarget) {
          this.destinationCityInputTarget.value = cityName
        }
      }
    }
    
    this.closeModal()
  }

  // Dispatch city-changed event for other controllers (like tour-group-filter)
  private dispatchCityChangedEvent(cityName: string): void {
    const cityChangedEvent = new CustomEvent('city-selector:city-changed', {
      detail: { cityName },
      bubbles: true
    })
    this.element.dispatchEvent(cityChangedEvent)
    console.log('City selector: Dispatched city-changed event', cityName)
  }

  // Dispatch hotel-specific city update event
  private dispatchHotelCityUpdateEvent(cityName: string): void {
    const hotelCityEvent = new CustomEvent('city-selector:city-selected-for-hotel', {
      detail: { cityName },
      bubbles: true
    })
    document.dispatchEvent(hotelCityEvent)
    console.log('City selector: Dispatched hotel city update event', cityName)
  }

  // Switch cities
  switchCities(): void {
    const temp = this.departureCityValue
    this.departureCityValue = this.destinationCityValue
    this.destinationCityValue = temp
    
    if (this.hasDepartureTarget) {
      this.departureTarget.textContent = this.departureCityValue
    }
    if (this.hasDestinationTarget) {
      this.destinationTarget.textContent = this.destinationCityValue
    }
    if (this.hasDepartureCityInputTarget) {
      this.departureCityInputTarget.value = this.departureCityValue
    }
    if (this.hasDestinationCityInputTarget) {
      this.destinationCityInputTarget.value = this.destinationCityValue
    }
  }

  // Switch between domestic and international tabs
  showDomestic(): void {
    if (!this.hasDomesticListTarget || !this.hasInternationalListTarget || !this.hasTabDomesticTarget || !this.hasTabInternationalTarget) return
    
    this.domesticListTarget.classList.remove('hidden')
    this.domesticListTarget.classList.add('flex')
    this.internationalListTarget.classList.add('hidden')
    this.internationalListTarget.classList.remove('flex')
    
    // Update tab styles
    this.tabDomesticTarget.classList.add('text-gray-900')
    this.tabDomesticTarget.classList.remove('text-gray-500')
    this.tabInternationalTarget.classList.remove('text-gray-900')
    this.tabInternationalTarget.classList.add('text-gray-500')
    
    // Show/hide underline
    const domesticUnderline = this.tabDomesticTarget.querySelector('div')
    const internationalUnderline = this.tabInternationalTarget.querySelector('div')
    if (domesticUnderline) domesticUnderline.classList.remove('hidden')
    if (internationalUnderline) internationalUnderline.classList.add('hidden')
  }

  showInternational(): void {
    if (!this.hasDomesticListTarget || !this.hasInternationalListTarget || !this.hasTabDomesticTarget || !this.hasTabInternationalTarget) return
    
    this.domesticListTarget.classList.add('hidden')
    this.domesticListTarget.classList.remove('flex')
    this.internationalListTarget.classList.remove('hidden')
    this.internationalListTarget.classList.add('flex')
    
    // Update tab styles
    this.tabDomesticTarget.classList.remove('text-gray-900')
    this.tabDomesticTarget.classList.add('text-gray-500')
    this.tabInternationalTarget.classList.add('text-gray-900')
    this.tabInternationalTarget.classList.remove('text-gray-500')
    
    // Show/hide underline
    const domesticUnderline = this.tabDomesticTarget.querySelector('div')
    const internationalUnderline = this.tabInternationalTarget.querySelector('div')
    if (domesticUnderline) domesticUnderline.classList.add('hidden')
    if (internationalUnderline) internationalUnderline.classList.remove('hidden')
  }

  // Search cities
  search(): void {
    if (!this.hasSearchInputTarget || !this.hasHistorySectionTarget || !this.hasDomesticListTarget || !this.hasInternationalListTarget) return
    
    const query = this.searchInputTarget.value.toLowerCase().trim()
    
    if (query === '') {
      this.clearSearch()
      return
    }

    // Hide history section when searching
    this.historySectionTarget.classList.add('hidden')
    
    // Filter cities in both lists
    this.filterCities(this.domesticListTarget, query)
    if (!this.internationalListTarget.classList.contains('hidden')) {
      this.filterCities(this.internationalListTarget, query)
    }
  }

  // Filter cities helper
  private filterCities(listTarget: HTMLElement, query: string): void {
    const cityButtons = listTarget.querySelectorAll('[data-city-name]')
    cityButtons.forEach((button) => {
      const cityName = (button as HTMLElement).dataset.cityName?.toLowerCase() || ''
      const cityPinyin = (button as HTMLElement).dataset.cityPinyin?.toLowerCase() || ''
      
      if (cityName.includes(query) || cityPinyin.includes(query)) {
        (button as HTMLElement).classList.remove('hidden')
      } else {
        (button as HTMLElement).classList.add('hidden')
      }
    })
  }

  // Clear search
  clearSearch(): void {
    if (!this.hasSearchInputTarget || !this.hasHistorySectionTarget) return
    
    this.searchInputTarget.value = ''
    this.historySectionTarget.classList.remove('hidden')
    
    // Show all cities
    const allButtons = this.element.querySelectorAll('[data-city-name]')
    allButtons.forEach((button) => {
      (button as HTMLElement).classList.remove('hidden')
    })
  }

  // Update modal title based on selection type
  private updateModalTitle(): void {
    if (!this.hasModalTarget) return
    
    const singleSelectTitle = this.modalTarget.querySelector('[data-single-select-title]')
    const multiSelectTitle = this.modalTarget.querySelector('[data-multi-select-title]')
    
    // If custom modal title is provided and multi-select is disabled, use custom title
    if (!this.enableMultiSelectValue && this.modalTitleValue) {
      if (singleSelectTitle) {
        singleSelectTitle.textContent = this.modalTitleValue
      }
    } else {
      // Default behavior: update based on selection type
      if (singleSelectTitle) {
        singleSelectTitle.textContent = this.selectionType === 'departure' ? '单选出发地' : '单选目的地'
      }
      if (multiSelectTitle) {
        multiSelectTitle.textContent = this.selectionType === 'departure' ? '多选出发地' : '多选目的地'
      }
    }
  }

  // Switch to single select mode
  switchToSingleSelect(): void {
    this.isMultiSelectMode = false
    this.selectedCities = []
    this.updateModalTitle()
    this.updateMultiSelectUI()
  }

  // Switch to multi select mode
  switchToMultiSelect(): void {
    this.isMultiSelectMode = true
    // Initialize with current selection type's value
    const currentValue = this.selectionType === 'departure' ? this.departureCityValue : this.destinationCityValue
    if (currentValue && currentValue !== '') {
      // Support comma-separated multiple cities
      this.selectedCities = currentValue.split(',').map(city => city.trim()).filter(city => city !== '')
    } else {
      this.selectedCities = []
    }
    this.updateModalTitle()
    this.updateMultiSelectUI()
  }

  // Update multi-select UI elements
  private updateMultiSelectUI(): void {
    if (!this.hasModalTarget) return
    
    const selectedCitiesContainer = this.modalTarget.querySelector('[data-selected-cities]')
    const confirmButton = this.modalTarget.querySelector('[data-confirm-button]')
    const singleSelectTab = this.modalTarget.querySelector('[data-single-select-tab]')
    const multiSelectTab = this.modalTarget.querySelector('[data-multi-select-tab]')
    
    if (this.isMultiSelectMode) {
      selectedCitiesContainer?.classList.remove('hidden')
      confirmButton?.classList.remove('hidden')
      singleSelectTab?.classList.remove('bg-white', 'shadow-sm', 'text-gray-900')
      singleSelectTab?.classList.add('text-gray-500')
      multiSelectTab?.classList.remove('text-gray-500')
      multiSelectTab?.classList.add('bg-white', 'shadow-sm', 'text-gray-900')
      this.updateSelectedCitiesDisplay()
      this.updateCityButtonStates()
    } else {
      selectedCitiesContainer?.classList.add('hidden')
      confirmButton?.classList.add('hidden')
      singleSelectTab?.classList.remove('text-gray-500')
      singleSelectTab?.classList.add('bg-white', 'shadow-sm', 'text-gray-900')
      multiSelectTab?.classList.remove('bg-white', 'shadow-sm', 'text-gray-900')
      multiSelectTab?.classList.add('text-gray-500')
      this.clearCityButtonStates()
    }
  }

  // Update selected cities display
  private updateSelectedCitiesDisplay(): void {
    if (!this.hasModalTarget) return
    
    const container = this.modalTarget.querySelector('[data-selected-cities]')
    if (!container) return
    
    container.innerHTML = this.selectedCities.map(city => `
      <div class="inline-flex items-center bg-yellow-100 px-3 py-1.5 rounded-lg">
        <span class="text-sm font-medium text-gray-900">${city}</span>
        <button 
          data-action="click->city-selector#removeSelectedCity"
          data-city-name="${city}"
          class="ml-2 text-gray-500 hover:text-gray-700">
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
          </svg>
        </button>
      </div>
    `).join('')
  }

  // Remove selected city
  removeSelectedCity(event: Event): void {
    event.stopPropagation()
    const button = event.currentTarget as HTMLElement
    const cityName = button.dataset.cityName || ''
    this.selectedCities = this.selectedCities.filter(city => city !== cityName)
    this.updateSelectedCitiesDisplay()
    this.updateCityButtonStates()
  }

  // Update city button states (show checkmarks)
  private updateCityButtonStates(): void {
    if (!this.hasModalTarget) return
    
    const cityButtons = this.modalTarget.querySelectorAll('[data-city-name]')
    cityButtons.forEach(button => {
      const cityName = (button as HTMLElement).dataset.cityName || ''
      const isSelected = this.selectedCities.includes(cityName)
      
      if (isSelected) {
        button.classList.add('bg-yellow-100', 'relative')
        if (!button.querySelector('[data-checkmark]')) {
          const checkmark = document.createElement('svg')
          checkmark.setAttribute('data-checkmark', '')
          checkmark.setAttribute('class', 'absolute right-1 top-1 w-4 h-4 text-yellow-600')
          checkmark.setAttribute('fill', 'currentColor')
          checkmark.setAttribute('viewBox', '0 0 20 20')
          checkmark.innerHTML =
            '<path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"/>'
          button.appendChild(checkmark)
        }
      } else {
        button.classList.remove('bg-yellow-100', 'relative')
        button.querySelector('[data-checkmark]')?.remove()
      }
    })
  }

  // Clear city button states
  private clearCityButtonStates(): void {
    if (!this.hasModalTarget) return
    
    const cityButtons = this.modalTarget.querySelectorAll('[data-city-name]')
    cityButtons.forEach(button => {
      button.classList.remove('bg-yellow-100', 'relative')
      button.querySelector('[data-checkmark]')?.remove()
    })
  }

  // Confirm multi-select
  confirmMultiSelect(): void {
    if (this.selectedCities.length === 0) {
      alert('请至少选择一个城市')
      return
    }
    
    // Update city value based on selection type
    if (this.selectionType === 'departure') {
      this.departureCityValue = this.selectedCities.join(',')
      this.departureTarget.textContent = this.selectedCities.join('、')
      this.departureCityInputTarget.value = this.departureCityValue
    } else {
      this.destinationCityValue = this.selectedCities.join(',')
      this.destinationTarget.textContent = this.selectedCities.join('、')
      this.destinationCityInputTarget.value = this.destinationCityValue
    }
    
    this.closeModal()
  }

  // Jump to letter section
  jumpToLetter(event: Event): void {
    if (!this.hasDomesticListTarget) return
    
    const button = event.currentTarget as HTMLElement
    const letter = button.dataset.letter || ''
    const section = this.domesticListTarget.querySelector(`[data-letter-section="${letter}"]`)
    
    if (section) {
      section.scrollIntoView({ behavior: 'smooth', block: 'start' })
    }
  }

  // Request user location
  requestLocation(): void {
    console.log('===== requestLocation called =====')
    console.log('navigator.geolocation available:', !!navigator.geolocation)
    
    if (!navigator.geolocation) {
      const errorMsg = '浏览器不支持定位'
      if (this.hasLocationTextTarget) {
        this.locationTextTarget.textContent = errorMsg
      } else {
        alert(errorMsg)
      }
      return
    }

    // Show loading state
    if (this.hasLocationButtonTarget) {
      this.locationButtonTarget.disabled = true
    }
    
    if (this.hasLocationTextTarget) {
      this.locationTextTarget.textContent = '定位中...'
    }
    
    if (this.hasLocationSpinnerTarget) {
      this.locationSpinnerTarget.classList.remove('hidden')
    }

    navigator.geolocation.getCurrentPosition(
      (position) => this.handleLocationSuccess(position),
      (error) => this.handleLocationError(error),
      {
        enableHighAccuracy: true,
        timeout: 10000,
        maximumAge: 0
      }
    )
  }

  // Handle location success
   
  private async handleLocationSuccess(position: any): Promise<void> {
    const { latitude, longitude } = position.coords
    console.log('Location obtained:', latitude, longitude)

    try {
      // Call reverse geocoding API
      const response = await fetch('/api/geocoding/reverse', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.getCSRFToken()
        },
        body: JSON.stringify({
          lat: latitude,
          lng: longitude
        })
      })

      if (!response.ok) {
        throw new Error('定位服务失败')
      }

      const data = await response.json()
      console.log('City found:', data)

      // Check if modal targets exist (modal-based page)
      if (this.hasLocationTextTarget && this.hasLocationSpinnerTarget) {
        // Modal-based page: Update modal UI with located city
        this.locationTextTarget.textContent = `当前位置: ${data.city}`
        this.locationButtonTarget.disabled = false
        this.locationSpinnerTarget.classList.add('hidden')

        // Show located city button in modal
        if (this.hasLocatedCityButtonTarget && this.hasLocatedCityTarget) {
          this.locatedCityButtonTarget.textContent = data.city
          this.locatedCityButtonTarget.dataset.cityName = data.city
          this.locatedCityButtonTarget.dataset.cityPinyin = data.pinyin
          this.locatedCityTarget.classList.remove('hidden')
        }
      } else {
        // No modal: Direct update for special_hotels-style pages
        console.log('No modal found, updating city display directly')
        
        // Update the departure target text immediately
        if (this.hasDepartureTarget) {
          this.departureTarget.textContent = data.city
        }
        
        // Update hidden input if exists
        if (this.hasDepartureCityInputTarget) {
          this.departureCityInputTarget.value = data.city
        }
        
        // Update the value
        this.departureCityValue = data.city
        
        // Re-enable button
        if (this.hasLocationButtonTarget) {
          this.locationButtonTarget.disabled = false
        }
        
        // Hide spinner if exists
        if (this.hasLocationSpinnerTarget) {
          this.locationSpinnerTarget.classList.add('hidden')
        }
        
        // Optionally update URL without reload (for consistency)
        const currentPath = window.location.pathname
        const newUrl = `${currentPath}?city=${encodeURIComponent(data.city)}`
        console.log('Updating URL to:', newUrl)
        
        // Use history.replaceState to update URL without page reload
        if (window.history && window.history.replaceState) {
          window.history.replaceState({}, '', newUrl)
        }
        
        // Dispatch city-changed event for other controllers to listen
        this.dispatchCityChangedEvent(data.city)
      }

    } catch (error) {
      console.error('Reverse geocoding error:', error)
       
      this.handleLocationError(error as any)
    }
  }

  // Handle location error
   
  private handleLocationError(error: any): void {
    let errorMessage = '定位失败'

    if ('code' in error) {
      switch (error.code) {
        case 1:
          errorMessage = '用户拒绝定位'
          break
        case 2:
          errorMessage = '位置信息不可用'
          break
        case 3:
          errorMessage = '定位超时'
          break
      }
    }

    console.error('Location error:', error)
    
    // Only update UI targets if they exist
    if (this.hasLocationTextTarget) {
      this.locationTextTarget.textContent = errorMessage
    }
    
    if (this.hasLocationButtonTarget) {
      this.locationButtonTarget.disabled = false
    }
    
    if (this.hasLocationSpinnerTarget) {
      this.locationSpinnerTarget.classList.add('hidden')
    }
    
    // Show alert for pages without modal
    if (!this.hasLocationTextTarget) {
      alert(errorMessage)
    }
  }

  // Get CSRF token
  private getCSRFToken(): string {
    const token = document.querySelector('meta[name="csrf-token"]') as HTMLMetaElement
    return token ? token.content : ''
  }

  // Hide multi-select UI elements (for pages that don't need multi-select)
  private hideMultiSelectUI(): void {
    // Replace the toggle buttons container with a fixed title
    const singleSelectTab = this.modalTarget.querySelector('[data-single-select-tab]')
    const multiSelectTab = this.modalTarget.querySelector('[data-multi-select-tab]')
    
    if (singleSelectTab && multiSelectTab) {
      const toggleContainer = singleSelectTab.parentElement
      if (toggleContainer) {
        // Replace the entire toggle container with a simple title
        const titleText = this.modalTitleValue || '选择目的地'
        toggleContainer.outerHTML = `<div class="text-lg font-bold text-gray-900">${titleText}</div>`
      }
    }
    
    // Hide selected cities container and confirm button
    const selectedCitiesContainer = this.modalTarget.querySelector('[data-selected-cities]') as HTMLElement
    const confirmButton = this.modalTarget.querySelector('[data-confirm-button]') as HTMLElement
    
    if (selectedCitiesContainer) {
      selectedCitiesContainer.style.display = 'none'
    }
    if (confirmButton) {
      confirmButton.style.display = 'none'
    }
  }

  // Switch to international tab in hotel context
  private switchToInternationalTab(): void {
    console.log('City selector: Switching to international hotel tab')
    // Dispatch event to hotel-tabs controller
    const event = new CustomEvent('city-selector:switch-to-international', {
      detail: {},
      bubbles: true
    })
    document.dispatchEvent(event)
  }

  // Scroll to region in international tab
  scrollToRegion(event: Event): void {
    const button = event.currentTarget as HTMLElement
    const regionId = button.dataset.region
    
    if (!regionId) return
    
    console.log('Scrolling to region:', regionId)
    
    // Update active tab styling
    const allRegionTabs = this.internationalListTarget.querySelectorAll('[data-region]')
    allRegionTabs.forEach(tab => {
      tab.classList.remove('bg-white', 'font-bold', 'text-gray-900')
      tab.classList.add('text-gray-500')
    })
    button.classList.add('bg-white', 'font-bold', 'text-gray-900')
    button.classList.remove('text-gray-500')
    
    // Find and scroll to the content section
    const contentArea = this.internationalListTarget.querySelector('.overflow-y-auto')
    const targetSection = contentArea?.querySelector(`[data-region-section="${regionId}"]`)
    
    if (targetSection && contentArea) {
      // Scroll the content area (not the whole window)
      const offsetTop = (targetSection as HTMLElement).offsetTop - 20
      contentArea.scrollTo({
        top: offsetTop,
        behavior: 'smooth'
      })
    }
  }
}
