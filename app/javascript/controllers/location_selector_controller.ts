import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = [
    "modal",
    "searchInput",
    "locationList",
    "locationInput",
    "locationDisplay",
    "recentSection",
    "recentList"
  ]

  static values = {
    locationType: String, // "from" or "to"
  }

  declare readonly modalTarget: HTMLElement
  declare readonly searchInputTarget: HTMLInputElement
  declare readonly locationListTarget: HTMLElement
  declare readonly locationInputTarget: HTMLInputElement
  declare readonly locationDisplayTarget: HTMLElement
  declare readonly recentSectionTarget: HTMLElement
  declare readonly recentListTarget: HTMLElement
  declare readonly hasLocationInputTarget: boolean
  declare readonly hasLocationDisplayTarget: boolean
  declare readonly locationTypeValue: string

  private selectedLocation: { name: string; address: string } | null = null

  connect(): void {
    console.log("LocationSelector connected")
  }

  disconnect(): void {
    console.log("LocationSelector disconnected")
  }

  openModal(): void {
    this.modalTarget.classList.remove("hidden")
    this.searchInputTarget.value = ""
    this.searchInputTarget.focus()
    document.body.style.overflow = "hidden"
  }

  closeModal(): void {
    this.modalTarget.classList.add("hidden")
    document.body.style.overflow = ""
  }

  stopPropagation(event: Event): void {
    event.stopPropagation()
  }

  selectLocation(event: Event): void {
    const button = event.currentTarget as HTMLElement
    const name = button.dataset.locationName || ""
    const address = button.dataset.locationAddress || ""
    
    this.selectedLocation = { name, address }

    // Update UI to show selected state
    this.locationListTarget.querySelectorAll("button").forEach(btn => {
      btn.classList.remove("bg-primary-light", "border-primary")
    })
    button.classList.add("bg-primary-light", "border", "border-primary")
  }

  confirm(): void {
    if (!this.selectedLocation) {
      return
    }

    // Update hidden input field if exists
    if (this.hasLocationInputTarget) {
      this.locationInputTarget.value = this.selectedLocation.name
    }

    // Update display element if exists
    if (this.hasLocationDisplayTarget) {
      this.locationDisplayTarget.textContent = this.selectedLocation.name
      this.locationDisplayTarget.classList.remove("text-text-muted")
      this.locationDisplayTarget.classList.add("text-text-primary")
    }

    // Save to recent locations
    this.saveToRecent(this.selectedLocation)

    this.closeModal()
  }

  search(event: Event): void {
    const input = event.target as HTMLInputElement
    const query = input.value.toLowerCase().trim()

    const buttons = this.locationListTarget.querySelectorAll("button[data-location-name]")
    
    buttons.forEach(button => {
      const element = button as HTMLElement
      const name = element.dataset.locationName?.toLowerCase() || ""
      const address = element.dataset.locationAddress?.toLowerCase() || ""
      
      if (name.includes(query) || address.includes(query)) {
        element.classList.remove("hidden")
      } else {
        element.classList.add("hidden")
      }
    })
  }

  private saveToRecent(location: { name: string; address: string }): void {
    try {
      const key = "recent_transfer_locations"
      const stored = localStorage.getItem(key)
      let recent: Array<{ name: string; address: string }> = stored ? JSON.parse(stored) : []

      // Remove if already exists
      recent = recent.filter(loc => loc.name !== location.name)

      // Add to front
      recent.unshift(location)

      // Keep only last 5
      recent = recent.slice(0, 5)

      localStorage.setItem(key, JSON.stringify(recent))

      // Update UI
      this.updateRecentList(recent)
    } catch (error) {
      console.error("Failed to save recent location:", error)
    }
  }

  private updateRecentList(locations: Array<{ name: string; address: string }>): void {
    if (locations.length === 0) {
      this.recentSectionTarget.classList.add("hidden")
      return
    }

    this.recentSectionTarget.classList.remove("hidden")
    
    const html = locations.map(loc => `
      <button
        type="button"
        data-action="click->location-selector#selectLocation"
        data-location-name="${loc.name}"
        data-location-address="${loc.address}"
        class="w-full text-left p-3 rounded-lg hover:bg-surface-hover transition-colors">
        <div class="flex items-start">
          <svg class="w-5 h-5 text-text-muted mt-0.5 mr-3 flex-shrink-0" fill="currentColor" viewBox="0 0 20 20">
            <path fill-rule="evenodd" d="M5.05 4.05a7 7 0 119.9 9.9L10 18.9l-4.95-4.95a7 7 0 010-9.9zM10 11a2 2 0 100-4 2 2 0 000 4z" clip-rule="evenodd"/>
          </svg>
          <div class="flex-1">
            <div class="text-text-primary font-medium">${loc.name}</div>
            <div class="text-xs text-text-muted mt-0.5">${loc.address}</div>
          </div>
        </div>
      </button>
    `).join("")

    this.recentListTarget.innerHTML = html
  }
}
