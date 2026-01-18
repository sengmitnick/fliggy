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
  private currentRegionType: 'domestic' | 'international' = 'domestic'

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

  // Open modal for hotel search city selection
  openHotelCitySelector(): void {
    this.selectionType = 'departure'
    this.isMultiSelectMode = false
    this.selectedCities = []
    this.updateModalTitle()
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
        
        // Special handling for hotels/search page - reload with new city parameter
        if (window.location.pathname === '/hotels/search') {
          const url = new URL(window.location.href)
          url.searchParams.set('city', cityName)
          // Set location_type based on isInternational flag
          url.searchParams.set('location_type', isInternational ? 'international' : 'domestic')
          Turbo.visit(url.toString())
          return
        }
        
        // Dispatch city-changed event for tour-group-filter and hotel-services-search to listen
        this.dispatchCityChangedEvent(cityName)
        
        // Dispatch hotel-specific event for hotel-search controller
        this.dispatchHotelCityUpdateEvent(cityName)
        
        // Dispatch trip-planner city change event
        this.dispatchTripCityChangeEvent('departure', cityName)
      } else {
        this.destinationCityValue = cityName
        if (this.hasDestinationTarget) {
          this.destinationTarget.textContent = cityName
        }
        if (this.hasDestinationCityInputTarget) {
          this.destinationCityInputTarget.value = cityName
        }
        
        // Dispatch city-changed event for tour-group-filter to listen
        this.dispatchCityChangedEvent(cityName)
        
        // Dispatch trip-planner city change event
        this.dispatchTripCityChangeEvent('destination', cityName)
      }
    }
    
    this.closeModal()
    this.saveToHistory(cityName)
  }

  // Toggle region tab (domestic/international)
  toggleRegion(event: Event): void {
    const button = event.currentTarget as HTMLElement
    const region = button.dataset.region as 'domestic' | 'international'
    
    this.currentRegionType = region
    
    // Update tab styles
    if (this.hasTabDomesticTarget && this.hasTabInternationalTarget) {
      if (region === 'domestic') {
        this.tabDomesticTarget.classList.add('border-b-2', 'border-primary', 'text-primary', 'font-bold')
        this.tabDomesticTarget.classList.remove('text-gray-500')
        this.tabInternationalTarget.classList.remove('border-b-2', 'border-primary', 'text-primary', 'font-bold')
        this.tabInternationalTarget.classList.add('text-gray-500')
      } else {
        this.tabInternationalTarget.classList.add('border-b-2', 'border-primary', 'text-primary', 'font-bold')
        this.tabInternationalTarget.classList.remove('text-gray-500')
        this.tabDomesticTarget.classList.remove('border-b-2', 'border-primary', 'text-primary', 'font-bold')
        this.tabDomesticTarget.classList.add('text-gray-500')
      }
    }
    
    // Toggle list visibility
    if (this.hasDomesticListTarget && this.hasInternationalListTarget) {
      if (region === 'domestic') {
        this.domesticListTarget.classList.remove('hidden')
        this.internationalListTarget.classList.add('hidden')
      } else {
        this.domesticListTarget.classList.add('hidden')
        this.internationalListTarget.classList.remove('hidden')
      }
    }
  }

  // Search cities
  searchCities(): void {
    if (!this.hasSearchInputTarget) return
    
    const query = this.searchInputTarget.value.toLowerCase().trim()
    const cityButtons = this.element.querySelectorAll('[data-city-name]')
    
    cityButtons.forEach((button) => {
      const cityName = (button as HTMLElement).dataset.cityName?.toLowerCase() || ''
      const cityElement = button as HTMLElement
      
      if (!query || cityName.includes(query)) {
        cityElement.classList.remove('hidden')
      } else {
        cityElement.classList.add('hidden')
      }
    })
  }

  // Clear search
  clearSearch(): void {
    if (!this.hasSearchInputTarget) return
    
    this.searchInputTarget.value = ''
    this.searchCities()
  }

  // Expand hot cities section
  expandHotCities(event: Event): void {
    const button = event.currentTarget as HTMLElement
    const hotCitiesSection = button.closest('.p-4')
    
    if (!hotCitiesSection) return
    
    // Toggle button text
    if (button.textContent?.includes('展开')) {
      button.innerHTML = '收起 ›'
    } else {
      button.innerHTML = '展开 ›'
    }
    
    // Toggle expanded state (you can add more cities here if needed)
    // For now, just toggle the button text to indicate the action
    console.log('Hot cities section expand/collapse toggled')
  }

  // Request location - simple IP-based geolocation
  requestLocation(): void {
    if (!this.hasLocationButtonTarget || !this.hasLocationTextTarget) return
    
    // Show loading
    this.locationTextTarget.textContent = '定位中...'
    if (this.hasLocationSpinnerTarget) {
      this.locationSpinnerTarget.classList.remove('hidden')
    }
    this.locationButtonTarget.disabled = true
    
    // Simple IP geolocation
    fetch('https://ipapi.co/json/')
      .then(response => response.json())
      .then(data => {
        const cityName = data.city || '深圳'
        this.showLocationResult(cityName)
      })
      .catch(() => {
        this.showLocationResult('深圳')
      })
  }
  
  // Show location result
  private showLocationResult(cityName: string): void {
    if (!this.hasLocationTextTarget) return
    
    // Show city name directly in locationText
    this.locationTextTarget.textContent = cityName
    
    if (this.hasLocationSpinnerTarget) {
      this.locationSpinnerTarget.classList.add('hidden')
    }
    if (this.hasLocationButtonTarget) {
      this.locationButtonTarget.disabled = false
      // Change button text to "重新定位"
      this.locationButtonTarget.textContent = '重新定位'
    }
  }

  // Save to history
  private saveToHistory(cityName: string): void {
    const storageKey = 'city_history'
    let history: string[] = []
    
    try {
      const stored = localStorage.getItem(storageKey)
      if (stored) {
        history = JSON.parse(stored)
      }
    } catch (e) {
      console.error('Failed to load city history:', e)
    }
    
    // Remove if already exists
    history = history.filter(city => city !== cityName)
    
    // Add to beginning
    history.unshift(cityName)
    
    // Keep only last 5
    history = history.slice(0, 5)
    
    try {
      localStorage.setItem(storageKey, JSON.stringify(history))
    } catch (e) {
      console.error('Failed to save city history:', e)
    }
  }

  // Update modal title
  private updateModalTitle(): void {
    // Modal title can be customized via value
  }

  // Hide multi-select UI
  private hideMultiSelectUI(): void {
    // Hide multi-select related UI elements
  }

  // Update multi-select UI
  private updateMultiSelectUI(): void {
    // Update multi-select UI state
  }

  // Update selected cities display
  private updateSelectedCitiesDisplay(): void {
    // Update display of selected cities in multi-select mode
  }

  // Update city button states
  private updateCityButtonStates(): void {
    // Update visual state of city buttons in multi-select mode
  }

  // Dispatch city-changed event
  private dispatchCityChangedEvent(cityName: string): void {
    const event = new CustomEvent('city-changed', {
      detail: { city: cityName },
      bubbles: true
    })
    this.element.dispatchEvent(event)
  }

  // Dispatch hotel city update event
  private dispatchHotelCityUpdateEvent(cityName: string): void {
    const event = new CustomEvent('hotel:city-updated', {
      detail: { city: cityName },
      bubbles: true
    })
    document.dispatchEvent(event)
  }

  // Dispatch trip planner city change event
  private dispatchTripCityChangeEvent(type: 'departure' | 'destination', cityName: string): void {
    const event = new CustomEvent('trip-planner:city-changed', {
      detail: { type, city: cityName },
      bubbles: true
    })
    document.dispatchEvent(event)
  }

  // Stop event propagation
  stopPropagation(event: Event): void {
    event.stopPropagation()
  }
}
