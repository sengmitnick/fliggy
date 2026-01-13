import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = [
    "searchForm",
    "cityInput",
    "cityDisplay",
    "checkInInput",
    "checkOutInput",
    "roomsInput",
    "adultsInput",
    "childrenInput",
    "queryInput",
    "domesticTab",
    "internationalTab",
    "domesticIndicator",
    "internationalIndicator"
  ]

  declare readonly searchFormTarget: HTMLFormElement
  declare readonly hasCityInputTarget: boolean
  declare readonly cityInputTarget: HTMLInputElement
  declare readonly hasCityDisplayTarget: boolean
  declare readonly cityDisplayTarget: HTMLElement
  declare readonly hasCheckInInputTarget: boolean
  declare readonly checkInInputTarget: HTMLInputElement
  declare readonly hasCheckOutInputTarget: boolean
  declare readonly checkOutInputTarget: HTMLInputElement
  declare readonly hasRoomsInputTarget: boolean
  declare readonly roomsInputTarget: HTMLInputElement
  declare readonly hasAdultsInputTarget: boolean
  declare readonly adultsInputTarget: HTMLInputElement
  declare readonly hasChildrenInputTarget: boolean
  declare readonly childrenInputTarget: HTMLInputElement
  declare readonly hasQueryInputTarget: boolean
  declare readonly queryInputTarget: HTMLInputElement
  declare readonly domesticTabTarget: HTMLElement
  declare readonly internationalTabTarget: HTMLElement
  declare readonly domesticIndicatorTarget: HTMLElement
  declare readonly internationalIndicatorTarget: HTMLElement

  private currentLocationType: 'domestic' | 'international' = 'domestic'
  private lastDomesticCity: string = '北京'
  private lastInternationalCity: string = '香港'

  connect(): void {
    console.log("HomestaySearch connected")
    
    // Initialize: Read current city and store it as domestic city (default state)
    if (this.hasCityInputTarget) {
      const currentCity = this.cityInputTarget.value
      if (currentCity) {
        this.lastDomesticCity = currentCity
        console.log('HomestaySearch: Initialized lastDomesticCity to:', currentCity)
      }
    }
    
    // Listen for city-selector updates
    document.addEventListener('city-selector:city-selected-for-hotel', this.handleCityUpdate.bind(this))
    // Listen for date-picker updates
    document.addEventListener('hotel-date-picker:dates-selected', this.handleDateUpdate.bind(this))
    // Listen for guest-selector updates
    document.addEventListener('hotel-guest-selector:guests-updated', this.handleGuestUpdate.bind(this))
  }

  disconnect(): void {
    console.log("HomestaySearch disconnected")
    document.removeEventListener('city-selector:city-selected-for-hotel', this.handleCityUpdate.bind(this))
    document.removeEventListener('hotel-date-picker:dates-selected', this.handleDateUpdate.bind(this))
    document.removeEventListener('hotel-guest-selector:guests-updated', this.handleGuestUpdate.bind(this))
  }

  // Handle city selection update from city-selector
  handleCityUpdate(event: Event): void {
    const customEvent = event as CustomEvent
    const { cityName, isInternational } = customEvent.detail
    console.log('HomestaySearch: Received city update:', cityName, 'isInternational:', isInternational)
    
    // Remember the city for this location type
    if (isInternational) {
      this.lastInternationalCity = cityName
    } else {
      this.lastDomesticCity = cityName
    }
    
    if (this.hasCityInputTarget) {
      this.cityInputTarget.value = cityName
      console.log('HomestaySearch: Updated city input to:', cityName)
    }

    // Auto-switch tab based on city type
    if (isInternational) {
      this.switchToInternational(false) // false = don't update city
    } else {
      this.switchToDomestic(false) // false = don't update city
    }
  }

  // Handle date selection update from hotel-date-picker
  handleDateUpdate(event: Event): void {
    const customEvent = event as CustomEvent
    const { checkIn, checkOut } = customEvent.detail
    console.log('HomestaySearch: Received date update:', { checkIn, checkOut })
    
    if (this.hasCheckInInputTarget) {
      this.checkInInputTarget.value = checkIn
      console.log('HomestaySearch: Updated check-in to:', checkIn)
    }
    
    if (this.hasCheckOutInputTarget) {
      this.checkOutInputTarget.value = checkOut
      console.log('HomestaySearch: Updated check-out to:', checkOut)
    }
  }

  // Handle guest selection update from hotel-guest-selector
  handleGuestUpdate(event: Event): void {
    const customEvent = event as CustomEvent
    const { rooms, adults, children } = customEvent.detail
    console.log('HomestaySearch: Received guest update:', { rooms, adults, children })
    
    if (this.hasRoomsInputTarget) {
      this.roomsInputTarget.value = rooms.toString()
      console.log('HomestaySearch: Updated rooms to:', rooms)
    }
    
    if (this.hasAdultsInputTarget) {
      this.adultsInputTarget.value = adults.toString()
      console.log('HomestaySearch: Updated adults to:', adults)
    }
    
    if (this.hasChildrenInputTarget) {
      this.childrenInputTarget.value = children.toString()
      console.log('HomestaySearch: Updated children to:', children)
    }
  }

  openSearchModal(): void {
    // Show a prompt for search keyword
    const keyword = prompt('请输入民宿名称、地名或关键词：')
    
    if (keyword !== null && this.hasQueryInputTarget) {
      this.queryInputTarget.value = keyword
      
      // Submit the form
      if (this.searchFormTarget) {
        this.searchFormTarget.requestSubmit()
      }
    }
  }

  // Switch to domestic tab
  switchToDomestic(updateCity: boolean = true): void {
    if (this.currentLocationType === 'domestic') return

    console.log('HomestaySearch: Switching to domestic')
    this.currentLocationType = 'domestic'

    // Update city input to last domestic city when manually switching
    if (updateCity) {
      if (this.hasCityInputTarget) {
        this.cityInputTarget.value = this.lastDomesticCity
        console.log('HomestaySearch: Restored domestic city to:', this.lastDomesticCity)
      }
      if (this.hasCityDisplayTarget) {
        this.cityDisplayTarget.textContent = this.lastDomesticCity
        console.log('HomestaySearch: Updated city display to:', this.lastDomesticCity)
      }
    }

    // Update domestic tab styles
    const domesticSpan = this.domesticTabTarget.querySelector('span')
    if (domesticSpan) {
      domesticSpan.classList.remove('font-medium')
      domesticSpan.classList.add('font-bold')
    }
    this.domesticTabTarget.classList.remove('text-gray-500')
    this.domesticTabTarget.classList.add('text-gray-800')
    this.domesticIndicatorTarget.classList.remove('hidden')

    // Update international tab styles
    const internationalSpan = this.internationalTabTarget.querySelector('span')
    if (internationalSpan) {
      internationalSpan.classList.remove('font-bold')
      internationalSpan.classList.add('font-medium')
    }
    this.internationalTabTarget.classList.remove('text-gray-800')
    this.internationalTabTarget.classList.add('text-gray-500')
    this.internationalIndicatorTarget.classList.add('hidden')
  }

  // Switch to international tab
  switchToInternational(updateCity: boolean = true): void {
    if (this.currentLocationType === 'international') return

    console.log('HomestaySearch: Switching to international')
    this.currentLocationType = 'international'

    // Update city input to last international city when manually switching
    if (updateCity) {
      if (this.hasCityInputTarget) {
        this.cityInputTarget.value = this.lastInternationalCity
        console.log('HomestaySearch: Restored international city to:', this.lastInternationalCity)
      }
      if (this.hasCityDisplayTarget) {
        this.cityDisplayTarget.textContent = this.lastInternationalCity
        console.log('HomestaySearch: Updated city display to:', this.lastInternationalCity)
      }
    }

    // Update international tab styles
    const internationalSpan = this.internationalTabTarget.querySelector('span')
    if (internationalSpan) {
      internationalSpan.classList.remove('font-medium')
      internationalSpan.classList.add('font-bold')
    }
    this.internationalTabTarget.classList.remove('text-gray-500')
    this.internationalTabTarget.classList.add('text-gray-800')
    this.internationalIndicatorTarget.classList.remove('hidden')

    // Update domestic tab styles
    const domesticSpan = this.domesticTabTarget.querySelector('span')
    if (domesticSpan) {
      domesticSpan.classList.remove('font-bold')
      domesticSpan.classList.add('font-medium')
    }
    this.domesticTabTarget.classList.remove('text-gray-800')
    this.domesticTabTarget.classList.add('text-gray-500')
    this.domesticIndicatorTarget.classList.add('hidden')
  }
}
