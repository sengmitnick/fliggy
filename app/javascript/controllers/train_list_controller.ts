import { Controller } from "@hotwired/stimulus"
import * as Turbo from "@hotwired/turbo"

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
    this.restoreFiltersFromURL()
  }

  private restoreFiltersFromURL(): void {
    const url = new URL(window.location.href)
    
    // Restore train type filters
    const trainTypes = url.searchParams.get('train_types')
    if (trainTypes) {
      trainTypes.split(',').forEach(type => {
        this.selectedFilters.add(type)
        // Find and activate the button
        const button = this.filterButtonTargets.find(btn => 
          btn.dataset.type === type
        )
        if (button) {
          button.classList.add('bg-primary', 'text-primary-foreground', 'border-primary')
          button.classList.remove('border-border')
        }
      })
    }
    
    // Restore departure time range
    const depStart = url.searchParams.get('departure_time_start')
    const depEnd = url.searchParams.get('departure_time_end')
    if (depStart) {
      this.departureTimeStartTarget.value = depStart
      this.departureStartTimeTarget.textContent = this.formatMinutesToTime(parseInt(depStart))
    }
    if (depEnd) {
      this.departureTimeEndTarget.value = depEnd
      this.departureEndTimeTarget.textContent = this.formatMinutesToTime(parseInt(depEnd))
    }
    
    // Restore arrival time range
    const arrStart = url.searchParams.get('arrival_time_start')
    const arrEnd = url.searchParams.get('arrival_time_end')
    if (arrStart) {
      this.arrivalTimeStartTarget.value = arrStart
      this.arrivalStartTimeTarget.textContent = this.formatMinutesToTime(parseInt(arrStart))
    }
    if (arrEnd) {
      this.arrivalTimeEndTarget.value = arrEnd
      this.arrivalEndTimeTarget.textContent = this.formatMinutesToTime(parseInt(arrEnd))
    }
    
    // Update indicator badge
    this.updateAdvancedFilterIndicator()
  }

  disconnect(): void {
    console.log("TrainList disconnected")
  }

  toggleFilter(event: Event): void {
    const button = event.currentTarget as HTMLButtonElement
    const filter = button.dataset.filter!
    this.toggleFilterButton(button, filter)
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
    
    // Reset time sliders to default values
    this.departureTimeStartTarget.value = '0'
    this.departureTimeEndTarget.value = '1440'
    this.departureStartTimeTarget.textContent = '00:00'
    this.departureEndTimeTarget.textContent = '24:00'
    
    this.arrivalTimeStartTarget.value = '0'
    this.arrivalTimeEndTarget.value = '1440'
    this.arrivalStartTimeTarget.textContent = '00:00'
    this.arrivalEndTimeTarget.textContent = '24:00'
    
    this.updateAdvancedFilterIndicator()
    
    // Reload page without filter params (keep core search params only)
    const url = new URL(window.location.href)
    url.searchParams.delete('train_types')
    url.searchParams.delete('departure_time_start')
    url.searchParams.delete('departure_time_end')
    url.searchParams.delete('arrival_time_start')
    url.searchParams.delete('arrival_time_end')
    url.searchParams.delete('only_high_speed')
    
    this.closeModal()
    Turbo.visit(url.toString())
  }

  applyFilters(): void {
    // Build URL with current search params
    const url = new URL(window.location.href)
    
    // Preserve core search params (departure_city, arrival_city, date)
    // These are already in the URL from the initial search
    
    // Add train type filters
    const trainTypes = Array.from(this.selectedFilters).filter(f => 
      ['高铁(G)', '动车(D)', '城际(C/S)', '普通(Z/T/K)', '临时(L)/旅游(Y)'].includes(f)
    )
    if (trainTypes.length > 0) {
      url.searchParams.set('train_types', trainTypes.join(','))
    } else {
      url.searchParams.delete('train_types')
    }
    
    // Add departure time range
    const depStart = parseInt(this.departureTimeStartTarget.value)
    const depEnd = parseInt(this.departureTimeEndTarget.value)
    if (depStart > 0 || depEnd < 1440) {
      url.searchParams.set('departure_time_start', depStart.toString())
      url.searchParams.set('departure_time_end', depEnd.toString())
    } else {
      url.searchParams.delete('departure_time_start')
      url.searchParams.delete('departure_time_end')
    }
    
    // Add arrival time range
    const arrStart = parseInt(this.arrivalTimeStartTarget.value)
    const arrEnd = parseInt(this.arrivalTimeEndTarget.value)
    if (arrStart > 0 || arrEnd < 1440) {
      url.searchParams.set('arrival_time_start', arrStart.toString())
      url.searchParams.set('arrival_time_end', arrEnd.toString())
    } else {
      url.searchParams.delete('arrival_time_start')
      url.searchParams.delete('arrival_time_end')
    }
    
    // Remove legacy only_high_speed param (we now use train_types)
    url.searchParams.delete('only_high_speed')
    
    // Close modal and refresh page with Turbo
    this.closeModal()
    Turbo.visit(url.toString())
  }

  private updateAdvancedFilterIndicator(): void {
    // Count active filters (buttons + time ranges)
    let activeCount = this.selectedFilters.size
    
    // Check if time ranges are non-default
    const depStart = parseInt(this.departureTimeStartTarget.value)
    const depEnd = parseInt(this.departureTimeEndTarget.value)
    const arrStart = parseInt(this.arrivalTimeStartTarget.value)
    const arrEnd = parseInt(this.arrivalTimeEndTarget.value)
    
    if (depStart > 0 || depEnd < 1440) activeCount++
    if (arrStart > 0 || arrEnd < 1440) activeCount++
    
    if (activeCount > 0) {
      // Add active state styling
      this.advancedFilterButtonTarget.classList.add('text-primary', 'bg-primary/10', 'border-t-2', 'border-primary')
      this.advancedFilterButtonTarget.classList.remove('text-foreground')
      // Show badge with count
      this.filterBadgeTarget.classList.remove('hidden')
      this.filterBadgeTarget.textContent = activeCount.toString()
    } else {
      // Remove active state styling
      this.advancedFilterButtonTarget.classList.remove('text-primary', 'bg-primary/10', 'border-t-2', 'border-primary')
      this.advancedFilterButtonTarget.classList.add('text-foreground')
      // Hide badge
      this.filterBadgeTarget.classList.add('hidden')
    }
  }
}
