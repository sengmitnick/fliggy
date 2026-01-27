import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = [
    "modal",
    "searchInput",
    "locationList",
    "locationInput",
    "locationDisplay"
  ]

  static values = {
    locationType: String, // "from" or "to"
    currentCity: String, // current selected city
    arrivalCity: String, // arrival city from flight (for transfers)
    apiEndpoint: { type: String, default: "/cars/locations" }, // API endpoint for locations
  }

  declare readonly modalTarget: HTMLElement
  declare readonly searchInputTarget: HTMLInputElement
  declare readonly locationListTarget: HTMLElement
  declare readonly locationInputTarget: HTMLInputElement
  declare readonly locationDisplayTarget: HTMLElement
  declare readonly hasLocationInputTarget: boolean
  declare readonly hasLocationDisplayTarget: boolean
  declare readonly locationTypeValue: string
  declare currentCityValue: string
  declare readonly arrivalCityValue: string
  declare readonly hasArrivalCityValue: boolean
  declare readonly apiEndpointValue: string

  private selectedLocation: { name: string; address: string } | null = null

  connect(): void {
    console.log("LocationSelector connected")
    // Get initial city from the page
    this.initializeCurrentCity()
    // Listen for city changes
    document.addEventListener('city-selector:city-selected', this.handleCityChange.bind(this))
  }

  disconnect(): void {
    console.log("LocationSelector disconnected")
    document.removeEventListener('city-selector:city-selected', this.handleCityChange.bind(this))
  }

  // Initialize current city from the page
  private initializeCurrentCity(): void {
    // For transfers page: use arrival city from flight data
    if (this.hasArrivalCityValue && this.arrivalCityValue) {
      this.currentCityValue = this.arrivalCityValue
      console.log('LocationSelector: Using arrival city from flight:', this.currentCityValue)
      return
    }
    
    // For car rental page: try to get city from car-rental-tabs city display
    const cityDisplay = document.querySelector('[data-car-rental-tabs-target="cityDisplay"]')
    if (cityDisplay && cityDisplay.textContent) {
      this.currentCityValue = cityDisplay.textContent.trim()
      console.log('LocationSelector: Initial city from DOM:', this.currentCityValue)
    } else {
      this.currentCityValue = '深圳' // fallback to Shenzhen
      console.log('LocationSelector: Using fallback city:', this.currentCityValue)
    }
  }

  // Handle city change event
  private handleCityChange(event: Event): void {
    const customEvent = event as CustomEvent
    const { cityName } = customEvent.detail
    console.log('LocationSelector: City changed to', cityName)
    this.currentCityValue = cityName
    // Reload locations when modal is opened
  }

  openModal(): void {
    console.log('[LocationSelector] ========== openModal START ===========')
    
    // For transfers page: use arrival city from flight data (already set in initializeCurrentCity)
    if (this.hasArrivalCityValue && this.arrivalCityValue) {
      console.log('[LocationSelector] Using arrival city for transfers:', this.arrivalCityValue)
      this.currentCityValue = this.arrivalCityValue
    } else {
      // For car rental page: sync with DOM to ensure we have the current city
      // Check if we're selecting return location (异地还车)
      const carRentalController = this.application.getControllerForElementAndIdentifier(
        document.querySelector('[data-controller*="car-rental-tabs"]') as Element,
        'car-rental-tabs'
      ) as any
      
      let cityToUse = ''
      if (carRentalController) {
        const selectionType = (carRentalController as any).currentSelectionType
        console.log('[LocationSelector] Selection type:', selectionType)
        
        if (selectionType === 'return') {
          // Use return city for return location selection
          const returnCityDisplay = document.querySelector('[data-car-rental-tabs-target="returnCityDisplay"]')
          if (returnCityDisplay && returnCityDisplay.textContent) {
            cityToUse = returnCityDisplay.textContent.trim()
            console.log('[LocationSelector] Using return city:', cityToUse)
          }
        }
      }
      
      // If no return city specified, use pickup city
      if (!cityToUse) {
        const cityDisplay = document.querySelector('[data-car-rental-tabs-target="cityDisplay"]')
        if (cityDisplay && cityDisplay.textContent) {
          cityToUse = cityDisplay.textContent.trim()
          console.log('[LocationSelector] Using pickup city:', cityToUse)
        }
      }
      
      // Clean the city name
      if (cityToUse) {
        // Trim first, then remove zero-width characters and normalize consecutive spaces
        cityToUse = cityToUse.replace(/[\u200B-\u200D\uFEFF]/g, '') // Remove zero-width spaces
        cityToUse = cityToUse.replace(/\s+/g, '') // Remove all spaces (Chinese city names don't have spaces)
        console.log('[LocationSelector] DOM city cleaned:', JSON.stringify(cityToUse))
        console.log('[LocationSelector] DOM city bytes:', Array.from(cityToUse).map(c => c.charCodeAt(0)))
        console.log('[LocationSelector] Current city value before:', JSON.stringify(this.currentCityValue))
        console.log('[LocationSelector] Match check:', this.currentCityValue === cityToUse)
        if (this.currentCityValue !== cityToUse) {
          console.log('[LocationSelector] Syncing city from DOM:', this.currentCityValue, '->', cityToUse)
          this.currentCityValue = cityToUse
        }
      }
    }
    
    console.log('[LocationSelector] currentCityValue after sync:', JSON.stringify(this.currentCityValue))
    console.log('[LocationSelector] currentCityValue bytes:', Array.from(this.currentCityValue || '').map(c => c.charCodeAt(0)))
    
    // Clear previous content immediately
    this.locationListTarget.innerHTML = '<div class="text-center py-8 text-text-muted">加载中...</div>'
    
    this.modalTarget.classList.remove("hidden")
    this.searchInputTarget.value = ""
    this.searchInputTarget.focus()
    document.body.style.overflow = "hidden"
    
    console.log('[LocationSelector] About to call loadLocations() with city:', this.currentCityValue)
    // Load locations for current city
    this.loadLocations()
    console.log('[LocationSelector] loadLocations() triggered')
    console.log('[LocationSelector] ========== openModal END ===========')
  }

  closeModal(): void {
    this.modalTarget.classList.add("hidden")
    document.body.style.overflow = ""
  }

  stopPropagation(event: Event): void {
    event.stopPropagation()
  }

  selectLocation(event: Event): void {
    const button = event.currentTarget as HTMLElement
    const name = button.dataset.locationName || ""
    const address = button.dataset.locationAddress || ""
    
    this.selectedLocation = { name, address }

    // Update UI to show selected state
    this.locationListTarget.querySelectorAll("button").forEach(btn => {
      btn.classList.remove("bg-primary-light", "border-primary")
    })
    button.classList.add("bg-primary-light", "border", "border-primary")
  }

  confirm(): void {
    if (!this.selectedLocation) {
      return
    }

    // Update hidden input field if exists
    if (this.hasLocationInputTarget) {
      this.locationInputTarget.value = this.selectedLocation.name
    }

    // Update display element if exists
    if (this.hasLocationDisplayTarget) {
      this.locationDisplayTarget.textContent = this.selectedLocation.name
      this.locationDisplayTarget.classList.remove("text-text-muted")
      this.locationDisplayTarget.classList.add("text-text-primary")
    }

    // Dispatch event for other controllers (e.g. car-rental-tabs)
    const event = new CustomEvent('location-selector:location-selected', {
      detail: {
        locationName: this.selectedLocation.name,
        locationAddress: this.selectedLocation.address
      },
      bubbles: true
    })
    document.dispatchEvent(event)

    this.closeModal()
  }

  search(event: Event): void {
    const input = event.target as HTMLInputElement
    const query = input.value.toLowerCase().trim()

    const buttons = this.locationListTarget.querySelectorAll("button[data-location-name]")
    
    buttons.forEach(button => {
      const element = button as HTMLElement
      const name = element.dataset.locationName?.toLowerCase() || ""
      const address = element.dataset.locationAddress?.toLowerCase() || ""
      
      if (name.includes(query) || address.includes(query)) {
        element.classList.remove("hidden")
      } else {
        element.classList.add("hidden")
      }
    })
  }

  private async loadLocations(): Promise<void> {
    const city = this.currentCityValue || '深圳'
    console.log('[LocationSelector] ========== loadLocations START ===========')
    console.log('[LocationSelector] Loading locations for city:', city)
    
    try {
      const url = `${this.apiEndpointValue}?city=${encodeURIComponent(city)}`
      console.log('[LocationSelector] Fetching from URL:', url)
      const response = await fetch(url)
      console.log('[LocationSelector] Response received - status:', response.status, 'ok:', response.ok)
      
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }
      
      const data = await response.json()
      console.log('[LocationSelector] ========== API RESPONSE ===========')
      console.log('[LocationSelector] Full response data:', JSON.stringify(data, null, 2))
      console.log('[LocationSelector] City from response:', data.city)
      console.log('[LocationSelector] Airports count:', data.locations?.airports?.length || 0)
      console.log('[LocationSelector] Train stations count:', data.locations?.train_stations?.length || 0)
      console.log('[LocationSelector] Others count:', data.locations?.others?.length || 0)
      console.log('[LocationSelector] =====================================')
      
      this.renderLocations(data.locations)
      console.log('[LocationSelector] renderLocations completed')
    } catch (error) {
      console.error('[LocationSelector] ========== ERROR ===========')
      console.error('[LocationSelector] Failed to load locations:', error)
      if (error instanceof Error) {
        console.error('[LocationSelector] Error details:', error.message)
      }
      console.error('[LocationSelector] =============================')
      // Fallback to default locations
      this.renderDefaultLocations()
    }
    console.log('[LocationSelector] ========== loadLocations END ===========')
  }

  private renderLocations(locations: { airports: string[], train_stations: string[], others: string[] }): void {
    console.log('[LocationSelector] renderLocations START')
    console.log('[LocationSelector] Airports:', locations.airports)
    console.log('[LocationSelector] Train stations:', locations.train_stations)
    console.log('[LocationSelector] Others:', locations.others)
    let html = ''

    // Airports
    if (locations.airports && locations.airports.length > 0) {
      html += `
        <div class="mb-4">
          <h4 class="text-xs text-text-muted mb-2">机场</h4>
          <div class="grid grid-cols-2 gap-2">
            ${locations.airports.map(airport => `
              <button
                type="button"
                data-action="click->location-selector#selectLocation"
                data-location-name="${airport}"
                data-location-address="机场"
                class="w-full text-center p-2 rounded-lg hover:bg-surface-hover transition-colors text-sm">
                ${airport}
              </button>
            `).join('')}
          </div>
        </div>
      `
    }

    // Train Stations
    if (locations.train_stations && locations.train_stations.length > 0) {
      html += `
        <div class="mb-4">
          <h4 class="text-xs text-text-muted mb-2">火车站</h4>
          <div class="grid grid-cols-3 gap-2">
            ${locations.train_stations.map(station => `
              <button
                type="button"
                data-action="click->location-selector#selectLocation"
                data-location-name="${station}"
                data-location-address="火车站"
                class="w-full text-center p-2 rounded-lg hover:bg-surface-hover transition-colors text-xs">
                ${station}
              </button>
            `).join('')}
          </div>
        </div>
      `
    }

    // Others
    if (locations.others && locations.others.length > 0) {
      html += `
        <div class="mb-4">
          <h4 class="text-xs text-text-muted mb-2">其他地点</h4>
          <div class="space-y-2">
            ${locations.others.map(location => `
              <button
                type="button"
                data-action="click->location-selector#selectLocation"
                data-location-name="${location}"
                data-location-address="接送点"
                class="w-full text-left p-3 rounded-lg hover:bg-surface-hover transition-colors">
                <div class="flex items-start">
                  <svg class="w-5 h-5 text-text-muted mt-0.5 mr-3 flex-shrink-0" fill="currentColor" viewBox="0 0 20 20">
                    <path fill-rule="evenodd" d="M5.05 4.05a7 7 0 119.9 9.9L10 18.9l-4.95-4.95a7 7 0 010-9.9zM10 11a2 2 0 100-4 2 2 0 000 4z" clip-rule="evenodd"/>
                  </svg>
                  <div class="flex-1">
                    <div class="text-text-primary font-medium">${location}</div>
                    <div class="text-xs text-text-muted mt-0.5">接送点</div>
                  </div>
                </div>
              </button>
            `).join('')}
          </div>
        </div>
      `
    }

    // If no locations found
    if (!html) {
      console.log('[LocationSelector] No locations found, showing fallback message')
      html = `
        <div class="text-center py-8 text-text-muted">
          <p>该城市暂无接送点</p>
        </div>
      `
    }

    console.log('[LocationSelector] Setting innerHTML, html length:', html.length)
    this.locationListTarget.innerHTML = html
    console.log('[LocationSelector] innerHTML set successfully')
  }

  private renderDefaultLocations(): void {
    // Fallback for武汉
    this.renderLocations({
      airports: ['天河国际机场T3'],
      train_stations: ['武汉站', '武昌站', '汉口站'],
      others: []
    })
  }
}
