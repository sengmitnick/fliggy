import { Controller } from "@hotwired/stimulus"

interface SearchHistory {
  departure_city: string
  destination_city: string
  date: string
  return_date?: string
  trip_type: string
  cabin_class?: string
  timestamp: number
}

export default class extends Controller {
  static targets = ["container", "list"]

  declare readonly containerTarget: HTMLElement
  declare readonly listTarget: HTMLElement
  declare readonly hasContainerTarget: boolean
  declare readonly hasListTarget: boolean

  private maxHistoryItems: number = 5

  connect(): void {
    // Check if targets exist before rendering
    if (this.hasContainerTarget && this.hasListTarget) {
      this.renderHistory()
    }
  }

  // Save current search to history when form is submitted
  saveSearch(event: Event): void {
    const form = event.target as HTMLFormElement
    const formData = new FormData(form)
    
    const searchData: SearchHistory = {
      departure_city: formData.get('departure_city') as string,
      destination_city: formData.get('destination_city') as string,
      date: formData.get('date') as string,
      return_date: formData.get('return_date') as string || undefined,
      trip_type: formData.get('trip_type') as string,
      cabin_class: formData.get('cabin_class') as string || undefined,
      timestamp: Date.now()
    }
    
    this.addToHistory(searchData)
  }

  private addToHistory(searchData: SearchHistory): void {
    let history = this.getHistory()
    
    // Remove duplicate if exists (same departure, destination, and date)
    history = history.filter(item => 
      !(item.departure_city === searchData.departure_city && 
        item.destination_city === searchData.destination_city &&
        item.date === searchData.date)
    )
    
    // Add new search at the beginning
    history.unshift(searchData)
    
    // Keep only the most recent items
    history = history.slice(0, this.maxHistoryItems)
    
    localStorage.setItem('flight_search_history', JSON.stringify(history))
  }

  private getHistory(): SearchHistory[] {
    const historyStr = localStorage.getItem('flight_search_history')
    if (!historyStr) return []
    
    try {
      return JSON.parse(historyStr)
    } catch {
      return []
    }
  }

  private renderHistory(): void {
    // Check if targets exist
    if (!this.hasContainerTarget || !this.hasListTarget) {
      return
    }

    const history = this.getHistory()
    
    if (history.length === 0) {
      this.containerTarget.classList.add('hidden')
      return
    }
    
    this.containerTarget.classList.remove('hidden')
    
    const historyHTML = history.map(item => {
      const date = new Date(item.date)
      const dateStr = `${date.getMonth() + 1}/${date.getDate()}`
      const tripTypeText = item.trip_type === 'round_trip' ? '往返' : '单程'
      
      // Build URL with parameters
      const params = new URLSearchParams({
        departure_city: item.departure_city,
        destination_city: item.destination_city,
        date: item.date,
        trip_type: item.trip_type
      })
      
      if (item.return_date) {
        params.append('return_date', item.return_date)
      }
      
      if (item.cabin_class) {
        params.append('cabin_class', item.cabin_class)
      }
      
      const url = `/flights/search?${params.toString()}`
      
      return `
        <a href="${url}" 
           class="inline-block whitespace-nowrap px-3 py-1.5 rounded-full bg-gray-100 text-sm text-gray-600 hover:bg-blue-50 hover:text-blue-600 transition-colors">
          ${item.departure_city} → ${item.destination_city}  ${dateStr}  ${tripTypeText}
        </a>
      `
    }).join('')
    
    this.listTarget.innerHTML = historyHTML
  }

  clearHistory(event: Event): void {
    event.preventDefault()
    event.stopPropagation()
    
    localStorage.removeItem('flight_search_history')
    
    if (this.hasContainerTarget && this.hasListTarget) {
      this.containerTarget.classList.add('hidden')
      this.listTarget.innerHTML = ''
    }
  }
}
