import { Controller } from "@hotwired/stimulus"

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
    "locatedCityButton"
  ]

  static values = {
    departureCity: String,
    destinationCity: String
  }

  private selectionType: 'departure' | 'destination' = 'departure'

  declare readonly departureTarget: HTMLElement
  declare readonly destinationTarget: HTMLElement
  declare readonly departureCityInputTarget: HTMLInputElement
  declare readonly destinationCityInputTarget: HTMLInputElement
  // stimulus-validator: disable-next-line
  declare readonly modalTarget: HTMLElement
  // stimulus-validator: disable-next-line
  declare readonly tabDepartureTarget: HTMLElement
  // stimulus-validator: disable-next-line
  declare readonly tabDestinationTarget: HTMLElement
  // stimulus-validator: disable-next-line
  declare readonly tabDomesticTarget: HTMLElement
  // stimulus-validator: disable-next-line
  declare readonly tabInternationalTarget: HTMLElement
  // stimulus-validator: disable-next-line
  declare readonly searchInputTarget: HTMLInputElement
  // stimulus-validator: disable-next-line
  declare readonly domesticListTarget: HTMLElement
  // stimulus-validator: disable-next-line
  declare readonly internationalListTarget: HTMLElement
  // stimulus-validator: disable-next-line
  declare readonly historySectionTarget: HTMLElement
  // stimulus-validator: disable-next-line
  declare readonly currentCityTarget: HTMLElement
  // stimulus-validator: disable-next-line
  declare readonly locationStatusTarget: HTMLElement
  // stimulus-validator: disable-next-line
  declare readonly locationButtonTarget: HTMLButtonElement
  // stimulus-validator: disable-next-line
  declare readonly locationTextTarget: HTMLElement
  // stimulus-validator: disable-next-line
  declare readonly locationSpinnerTarget: HTMLElement
  // stimulus-validator: disable-next-line
  declare readonly locatedCityTarget: HTMLElement
  // stimulus-validator: disable-next-line
  declare readonly locatedCityButtonTarget: HTMLButtonElement
  declare departureCityValue: string
  declare destinationCityValue: string

  private currentMultiCitySegmentId: string | null = null
  private currentMultiCityCityType: string | null = null

  connect(): void {
    console.log("CitySelector connected")
    // Initialize default values
    if (!this.departureCityValue) this.departureCityValue = "北京"
    if (!this.destinationCityValue) this.destinationCityValue = "杭州"
    
    // Set initial values to hidden inputs
    this.departureCityInputTarget.value = this.departureCityValue
    this.destinationCityInputTarget.value = this.destinationCityValue
    
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
    this.updateModalTitle()
    this.showModal()
  }

  // Open modal for destination city selection
  openDestination(): void {
    this.selectionType = 'destination'
    this.updateModalTitle()
    this.showModal()
  }

  // Show modal
  showModal(): void {
    this.modalTarget.classList.remove('hidden')
    document.body.style.overflow = 'hidden'
  }

  // Close modal
  closeModal(): void {
    this.modalTarget.classList.add('hidden')
    document.body.style.overflow = ''
    this.clearSearch()
  }

  // Select city
  selectCity(event: Event): void {
    const button = event.currentTarget as HTMLElement
    const cityName = button.dataset.cityName || ''
    
    console.log('City selector: City selected:', cityName)
    
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
        this.departureTarget.textContent = cityName
        this.departureCityInputTarget.value = cityName
      } else {
        this.destinationCityValue = cityName
        this.destinationTarget.textContent = cityName
        this.destinationCityInputTarget.value = cityName
      }
    }
    
    this.closeModal()
  }

  // Switch cities
  switchCities(): void {
    const temp = this.departureCityValue
    this.departureCityValue = this.destinationCityValue
    this.destinationCityValue = temp
    
    this.departureTarget.textContent = this.departureCityValue
    this.destinationTarget.textContent = this.destinationCityValue
    this.departureCityInputTarget.value = this.departureCityValue
    this.destinationCityInputTarget.value = this.destinationCityValue
  }

  // Switch between domestic and international tabs
  showDomestic(): void {
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
    this.searchInputTarget.value = ''
    this.historySectionTarget.classList.remove('hidden')
    
    // Show all cities
    // stimulus-validator: disable-next-line
    const allButtons = this.element.querySelectorAll('[data-city-name]')
    allButtons.forEach((button) => {
      (button as HTMLElement).classList.remove('hidden')
    })
  }

  // Update modal title based on selection type
  private updateModalTitle(): void {
    const titleElement = this.modalTarget.querySelector('[data-modal-title]')
    if (titleElement) {
      titleElement.textContent = this.selectionType === 'departure' ? '单选出发地' : '单选目的地'
    }
  }

  // Jump to letter section
  jumpToLetter(event: Event): void {
    const button = event.currentTarget as HTMLElement
    const letter = button.dataset.letter || ''
    const section = this.domesticListTarget.querySelector(`[data-letter-section="${letter}"]`)
    
    if (section) {
      section.scrollIntoView({ behavior: 'smooth', block: 'start' })
    }
  }

  // Request user location
  requestLocation(): void {
    if (!navigator.geolocation) {
      this.locationTextTarget.textContent = '浏览器不支持定位'
      return
    }

    // Show loading state
    this.locationButtonTarget.disabled = true
    this.locationTextTarget.textContent = '定位中...'
    this.locationSpinnerTarget.classList.remove('hidden')

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
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
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

      // Update UI with located city
      this.locationTextTarget.textContent = `当前位置: ${data.city}`
      this.locationButtonTarget.disabled = false
      this.locationSpinnerTarget.classList.add('hidden')

      // Show located city button
      this.locatedCityButtonTarget.textContent = data.city
      this.locatedCityButtonTarget.dataset.cityName = data.city
      this.locatedCityButtonTarget.dataset.cityPinyin = data.pinyin
      this.locatedCityTarget.classList.remove('hidden')

    } catch (error) {
      console.error('Reverse geocoding error:', error)
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      this.handleLocationError(error as any)
    }
  }

  // Handle location error
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
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
    this.locationTextTarget.textContent = errorMessage
    this.locationButtonTarget.disabled = false
    this.locationSpinnerTarget.classList.add('hidden')
  }

  // Get CSRF token
  private getCSRFToken(): string {
    const token = document.querySelector('meta[name="csrf-token"]') as HTMLMetaElement
    return token ? token.content : ''
  }
}
