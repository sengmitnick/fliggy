import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = [
    "searchModal",
    "searchInput",
    "searchDisplay",
    "hotSearchContent", "hotSearchIcon",
    "hotBrandContent", "hotBrandIcon",
    "hotLocationContent", "hotLocationIcon",
    "metroContent", "metroIcon",
    "airportContent", "airportIcon",
    "attractionContent", "attractionIcon",
    "themeContent", "themeIcon",
    "hospitalContent", "hospitalIcon",
    "universityContent", "universityIcon",
    "cityInput",
    "checkInInput",
    "checkOutInput",
    "roomsInput",
    "adultsInput",
    "childrenInput"
  ]

  declare readonly searchModalTarget: HTMLElement
  declare readonly searchInputTarget: HTMLInputElement
  declare readonly hasSearchDisplayTarget: boolean
  declare readonly searchDisplayTarget: HTMLInputElement
  declare readonly hotSearchContentTarget: HTMLElement
  declare readonly hotSearchIconTarget: HTMLElement
  declare readonly hotBrandContentTarget: HTMLElement
  declare readonly hotBrandIconTarget: HTMLElement
  declare readonly hotLocationContentTarget: HTMLElement
  declare readonly hotLocationIconTarget: HTMLElement
  declare readonly metroContentTarget: HTMLElement
  declare readonly metroIconTarget: HTMLElement
  declare readonly airportContentTarget: HTMLElement
  declare readonly airportIconTarget: HTMLElement
  declare readonly attractionContentTarget: HTMLElement
  declare readonly attractionIconTarget: HTMLElement
  declare readonly themeContentTarget: HTMLElement
  declare readonly themeIconTarget: HTMLElement
  declare readonly hospitalContentTarget: HTMLElement
  declare readonly hospitalIconTarget: HTMLElement
  declare readonly universityContentTarget: HTMLElement
  declare readonly universityIconTarget: HTMLElement
  declare readonly hasCityInputTarget: boolean
  declare readonly cityInputTarget: HTMLInputElement
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

  connect(): void {
    console.log("HotelSearch connected")
    // Listen for city-selector updates
    document.addEventListener('city-selector:city-selected-for-hotel', this.handleCityUpdate.bind(this))
    // Listen for date-picker updates
    document.addEventListener('hotel-date-picker:dates-selected', this.handleDateUpdate.bind(this))
    // Listen for guest-selector updates
    document.addEventListener('hotel-guest-selector:guests-updated', this.handleGuestUpdate.bind(this))
  }

  disconnect(): void {
    console.log("HotelSearch disconnected")
    document.removeEventListener('city-selector:city-selected-for-hotel', this.handleCityUpdate.bind(this))
    document.removeEventListener('hotel-date-picker:dates-selected', this.handleDateUpdate.bind(this))
    document.removeEventListener('hotel-guest-selector:guests-updated', this.handleGuestUpdate.bind(this))
  }

  // Handle city selection update from city-selector
  handleCityUpdate(event: Event): void {
    const customEvent = event as CustomEvent
    const { cityName } = customEvent.detail
    console.log('HotelSearch: Received city update:', cityName)
    
    // Update URL with new city and reload page to fetch city-specific data
    const url = new URL(window.location.href)
    url.searchParams.set('city', cityName)
    
    console.log('HotelSearch: Reloading page with new city:', cityName)
    window.location.href = url.toString()
  }

  // Handle date selection update from hotel-date-picker
  handleDateUpdate(event: Event): void {
    const customEvent = event as CustomEvent
    const { checkIn, checkOut } = customEvent.detail
    console.log('HotelSearch: Received date update:', { checkIn, checkOut })
    
    if (this.hasCheckInInputTarget) {
      this.checkInInputTarget.value = checkIn
      console.log('HotelSearch: Updated check-in to:', checkIn)
    }
    
    if (this.hasCheckOutInputTarget) {
      this.checkOutInputTarget.value = checkOut
      console.log('HotelSearch: Updated check-out to:', checkOut)
    }
  }

  // Handle guest selection update from hotel-guest-selector
  handleGuestUpdate(event: Event): void {
    const customEvent = event as CustomEvent
    const { rooms, adults, children } = customEvent.detail
    console.log('HotelSearch: Received guest update:', { rooms, adults, children })
    
    if (this.hasRoomsInputTarget) {
      this.roomsInputTarget.value = rooms.toString()
      console.log('HotelSearch: Updated rooms to:', rooms)
    }
    
    if (this.hasAdultsInputTarget) {
      this.adultsInputTarget.value = adults.toString()
      console.log('HotelSearch: Updated adults to:', adults)
    }
    
    if (this.hasChildrenInputTarget) {
      this.childrenInputTarget.value = children.toString()
      console.log('HotelSearch: Updated children to:', children)
    }
  }

  openSearchModal(): void {
    this.searchModalTarget.classList.remove("hidden")
    setTimeout(() => {
      this.searchInputTarget.focus()
    }, 100)
  }

  closeSearchModal(): void {
    this.searchModalTarget.classList.add("hidden")
  }

  submitSearch(): void {
    const form = this.searchInputTarget.closest("form") as HTMLFormElement
    if (form) {
      // Always submit the form, even if input is empty
      form.requestSubmit()
    }
  }

  handleSearchInputKeypress(event: KeyboardEvent): void {
    if (event.key === "Enter") {
      event.preventDefault()
      this.submitSearch()
    }
  }

  toggleSection(event: Event): void {
    const button = event.currentTarget as HTMLElement
    const section = button.dataset.section
    
    if (!section) return

    const contentTarget = `${section}ContentTarget` as keyof this
    const iconTarget = `${section}IconTarget` as keyof this

    const content = this[contentTarget] as HTMLElement
    const icon = this[iconTarget] as HTMLElement

    if (content && icon) {
      content.classList.toggle("hidden")
      icon.classList.toggle("rotate-180")
    }
  }

  openCitySelector(): void {
    alert("城市选择功能：\n\n在完整版本中，这里会打开城市选择器。\n\n当前城市：深圳市")
  }

  openGuestSelector(): void {
    const rooms = prompt("请输入房间数量", "1")
    const adults = prompt("请输入成人数量", "1")
    const children = prompt("请输入儿童数量", "0")
    
    if (rooms && adults) {
      const url = new URL(window.location.href)
      url.searchParams.set('rooms', rooms)
      url.searchParams.set('adults', adults)
      url.searchParams.set('children', children || '0')
      window.location.href = url.toString()
    }
  }

  getCurrentLocation(): void {
    if (!navigator.geolocation) {
      alert('您的浏览器不支持地理定位功能')
      return
    }

    const button = event?.currentTarget as HTMLButtonElement
    if (button) {
      button.disabled = true
      button.classList.add('opacity-50')
    }

    navigator.geolocation.getCurrentPosition(
      (position) => {
        const { latitude, longitude } = position.coords
        console.log('Got location:', { latitude, longitude })
        
        // In a real app, you would reverse geocode these coordinates to get the city name
        // For now, we'll show the coordinates and alert the user
        alert(`获取到您的位置：\n纬度: ${latitude.toFixed(6)}\n经度: ${longitude.toFixed(6)}\n\n在完整版本中，这里会自动选择最近的城市`)
        
        if (button) {
          button.disabled = false
          button.classList.remove('opacity-50')
        }
      },
      (error) => {
        console.error('Geolocation error:', error)
        let message = '无法获取您的位置'
        
        switch (error.code) {
          case error.PERMISSION_DENIED:
            message = '您拒绝了位置权限请求。请在浏览器设置中允许访问位置信息。'
            break
          case error.POSITION_UNAVAILABLE:
            message = '位置信息不可用，请检查您的网络连接。'
            break
          case error.TIMEOUT:
            message = '获取位置信息超时，请重试。'
            break
        }
        
        alert(message)
        
        if (button) {
          button.disabled = false
          button.classList.remove('opacity-50')
        }
      },
      {
        enableHighAccuracy: true,
        timeout: 10000,
        maximumAge: 0
      }
    )
  }

  selectOption(event: Event): void {
    const button = event.currentTarget as HTMLButtonElement
    const searchTerm = button.dataset.searchTerm
    
    if (!searchTerm) return

    console.log('HotelSearch: Selected option:', searchTerm)

    // Update the search input value
    this.searchInputTarget.value = searchTerm

    // Update the search display input if it exists
    if (this.hasSearchDisplayTarget) {
      this.searchDisplayTarget.value = searchTerm
      console.log('HotelSearch: Updated search display to:', searchTerm)
    }

    // Close the search modal
    this.closeSearchModal()

    // Submit the search form directly
    this.submitSearch()
  }
}
