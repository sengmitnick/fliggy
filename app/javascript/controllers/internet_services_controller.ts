import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = [
    "regionModal",
    "regionDisplay", 
    "searchInput",
    "searchResults",
    "selectorTab",
    "popularSection",
    "historySection",
    "continentBtn",
    "continentSection"
  ]

  declare readonly regionModalTarget: HTMLElement
  declare readonly regionDisplayTarget: HTMLElement
  declare readonly searchInputTarget: HTMLInputElement
  declare readonly searchResultsTarget: HTMLElement
  declare readonly selectorTabTargets: HTMLElement[]
  declare readonly popularSectionTarget: HTMLElement
  declare readonly historySectionTarget: HTMLElement
  declare readonly continentBtnTargets: HTMLElement[]
  declare readonly continentSectionTargets: HTMLElement[]

  private currentContinent: string = 'asia'
  private currentTab: string = 'popular'
  private destinationHistory: string[] = []

  connect(): void {
    console.log("InternetServices connected")
    this.loadHistory()
  }

  openRegionModal(event: Event): void {
    event.preventDefault()
    this.regionModalTarget.classList.remove('hidden')
    // Reset to default view
    this.showContinent('asia')
    this.switchSelectorTab({currentTarget: this.selectorTabTargets[0]} as any)
  }

  closeRegionModal(): void {
    this.regionModalTarget.classList.add('hidden')
    // Clear search
    this.searchInputTarget.value = ''
    this.searchResultsTarget.classList.add('hidden')
  }

  selectDestination(event: Event): void {
    const target = event.currentTarget as HTMLElement
    const destination = target.dataset.destination
    
    if (destination) {
      // Save to history
      this.saveToHistory(destination)
      // Turbo Drive will handle navigation
      // Close modal
      this.closeRegionModal()
    }
  }

  selectRegion(event: Event): void {
    // Backward compatibility method
    this.selectDestination(event)
  }

  switchTab(event: Event): void {
    // Product tab switching (境外电话卡, 境外流量包, etc.)
    // Turbo Drive handles navigation automatically
  }

  switchSelectorTab(event: Event): void {
    const button = event.currentTarget as HTMLElement
    const tab = button.dataset.tab || 'popular'
    
    // Update tab active states
    this.selectorTabTargets.forEach(tabBtn => {
      if (tabBtn === button) {
        tabBtn.classList.add('border-black', 'text-black')
        tabBtn.classList.remove('text-gray-500')
      } else {
        tabBtn.classList.remove('border-black', 'text-black')
        tabBtn.classList.add('text-gray-500')
      }
    })

    // Show/hide sections
    if (tab === 'popular') {
      this.popularSectionTarget.classList.remove('hidden')
      this.historySectionTarget.classList.add('hidden')
      this.searchResultsTarget.classList.add('hidden')
    } else {
      this.popularSectionTarget.classList.add('hidden')
      this.historySectionTarget.classList.remove('hidden')
      this.searchResultsTarget.classList.add('hidden')
      this.renderHistory()
    }

    this.currentTab = tab
  }

  selectContinent(event: Event): void {
    const button = event.currentTarget as HTMLElement
    const continent = button.dataset.continent || 'asia'
    
    this.showContinent(continent)
  }

  private showContinent(continent: string): void {
    // Update continent button states
    this.continentBtnTargets.forEach(btn => {
      if (btn.dataset.continent === continent) {
        btn.classList.add('bg-white', 'font-bold', 'border-l-2', 'border-yellow-500')
        btn.classList.remove('text-gray-600')
      } else {
        btn.classList.remove('bg-white', 'font-bold', 'border-l-2', 'border-yellow-500')
        btn.classList.add('text-gray-600')
      }
    })

    // Show/hide continent sections
    this.continentSectionTargets.forEach(section => {
      const sectionContinent = section.dataset.continent
      if (sectionContinent === continent) {
        section.classList.remove('hidden')
      } else {
        section.classList.add('hidden')
      }
    })

    this.currentContinent = continent
  }

  searchDestinations(event: Event): void {
    const query = this.searchInputTarget.value.trim().toLowerCase()

    if (query === '') {
      // Show current tab content
      this.searchResultsTarget.classList.add('hidden')
      if (this.currentTab === 'popular') {
        this.popularSectionTarget.classList.remove('hidden')
      } else {
        this.historySectionTarget.classList.remove('hidden')
      }
      return
    }

    // Hide regular sections, show search results
    this.popularSectionTarget.classList.add('hidden')
    this.historySectionTarget.classList.add('hidden')
    this.searchResultsTarget.classList.remove('hidden')

    // Get all destination links and filter
    const allDestLinks = this.popularSectionTarget.querySelectorAll('[data-destination]')
    const matchingDests: HTMLElement[] = []

    allDestLinks.forEach((link: Element) => {
      const htmlLink = link as HTMLElement
      const dest = htmlLink.dataset.destination || ''
      if (dest.toLowerCase().includes(query)) {
        matchingDests.push(htmlLink)
      }
    })

    // Render search results
    if (matchingDests.length > 0) {
      const resultsHtml = `
        <h3 class="text-sm font-bold text-gray-500 mb-3">搜索结果 (${matchingDests.length})</h3>
        <div class="grid grid-cols-3 gap-3">
          ${matchingDests.map(link => link.outerHTML).join('')}
        </div>
      `
      this.searchResultsTarget.innerHTML = resultsHtml
    } else {
      this.searchResultsTarget.innerHTML = `
        <div class="text-center text-gray-400 py-12">
          <p>未找到匹配的目的地</p>
        </div>
      `
    }
  }

  clearHistory(event: Event): void {
    event.preventDefault()
    event.stopPropagation()
    
    if (confirm('确定要清空历史选择记录吗?')) {
      this.destinationHistory = []
      localStorage.removeItem('internet_services_destination_history')
      this.renderHistory()
    }
  }

  private saveToHistory(destination: string): void {
    // Remove if already exists (move to front)
    this.destinationHistory = this.destinationHistory.filter(d => d !== destination)
    // Add to front
    this.destinationHistory.unshift(destination)
    // Keep only last 20
    if (this.destinationHistory.length > 20) {
      this.destinationHistory = this.destinationHistory.slice(0, 20)
    }
    // Save to localStorage
    localStorage.setItem('internet_services_destination_history', JSON.stringify(this.destinationHistory))
  }

  private loadHistory(): void {
    const stored = localStorage.getItem('internet_services_destination_history')
    if (stored) {
      try {
        this.destinationHistory = JSON.parse(stored)
      } catch (e) {
        this.destinationHistory = []
      }
    }
  }

  private renderHistory(): void {
    if (this.destinationHistory.length === 0) {
      this.historySectionTarget.innerHTML = `
        <div class="text-center text-gray-400 py-12">
          <svg class="w-16 h-16 mx-auto mb-4 text-gray-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path>
          </svg>
          <p>暂无历史选择记录</p>
        </div>
      `
      return
    }

    // Get current region from URL or default
    const urlParams = new URLSearchParams(window.location.search)
    const currentRegion = urlParams.get('region') || '中国香港'
    const currentTab = urlParams.get('tab') || 'sim_card'

    const historyHtml = `
      <h3 class="text-sm font-bold text-gray-500 mb-3">最近选择</h3>
      <div class="grid grid-cols-3 gap-3">
        ${this.destinationHistory.map(dest => {
    const isSelected = dest === currentRegion
    return `
            <a href="/internet_services?region=${encodeURIComponent(dest)}&tab=${currentTab}" 
               data-action="click->internet-services#selectDestination" 
               data-destination="${dest}"
               class="p-3 text-center rounded-lg border-2 transition-all ${
  isSelected 
    ? 'border-yellow-500 bg-yellow-50 font-bold text-yellow-600' 
    : 'border-gray-200 hover:border-yellow-300'
}">
              <div class="flex items-center justify-center">
                <span class="text-sm">${dest}</span>
                ${isSelected ? `
                  <svg class="w-4 h-4 ml-1 text-yellow-500" fill="currentColor" viewBox="0 0 20 20">
                    <path fill-rule="evenodd"
                          d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
                          clip-rule="evenodd"/>
                  </svg>
                ` : ''}
              </div>
            </a>
          `
  }).join('')}
      </div>
    `
    this.historySectionTarget.innerHTML = historyHtml
  }
}
