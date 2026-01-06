import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = [
    "modal",
    "overlay",
    "flightPreferenceTab",
    "airlineCompanyTab",
    "airportTab",
    "departureTimeTab",
    "transferCityTab",
    "transferTimesTab",
    "transferDurationTab",
    "totalDurationTab",
    "seatClassTab",
    "aircraftModelTab",
    "ticketCancellationTab",
    "flightPreferenceSection",
    "airlineCompanySection",
    "airportSection",
    "departureTimeSection",
    "transferCitySection",
    "transferTimesSection",
    "transferDurationSection",
    "totalDurationSection",
    "seatClassSection",
    "aircraftModelSection",
    "ticketCancellationSection",
    "resultCount",
    "directFlightCheckbox",
    "noTransitCheckbox",
    "includeCheckedLuggageCheckbox",
    "noSharedFlightCheckbox",
    "discountPriceCheckbox",
    "resetButton",
    "confirmButton",
    "filterBadge",
    "selectedFiltersContainer",
    "selectedFiltersList",
    // Card targets for grid layout
    "directFlightCard",
    "checkedLuggageCard",
    "noSharedFlightCard",
    "noTransitCard",
    "discountPriceCard",
    // Quick filter button targets
    "quickDirectFlight",
    "quickNoSharedFlight",
    "quickCheckedLuggage",
    "quickNoTransit",
    "quickDiscountPrice"
  ]

  declare readonly modalTarget: HTMLElement
  declare readonly overlayTarget: HTMLElement
  declare readonly flightPreferenceTabTarget: HTMLElement
  declare readonly airlineCompanyTabTarget: HTMLElement
  declare readonly airportTabTarget: HTMLElement
  declare readonly departureTimeTabTarget: HTMLElement
  declare readonly transferCityTabTarget: HTMLElement
  declare readonly transferTimesTabTarget: HTMLElement
  declare readonly transferDurationTabTarget: HTMLElement
  declare readonly totalDurationTabTarget: HTMLElement
  declare readonly seatClassTabTarget: HTMLElement
  declare readonly aircraftModelTabTarget: HTMLElement
  declare readonly ticketCancellationTabTarget: HTMLElement
  declare readonly flightPreferenceSectionTarget: HTMLElement
  declare readonly airlineCompanySectionTarget: HTMLElement
  declare readonly airportSectionTarget: HTMLElement
  declare readonly departureTimeSectionTarget: HTMLElement
  declare readonly transferCitySectionTarget: HTMLElement
  declare readonly transferTimesSectionTarget: HTMLElement
  declare readonly transferDurationSectionTarget: HTMLElement
  declare readonly totalDurationSectionTarget: HTMLElement
  declare readonly seatClassSectionTarget: HTMLElement
  declare readonly aircraftModelSectionTarget: HTMLElement
  declare readonly ticketCancellationSectionTarget: HTMLElement
  declare readonly resultCountTarget: HTMLElement
  declare readonly directFlightCheckboxTarget: HTMLInputElement
  declare readonly noTransitCheckboxTarget: HTMLInputElement
  declare readonly includeCheckedLuggageCheckboxTarget: HTMLInputElement
  declare readonly noSharedFlightCheckboxTarget: HTMLInputElement
  declare readonly discountPriceCheckboxTarget: HTMLInputElement
  declare readonly resetButtonTarget: HTMLElement
  declare readonly confirmButtonTarget: HTMLElement
  declare readonly filterBadgeTarget: HTMLElement
  declare readonly selectedFiltersContainerTarget: HTMLElement
  declare readonly selectedFiltersListTarget: HTMLElement
  declare readonly directFlightCardTarget?: HTMLElement
  declare readonly checkedLuggageCardTarget?: HTMLElement
  declare readonly noSharedFlightCardTarget?: HTMLElement
  declare readonly noTransitCardTarget?: HTMLElement
  declare readonly discountPriceCardTarget?: HTMLElement
  declare readonly quickDirectFlightTarget?: HTMLElement
  declare readonly quickNoSharedFlightTarget?: HTMLElement
  declare readonly quickCheckedLuggageTarget?: HTMLElement
  declare readonly quickNoTransitTarget?: HTMLElement
  declare readonly quickDiscountPriceTarget?: HTMLElement

  declare currentTab: string
  declare filters: {
    directFlight: boolean
    noTransit: boolean
    includeCheckedLuggage: boolean
    noSharedFlight: boolean
    discountPrice: boolean
    airlines: Set<string>
    departureAirports: Set<string>
    arrivalAirports: Set<string>
    departureTimeRanges: Set<string>
    aircraftModels: Set<string>
  }

  connect(): void {
    console.log("FlightFilter controller connected")
    this.currentTab = "flightPreference"
    this.initializeFilters()
  }

  initializeFilters(): void {
    this.filters = {
      directFlight: false,
      noTransit: false,
      includeCheckedLuggage: false,
      noSharedFlight: false,
      discountPrice: false,
      airlines: new Set(),
      departureAirports: new Set(),
      arrivalAirports: new Set(),
      departureTimeRanges: new Set(),
      aircraftModels: new Set()
    }
  }

  openModal(): void {
    this.modalTarget.classList.remove("hidden")
    this.overlayTarget.classList.remove("hidden")
    document.body.style.overflow = "hidden"
  }

  closeModal(): void {
    this.modalTarget.classList.add("hidden")
    this.overlayTarget.classList.add("hidden")
    document.body.style.overflow = ""
  }

  selectTab(event: Event): void {
    const button = event.currentTarget as HTMLElement
    const tabName = button.dataset.tab
    if (!tabName) return

    this.currentTab = tabName

    // Update tab buttons
    const allTabs = [
      this.flightPreferenceTabTarget,
      this.airlineCompanyTabTarget,
      this.airportTabTarget,
      this.departureTimeTabTarget,
      this.transferCityTabTarget,
      this.transferTimesTabTarget,
      this.transferDurationTabTarget,
      this.totalDurationTabTarget,
      this.seatClassTabTarget,
      this.aircraftModelTabTarget,
      this.ticketCancellationTabTarget
    ]

    allTabs.forEach(tab => {
      tab.classList.remove("border-blue-500", "text-blue-600", "font-bold")
      tab.classList.add("text-gray-600")
    })

    button.classList.add("border-blue-500", "text-blue-600", "font-bold")
    button.classList.remove("text-gray-600")

    // Update sections
    const allSections = [
      this.flightPreferenceSectionTarget,
      this.airlineCompanySectionTarget,
      this.airportSectionTarget,
      this.departureTimeSectionTarget,
      this.transferCitySectionTarget,
      this.transferTimesSectionTarget,
      this.transferDurationSectionTarget,
      this.totalDurationSectionTarget,
      this.seatClassSectionTarget,
      this.aircraftModelSectionTarget,
      this.ticketCancellationSectionTarget
    ]

    allSections.forEach(section => section.classList.add("hidden"))

    const sectionMap: { [key: string]: HTMLElement } = {
      flightPreference: this.flightPreferenceSectionTarget,
      airlineCompany: this.airlineCompanySectionTarget,
      airport: this.airportSectionTarget,
      departureTime: this.departureTimeSectionTarget,
      transferCity: this.transferCitySectionTarget,
      transferTimes: this.transferTimesSectionTarget,
      transferDuration: this.transferDurationSectionTarget,
      totalDuration: this.totalDurationSectionTarget,
      seatClass: this.seatClassSectionTarget,
      aircraftModel: this.aircraftModelSectionTarget,
      ticketCancellation: this.ticketCancellationSectionTarget
    }

    const targetSection = sectionMap[tabName]
    if (targetSection) {
      targetSection.classList.remove("hidden")
    }
  }

  // Flight preference toggles
  toggleDirectFlight(): void {
    // Toggle checkbox state
    this.directFlightCheckboxTarget.checked = !this.directFlightCheckboxTarget.checked
    this.filters.directFlight = this.directFlightCheckboxTarget.checked
    
    // Update card style
    if (this.directFlightCardTarget) {
      if (this.filters.directFlight) {
        this.directFlightCardTarget.classList.remove("bg-[#f6f7f9]")
        this.directFlightCardTarget.classList.add("bg-[#fff9e6]", "border-[0.5px]", "border-[#ffda80]")
        // Add checkmark
        if (!this.directFlightCardTarget.querySelector(".checkmark")) {
          const checkmark = this.createCheckmark()
          this.directFlightCardTarget.appendChild(checkmark)
        }
      } else {
        this.directFlightCardTarget.classList.add("bg-[#f6f7f9]")
        this.directFlightCardTarget.classList.remove("bg-[#fff9e6]", "border-[0.5px]", "border-[#ffda80]")
        // Remove checkmark
        const checkmark = this.directFlightCardTarget.querySelector(".checkmark")
        if (checkmark) checkmark.remove()
      }
    }
    
    // Sync with quick filter button if exists
    if (this.quickDirectFlightTarget) {
      if (this.filters.directFlight) {
        this.quickDirectFlightTarget.classList.add("bg-yellow-100", "border-yellow-400", "text-yellow-800")
        this.quickDirectFlightTarget.classList.remove("border-gray-300")
      } else {
        this.quickDirectFlightTarget.classList.remove("bg-yellow-100", "border-yellow-400", "text-yellow-800")
        this.quickDirectFlightTarget.classList.add("border-gray-300")
      }
    }
    
    this.updateResultCount()
  }

  toggleNoTransit(): void {
    // Toggle checkbox state
    this.noTransitCheckboxTarget.checked = !this.noTransitCheckboxTarget.checked
    this.filters.noTransit = this.noTransitCheckboxTarget.checked
    
    // Update card style
    if (this.noTransitCardTarget) {
      if (this.filters.noTransit) {
        this.noTransitCardTarget.classList.remove("bg-[#f6f7f9]")
        this.noTransitCardTarget.classList.add("bg-[#fff9e6]", "border-[0.5px]", "border-[#ffda80]")
        // Add checkmark
        if (!this.noTransitCardTarget.querySelector(".checkmark")) {
          const checkmark = this.createCheckmark()
          this.noTransitCardTarget.appendChild(checkmark)
        }
      } else {
        this.noTransitCardTarget.classList.add("bg-[#f6f7f9]")
        this.noTransitCardTarget.classList.remove("bg-[#fff9e6]", "border-[0.5px]", "border-[#ffda80]")
        // Remove checkmark
        const checkmark = this.noTransitCardTarget.querySelector(".checkmark")
        if (checkmark) checkmark.remove()
      }
    }
    
    // Sync with quick filter button if exists
    if (this.quickNoTransitTarget) {
      if (this.filters.noTransit) {
        this.quickNoTransitTarget.classList.add("bg-yellow-100", "border-yellow-400", "text-yellow-800")
        this.quickNoTransitTarget.classList.remove("border-gray-300")
      } else {
        this.quickNoTransitTarget.classList.remove("bg-yellow-100", "border-yellow-400", "text-yellow-800")
        this.quickNoTransitTarget.classList.add("border-gray-300")
      }
    }
    
    this.updateResultCount()
  }

  toggleCheckedLuggage(): void {
    // Toggle checkbox state
    this.includeCheckedLuggageCheckboxTarget.checked = !this.includeCheckedLuggageCheckboxTarget.checked
    this.filters.includeCheckedLuggage = this.includeCheckedLuggageCheckboxTarget.checked
    
    // Update card style
    if (this.checkedLuggageCardTarget) {
      if (this.filters.includeCheckedLuggage) {
        this.checkedLuggageCardTarget.classList.remove("bg-[#f6f7f9]")
        this.checkedLuggageCardTarget.classList.add("bg-[#fff9e6]", "border-[0.5px]", "border-[#ffda80]")
        // Add checkmark
        if (!this.checkedLuggageCardTarget.querySelector(".checkmark")) {
          const checkmark = this.createCheckmark()
          this.checkedLuggageCardTarget.appendChild(checkmark)
        }
      } else {
        this.checkedLuggageCardTarget.classList.add("bg-[#f6f7f9]")
        this.checkedLuggageCardTarget.classList.remove("bg-[#fff9e6]", "border-[0.5px]", "border-[#ffda80]")
        // Remove checkmark
        const checkmark = this.checkedLuggageCardTarget.querySelector(".checkmark")
        if (checkmark) checkmark.remove()
      }
    }
    
    // Sync with quick filter button if exists
    if (this.quickCheckedLuggageTarget) {
      if (this.filters.includeCheckedLuggage) {
        this.quickCheckedLuggageTarget.classList.add("bg-yellow-100", "border-yellow-400", "text-yellow-800")
        this.quickCheckedLuggageTarget.classList.remove("border-gray-300")
      } else {
        this.quickCheckedLuggageTarget.classList.remove("bg-yellow-100", "border-yellow-400", "text-yellow-800")
        this.quickCheckedLuggageTarget.classList.add("border-gray-300")
      }
    }
    
    this.updateResultCount()
  }

  toggleNoSharedFlight(): void {
    // Toggle checkbox state
    this.noSharedFlightCheckboxTarget.checked = !this.noSharedFlightCheckboxTarget.checked
    this.filters.noSharedFlight = this.noSharedFlightCheckboxTarget.checked
    
    // Update card style
    if (this.noSharedFlightCardTarget) {
      if (this.filters.noSharedFlight) {
        this.noSharedFlightCardTarget.classList.remove("bg-[#f6f7f9]")
        this.noSharedFlightCardTarget.classList.add("bg-[#fff9e6]", "border-[0.5px]", "border-[#ffda80]")
        // Add checkmark
        if (!this.noSharedFlightCardTarget.querySelector(".checkmark")) {
          const checkmark = this.createCheckmark()
          this.noSharedFlightCardTarget.appendChild(checkmark)
        }
      } else {
        this.noSharedFlightCardTarget.classList.add("bg-[#f6f7f9]")
        this.noSharedFlightCardTarget.classList.remove("bg-[#fff9e6]", "border-[0.5px]", "border-[#ffda80]")
        // Remove checkmark
        const checkmark = this.noSharedFlightCardTarget.querySelector(".checkmark")
        if (checkmark) checkmark.remove()
      }
    }
    
    // Sync with quick filter button if exists
    if (this.quickNoSharedFlightTarget) {
      if (this.filters.noSharedFlight) {
        this.quickNoSharedFlightTarget.classList.add("bg-yellow-100", "border-yellow-400", "text-yellow-800")
        this.quickNoSharedFlightTarget.classList.remove("border-gray-300")
      } else {
        this.quickNoSharedFlightTarget.classList.remove("bg-yellow-100", "border-yellow-400", "text-yellow-800")
        this.quickNoSharedFlightTarget.classList.add("border-gray-300")
      }
    }
    
    this.updateResultCount()
  }

  toggleDiscountPrice(): void {
    // Toggle checkbox state
    this.discountPriceCheckboxTarget.checked = !this.discountPriceCheckboxTarget.checked
    this.filters.discountPrice = this.discountPriceCheckboxTarget.checked
    
    // Update card style
    if (this.discountPriceCardTarget) {
      if (this.filters.discountPrice) {
        this.discountPriceCardTarget.classList.remove("bg-[#f6f7f9]")
        this.discountPriceCardTarget.classList.add("bg-[#fff9e6]", "border-[0.5px]", "border-[#ffda80]")
        // Add checkmark
        if (!this.discountPriceCardTarget.querySelector(".checkmark")) {
          const checkmark = this.createCheckmark()
          this.discountPriceCardTarget.appendChild(checkmark)
        }
      } else {
        this.discountPriceCardTarget.classList.add("bg-[#f6f7f9]")
        this.discountPriceCardTarget.classList.remove("bg-[#fff9e6]", "border-[0.5px]", "border-[#ffda80]")
        // Remove checkmark
        const checkmark = this.discountPriceCardTarget.querySelector(".checkmark")
        if (checkmark) checkmark.remove()
      }
    }
    
    // Sync with quick filter button if exists
    if (this.quickDiscountPriceTarget) {
      if (this.filters.discountPrice) {
        this.quickDiscountPriceTarget.classList.add("bg-yellow-100", "border-yellow-400", "text-yellow-800")
        this.quickDiscountPriceTarget.classList.remove("border-gray-300")
      } else {
        this.quickDiscountPriceTarget.classList.remove("bg-yellow-100", "border-yellow-400", "text-yellow-800")
        this.quickDiscountPriceTarget.classList.add("border-gray-300")
      }
    }
    
    this.updateResultCount()
  }

  // Quick filter button actions
  toggleQuickDirectFlight(): void {
    this.filters.directFlight = !this.filters.directFlight
    this.directFlightCheckboxTarget.checked = this.filters.directFlight
    
    // Update quick button style
    if (this.quickDirectFlightTarget) {
      if (this.filters.directFlight) {
        this.quickDirectFlightTarget.classList.add("bg-yellow-100", "border-yellow-400", "text-yellow-800")
        this.quickDirectFlightTarget.classList.remove("border-gray-300")
      } else {
        this.quickDirectFlightTarget.classList.remove("bg-yellow-100", "border-yellow-400", "text-yellow-800")
        this.quickDirectFlightTarget.classList.add("border-gray-300")
      }
    }
    
    this.updateResultCount()
  }

  toggleQuickNoSharedFlight(): void {
    this.filters.noSharedFlight = !this.filters.noSharedFlight
    this.noSharedFlightCheckboxTarget.checked = this.filters.noSharedFlight
    
    // Update quick button style
    if (this.quickNoSharedFlightTarget) {
      if (this.filters.noSharedFlight) {
        this.quickNoSharedFlightTarget.classList.add("bg-yellow-100", "border-yellow-400", "text-yellow-800")
        this.quickNoSharedFlightTarget.classList.remove("border-gray-300")
      } else {
        this.quickNoSharedFlightTarget.classList.remove("bg-yellow-100", "border-yellow-400", "text-yellow-800")
        this.quickNoSharedFlightTarget.classList.add("border-gray-300")
      }
    }
    
    this.updateResultCount()
  }

  toggleQuickCheckedLuggage(): void {
    this.filters.includeCheckedLuggage = !this.filters.includeCheckedLuggage
    this.includeCheckedLuggageCheckboxTarget.checked = this.filters.includeCheckedLuggage
    
    // Update quick button style
    if (this.quickCheckedLuggageTarget) {
      if (this.filters.includeCheckedLuggage) {
        this.quickCheckedLuggageTarget.classList.add("bg-yellow-100", "border-yellow-400", "text-yellow-800")
        this.quickCheckedLuggageTarget.classList.remove("border-gray-300")
      } else {
        this.quickCheckedLuggageTarget.classList.remove("bg-yellow-100", "border-yellow-400", "text-yellow-800")
        this.quickCheckedLuggageTarget.classList.add("border-gray-300")
      }
    }
    
    this.updateResultCount()
  }

  toggleQuickNoTransit(): void {
    this.filters.noTransit = !this.filters.noTransit
    this.noTransitCheckboxTarget.checked = this.filters.noTransit
    
    // Update quick button style
    if (this.quickNoTransitTarget) {
      if (this.filters.noTransit) {
        this.quickNoTransitTarget.classList.add("bg-yellow-100", "border-yellow-400", "text-yellow-800")
        this.quickNoTransitTarget.classList.remove("border-gray-300")
      } else {
        this.quickNoTransitTarget.classList.remove("bg-yellow-100", "border-yellow-400", "text-yellow-800")
        this.quickNoTransitTarget.classList.add("border-gray-300")
      }
    }
    
    this.updateResultCount()
  }

  toggleQuickDiscountPrice(): void {
    this.filters.discountPrice = !this.filters.discountPrice
    this.discountPriceCheckboxTarget.checked = this.filters.discountPrice
    
    // Update quick button style
    if (this.quickDiscountPriceTarget) {
      if (this.filters.discountPrice) {
        this.quickDiscountPriceTarget.classList.add("bg-yellow-100", "border-yellow-400", "text-yellow-800")
        this.quickDiscountPriceTarget.classList.remove("border-gray-300")
      } else {
        this.quickDiscountPriceTarget.classList.remove("bg-yellow-100", "border-yellow-400", "text-yellow-800")
        this.quickDiscountPriceTarget.classList.add("border-gray-300")
      }
    }
    
    this.updateResultCount()
  }

  // Airline selection
  toggleAirline(event: Event): void {
    const checkbox = event.target as HTMLInputElement
    const airline = checkbox.value
    
    if (checkbox.checked) {
      this.filters.airlines.add(airline)
    } else {
      this.filters.airlines.delete(airline)
    }
    
    this.updateResultCount()
  }

  // Airport selection
  toggleDepartureAirport(event: Event): void {
    const checkbox = event.target as HTMLInputElement
    const airport = checkbox.value
    
    if (checkbox.checked) {
      this.filters.departureAirports.add(airport)
    } else {
      this.filters.departureAirports.delete(airport)
    }
    
    this.updateResultCount()
  }

  toggleArrivalAirport(event: Event): void {
    const checkbox = event.target as HTMLInputElement
    const airport = checkbox.value
    
    if (checkbox.checked) {
      this.filters.arrivalAirports.add(airport)
    } else {
      this.filters.arrivalAirports.delete(airport)
    }
    
    this.updateResultCount()
  }

  // Departure time selection
  toggleDepartureTime(event: Event): void {
    const checkbox = event.target as HTMLInputElement
    const timeRange = checkbox.value
    
    if (checkbox.checked) {
      this.filters.departureTimeRanges.add(timeRange)
    } else {
      this.filters.departureTimeRanges.delete(timeRange)
    }
    
    this.updateResultCount()
  }

  // Aircraft model selection
  toggleAircraftModel(event: Event): void {
    const checkbox = event.target as HTMLInputElement
    const model = checkbox.value
    
    if (checkbox.checked) {
      this.filters.aircraftModels.add(model)
    } else {
      this.filters.aircraftModels.delete(model)
    }
    
    this.updateResultCount()
  }

  // Reset all filters
  reset(): void {
    this.initializeFilters()
    
    // Reset all checkboxes
    this.directFlightCheckboxTarget.checked = false
    this.noTransitCheckboxTarget.checked = false
    this.includeCheckedLuggageCheckboxTarget.checked = false
    this.noSharedFlightCheckboxTarget.checked = false
    this.discountPriceCheckboxTarget.checked = false
    
    // stimulus-validator: disable-next-line
    const airlineCheckboxes = this.element.querySelectorAll<HTMLInputElement>('input[type="checkbox"][data-filter-type="airline"]')
    airlineCheckboxes.forEach(cb => cb.checked = false)
    
    // stimulus-validator: disable-next-line
    const airportCheckboxes = this.element.querySelectorAll<HTMLInputElement>('input[type="checkbox"][data-filter-type="airport"]')
    airportCheckboxes.forEach(cb => cb.checked = false)
    
    // stimulus-validator: disable-next-line
    const timeCheckboxes = this.element.querySelectorAll<HTMLInputElement>('input[type="checkbox"][data-filter-type="departure-time"]')
    timeCheckboxes.forEach(cb => cb.checked = false)
    
    // stimulus-validator: disable-next-line
    const modelCheckboxes = this.element.querySelectorAll<HTMLInputElement>('input[type="checkbox"][data-filter-type="aircraft-model"]')
    modelCheckboxes.forEach(cb => cb.checked = false)
    
    // Reset quick filter buttons
    if (this.quickDirectFlightTarget) {
      this.quickDirectFlightTarget.classList.remove("bg-yellow-100", "border-yellow-400", "text-yellow-800")
      this.quickDirectFlightTarget.classList.add("border-gray-300")
    }
    
    if (this.quickNoSharedFlightTarget) {
      this.quickNoSharedFlightTarget.classList.remove("bg-yellow-100", "border-yellow-400", "text-yellow-800")
      this.quickNoSharedFlightTarget.classList.add("border-gray-300")
    }
    
    if (this.quickCheckedLuggageTarget) {
      this.quickCheckedLuggageTarget.classList.remove("bg-yellow-100", "border-yellow-400", "text-yellow-800")
      this.quickCheckedLuggageTarget.classList.add("border-gray-300")
    }
    
    if (this.quickNoTransitTarget) {
      this.quickNoTransitTarget.classList.remove("bg-yellow-100", "border-yellow-400", "text-yellow-800")
      this.quickNoTransitTarget.classList.add("border-gray-300")
    }
    
    if (this.quickDiscountPriceTarget) {
      this.quickDiscountPriceTarget.classList.remove("bg-yellow-100", "border-yellow-400", "text-yellow-800")
      this.quickDiscountPriceTarget.classList.add("border-gray-300")
    }
    
    // Reset card visual states
    if (this.directFlightCardTarget) {
      this.directFlightCardTarget.classList.add("bg-[#f6f7f9]")
      this.directFlightCardTarget.classList.remove("bg-[#fff9e6]", "border-[0.5px]", "border-[#ffda80]")
      const checkmark = this.directFlightCardTarget.querySelector(".checkmark")
      if (checkmark) checkmark.remove()
    }
    
    if (this.noSharedFlightCardTarget) {
      this.noSharedFlightCardTarget.classList.add("bg-[#f6f7f9]")
      this.noSharedFlightCardTarget.classList.remove("bg-[#fff9e6]", "border-[0.5px]", "border-[#ffda80]")
      const checkmark = this.noSharedFlightCardTarget.querySelector(".checkmark")
      if (checkmark) checkmark.remove()
    }
    
    if (this.checkedLuggageCardTarget) {
      this.checkedLuggageCardTarget.classList.add("bg-[#f6f7f9]")
      this.checkedLuggageCardTarget.classList.remove("bg-[#fff9e6]", "border-[0.5px]", "border-[#ffda80]")
      const checkmark = this.checkedLuggageCardTarget.querySelector(".checkmark")
      if (checkmark) checkmark.remove()
    }
    
    if (this.noTransitCardTarget) {
      this.noTransitCardTarget.classList.add("bg-[#f6f7f9]")
      this.noTransitCardTarget.classList.remove("bg-[#fff9e6]", "border-[0.5px]", "border-[#ffda80]")
      const checkmark = this.noTransitCardTarget.querySelector(".checkmark")
      if (checkmark) checkmark.remove()
    }
    
    if (this.discountPriceCardTarget) {
      this.discountPriceCardTarget.classList.add("bg-[#f6f7f9]")
      this.discountPriceCardTarget.classList.remove("bg-[#fff9e6]", "border-[0.5px]", "border-[#ffda80]")
      const checkmark = this.discountPriceCardTarget.querySelector(".checkmark")
      if (checkmark) checkmark.remove()
    }
    
    this.updateResultCount()
  }

  // Apply filters and close modal
  confirm(): void {
    // In a real application, this would trigger filtering of the flight list
    // For now, we just close the modal
    this.closeModal()
    
    // Dispatch custom event for other controllers to listen to
    this.element.dispatchEvent(new CustomEvent('filters-applied', {
      detail: { filters: this.filters },
      bubbles: true
    }))
  }

  // Update result count (placeholder - in real app would count filtered flights)
  updateResultCount(): void {
    // Mock calculation - in real app would filter actual flight data
    let count = 66 // Base count from screenshot
    
    if (this.filters.directFlight) count = Math.floor(count * 0.7)
    if (this.filters.noTransit) count = Math.floor(count * 0.8)
    if (this.filters.airlines.size > 0) count = Math.floor(count * 0.6)
    if (this.filters.departureAirports.size > 0) count = Math.floor(count * 0.7)
    if (this.filters.arrivalAirports.size > 0) count = Math.floor(count * 0.7)
    if (this.filters.departureTimeRanges.size > 0) count = Math.floor(count * 0.5)
    if (this.filters.aircraftModels.size > 0) count = Math.floor(count * 0.6)
    
    this.resultCountTarget.textContent = count.toString()
    
    // Update filter badge
    this.updateFilterBadge()
    
    // Update selected filters display
    this.updateSelectedFiltersDisplay()
  }

  // Update filter badge count
  updateFilterBadge(): void {
    let activeFilterCount = 0
    
    // Count boolean filters
    if (this.filters.directFlight) activeFilterCount++
    if (this.filters.noTransit) activeFilterCount++
    if (this.filters.includeCheckedLuggage) activeFilterCount++
    if (this.filters.noSharedFlight) activeFilterCount++
    if (this.filters.discountPrice) activeFilterCount++
    
    // Count Set-based filters
    activeFilterCount += this.filters.airlines.size
    activeFilterCount += this.filters.departureAirports.size
    activeFilterCount += this.filters.arrivalAirports.size
    activeFilterCount += this.filters.departureTimeRanges.size
    activeFilterCount += this.filters.aircraftModels.size
    
    // Update badge display
    if (activeFilterCount > 0) {
      this.filterBadgeTarget.textContent = activeFilterCount.toString()
      this.filterBadgeTarget.classList.remove("hidden")
    } else {
      this.filterBadgeTarget.classList.add("hidden")
    }
  }

  // Update selected filters display
  updateSelectedFiltersDisplay(): void {
    const filterLabels: { text: string; type: string; value: string }[] = []
    
    // Add boolean filters
    const filterNameMap: { [key: string]: string } = {
      directFlight: "只看直飞",
      noSharedFlight: "不看共享航班",
      includeCheckedLuggage: "含托运行李额",
      noTransit: "无需过境签",
      discountPrice: "看优惠前价格"
    }
    
    if (this.filters.directFlight) {
      filterLabels.push({ text: filterNameMap.directFlight, type: "directFlight", value: "" })
    }
    if (this.filters.noSharedFlight) {
      filterLabels.push({ text: filterNameMap.noSharedFlight, type: "noSharedFlight", value: "" })
    }
    if (this.filters.includeCheckedLuggage) {
      filterLabels.push({ text: filterNameMap.includeCheckedLuggage, type: "includeCheckedLuggage", value: "" })
    }
    if (this.filters.noTransit) {
      filterLabels.push({ text: filterNameMap.noTransit, type: "noTransit", value: "" })
    }
    if (this.filters.discountPrice) {
      filterLabels.push({ text: filterNameMap.discountPrice, type: "discountPrice", value: "" })
    }
    
    // Add Set-based filters
    this.filters.airlines.forEach(airline => {
      filterLabels.push({ text: airline, type: "airline", value: airline })
    })
    
    this.filters.departureAirports.forEach(airport => {
      filterLabels.push({ text: airport, type: "departureAirport", value: airport })
    })
    
    this.filters.arrivalAirports.forEach(airport => {
      filterLabels.push({ text: airport, type: "arrivalAirport", value: airport })
    })
    
    this.filters.departureTimeRanges.forEach(range => {
      filterLabels.push({ text: range, type: "departureTime", value: range })
    })
    
    this.filters.aircraftModels.forEach(model => {
      filterLabels.push({ text: model, type: "aircraftModel", value: model })
    })
    
    // Clear existing filter tags
    this.selectedFiltersListTarget.innerHTML = ""
    
    // Show/hide container based on whether there are filters
    if (filterLabels.length > 0) {
      this.selectedFiltersContainerTarget.classList.remove("hidden")
      
      // Create and append filter tags
      filterLabels.forEach(filter => {
        const tag = document.createElement("button")
        tag.className = "inline-flex items-center gap-1 px-2 py-1 bg-yellow-100 text-yellow-800 text-xs rounded-full border border-yellow-300 hover:bg-yellow-200"
        tag.dataset.filterType = filter.type
        tag.dataset.filterValue = filter.value
        tag.innerHTML = `
          ${filter.text}
          <svg class="w-3 h-3" fill="currentColor" viewBox="0 0 20 20">
            <path fill-rule="evenodd"
              d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0
                -1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z"
              clip-rule="evenodd"/>
          </svg>
        `
        tag.addEventListener("click", () => this.removeFilter(filter.type, filter.value))
        this.selectedFiltersListTarget.appendChild(tag)
      })
    } else {
      this.selectedFiltersContainerTarget.classList.add("hidden")
    }
  }

  // Remove a single filter
  removeFilter(type: string, value: string): void {
    switch(type) {
      case "directFlight":
        this.filters.directFlight = false
        this.directFlightCheckboxTarget.checked = false
        if (this.quickDirectFlightTarget) {
          this.quickDirectFlightTarget.classList.remove("bg-yellow-100", "border-yellow-400", "text-yellow-800")
          this.quickDirectFlightTarget.classList.add("border-gray-300")
        }
        if (this.directFlightCardTarget) {
          this.directFlightCardTarget.classList.add("bg-[#f6f7f9]")
          this.directFlightCardTarget.classList.remove("bg-[#fff9e6]", "border-[0.5px]", "border-[#ffda80]")
          const checkmark = this.directFlightCardTarget.querySelector(".checkmark")
          if (checkmark) checkmark.remove()
        }
        break
      case "noSharedFlight":
        this.filters.noSharedFlight = false
        this.noSharedFlightCheckboxTarget.checked = false
        if (this.quickNoSharedFlightTarget) {
          this.quickNoSharedFlightTarget.classList.remove("bg-yellow-100", "border-yellow-400", "text-yellow-800")
          this.quickNoSharedFlightTarget.classList.add("border-gray-300")
        }
        if (this.noSharedFlightCardTarget) {
          this.noSharedFlightCardTarget.classList.add("bg-[#f6f7f9]")
          this.noSharedFlightCardTarget.classList.remove("bg-[#fff9e6]", "border-[0.5px]", "border-[#ffda80]")
          const checkmark = this.noSharedFlightCardTarget.querySelector(".checkmark")
          if (checkmark) checkmark.remove()
        }
        break
      case "includeCheckedLuggage":
        this.filters.includeCheckedLuggage = false
        this.includeCheckedLuggageCheckboxTarget.checked = false
        if (this.quickCheckedLuggageTarget) {
          this.quickCheckedLuggageTarget.classList.remove("bg-yellow-100", "border-yellow-400", "text-yellow-800")
          this.quickCheckedLuggageTarget.classList.add("border-gray-300")
        }
        if (this.checkedLuggageCardTarget) {
          this.checkedLuggageCardTarget.classList.add("bg-[#f6f7f9]")
          this.checkedLuggageCardTarget.classList.remove("bg-[#fff9e6]", "border-[0.5px]", "border-[#ffda80]")
          const checkmark = this.checkedLuggageCardTarget.querySelector(".checkmark")
          if (checkmark) checkmark.remove()
        }
        break
      case "noTransit":
        this.filters.noTransit = false
        this.noTransitCheckboxTarget.checked = false
        if (this.quickNoTransitTarget) {
          this.quickNoTransitTarget.classList.remove("bg-yellow-100", "border-yellow-400", "text-yellow-800")
          this.quickNoTransitTarget.classList.add("border-gray-300")
        }
        if (this.noTransitCardTarget) {
          this.noTransitCardTarget.classList.add("bg-[#f6f7f9]")
          this.noTransitCardTarget.classList.remove("bg-[#fff9e6]", "border-[0.5px]", "border-[#ffda80]")
          const checkmark = this.noTransitCardTarget.querySelector(".checkmark")
          if (checkmark) checkmark.remove()
        }
        break
      case "discountPrice":
        this.filters.discountPrice = false
        this.discountPriceCheckboxTarget.checked = false
        if (this.quickDiscountPriceTarget) {
          this.quickDiscountPriceTarget.classList.remove("bg-yellow-100", "border-yellow-400", "text-yellow-800")
          this.quickDiscountPriceTarget.classList.add("border-gray-300")
        }
        if (this.discountPriceCardTarget) {
          this.discountPriceCardTarget.classList.add("bg-[#f6f7f9]")
          this.discountPriceCardTarget.classList.remove("bg-[#fff9e6]", "border-[0.5px]", "border-[#ffda80]")
          const checkmark = this.discountPriceCardTarget.querySelector(".checkmark")
          if (checkmark) checkmark.remove()
        }
        break
      case "airline": {
        this.filters.airlines.delete(value)
        const airlineCheckbox = this.element.querySelector<HTMLInputElement>(`input[type="checkbox"][data-filter-type="airline"][value="${value}"]`)
        if (airlineCheckbox) airlineCheckbox.checked = false
        break
      }
      case "departureAirport": {
        this.filters.departureAirports.delete(value)
        const depAirportCheckbox = this.element.querySelector<HTMLInputElement>(`input[type="checkbox"][data-filter-type="airport"][value="${value}"]`)
        if (depAirportCheckbox) depAirportCheckbox.checked = false
        break
      }
      case "arrivalAirport": {
        this.filters.arrivalAirports.delete(value)
        const arrAirportCheckbox = this.element.querySelector<HTMLInputElement>(`input[type="checkbox"][data-filter-type="airport"][value="${value}"]`)
        if (arrAirportCheckbox) arrAirportCheckbox.checked = false
        break
      }
      case "departureTime": {
        this.filters.departureTimeRanges.delete(value)
        const timeCheckbox = this.element.querySelector<HTMLInputElement>(`input[type="checkbox"][data-filter-type="departure-time"][value="${value}"]`)
        if (timeCheckbox) timeCheckbox.checked = false
        break
      }
      case "aircraftModel": {
        this.filters.aircraftModels.delete(value)
        const modelCheckbox = this.element.querySelector<HTMLInputElement>(`input[type="checkbox"][data-filter-type="aircraft-model"][value="${value}"]`)
        if (modelCheckbox) modelCheckbox.checked = false
        break
      }
    }
    
    this.updateResultCount()
  }

  // Helper method to create checkmark SVG
  private createCheckmark(): SVGElement {
    const svg = document.createElementNS("http://www.w3.org/2000/svg", "svg")
    svg.setAttribute("class", "checkmark absolute bottom-0 right-0")
    svg.setAttribute("width", "16")
    svg.setAttribute("height", "16")
    svg.setAttribute("viewBox", "0 0 24 24")
    
    // Background triangle
    const bgPath = document.createElementNS("http://www.w3.org/2000/svg", "path")
    bgPath.setAttribute("d", "M24 24H0L24 0V24Z")
    bgPath.setAttribute("fill", "#fcc32a")
    svg.appendChild(bgPath)
    
    // Checkmark path
    const checkPath = document.createElementNS("http://www.w3.org/2000/svg", "path")
    checkPath.setAttribute("d", "M14 18l2 2 4-4")
    checkPath.setAttribute("stroke", "white")
    checkPath.setAttribute("stroke-width", "2")
    checkPath.setAttribute("stroke-linecap", "round")
    checkPath.setAttribute("stroke-linejoin", "round")
    checkPath.setAttribute("fill", "none")
    svg.appendChild(checkPath)
    
    return svg
  }
}
