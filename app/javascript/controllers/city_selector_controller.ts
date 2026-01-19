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
          Turbo.visit(url.toString())
          return
        }
        
        // Dispatch city-changed event for tour-group-filter and hotel-services-search to listen
        this.dispatchCityChangedEvent(cityName)
        
        // Dispatch hotel-specific event for hotel-search controller
        this.dispatchHotelCityUpdateEvent(cityName, isInternational)
        
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
  private dispatchHotelCityUpdateEvent(cityName: string, isInternational: boolean = false): void {
    const hotelCityEvent = new CustomEvent('city-selector:city-selected-for-hotel', {
      detail: { 
        cityName,
        isInternational 
      },
      bubbles: true
    })
    document.dispatchEvent(hotelCityEvent)
    console.log('City selector: Dispatched hotel city update event', { cityName, isInternational })
  }

  // Switch cities
  switchCities(): void {
    const temp = this.departureCityValue
    this.departureCityValue = this.destinationCityValue
    this.destinationCityValue = temp

    // Dispatch a custom event to notify other controllers
    this.element.dispatchEvent(new CustomEvent('cities-switched', {
      detail: {
        departure: this.departureCityValue,
        destination: this.destinationCityValue
      },
      bubbles: true
    }))
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

  // Request location
  requestLocation(): void {
    if (!this.hasLocationButtonTarget || !this.hasLocationTextTarget || !this.hasLocationSpinnerTarget) return
    
    // Show loading state
    this.locationTextTarget.textContent = '定位中...'
    this.locationSpinnerTarget.classList.remove('hidden')
    this.locationButtonTarget.disabled = true
    
    // Update status text
    if (this.hasLocationStatusTarget) {
      const statusSpan = this.locationStatusTarget.querySelector('span')
      if (statusSpan) statusSpan.textContent = '正在获取位置信息...'
    }
    
    // Directly use IP-based geolocation (most reliable for China)
    this.getCityFromIP()
  }
  
  // Get city from IP address using ipapi.co (free, no key needed)
  private getCityFromIP(): void {
    // Try ipapi.co first (supports Chinese cities)
    fetch('https://ipapi.co/json/')
      .then(response => {
        if (!response.ok) throw new Error('ipapi.co failed')
        return response.json()
      })
      .then(data => {
        console.log('Location data:', data)
        let cityName = ''
        
        // Try to get Chinese city name or use English name
        if (data.city) {
          cityName = data.city
          // Map common English city names to Chinese
          const cityMap: {[key: string]: string} = {
            'Beijing': '北京',
            'Shanghai': '上海',
            'Guangzhou': '广州',
            'Shenzhen': '深圳',
            'Chengdu': '成都',
            'Hangzhou': '杭州',
            'Wuhan': '武汉',
            'Chongqing': '重庆',
            'Nanjing': '南京',
            'Xi\'an': '西安',
            'Tianjin': '天津',
            'Suzhou': '苏州',
            'Changsha': '长沙',
            'Zhengzhou': '郑州',
            'Harbin': '哈尔滨',
            'Qingdao': '青岛',
            'Kunming': '昆明',
            'Xiamen': '厦门',
            'Dalian': '大连'
          }
          
          if (cityMap[data.city]) {
            cityName = cityMap[data.city]
          }
          
          // Remove 'Shi' or 'City' suffix
          cityName = cityName.replace(/\s+Shi$/, '').replace(/\s+City$/, '').replace('市', '')
          
          this.handleLocationSuccess(cityName)
        } else {
          // Fallback to alternative service
          this.getCityFromIPFallback()
        }
      })
      .catch(error => {
        console.error('IP location error:', error)
        // Try fallback service
        this.getCityFromIPFallback()
      })
  }
  
  // Fallback: Use ip-api.com (free, no key, better for China)
  private getCityFromIPFallback(): void {
    fetch('http://ip-api.com/json/?lang=zh-CN')
      .then(response => response.json())
      .then(data => {
        console.log('Fallback location data:', data)
        if (data.status === 'success' && data.city) {
          const cityName = data.city.replace('市', '')
          this.handleLocationSuccess(cityName)
        } else {
          // Last resort: detect from browser language/timezone
          this.handleLocationError('无法自动定位，请手动选择城市')
        }
      })
      .catch(error => {
        console.error('Fallback IP location error:', error)
        this.handleLocationError('定位服务暂时不可用，请手动选择城市')
      })
  }

  // Handle location success
  private handleLocationSuccess(cityName: string): void {
    if (!this.hasLocationTextTarget || !this.hasLocationSpinnerTarget || 
        !this.hasLocationButtonTarget || !this.hasLocatedCityTarget || 
        !this.hasLocatedCityButtonTarget) return
    
    this.locationTextTarget.textContent = '重新定位'
    this.locationSpinnerTarget.classList.add('hidden')
    this.locationButtonTarget.disabled = false
    
    // Update status text
    if (this.hasLocationStatusTarget) {
      const statusSpan = this.locationStatusTarget.querySelector('span')
      if (statusSpan) statusSpan.textContent = `定位成功：${cityName}`
    }
    
    // Show located city
    this.locatedCityTarget.classList.remove('hidden')
    this.locatedCityButtonTarget.textContent = cityName
    this.locatedCityButtonTarget.dataset.cityName = cityName
  }

  // Handle location error
  private handleLocationError(errorMessage?: string): void {
    if (!this.hasLocationTextTarget || !this.hasLocationSpinnerTarget || !this.hasLocationButtonTarget) return
    
    this.locationTextTarget.textContent = '重试定位'
    this.locationSpinnerTarget.classList.add('hidden')
    this.locationButtonTarget.disabled = false
    
    // Update status text
    if (this.hasLocationStatusTarget) {
      const statusSpan = this.locationStatusTarget.querySelector('span')
      if (statusSpan) statusSpan.textContent = errorMessage || '定位失败，请重试或手动选择城市'
    }
    
    setTimeout(() => {
      if (this.hasLocationTextTarget) {
        this.locationTextTarget.textContent = '开启定位权限'
      }
    }, 3000)
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

  switchToSingleSelect(): void {
    this.isMultiSelectMode = false
    this.selectedCities = []
    this.updateMultiSelectUI()
  }

  switchToMultiSelect(): void {
    this.isMultiSelectMode = true
    this.updateMultiSelectUI()
  }

  confirmMultiSelect(): void {
    // Confirm multi-select and close modal
    if (this.selectedCities.length > 0) {
      // Trigger event with selected cities
      const event = new CustomEvent('city-selector:multi-cities-selected', {
        detail: { cities: this.selectedCities },
        bubbles: true
      })
      document.dispatchEvent(event)
    }
    this.closeModal()
  }

  showDomestic(): void {
    if (this.hasTabDomesticTarget && this.hasTabInternationalTarget) {
      this.tabDomesticTarget.classList.add('border-blue-500')
      this.tabDomesticTarget.classList.remove('border-transparent')
      this.tabInternationalTarget.classList.remove('border-blue-500')
      this.tabInternationalTarget.classList.add('border-transparent')
    }
    if (this.hasDomesticListTarget) {
      this.domesticListTarget.classList.remove('hidden')
    }
    if (this.hasInternationalListTarget) {
      this.internationalListTarget.classList.add('hidden')
    }
    this.currentRegionType = 'domestic'
  }

  showInternational(): void {
    if (this.hasTabInternationalTarget && this.hasTabDomesticTarget) {
      this.tabInternationalTarget.classList.add('border-blue-500')
      this.tabInternationalTarget.classList.remove('border-transparent')
      this.tabDomesticTarget.classList.remove('border-blue-500')
      this.tabDomesticTarget.classList.add('border-transparent')
    }
    if (this.hasInternationalListTarget) {
      this.internationalListTarget.classList.remove('hidden')
    }
    if (this.hasDomesticListTarget) {
      this.domesticListTarget.classList.add('hidden')
    }
    this.currentRegionType = 'international'
  }

  jumpToLetter(event: Event): void {
    const button = event.currentTarget as HTMLElement
    const letter = button.dataset.letter
    if (letter) {
      const targetElement = this.element.querySelector(`[data-letter-section="${letter}"]`)
      if (targetElement) {
        targetElement.scrollIntoView({ behavior: 'smooth', block: 'start' })
      }
    }
  }

  scrollToRegion(event: Event): void {
    const button = event.currentTarget as HTMLElement
    const region = button.dataset.region
    if (region) {
      const targetElement = this.element.querySelector(`[data-region-section="${region}"]`)
      if (targetElement) {
        targetElement.scrollIntoView({ behavior: 'smooth', block: 'start' })
      }
    }
  }

  expandHotCities(): void {
    const hotCitiesSection = this.element.querySelector('[data-hot-cities]')
    if (hotCitiesSection) {
      hotCitiesSection.classList.toggle('expanded')
    }
  }

  search(): void {
    this.searchCities()
  }
}
