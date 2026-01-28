import { Controller } from "@hotwired/stimulus"

// Declare Turbo global type
declare const Turbo: any

export default class extends Controller<HTMLElement> {
  static targets = [
    "sortModal",
    "districtModal",
    "starModal",
    "brandModal",
    "sortButton",
    "districtButton",
    "starButton",
    "brandButton"
  ]
  
  static values = {
    city: String,
    query: String,
    sort: { type: String, default: "" },
    district: { type: String, default: "" },
    starLevel: { type: String, default: "" },
    brand: { type: String, default: "" }
  }

  declare readonly sortModalTarget: HTMLElement
  declare readonly districtModalTarget: HTMLElement
  declare readonly starModalTarget: HTMLElement
  declare readonly brandModalTarget: HTMLElement
  declare readonly sortButtonTarget: HTMLElement
  declare readonly districtButtonTarget: HTMLElement
  declare readonly starButtonTarget: HTMLElement
  declare readonly brandButtonTarget: HTMLElement
  
  declare readonly hasSortModalTarget: boolean
  declare readonly hasDistrictModalTarget: boolean
  declare readonly hasStarModalTarget: boolean
  declare readonly hasBrandModalTarget: boolean
  
  declare cityValue: string
  declare queryValue: string
  declare sortValue: string
  declare districtValue: string
  declare starLevelValue: string
  declare brandValue: string

  connect(): void {
    // Initialize controller
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

  openStarModal(): void {
    if (this.hasStarModalTarget) {
      this.closeAllModals()
      this.starModalTarget.classList.remove('hidden')
    }
  }

  openBrandModal(): void {
    if (this.hasBrandModalTarget) {
      this.closeAllModals()
      this.brandModalTarget.classList.remove('hidden')
    }
  }

  // Close all modals
  closeAllModals(): void {
    if (this.hasSortModalTarget) this.sortModalTarget.classList.add('hidden')
    if (this.hasDistrictModalTarget) this.districtModalTarget.classList.add('hidden')
    if (this.hasStarModalTarget) this.starModalTarget.classList.add('hidden')
    if (this.hasBrandModalTarget) this.brandModalTarget.classList.add('hidden')
  }

  // Select sort option
  selectSort(event: Event): void {
    const target = event.currentTarget as HTMLElement
    const sortValue = target.dataset.value || ''
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

  // Select star level option
  selectStarLevel(event: Event): void {
    const target = event.currentTarget as HTMLElement
    const starValue = target.dataset.value || ''
    this.starLevelValue = starValue
    this.closeAllModals()
    this.applyFilters()
  }

  // Select brand option
  selectBrand(event: Event): void {
    const target = event.currentTarget as HTMLElement
    const brandValue = target.dataset.value || ''
    this.brandValue = brandValue
    this.closeAllModals()
    this.applyFilters()
  }

  // Apply all filters
  applyFilters(): void {
    const url = new URL('/hotel_packages/search', window.location.origin)
    
    // Add city and query
    url.searchParams.set('city', this.cityValue || '武汉')
    
    if (this.queryValue) {
      url.searchParams.set('q', this.queryValue)
    }
    
    // Add filter parameters
    if (this.sortValue) {
      url.searchParams.set('sort_by', this.sortValue)
    }
    
    if (this.districtValue) {
      url.searchParams.set('district', this.districtValue)
    }
    
    if (this.starLevelValue) {
      url.searchParams.set('star_level', this.starLevelValue)
    }
    
    if (this.brandValue) {
      url.searchParams.set('brand', this.brandValue)
    }
    
    this.closeAllModals()
    Turbo.visit(url.toString())
  }

  // Stop event propagation
  stopPropagation(event: Event): void {
    event.stopPropagation()
  }
}
