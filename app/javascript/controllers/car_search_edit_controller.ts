import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["cityDisplay"]

  declare readonly cityDisplayTarget: HTMLElement

  connect(): void {
    console.log("CarSearchEdit connected")
    
    // Sync current city value from URL params after a brief delay
    // to ensure location-selector controller is initialized
    setTimeout(() => {
      this.syncCityFromURL()
    }, 100)
    
    // Listen for location selection
    document.addEventListener('location-selector:location-selected', this.handleLocationSelected.bind(this))
  }

  disconnect(): void {
    document.removeEventListener('location-selector:location-selected', this.handleLocationSelected.bind(this))
  }

  // Sync city from URL parameters to location-selector
  private syncCityFromURL(): void {
    const params = new URLSearchParams(window.location.search)
    const city = params.get('city')
    
    if (city) {
      // Update location-selector's currentCityValue
      const element = document.querySelector('[data-controller*="location-selector"]')
      if (!element) {
        console.warn('[CarSearchEdit] location-selector element not found')
        return
      }
      
      const locationSelectorController = this.application.getControllerForElementAndIdentifier(
        element,
        'location-selector'
      ) as any
      
      if (locationSelectorController) {
        locationSelectorController.currentCityValue = city
        console.log('[CarSearchEdit] Synced city to location-selector:', city)
      } else {
        console.warn('[CarSearchEdit] location-selector controller not initialized yet')
      }
    }
  }

  // Open location editor (reuse location selector modal from homepage)
  openLocationEditor(): void {
    console.log('[CarSearchEdit] Opening location editor')
    
    // Ensure city is synced before opening modal
    this.syncCityFromURL()
    
    // Get location-selector controller and open modal
    const element = document.querySelector('[data-controller*="location-selector"]')
    if (!element) {
      console.error('[CarSearchEdit] location-selector element not found in DOM')
      return
    }
    
    const locationSelectorController = this.application.getControllerForElementAndIdentifier(
      element,
      'location-selector'
    ) as any
    
    if (locationSelectorController && locationSelectorController.openModal) {
      console.log('[CarSearchEdit] Opening modal...')
      locationSelectorController.openModal()
    } else {
      console.error('[CarSearchEdit] location-selector controller or openModal method not found')
    }
  }

  // Handle location selection
  private handleLocationSelected(event: Event): void {
    const customEvent = event as CustomEvent
    const { locationName } = customEvent.detail
    
    console.log('[CarSearchEdit] Location selected:', locationName)
    
    // Get current URL parameters
    const params = new URLSearchParams(window.location.search)
    
    // Update pickup_location parameter
    params.set('pickup_location', locationName)
    
    // Redirect to search page with updated parameters
    const newUrl = `${window.location.pathname}?${params.toString()}`
    console.log('[CarSearchEdit] Redirecting to:', newUrl)
    window.location.href = newUrl
  }
}
