import { Controller } from "@hotwired/stimulus"

interface SearchHistory {
  departure_city: string
  destination_city: string
  date: string
  timestamp: number
}

export default class extends Controller<HTMLElement> {
  static targets = ["container", "list"]

  declare readonly containerTarget: HTMLElement
  declare readonly listTarget: HTMLElement
  declare readonly hasContainerTarget: boolean
  declare readonly hasListTarget: boolean

  private maxHistoryItems: number = 5

  connect(): void {
    console.log("BusTicketHistory connected")
    
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
      timestamp: Date.now()
    }
    
    this.addToHistory(searchData)
  }

  private addToHistory(searchData: SearchHistory): void {
    let history = this.getHistory()
    
    // Remove duplicate if exists (same departure and destination)
    history = history.filter(item => 
      !(item.departure_city === searchData.departure_city && 
        item.destination_city === searchData.destination_city)
    )
    
    // Add new search at the beginning
    history.unshift(searchData)
    
    // Keep only the most recent items
    history = history.slice(0, this.maxHistoryItems)
    
    localStorage.setItem('bus_search_history', JSON.stringify(history))
  }

  private getHistory(): SearchHistory[] {
    const historyStr = localStorage.getItem('bus_search_history')
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
      // Build URL with parameters
      const params = new URLSearchParams({
        departure_city: item.departure_city,
        destination_city: item.destination_city,
        date: item.date
      })
      
      const url = `/bus_tickets/search?${params.toString()}`
      
      return `
        <a href="${url}" 
           class="inline-block whitespace-nowrap px-3 py-1.5 rounded-full bg-gray-100 text-sm text-gray-600 hover:bg-blue-50 hover:text-blue-600 transition-colors">
          ${item.departure_city} → ${item.destination_city}
        </a>
      `
    }).join('')
    
    this.listTarget.innerHTML = historyHTML
  }

  // 清除历史记录
  clearHistory(event: Event): void {
    event.preventDefault()
    event.stopPropagation()
    
    localStorage.removeItem('bus_search_history')
    
    if (this.hasContainerTarget && this.hasListTarget) {
      this.containerTarget.classList.add('hidden')
      this.listTarget.innerHTML = ''
    }
    
    // 显示toast提示
    if (typeof (window as any).showToast === 'function') {
      (window as any).showToast('历史记录已清除', 'success')
    }
  }

  // 显示精彩即将上线提示
  showComingSoon(event: Event): void {
    event.preventDefault()
    event.stopPropagation()
    
    if (typeof (window as any).showToast === 'function') {
      (window as any).showToast('精彩即将上线', 'info')
    } else {
      console.warn('showToast function not available')
      alert('精彩即将上线')
    }
  }
}
