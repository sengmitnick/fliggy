import { Controller } from "@hotwired/stimulus"

// Declare Turbo global type
declare const Turbo: any

export default class extends Controller<HTMLElement> {
  static targets = [
    "sortModal",
    "districtModal", 
    "priceModal",
    "filterModal",
    "sortButton",
    "districtButton",
    "priceButton",
    "filterButton",
    "sortOption",
    "districtOption",
    "priceOption",
    "starOption"
  ]
  
  static values = {
    city: String,
    query: String,
    sort: { type: String, default: "price" },
    district: { type: String, default: "" },
    priceRange: { type: String, default: "" },
    stars: { type: String, default: "" }
  }

  declare readonly sortModalTarget: HTMLElement
  declare readonly districtModalTarget: HTMLElement
  declare readonly priceModalTarget: HTMLElement
  declare readonly filterModalTarget: HTMLElement
  declare readonly sortButtonTarget: HTMLElement
  declare readonly districtButtonTarget: HTMLElement
  declare readonly priceButtonTarget: HTMLElement
  declare readonly filterButtonTarget: HTMLElement
  declare readonly sortOptionTargets: HTMLElement[]
  declare readonly districtOptionTargets: HTMLElement[]
  declare readonly priceOptionTargets: HTMLElement[]
  declare readonly starOptionTargets: HTMLElement[]
  
  declare readonly hasSortModalTarget: boolean
  declare readonly hasDistrictModalTarget: boolean
  declare readonly hasPriceModalTarget: boolean
  declare readonly hasFilterModalTarget: boolean
  
  declare cityValue: string
  declare queryValue: string
  declare sortValue: string
  declare districtValue: string
  declare priceRangeValue: string
  declare starsValue: string

  connect(): void {
    this.updateButtonStates()
  }

  // Open modals
  openSortModal(): void {
    if (this.hasSortModalTarget) {
      this.closeAllModals()
      this.sortModalTarget.classList.remove('hidden')
    }
  }

  openDistrictModal(): void {
    if (this.hasDistrictModalTarget) {
      this.closeAllModals()
      this.districtModalTarget.classList.remove('hidden')
    }
  }

  openPriceModal(): void {
    if (this.hasPriceModalTarget) {
      this.closeAllModals()
      this.priceModalTarget.classList.remove('hidden')
    }
  }

  openFilterModal(): void {
    if (this.hasFilterModalTarget) {
      this.closeAllModals()
      this.filterModalTarget.classList.remove('hidden')
    }
  }

  // Close all modals
  closeAllModals(): void {
    if (this.hasSortModalTarget) this.sortModalTarget.classList.add('hidden')
    if (this.hasDistrictModalTarget) this.districtModalTarget.classList.add('hidden')
    if (this.hasPriceModalTarget) this.priceModalTarget.classList.add('hidden')
    if (this.hasFilterModalTarget) this.filterModalTarget.classList.add('hidden')
  }

  // Select sort option
  selectSort(event: Event): void {
    const target = event.currentTarget as HTMLElement
    const sortValue = target.dataset.value || 'price'
    this.sortValue = sortValue
    this.closeAllModals()
    this.applyFilters()
  }

  // Select district option
  selectDistrict(event: Event): void {
    const target = event.currentTarget as HTMLElement
    const districtValue = target.dataset.value || ''
    this.districtValue = districtValue
    this.closeAllModals()
    this.applyFilters()
  }

  // Select price range option
  selectPriceRange(event: Event): void {
    const target = event.currentTarget as HTMLElement
    const priceValue = target.dataset.value || ''
    this.priceRangeValue = priceValue
    this.closeAllModals()
    this.applyFilters()
  }

  // Toggle star rating
  toggleStar(event: Event): void {
    const target = event.currentTarget as HTMLElement
    const starValue = target.dataset.value || ''
    
    // Toggle the star value
    if (this.starsValue === starValue) {
      this.starsValue = ''
    } else {
      this.starsValue = starValue
    }
    
    this.updateStarStates()
  }

  // Apply all filters
  applyFilters(): void {
    const url = new URL('/special_hotels', window.location.origin)
    url.searchParams.set('city', this.cityValue || '北京市')
    
    if (this.queryValue) {
      url.searchParams.set('query', this.queryValue)
    }
    
    if (this.sortValue && this.sortValue !== 'price') {
      url.searchParams.set('sort', this.sortValue)
    }
    
    if (this.districtValue) {
      url.searchParams.set('district', this.districtValue)
    }
    
    if (this.priceRangeValue) {
      url.searchParams.set('price_range', this.priceRangeValue)
    }
    
    if (this.starsValue) {
      url.searchParams.set('stars', this.starsValue)
    }
    
    this.closeAllModals()
    Turbo.visit(url.toString())
  }

  // Clear all filters
  clearFilters(): void {
    this.sortValue = 'price'
    this.districtValue = ''
    this.priceRangeValue = ''
    this.starsValue = ''
    this.applyFilters()
  }

  // Update button states based on active filters
  private updateButtonStates(): void {
    // Update sort button
    if (this.sortValue !== 'price') {
      this.sortButtonTarget.classList.add('text-primary')
    }
    
    // Update district button
    if (this.districtValue) {
      this.districtButtonTarget.classList.add('text-primary')
    }
    
    // Update price button
    if (this.priceRangeValue) {
      this.priceButtonTarget.classList.add('text-primary')
    }
    
    // Update filter button
    if (this.starsValue) {
      this.filterButtonTarget.classList.add('text-primary')
    }
  }

  // Update star rating visual states
  private updateStarStates(): void {
    this.starOptionTargets.forEach(target => {
      const value = target.dataset.value || ''
      if (value === this.starsValue) {
        target.classList.add('bg-primary', 'text-white')
        target.classList.remove('bg-gray-100', 'text-gray-700')
      } else {
        target.classList.remove('bg-primary', 'text-white')
        target.classList.add('bg-gray-100', 'text-gray-700')
      }
    })
  }

  // Stop event propagation
  stopPropagation(event: Event): void {
    event.stopPropagation()
  }
}
