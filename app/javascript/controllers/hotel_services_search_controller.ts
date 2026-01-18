import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = ["cityInput", "checkInInput", "checkOutInput"]

  declare readonly cityInputTarget: HTMLInputElement
  declare readonly checkInInputTarget: HTMLInputElement
  declare readonly checkOutInputTarget: HTMLInputElement

  connect(): void {
    console.log("HotelServicesSearch connected")
    
    // Listen for city selection changes
    document.addEventListener('city-selector:city-changed', this.handleCityChange.bind(this))
    
    // Listen for date selection changes
    document.addEventListener('hotel-date-picker:dates-selected', this.handleDateChange.bind(this))
  }

  disconnect(): void {
    document.removeEventListener('city-selector:city-changed', this.handleCityChange.bind(this))
    document.removeEventListener('hotel-date-picker:dates-selected', this.handleDateChange.bind(this))
  }

  private handleCityChange(event: Event): void {
    const customEvent = event as CustomEvent
    const cityName = customEvent.detail.cityName
    console.log('HotelServicesSearch: City changed to', cityName)
    
    // Update hidden input
    this.cityInputTarget.value = cityName
    
    // Update URL and reload page
    this.updateURLAndReload()
  }

  private handleDateChange(event: Event): void {
    const customEvent = event as CustomEvent
    const { checkIn, checkOut } = customEvent.detail
    console.log('HotelServicesSearch: Dates changed', { checkIn, checkOut })
    
    // Update hidden inputs
    this.checkInInputTarget.value = checkIn
    this.checkOutInputTarget.value = checkOut
    
    // Update URL and reload page
    this.updateURLAndReload()
  }

  private updateURLAndReload(): void {
    const params = new URLSearchParams(window.location.search)
    
    // Update or remove city parameter
    if (this.cityInputTarget.value) {
      params.set('city', this.cityInputTarget.value)
    } else {
      params.delete('city')
    }
    
    // Update or remove date parameters
    // If dates are empty strings (after reset), remove them from URL
    if (this.checkInInputTarget.value) {
      params.set('check_in', this.checkInInputTarget.value)
    } else {
      params.delete('check_in')
    }
    
    if (this.checkOutInputTarget.value) {
      params.set('check_out', this.checkOutInputTarget.value)
    } else {
      params.delete('check_out')
    }
    
    // Reload page with updated parameters
    window.location.href = `${window.location.pathname}?${params.toString()}`
  }
}
