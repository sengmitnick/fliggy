import { Controller } from "@hotwired/stimulus"

interface FilterState {
  city: string
  checkIn: string
  checkOut: string
  rooms: number
  adults: number
  children: number
  priceMin: string
  priceMax: string
  starLevel: string
  query: string
  timestamp: number
}

export default class extends Controller<HTMLElement> {
  private readonly STORAGE_KEY = 'hotel_filters_state'
  private readonly EXPIRY_TIME = 24 * 60 * 60 * 1000 // 24 hours

  connect(): void {
    console.log("HotelFilterPersistence connected")
    
    // Restore filters from sessionStorage when page loads
    this.restoreFilters()
    
    // Save filters when user navigates away
    this.setupSaveOnNavigation()
  }

  disconnect(): void {
    console.log("HotelFilterPersistence disconnected")
    // Save filters when controller disconnects (page navigation)
    this.saveFilters()
  }

  /**
   * Setup listeners to save filters on navigation
   */
  private setupSaveOnNavigation(): void {
    // Save on beforeunload (refresh/close)
    window.addEventListener('beforeunload', this.saveFilters.bind(this))
    
    // Save when clicking any link (Turbo navigation)
    document.addEventListener('turbo:before-visit', this.saveFilters.bind(this))
    
    // Save when form is submitted (search button clicked)
    const form = document.querySelector('form[action*="hotels"]')
    if (form) {
      form.addEventListener('submit', this.saveFilters.bind(this))
    }
    
    // Save immediately when URL has filter parameters (user just searched)
    // This ensures we capture the latest filter state right after search
    const urlParams = new URLSearchParams(window.location.search)
    if (urlParams.has('check_in') && urlParams.has('check_out')) {
      console.log('Detected filter parameters in URL, saving immediately')
      this.saveFilters()
    }
    
    // Monitor hidden input changes (when user modifies filters but doesn't search yet)
    this.monitorInputChanges()
  }
  
  /**
   * Monitor hidden input field changes and save immediately
   */
  private monitorInputChanges(): void {
    // Get all hidden inputs that store filter values
    const filterInputs = [
      'checkInInput',
      'checkOutInput', 
      'roomsInput',
      'adultsInput',
      'childrenInput',
      'minPriceInput',
      'maxPriceInput',
      'starsInput'
    ]
    
    filterInputs.forEach(targetName => {
      const selector = [
        `[data-hotel-search-target="${targetName}"]`,
        `[data-hotel-date-picker-target="${targetName}"]`,
        `[data-hotel-guest-selector-target="${targetName}"]`,
        `[data-hotel-price-filter-target="${targetName}"]`
      ].join(', ')
      
      const input = document.querySelector(selector) as HTMLInputElement
      if (input) {
        // Use MutationObserver to detect value changes (since hidden inputs don't fire 'change' events reliably)
        const observer = new MutationObserver(() => {
          console.log(`Filter input changed: ${targetName}, saving...`)
          this.saveFilters()
        })
        
        observer.observe(input, {
          attributes: true,
          attributeFilter: ['value']
        })
        
        // Also listen to input event
        input.addEventListener('input', () => {
          console.log(`Filter input changed: ${targetName}, saving...`)
          this.saveFilters()
        })
      }
    })
  }

  /**
   * Save current filter state to sessionStorage
   */
  private saveFilters(): void {
    try {
      const urlParams = new URLSearchParams(window.location.search)
      
      // Collect date values
      const checkIn = urlParams.get('check_in') || this.getInputValue('checkInInput') || ''
      const checkOut = urlParams.get('check_out') || this.getInputValue('checkOutInput') || ''
      
      // Don't save if dates are empty - this means user hasn't set dates yet
      if (!checkIn || !checkOut) {
        console.log('Skipping save - dates not set yet')
        return
      }
      
      const filterState: FilterState = {
        city: urlParams.get('city') || this.getInputValue('cityInput') || '深圳',
        checkIn: checkIn,
        checkOut: checkOut,
        rooms: parseInt(urlParams.get('rooms') || this.getInputValue('roomsInput') || '1'),
        adults: parseInt(urlParams.get('adults') || this.getInputValue('adultsInput') || '1'),
        children: parseInt(urlParams.get('children') || this.getInputValue('childrenInput') || '0'),
        priceMin: urlParams.get('price_min') || this.getInputValue('minPriceInput') || '',
        priceMax: urlParams.get('price_max') || this.getInputValue('maxPriceInput') || '',
        starLevel: urlParams.get('star_level') || this.getInputValue('starsInput') || '',
        query: urlParams.get('q') || '',
        timestamp: Date.now()
      }

      sessionStorage.setItem(this.STORAGE_KEY, JSON.stringify(filterState))
      console.log('Hotel filters saved to sessionStorage:', filterState)
    } catch (error) {
      console.error('Failed to save hotel filters:', error)
    }
  }

  /**
   * Restore filter state from sessionStorage and apply to URL
   */
  private restoreFilters(): void {
    try {
      const stored = sessionStorage.getItem(this.STORAGE_KEY)
      if (!stored) {
        console.log('No saved hotel filters found')
        return
      }

      const filterState: FilterState = JSON.parse(stored)
      
      // Validate that stored data has required date fields
      if (!filterState.checkIn || !filterState.checkOut) {
        console.log('Stored filters missing dates, clearing...')
        sessionStorage.removeItem(this.STORAGE_KEY)
        return
      }
      
      // Check if stored data is expired
      if (Date.now() - filterState.timestamp > this.EXPIRY_TIME) {
        console.log('Stored hotel filters expired, clearing...')
        sessionStorage.removeItem(this.STORAGE_KEY)
        return
      }

      // Check if user came from homepage or another internal page
      // If they came from homepage (with default city param only), restore saved filters
      const urlParams = new URLSearchParams(window.location.search)
      const hasOtherParams = Array.from(urlParams.keys()).filter(k => k !== 'city').length > 0
      
      // Only restore if:
      // 1. No URL params at all (direct navigation), OR
      // 2. Only has default city param from homepage link (no other filter params)
      const shouldRestore = !hasOtherParams
      
      if (shouldRestore) {
        console.log('Restoring hotel filters from sessionStorage:', filterState)
        this.applyFiltersToURL(filterState)
      } else {
        console.log('URL has existing filter parameters, skipping restore')
      }
    } catch (error) {
      console.error('Failed to restore hotel filters:', error)
      sessionStorage.removeItem(this.STORAGE_KEY)
    }
  }

  /**
   * Apply filter state to URL and reload page
   */
  private applyFiltersToURL(filterState: FilterState): void {
    const url = new URL(window.location.href)
    
    // Set all filter parameters
    url.searchParams.set('city', filterState.city)
    url.searchParams.set('check_in', filterState.checkIn)
    url.searchParams.set('check_out', filterState.checkOut)
    url.searchParams.set('rooms', filterState.rooms.toString())
    url.searchParams.set('adults', filterState.adults.toString())
    url.searchParams.set('children', filterState.children.toString())
    
    if (filterState.priceMin) {
      url.searchParams.set('price_min', filterState.priceMin)
    }
    if (filterState.priceMax) {
      url.searchParams.set('price_max', filterState.priceMax)
    }
    if (filterState.starLevel) {
      url.searchParams.set('star_level', filterState.starLevel)
    }
    if (filterState.query) {
      url.searchParams.set('q', filterState.query)
    }
    
    // Only redirect if URL would actually change
    const newURL = url.toString()
    if (newURL !== window.location.href) {
      console.log('Redirecting with restored filters:', newURL)
      window.location.href = newURL
    } else {
      console.log('URL already matches stored filters, skipping redirect')
    }
  }

  /**
   * Helper method to get input value by data-target attribute
   */
  private getInputValue(targetName: string): string {
    const selector = [
      `[data-hotel-search-target="${targetName}"]`,
      `[data-hotel-date-picker-target="${targetName}"]`,
      `[data-hotel-guest-selector-target="${targetName}"]`,
      `[data-hotel-price-filter-target="${targetName}"]`
    ].join(', ')
    const input = document.querySelector(selector) as HTMLInputElement
    return input ? input.value : ''
  }

  /**
   * Clear saved filters (can be called manually if needed)
   */
  clearSavedFilters(): void {
    sessionStorage.removeItem(this.STORAGE_KEY)
    console.log('Hotel filters cleared from sessionStorage')
  }
}
