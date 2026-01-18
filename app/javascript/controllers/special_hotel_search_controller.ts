import { Controller } from "@hotwired/stimulus"

// Declare Turbo global type
declare const Turbo: any

export default class extends Controller<HTMLElement> {
  static targets = ["searchInput"]
  static values = {
    city: String,
    query: String
  }

  declare readonly searchInputTarget: HTMLInputElement
  declare readonly hasSearchInputTarget: boolean
  declare cityValue: string
  declare queryValue: string

  private searchTimeout: number | null = null

  connect(): void {
    // Initialize search input with current query
    if (this.hasSearchInputTarget && this.queryValue) {
      this.searchInputTarget.value = this.queryValue
    }
  }

  // Search hotels with debounce
  search(): void {
    // Clear previous timeout
    if (this.searchTimeout) {
      clearTimeout(this.searchTimeout)
    }

    // Debounce search by 500ms
    this.searchTimeout = window.setTimeout(() => {
      this.performSearch()
    }, 500)
  }

  // Perform the actual search
  private performSearch(): void {
    if (!this.hasSearchInputTarget) return

    const query = this.searchInputTarget.value.trim()
    const city = this.cityValue || '北京市'

    // Build URL with city and query parameters
    const url = new URL('/special_hotels', window.location.origin)
    url.searchParams.set('city', city)
    
    if (query) {
      url.searchParams.set('query', query)
    }

    // Navigate to the new URL with Turbo
    Turbo.visit(url.toString())
  }
}
