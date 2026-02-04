import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = [
    "trainItem",
    "modal",
    "filterButton",
    "advancedFilterButton",
    "filterBadge",
    "departureStartTime",
    "departureEndTime",
    "arrivalStartTime",
    "arrivalEndTime",
    "departureTimeStart",
    "departureTimeEnd",
    "arrivalTimeStart",
    "arrivalTimeEnd"
  ]

  declare readonly trainItemTargets: HTMLElement[]
  declare readonly modalTarget: HTMLElement
  declare readonly filterButtonTargets: HTMLElement[]
  declare readonly advancedFilterButtonTarget: HTMLButtonElement
  declare readonly filterBadgeTarget: HTMLSpanElement
  declare readonly departureStartTimeTarget: HTMLSpanElement
  declare readonly departureEndTimeTarget: HTMLSpanElement
  declare readonly arrivalStartTimeTarget: HTMLSpanElement
  declare readonly arrivalEndTimeTarget: HTMLSpanElement
  declare readonly departureTimeStartTarget: HTMLInputElement
  declare readonly departureTimeEndTarget: HTMLInputElement
  declare readonly arrivalTimeStartTarget: HTMLInputElement
  declare readonly arrivalTimeEndTarget: HTMLInputElement

  private selectedFilters = new Set<string>()

  connect(): void {
    console.log("TrainList connected")
  }

  disconnect(): void {
    console.log("TrainList disconnected")
  }

  toggleFilter(event: Event): void {
    const button = event.currentTarget as HTMLButtonElement
    const filter = button.dataset.filter!
    this.toggleFilterButton(button, filter)
  }

  toggleStation(event: Event): void {
    const button = event.currentTarget as HTMLButtonElement
    const station = button.dataset.station!
    this.toggleFilterButton(button, station)
  }

  showAdvancedFilters(): void {
    this.modalTarget.classList.remove('hidden')
    document.body.style.overflow = 'hidden'
  }

  closeModal(): void {
    this.modalTarget.classList.add('hidden')
    document.body.style.overflow = ''
  }

  toggleTrainType(event: Event): void {
    const button = event.currentTarget as HTMLButtonElement
    const type = button.dataset.type!
    this.toggleFilterButton(button, type)
  }

  toggleSeatType(event: Event): void {
    const button = event.currentTarget as HTMLButtonElement
    const seat = button.dataset.seat!
    this.toggleFilterButton(button, seat)
  }

  toggleMoreFilter(event: Event): void {
    const button = event.currentTarget as HTMLButtonElement
    const filter = button.dataset.filter!
    this.toggleFilterButton(button, filter)
  }

  private toggleFilterButton(button: HTMLButtonElement, value: string): void {
    if (this.selectedFilters.has(value)) {
      this.selectedFilters.delete(value)
      button.classList.remove('bg-primary', 'text-primary-foreground', 'border-primary')
      button.classList.add('border-border')
    } else {
      this.selectedFilters.add(value)
      button.classList.add('bg-primary', 'text-primary-foreground', 'border-primary')
      button.classList.remove('border-border')
    }
    this.updateAdvancedFilterIndicator()
  }

  updateDepartureStartTime(): void {
    const minutes = parseInt(this.departureTimeStartTarget.value)
    const endMinutes = parseInt(this.departureTimeEndTarget.value)
    
    // Ensure start doesn't exceed end
    if (minutes > endMinutes) {
      this.departureTimeStartTarget.value = endMinutes.toString()
      return
    }
    
    this.departureStartTimeTarget.textContent = this.formatMinutesToTime(minutes)
  }

  updateDepartureEndTime(): void {
    const minutes = parseInt(this.departureTimeEndTarget.value)
    const startMinutes = parseInt(this.departureTimeStartTarget.value)
    
    // Ensure end doesn't go below start
    if (minutes < startMinutes) {
      this.departureTimeEndTarget.value = startMinutes.toString()
      return
    }
    
    this.departureEndTimeTarget.textContent = this.formatMinutesToTime(minutes)
  }

  updateArrivalStartTime(): void {
    const minutes = parseInt(this.arrivalTimeStartTarget.value)
    const endMinutes = parseInt(this.arrivalTimeEndTarget.value)
    
    // Ensure start doesn't exceed end
    if (minutes > endMinutes) {
      this.arrivalTimeStartTarget.value = endMinutes.toString()
      return
    }
    
    this.arrivalStartTimeTarget.textContent = this.formatMinutesToTime(minutes)
  }

  updateArrivalEndTime(): void {
    const minutes = parseInt(this.arrivalTimeEndTarget.value)
    const startMinutes = parseInt(this.arrivalTimeStartTarget.value)
    
    // Ensure end doesn't go below start
    if (minutes < startMinutes) {
      this.arrivalTimeEndTarget.value = startMinutes.toString()
      return
    }
    
    this.arrivalEndTimeTarget.textContent = this.formatMinutesToTime(minutes)
  }

  private formatMinutesToTime(minutes: number): string {
    const hours = Math.floor(minutes / 60)
    const mins = minutes % 60
    return `${hours.toString().padStart(2, '0')}:${mins.toString().padStart(2, '0')}`
  }

  clearFilters(): void {
    this.selectedFilters.clear()
    this.filterButtonTargets.forEach(button => {
      button.classList.remove('bg-primary', 'text-primary-foreground', 'border-primary')
      button.classList.add('border-border')
    })
    this.updateAdvancedFilterIndicator()
    console.log('Filters cleared')
  }

  applyFilters(): void {
    console.log('Selected filters:', Array.from(this.selectedFilters))
    // Will implement actual filtering logic later
    // For now, just close the modal
    this.closeModal()
    
    // Show a toast message
    if (typeof window.showToast === 'function') {
      window.showToast(`已应用 ${this.selectedFilters.size} 个筛选条件`)
    }
  }

  private updateAdvancedFilterIndicator(): void {
    if (this.selectedFilters.size > 0) {
      // Add active state styling
      this.advancedFilterButtonTarget.classList.add('text-primary', 'bg-primary/10', 'border-t-2', 'border-primary')
      this.advancedFilterButtonTarget.classList.remove('text-foreground')
      // Show badge
      this.filterBadgeTarget.classList.remove('hidden')
    } else {
      // Remove active state styling
      this.advancedFilterButtonTarget.classList.remove('text-primary', 'bg-primary/10', 'border-t-2', 'border-primary')
      this.advancedFilterButtonTarget.classList.add('text-foreground')
      // Hide badge
      this.filterBadgeTarget.classList.add('hidden')
    }
  }
}
