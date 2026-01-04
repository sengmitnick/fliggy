import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = [
    "destinationCitiesDisplay",
    "destinationCitiesInput",
    "cityModal",
    "cityList",
    "selectedCitiesContainer",
    "searchInput"
  ]

  static values = {
    departureCityValue: String,
    destinationCities: Array
  }

  declare readonly destinationCitiesDisplayTarget: HTMLElement
  declare readonly destinationCitiesInputTarget: HTMLInputElement
  declare readonly cityModalTarget: HTMLElement
  declare readonly cityListTarget: HTMLElement
  declare readonly selectedCitiesContainerTarget: HTMLElement
  declare readonly searchInputTarget: HTMLInputElement
  declare destinationCitiesValue: string[]

  private selectedCities: Set<string> = new Set()

  connect(): void {
    console.log("SpecialFlights controller connected")
    
    // Initialize selected cities from value
    if (this.destinationCitiesValue && Array.isArray(this.destinationCitiesValue)) {
      this.selectedCities = new Set(this.destinationCitiesValue)
    }
    
    this.updateDisplay()
  }

  // Open city selector modal for multi-select
  openCitySelector(): void {
    this.cityModalTarget.classList.remove('hidden')
    document.body.style.overflow = 'hidden'
  }

  // Close city selector modal
  closeCityModal(): void {
    this.cityModalTarget.classList.add('hidden')
    document.body.style.overflow = ''
    this.clearSearch()
  }

  // Toggle city selection (multi-select)
  toggleCity(event: Event): void {
    const button = event.currentTarget as HTMLElement
    const cityName = button.dataset.cityName || ''
    
    if (this.selectedCities.has(cityName)) {
      this.selectedCities.delete(cityName)
      button.classList.remove('bg-primary', 'text-white')
      button.classList.add('bg-gray-100', 'text-gray-700')
    } else {
      this.selectedCities.add(cityName)
      button.classList.remove('bg-gray-100', 'text-gray-700')
      button.classList.add('bg-primary', 'text-white')
    }
    
    this.updateSelectedCitiesDisplay()
  }

  // Confirm city selection
  confirmCitySelection(): void {
    if (this.selectedCities.size === 0) {
      window.showToast('请至少选择一个目的地')
      return
    }
    
    this.updateDisplay()
    this.destinationCitiesInputTarget.value = Array.from(this.selectedCities).join(',')
    this.closeCityModal()
  }

  // Update display of selected cities in main view
  private updateDisplay(): void {
    const citiesArray = Array.from(this.selectedCities)
    
    if (citiesArray.length === 0) {
      this.destinationCitiesDisplayTarget.textContent = '选择目的地'
      return
    }
    
    // Display cities with comma separation or show count if too many
    if (citiesArray.length <= 2) {
      this.destinationCitiesDisplayTarget.textContent = citiesArray.join(',')
    } else {
      this.destinationCitiesDisplayTarget.textContent = `${citiesArray[0]},${citiesArray[1]}等${citiesArray.length}地`
    }
  }

  // Update selected cities display in modal
  private updateSelectedCitiesDisplay(): void {
    const citiesArray = Array.from(this.selectedCities)
    
    if (citiesArray.length === 0) {
      this.selectedCitiesContainerTarget.innerHTML = '<span class="text-gray-500">未选择目的地</span>'
      return
    }
    
    // Create badge-style display for each selected city
    const badges = citiesArray.map(city => `
      <span class="inline-flex items-center gap-1 px-3 py-1 bg-primary text-white rounded-full text-sm">
        ${city}
        <button type="button" 
                data-action="click->special-flights#removeCity" 
                data-city-name="${city}"
                class="hover:bg-white hover:bg-opacity-20 rounded-full p-0.5">
          <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
          </svg>
        </button>
      </span>
    `).join('')
    
    this.selectedCitiesContainerTarget.innerHTML = badges
  }

  // Remove a city from selection
  removeCity(event: Event): void {
    const button = event.currentTarget as HTMLElement
    const cityName = button.dataset.cityName || ''
    
    this.selectedCities.delete(cityName)
    
    // Update button state in city list
    const cityButton = this.cityListTarget.querySelector(`[data-city-name="${cityName}"]`)
    if (cityButton) {
      cityButton.classList.remove('bg-primary', 'text-white')
      cityButton.classList.add('bg-gray-100', 'text-gray-700')
    }
    
    this.updateSelectedCitiesDisplay()
  }

  // Clear all selected cities
  clearAllCities(): void {
    this.selectedCities.clear()
    
    // Reset all city buttons
    const allButtons = this.cityListTarget.querySelectorAll('[data-city-name]')
    allButtons.forEach(button => {
      button.classList.remove('bg-primary', 'text-white')
      button.classList.add('bg-gray-100', 'text-gray-700')
    })
    
    this.updateSelectedCitiesDisplay()
  }

  // Search cities
  search(): void {
    const query = this.searchInputTarget.value.toLowerCase().trim()
    
    const cityButtons = this.cityListTarget.querySelectorAll('[data-city-name]')
    cityButtons.forEach((button) => {
      const cityName = (button as HTMLElement).dataset.cityName?.toLowerCase() || ''
      const cityPinyin = (button as HTMLElement).dataset.cityPinyin?.toLowerCase() || ''
      
      if (query === '' || cityName.includes(query) || cityPinyin.includes(query)) {
        (button as HTMLElement).classList.remove('hidden')
      } else {
        (button as HTMLElement).classList.add('hidden')
      }
    })
  }

  // Clear search
  clearSearch(): void {
    if (this.searchInputTarget) {
      this.searchInputTarget.value = ''
      
      // Show all cities
      const allButtons = this.cityListTarget.querySelectorAll('[data-city-name]')
      allButtons.forEach((button) => {
        (button as HTMLElement).classList.remove('hidden')
      })
    }
  }
}
