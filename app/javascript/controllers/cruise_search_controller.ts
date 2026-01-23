import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = [
    "routeDropdown",
    "tab",
    "cruiseLineContainer",
    "cityDropdown",
    "monthDropdown"
  ]

  declare readonly routeDropdownTarget: HTMLElement
  declare readonly tabTargets: HTMLElement[]
  declare readonly hasCruiseLineContainerTarget: boolean
  declare readonly cityDropdownTarget: HTMLElement
  declare readonly hasCityDropdownTarget: boolean
  declare readonly monthDropdownTarget: HTMLElement
  declare readonly hasMonthDropdownTarget: boolean

  connect(): void {
    console.log("CruiseSearch connected")
  }

  disconnect(): void {
    console.log("CruiseSearch disconnected")
  }

  // Toggle route dropdown menu
  toggleRouteDropdown(event: Event): void {
    event.preventDefault()
    this.routeDropdownTarget.classList.toggle('hidden')
  }

  // Select cruise line (visual effect only, actual filtering requires backend)
  selectCruiseLine(event: Event): void {
    event.preventDefault()
    const button = event.currentTarget as HTMLElement
    
    // Remove selection from all cruise line buttons
    if (this.hasCruiseLineContainerTarget) {
      const allButtons = this.element.querySelectorAll('[data-action="click->cruise-search#selectCruiseLine"]')
      allButtons.forEach(btn => {
        btn.classList.remove('border-yellow-400', 'bg-yellow-50')
        btn.classList.add('border-gray-200')
      })
    }
    
    // Add selection to clicked button
    button.classList.remove('border-gray-200')
    button.classList.add('border-yellow-400', 'bg-yellow-50')
  }

  // Switch tabs (visual effect only)
  switchTab(event: Event): void {
    event.preventDefault()
    const clickedTab = event.currentTarget as HTMLElement
    const tabName = clickedTab.dataset.tab
    
    // Update tab styles
    this.tabTargets.forEach(tab => {
      if (tab === clickedTab) {
        tab.classList.remove('border-transparent', 'text-gray-500')
        tab.classList.add('border-yellow-400', 'text-gray-900')
      } else {
        tab.classList.remove('border-yellow-400', 'text-gray-900')
        tab.classList.add('border-transparent', 'text-gray-500')
      }
    })
    
    // In a real implementation, you would load content for each tab
    console.log(`Switched to tab: ${tabName}`)
  }

  // Toggle city dropdown menu
  toggleCityDropdown(event: Event): void {
    event.preventDefault()
    if (this.hasCityDropdownTarget) {
      this.cityDropdownTarget.classList.toggle('hidden')
    }
  }

  // Toggle month dropdown menu
  toggleMonthDropdown(event: Event): void {
    event.preventDefault()
    if (this.hasMonthDropdownTarget) {
      this.monthDropdownTarget.classList.toggle('hidden')
    }
  }

  // Close dropdown when clicking outside
  closeDropdownOnClickOutside(event: Event): void {
    const target = event.target as HTMLElement
    if (!this.element.contains(target)) {
      this.routeDropdownTarget.classList.add('hidden')
      if (this.hasCityDropdownTarget) {
        this.cityDropdownTarget.classList.add('hidden')
      }
      if (this.hasMonthDropdownTarget) {
        this.monthDropdownTarget.classList.add('hidden')
      }
    }
  }
}
