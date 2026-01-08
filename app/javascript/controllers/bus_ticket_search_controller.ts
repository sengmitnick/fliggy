import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = [
    "modal",
    "overlay",
    "applyButton",
    // Tab targets
    "departureTimeTab",
    "seatTypeTab",
    "departureStationTab",
    "arrivalStationTab",
    // Section targets
    "departureTimeSection",
    "seatTypeSection",
    "departureStationSection",
    "arrivalStationSection",
    // Filter option targets
    "timeSlot",
    "seatType",
    "departureStation",
    "arrivalStation"
  ]

  declare readonly modalTarget: HTMLDivElement
  declare readonly overlayTarget: HTMLDivElement
  declare readonly applyButtonTarget: HTMLButtonElement
  
  declare readonly departureTimeTabTarget: HTMLButtonElement
  declare readonly seatTypeTabTarget: HTMLButtonElement
  declare readonly departureStationTabTarget: HTMLButtonElement
  declare readonly arrivalStationTabTarget: HTMLButtonElement
  
  declare readonly departureTimeSectionTarget: HTMLDivElement
  declare readonly seatTypeSectionTarget: HTMLDivElement
  declare readonly departureStationSectionTarget: HTMLDivElement
  declare readonly arrivalStationSectionTarget: HTMLDivElement
  
  declare readonly timeSlotTargets: HTMLDivElement[]
  declare readonly seatTypeTargets: HTMLDivElement[]
  declare readonly departureStationTargets: HTMLDivElement[]
  declare readonly arrivalStationTargets: HTMLDivElement[]

  private selectedFilters: {
      timeSlots: Set<string>
      seatTypes: Set<string>
      departureStations: Set<string>
      arrivalStations: Set<string>
    } = {
      timeSlots: new Set(),
      seatTypes: new Set(),
      departureStations: new Set(),
      arrivalStations: new Set()
    }

  connect(): void {
    console.log("Bus ticket search controller connected")
  }

  openFilter(event: Event): void {
    event.preventDefault()
    this.modalTarget.classList.remove("hidden")
    this.overlayTarget.classList.remove("hidden")
    document.body.style.overflow = "hidden"
  }

  closeModal(event?: Event): void {
    if (event) event.preventDefault()
    this.modalTarget.classList.add("hidden")
    this.overlayTarget.classList.add("hidden")
    document.body.style.overflow = ""
  }

  selectTab(event: Event): void {
    const button = event.currentTarget as HTMLButtonElement
    const tab = button.dataset.tab
    
    if (!tab) return

    // Update tab buttons
    const allTabs = [
      this.departureTimeTabTarget,
      this.seatTypeTabTarget,
      this.departureStationTabTarget,
      this.arrivalStationTabTarget
    ]
    
    allTabs.forEach(t => {
      t.classList.remove("bg-white", "border-[#FFD900]", "font-medium", "text-gray-900")
      t.classList.add("border-transparent", "text-gray-600")
    })
    
    button.classList.remove("border-transparent", "text-gray-600")
    button.classList.add("bg-white", "border-[#FFD900]", "font-medium", "text-gray-900")

    // Update sections
    const allSections = [
      this.departureTimeSectionTarget,
      this.seatTypeSectionTarget,
      this.departureStationSectionTarget,
      this.arrivalStationSectionTarget
    ]
    
    allSections.forEach(s => s.classList.add("hidden"))
    
    switch (tab) {
      case "departureTime":
        this.departureTimeSectionTarget.classList.remove("hidden")
        break
      case "seatType":
        this.seatTypeSectionTarget.classList.remove("hidden")
        break
      case "departureStation":
        this.departureStationSectionTarget.classList.remove("hidden")
        break
      case "arrivalStation":
        this.arrivalStationSectionTarget.classList.remove("hidden")
        break
    }
  }

  toggleTimeSlot(event: Event): void {
    const element = event.currentTarget as HTMLDivElement
    const value = element.dataset.value
    
    if (!value) return

    if (this.selectedFilters.timeSlots.has(value)) {
      this.selectedFilters.timeSlots.delete(value)
      element.classList.remove("bg-[#FFD900]", "font-bold")
      element.classList.add("bg-[#F7F8FA]")
    } else {
      this.selectedFilters.timeSlots.add(value)
      element.classList.remove("bg-[#F7F8FA]")
      element.classList.add("bg-[#FFD900]", "font-bold")
    }
    
    this.updateApplyButton()
  }

  toggleSeatType(event: Event): void {
    const element = event.currentTarget as HTMLDivElement
    const value = element.dataset.value
    
    if (!value) return

    if (this.selectedFilters.seatTypes.has(value)) {
      this.selectedFilters.seatTypes.delete(value)
      element.classList.remove("bg-[#FFD900]", "font-bold")
      element.classList.add("bg-[#F7F8FA]")
    } else {
      this.selectedFilters.seatTypes.add(value)
      element.classList.remove("bg-[#F7F8FA]")
      element.classList.add("bg-[#FFD900]", "font-bold")
    }
    
    this.updateApplyButton()
  }

  toggleDepartureStation(event: Event): void {
    const element = event.currentTarget as HTMLDivElement
    const value = element.dataset.value
    
    if (!value) return

    if (this.selectedFilters.departureStations.has(value)) {
      this.selectedFilters.departureStations.delete(value)
      element.classList.remove("bg-[#FFD900]", "font-bold")
      element.classList.add("bg-[#F7F8FA]")
    } else {
      this.selectedFilters.departureStations.add(value)
      element.classList.remove("bg-[#F7F8FA]")
      element.classList.add("bg-[#FFD900]", "font-bold")
    }
    
    this.updateApplyButton()
  }

  toggleArrivalStation(event: Event): void {
    const element = event.currentTarget as HTMLDivElement
    const value = element.dataset.value
    
    if (!value) return

    if (this.selectedFilters.arrivalStations.has(value)) {
      this.selectedFilters.arrivalStations.delete(value)
      element.classList.remove("bg-[#FFD900]", "font-bold")
      element.classList.add("bg-[#F7F8FA]")
    } else {
      this.selectedFilters.arrivalStations.add(value)
      element.classList.remove("bg-[#F7F8FA]")
      element.classList.add("bg-[#FFD900]", "font-bold")
    }
    
    this.updateApplyButton()
  }

  resetFilters(event: Event): void {
    event.preventDefault()
    
    // Clear all selected filters
    this.selectedFilters = {
      timeSlots: new Set(),
      seatTypes: new Set(),
      departureStations: new Set(),
      arrivalStations: new Set()
    }
    
    // Reset UI
    const allOptions = [
      ...this.timeSlotTargets,
      ...this.seatTypeTargets,
      ...this.departureStationTargets,
      ...this.arrivalStationTargets
    ]
    
    allOptions.forEach(option => {
      option.classList.remove("bg-[#FFD900]", "font-bold")
      option.classList.add("bg-[#F7F8FA]")
    })
    
    this.updateApplyButton()
  }

  applyFilters(event: Event): void {
    event.preventDefault()
    
    // Build filter query string
    const params = new URLSearchParams(window.location.search)
    
    // Clear existing filter params
    params.delete("time_slots")
    params.delete("seat_types")
    params.delete("departure_stations")
    params.delete("arrival_stations")
    
    // Add new filter params
    if (this.selectedFilters.timeSlots.size > 0) {
      params.set("time_slots", Array.from(this.selectedFilters.timeSlots).join(","))
    }
    
    if (this.selectedFilters.seatTypes.size > 0) {
      params.set("seat_types", Array.from(this.selectedFilters.seatTypes).join(","))
    }
    
    if (this.selectedFilters.departureStations.size > 0) {
      params.set("departure_stations", Array.from(this.selectedFilters.departureStations).join(","))
    }
    
    if (this.selectedFilters.arrivalStations.size > 0) {
      params.set("arrival_stations", Array.from(this.selectedFilters.arrivalStations).join(","))
    }
    
    // Redirect with filters
    window.location.href = `${window.location.pathname}?${params.toString()}`
  }

  private updateApplyButton(): void {
    const totalFilters = 
      this.selectedFilters.timeSlots.size +
      this.selectedFilters.seatTypes.size +
      this.selectedFilters.departureStations.size +
      this.selectedFilters.arrivalStations.size
    
    if (totalFilters > 0) {
      this.applyButtonTarget.textContent = `查看筛选结果`
    } else {
      this.applyButtonTarget.textContent = "查看结果"
    }
  }
}
