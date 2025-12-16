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
    "searchInput",
    // stimulus-validator: disable-next-line
    "domesticList",
    // stimulus-validator: disable-next-line
    "internationalList",
    // stimulus-validator: disable-next-line
    "historySection",
    // stimulus-validator: disable-next-line
    "currentCity"
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
  declare readonly searchInputTarget: HTMLInputElement
  // stimulus-validator: disable-next-line
  declare readonly domesticListTarget: HTMLElement
  // stimulus-validator: disable-next-line
  declare readonly internationalListTarget: HTMLElement
  // stimulus-validator: disable-next-line
  declare readonly historySectionTarget: HTMLElement
  // stimulus-validator: disable-next-line
  declare readonly currentCityTarget: HTMLElement
  declare departureCityValue: string
  declare destinationCityValue: string

  connect(): void {
    console.log("CitySelector connected")
    // Initialize default values
    if (!this.departureCityValue) this.departureCityValue = "北京"
    if (!this.destinationCityValue) this.destinationCityValue = "杭州"
    
    // Set initial values to hidden inputs
    this.departureCityInputTarget.value = this.departureCityValue
    this.destinationCityInputTarget.value = this.destinationCityValue
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
    
    if (this.selectionType === 'departure') {
      this.departureCityValue = cityName
      this.departureTarget.textContent = cityName
      this.departureCityInputTarget.value = cityName
    } else {
      this.destinationCityValue = cityName
      this.destinationTarget.textContent = cityName
      this.destinationCityInputTarget.value = cityName
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
    this.internationalListTarget.classList.add('hidden')
    this.tabDepartureTarget.classList.add('active-tab')
    this.tabDestinationTarget.classList.remove('active-tab')
  }

  showInternational(): void {
    this.domesticListTarget.classList.add('hidden')
    this.internationalListTarget.classList.remove('hidden')
    this.tabDepartureTarget.classList.remove('active-tab')
    this.tabDestinationTarget.classList.add('active-tab')
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
}
