import { Controller } from "@hotwired/stimulus"

// Station data interface
interface Station {
  name: string
  nameEn: string
  city: string
}

// Station selection controller for abroad tickets
export default class extends Controller<HTMLElement> {
  static targets = [
    "form",
    "regionInput",
    "originInput",
    "destinationInput",
    "originText",
    "destinationText",
    "dateInput",
    "dateText",
    "stationModal",
    "stationList",
    "searchInput"
  ]

  static values = {
    currentDate: String
  }

  declare readonly formTarget: HTMLFormElement
  declare readonly regionInputTarget: HTMLInputElement
  declare readonly originInputTarget: HTMLInputElement
  declare readonly destinationInputTarget: HTMLInputElement
  declare readonly originTextTarget: HTMLElement
  declare readonly destinationTextTarget: HTMLElement
  declare readonly dateInputTarget: HTMLInputElement
  declare readonly dateTextTarget: HTMLElement
  declare readonly stationModalTarget: HTMLElement
  declare readonly stationListTarget: HTMLElement
  declare readonly searchInputTarget: HTMLInputElement
  declare currentDateValue: string

  private currentSelectionType: 'origin' | 'destination' = 'origin'
  private currentRegion: string = 'japan'

  // 日本站点数据
  private japanStations: Record<string, Station[]> = {
    '东京': [
      { name: '东京站', nameEn: 'Tokyo Station', city: '东京' },
      { name: '新宿站', nameEn: 'Shinjuku Station', city: '东京' },
      { name: '涩谷站', nameEn: 'Shibuya Station', city: '东京' },
      { name: '池袋站', nameEn: 'Ikebukuro Station', city: '东京' },
      { name: '品川站', nameEn: 'Shinagawa Station', city: '东京' }
    ],
    '大阪': [
      { name: '新大阪站', nameEn: 'Shin-Osaka Station', city: '大阪' },
      { name: '大阪站', nameEn: 'Osaka Station', city: '大阪' },
      { name: '难波站', nameEn: 'Namba Station', city: '大阪' },
      { name: '天王寺站', nameEn: 'Tennoji Station', city: '大阪' }
    ],
    '京都': [
      { name: '京都站', nameEn: 'Kyoto Station', city: '京都' },
      { name: '品川站', nameEn: 'Shinagawa Station', city: '京都' }
    ],
    '名古屋': [
      { name: '名古屋站', nameEn: 'Nagoya Station', city: '名古屋' }
    ],
    '仙台': [
      { name: '仙台站', nameEn: 'Sendai Station', city: '仙台' }
    ],
    '青森': [
      { name: '青森站', nameEn: 'Aomori Station', city: '青森' }
    ],
    '新潟': [
      { name: '新潟站', nameEn: 'Niigata Station', city: '新潟' }
    ],
    '广岛': [
      { name: '广岛站', nameEn: 'Hiroshima Station', city: '广岛' }
    ],
    '福冈': [
      { name: '博多站', nameEn: 'Hakata Station', city: '福冈' }
    ],
    '鹿儿岛': [
      { name: '鹿儿岛中央站', nameEn: 'Kagoshima-Chuo Station', city: '鹿儿岛' }
    ],
    '北海道': [
      { name: '札幌站', nameEn: 'Sapporo Station', city: '北海道' }
    ]
  }

  // 欧洲站点数据
  private europeStations: Record<string, Station[]> = {
    '法国': [
      { name: '巴黎北站', nameEn: 'Paris Nord', city: '法国' },
      { name: '巴黎里昂站', nameEn: 'Paris Gare de Lyon', city: '法国' },
      { name: '里昂站', nameEn: 'Lyon Station', city: '法国' },
      { name: '马赛站', nameEn: 'Marseille Station', city: '法国' }
    ],
    '荷兰': [
      { name: '阿姆斯特丹中央车站', nameEn: 'Amsterdam Centraal', city: '荷兰' },
      { name: '鹿特丹中央车站', nameEn: 'Rotterdam Centraal', city: '荷兰' }
    ],
    '德国': [
      { name: '柏林中央车站', nameEn: 'Berlin Hauptbahnhof', city: '德国' },
      { name: '慕尼黑中央车站', nameEn: 'München Hauptbahnhof', city: '德国' },
      { name: '法兰克福中央车站', nameEn: 'Frankfurt Hauptbahnhof', city: '德国' }
    ],
    '意大利': [
      { name: '罗马特米尼站', nameEn: 'Roma Termini', city: '意大利' },
      { name: '米兰中央车站', nameEn: 'Milano Centrale', city: '意大利' },
      { name: '佛罗伦萨圣母玛利亚车站', nameEn: 'Firenze Santa Maria Novella', city: '意大利' }
    ],
    '西班牙': [
      { name: '马德里阿托查站', nameEn: 'Madrid Atocha', city: '西班牙' },
      { name: '巴塞罗那桑斯站', nameEn: 'Barcelona Sants', city: '西班牙' }
    ]
  }

  // 热门线路
  private popularRoutes = {
    japan: [
      { origin: '东京站', destination: '京都站' },
      { origin: '东京站', destination: '新大阪站' }
    ],
    europe: [
      { origin: '巴黎北站', destination: '阿姆斯特丹中央车站' },
      { origin: '巴黎里昂站', destination: '罗马特米尼站' }
    ]
  }

  connect(): void {
    this.currentRegion = this.regionInputTarget.value
    console.log('Abroad ticket search controller connected')
  }

  selectRegion(event: Event): void {
    const button = event.currentTarget as HTMLElement
    const region = button.dataset.abroadTicketSearchRegionParam
    
    if (region && region !== this.currentRegion) {
      // Use Turbo.visit to reload the page with new region parameter
      // This keeps us on the index page instead of navigating to search
      const url = new URL(window.location.href)
      url.searchParams.set('region', region)
      window.Turbo.visit(url.toString())
    }
  }

  selectTicketType(event: Event): void {
    event.preventDefault()
    const button = event.currentTarget as HTMLButtonElement
    const ticketType = button.dataset.abroadTicketSearchTicketTypeParam
    
    // Update button styles
    const allButtons = button.parentElement?.querySelectorAll('button') || []
    allButtons.forEach(btn => {
      btn.classList.remove('bg-white', 'shadow-sm', 'font-bold')
      btn.classList.add('font-medium', 'text-gray-500')
    })
    
    button.classList.remove('font-medium', 'text-gray-500')
    button.classList.add('bg-white', 'shadow-sm', 'font-bold')
    
    // TODO: Handle ticket type change (train vs pass)
    console.log('Selected ticket type:', ticketType)
  }

  selectOrigin(event: Event): void {
    event.preventDefault()
    this.currentSelectionType = 'origin'
    this.openStationModal()
  }

  selectDestination(event: Event): void {
    event.preventDefault()
    this.currentSelectionType = 'destination'
    this.openStationModal()
  }

  swapStations(event: Event): void {
    event.preventDefault()
    
    const originValue = this.originInputTarget.value
    const destinationValue = this.destinationInputTarget.value
    
    this.originInputTarget.value = destinationValue
    this.destinationInputTarget.value = originValue
    
    this.originTextTarget.textContent = destinationValue
    this.destinationTextTarget.textContent = originValue
  }

  openDatePicker(event: Event): void {
    event.preventDefault()
    // Dispatch event to abroad-date-picker controller
    const customEvent = new CustomEvent('abroad-ticket-search:open-date-picker', {
      bubbles: true
    })
    this.element.dispatchEvent(customEvent)
  }

  updateDate(dateStr: string): void {
    // Update the date input and text display
    this.dateInputTarget.value = dateStr
    this.currentDateValue = dateStr
    
    // Update the date display text
    const date = new Date(`${dateStr}T00:00:00`)
    const month = date.getMonth() + 1
    const day = date.getDate()
    const weekdays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六']
    const weekday = weekdays[date.getDay()]
    
    this.dateTextTarget.textContent = `${month}月${day}日`
    
    // Update weekday if there's a sibling element
    const weekdayElement = this.dateTextTarget.nextElementSibling
    if (weekdayElement) {
      weekdayElement.textContent = weekday
    }
  }

  private openStationModal(): void {
    this.stationModalTarget.classList.remove('hidden')
    this.renderStationList()
    this.searchInputTarget.value = ''
    this.searchInputTarget.focus()
  }

  closeStationModal(): void {
    this.stationModalTarget.classList.add('hidden')
  }

  selectStation(event: Event): void {
    const element = event.currentTarget as HTMLElement
    const stationName = element.dataset.stationName
    const stationNameEn = element.dataset.stationNameEn
    
    if (!stationName) return
    
    if (this.currentSelectionType === 'origin') {
      this.originInputTarget.value = stationName
      this.originTextTarget.textContent = stationName
      // Update English name in the subtitle
      const subtitle = this.originTextTarget.nextElementSibling
      if (subtitle) {
        subtitle.textContent = stationNameEn || ''
      }
    } else {
      this.destinationInputTarget.value = stationName
      this.destinationTextTarget.textContent = stationName
      // Update English name in the subtitle
      const subtitle = this.destinationTextTarget.nextElementSibling
      if (subtitle) {
        subtitle.textContent = stationNameEn || ''
      }
    }
    
    this.closeStationModal()
  }

  searchStations(event: Event): void {
    const input = event.currentTarget as HTMLInputElement
    const query = input.value.trim().toLowerCase()
    
    this.renderStationList(query)
  }

  private renderStationList(searchQuery: string = ''): void {
    const stations = this.currentRegion === 'japan' ? this.japanStations : this.europeStations
    const popularRoutes = this.currentRegion === 'japan' ? this.popularRoutes.japan : this.popularRoutes.europe
    
    /* eslint-disable indent */
    let html = ''
    
    // Popular routes (only show when no search query)
    if (!searchQuery && popularRoutes.length > 0) {
      html += `
        <div class="mb-6">
          <h3 class="text-sm font-medium text-gray-500 mb-3 px-4">热门路线</h3>
          <div class="flex gap-3 px-4 overflow-x-auto">
            ${popularRoutes.map(route => `
              <div class="bg-gray-50 rounded-lg px-4 py-2 whitespace-nowrap cursor-pointer hover:bg-gray-100"
                   data-action="click->abroad-ticket-search#selectPopularRoute"
                   data-origin="${route.origin}"
                   data-destination="${route.destination}">
                <span class="text-sm font-medium">${route.origin} - ${route.destination}</span>
              </div>
            `).join('')}
          </div>
        </div>
      `
    }
    
    // Station list grouped by city/region
    html += '<div class="mb-4"><h3 class="text-sm font-medium text-gray-500 mb-3 px-4">站点选择</h3></div>'
    
    Object.entries(stations).forEach(([city, stationList]) => {
      const filteredStations = stationList.filter(station => 
        !searchQuery || 
        station.name.toLowerCase().includes(searchQuery) || 
        station.nameEn.toLowerCase().includes(searchQuery) ||
        city.toLowerCase().includes(searchQuery)
      )
      
      if (filteredStations.length > 0) {
        html += `
          <div class="mb-4">
            <div class="flex items-center px-4 py-2 bg-gray-50">
              <span class="text-sm font-bold text-gray-700">${city}</span>
            </div>
            ${filteredStations.map(station => {
              const isSelected = (
                this.currentSelectionType === 'origin' &&
                this.originInputTarget.value === station.name
              ) || (
                this.currentSelectionType === 'destination' &&
                this.destinationInputTarget.value === station.name
              )
              
              return `
                <div class="flex items-center justify-between px-4 py-3 border-b border-gray-100 cursor-pointer hover:bg-gray-50"
                     data-action="click->abroad-ticket-search#selectStation"
                     data-station-name="${station.name}"
                     data-station-name-en="${station.nameEn}">
                  <div class="flex-1">
                    <div class="text-base font-medium text-gray-900">${station.name}</div>
                    <div class="text-xs text-gray-400 mt-0.5">${station.nameEn}</div>
                  </div>
                  ${isSelected ? `
                    <svg class="w-5 h-5 text-yellow-400" fill="currentColor" viewBox="0 0 20 20">
                      <path fill-rule="evenodd"
                            d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
                            clip-rule="evenodd"/>
                    </svg>
                  ` : ''}
                </div>
              `
            }).join('')}
          </div>
        `
      }
    })
    
    const noResultsHeader = '<div class="mb-4"><h3 class="text-sm font-medium text-gray-500 mb-3 px-4">站点选择</h3></div>'
    if (html === noResultsHeader) {
      html += '<div class="text-center py-8 text-gray-400">未找到匹配的站点</div>'
    }
    /* eslint-enable indent */
    
    this.stationListTarget.innerHTML = html
  }

  selectPopularRoute(event: Event): void {
    const element = event.currentTarget as HTMLElement
    const origin = element.dataset.origin
    const destination = element.dataset.destination
    
    if (origin && destination) {
      // Find station details
      const stations = this.currentRegion === 'japan' ? this.japanStations : this.europeStations
      let originStation: Station | undefined
      let destinationStation: Station | undefined
      
      Object.values(stations).forEach((stationList: Station[]) => {
        stationList.forEach((station: Station) => {
          if (station.name === origin) originStation = station
          if (station.name === destination) destinationStation = station
        })
      })
      
      if (originStation) {
        this.originInputTarget.value = originStation.name
        this.originTextTarget.textContent = originStation.name
        const subtitle = this.originTextTarget.nextElementSibling
        if (subtitle) subtitle.textContent = originStation.nameEn
      }
      
      if (destinationStation) {
        this.destinationInputTarget.value = destinationStation.name
        this.destinationTextTarget.textContent = destinationStation.name
        const subtitle = this.destinationTextTarget.nextElementSibling
        if (subtitle) subtitle.textContent = destinationStation.nameEn
      }
      
      this.closeStationModal()
    }
  }
}
