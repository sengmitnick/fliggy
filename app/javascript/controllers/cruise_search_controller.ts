import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = [
    "routeDropdown",
    "tab",
    "cruiseLineContainer",
    "cityDropdown",
    "monthDropdown",
    "itineraryModal",
    "itineraryContent",
    "dateCard",
    "cabinContainer",
    "cabinCard",
    "roomList"
  ]

  declare readonly routeDropdownTarget: HTMLElement
  declare readonly tabTargets: HTMLElement[]
  declare readonly hasCruiseLineContainerTarget: boolean
  declare readonly cityDropdownTarget: HTMLElement
  declare readonly hasCityDropdownTarget: boolean
  declare readonly monthDropdownTarget: HTMLElement
  declare readonly hasMonthDropdownTarget: boolean
  declare readonly itineraryModalTarget: HTMLElement
  declare readonly hasItineraryModalTarget: boolean
  declare readonly itineraryContentTarget: HTMLElement
  declare readonly hasItineraryContentTarget: boolean
  declare readonly dateCardTargets: HTMLElement[]
  declare readonly cabinContainerTargets: HTMLElement[]
  declare readonly cabinCardTargets: HTMLElement[]
  declare readonly roomListTargets: HTMLElement[]

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

  // Select date and show corresponding cabins and rooms
  selectDate(event: Event): void {
    event.preventDefault()
    const card = event.currentTarget as HTMLElement
    const sailingId = card.dataset.sailingId
    
    console.log('Selected sailing:', sailingId)
    
    // Update date card styles
    this.dateCardTargets.forEach(dateCard => {
      if (dateCard === card) {
        dateCard.classList.remove('bg-white', 'border-gray-200')
        dateCard.classList.add('bg-yellow-50', 'border-yellow-400')
      } else {
        dateCard.classList.remove('bg-yellow-50', 'border-yellow-400')
        dateCard.classList.add('bg-white', 'border-gray-200')
      }
    })
    
    // Show/hide corresponding cabin containers
    this.cabinContainerTargets.forEach(container => {
      const containerSailingId = container.dataset.sailingId
      if (containerSailingId === sailingId) {
        container.classList.remove('hidden')
      } else {
        container.classList.add('hidden')
      }
    })
    
    // Find first cabin type for selected sailing and show its room list
    const firstVisibleCabinCard = this.cabinCardTargets.find(card => {
      const cardSailingId = card.dataset.sailingId
      return cardSailingId === sailingId && !card.closest('.hidden')
    })
    
    if (firstVisibleCabinCard) {
      const cabinTypeId = firstVisibleCabinCard.dataset.cabinTypeId
      
      // Update cabin card styles - select first one
      this.cabinCardTargets.forEach(cabinCard => {
        const cardSailingId = cabinCard.dataset.sailingId
        const cardCabinTypeId = cabinCard.dataset.cabinTypeId
        const borderDiv = cabinCard.querySelector('div')
        
        if (cardSailingId === sailingId && cardCabinTypeId === cabinTypeId && borderDiv) {
          borderDiv.classList.remove('border-gray-200')
          borderDiv.classList.add('border-yellow-400')
        } else if (borderDiv) {
          borderDiv.classList.remove('border-yellow-400')
          borderDiv.classList.add('border-gray-200')
        }
      })
      
      // Show/hide room lists
      this.roomListTargets.forEach(roomList => {
        const listSailingId = roomList.dataset.sailingId
        const listCabinTypeId = roomList.dataset.cabinTypeId
        
        if (listSailingId === sailingId && listCabinTypeId === cabinTypeId) {
          roomList.classList.remove('hidden')
        } else {
          roomList.classList.add('hidden')
        }
      })
    }
  }

  // Select cabin type and show corresponding rooms
  selectCabinType(event: Event): void {
    event.preventDefault()
    const card = event.currentTarget as HTMLElement
    const sailingId = card.dataset.sailingId
    const cabinTypeId = card.dataset.cabinTypeId
    
    console.log('Selected cabin type:', cabinTypeId, 'for sailing:', sailingId)
    
    // Update cabin card border styles for the same sailing
    this.cabinCardTargets.forEach(cabinCard => {
      const cardSailingId = cabinCard.dataset.sailingId
      const cardCabinTypeId = cabinCard.dataset.cabinTypeId
      const borderDiv = cabinCard.querySelector('div')
      
      if (cardSailingId === sailingId && borderDiv) {
        if (cardCabinTypeId === cabinTypeId) {
          borderDiv.classList.remove('border-gray-200')
          borderDiv.classList.add('border-yellow-400')
        } else {
          borderDiv.classList.remove('border-yellow-400')
          borderDiv.classList.add('border-gray-200')
        }
      }
    })
    
    // Show/hide corresponding room lists
    this.roomListTargets.forEach(roomList => {
      const listSailingId = roomList.dataset.sailingId
      const listCabinTypeId = roomList.dataset.cabinTypeId
      
      if (listSailingId === sailingId && listCabinTypeId === cabinTypeId) {
        roomList.classList.remove('hidden')
      } else {
        roomList.classList.add('hidden')
      }
    })
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

  // Open itinerary modal
  openItineraryModal(event: Event): void {
    console.log('openItineraryModal called')
    event.preventDefault()
    const button = event.currentTarget as HTMLElement
    const sailingId = button.dataset.sailingId
    console.log('sailingId:', sailingId)
    console.log('hasItineraryModalTarget:', this.hasItineraryModalTarget)
    
    if (!this.hasItineraryModalTarget) {
      console.error('itineraryModal target not found!')
      return
    }
    
    // Fetch sailing itinerary data
    this.fetchItineraryData(sailingId)
    
    // Show modal
    console.log('Showing modal...')
    this.itineraryModalTarget.classList.remove('hidden')
    document.body.classList.add('overflow-hidden')
  }

  // Close itinerary modal
  closeItineraryModal(event?: Event): void {
    if (event) {
      event.preventDefault()
    }
    
    if (!this.hasItineraryModalTarget) return
    
    this.itineraryModalTarget.classList.add('hidden')
    document.body.classList.remove('overflow-hidden')
  }

  // Fetch itinerary data from backend
  async fetchItineraryData(sailingId: string | undefined): Promise<void> {
    if (!sailingId || !this.hasItineraryContentTarget) return
    
    try {
      // Show loading state
      this.itineraryContentTarget.innerHTML = `
        <div class="flex items-center justify-center py-20">
          <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
        </div>
      `
      
      // Fetch sailing data
      const response = await fetch(`/api/cruise_sailings/${sailingId}`)
      if (!response.ok) throw new Error('Failed to fetch itinerary')
      
      const data = await response.json()
      this.renderItinerary(data)
    } catch (error) {
      console.error('Error fetching itinerary:', error)
      this.itineraryContentTarget.innerHTML = `
        <div class="text-center py-20">
          <p class="text-red-500">加载失败，请稍后重试</p>
        </div>
      `
    }
  }

  // Render itinerary content
  renderItinerary(sailing: any): void {
    if (!this.hasItineraryContentTarget) return
    
    const itinerary = sailing.itinerary || []
    const boardingAddress = sailing.boarding_address || ''
    const boardingDeadline = sailing.boarding_deadline || ''
    
    let html = `
      <div class="bg-white rounded-t-3xl h-[85vh] flex flex-col">
        <!-- Header -->
        <div class="flex-none px-4 py-4 border-b border-gray-200 flex items-center justify-between">
          <h2 class="text-lg font-semibold text-gray-900">行程安排</h2>
          <button data-action="click->cruise-search#closeItineraryModal" class="p-2 hover:bg-gray-100 rounded-full transition">
            <svg class="w-6 h-6 text-gray-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
            </svg>
          </button>
        </div>
        
        <!-- Boarding Info -->
        ${boardingAddress ? `
        <div class="flex-none px-4 py-3 bg-yellow-50 border-b border-yellow-100">
          <div class="flex items-start gap-2">
            <svg class="w-5 h-5 text-yellow-600 flex-none mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"/>
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"/>
            </svg>
            <div class="flex-1 min-w-0">
              <div class="text-xs font-medium text-gray-900 mb-0.5">登船地点</div>
              <div class="text-xs text-gray-600">${boardingAddress}</div>
              ${boardingDeadline ? `
              <div class="mt-1 flex items-center gap-1 text-xs text-gray-600">
                <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"/>
                </svg>
                <span>截止时间：${boardingDeadline}</span>
              </div>
              ` : ''}
            </div>
          </div>
        </div>
        ` : ''}
        
        <!-- Two Column Layout: Date Sidebar + Content Area -->
        <div class="flex-1 flex min-h-0">
          <!-- Left: Date Sidebar (Fixed) -->
          <div class="flex-none w-20 border-r border-gray-200 bg-gray-50 overflow-y-auto py-4" data-cruise-search-target="dateSidebar">
    `
    
    // Render date buttons
    itinerary.forEach((day: any, index: number) => {
      const buttonClass = index === 0 ? 'bg-yellow-400 text-gray-900' : 'text-gray-500 hover:bg-gray-100'
      html += `
            <button class="w-full px-2 py-3 flex flex-col items-center gap-1 transition ${buttonClass}" 
                    data-action="click->cruise-search#scrollToDay" 
                    data-day="${day.day}"
                    data-cruise-search-target="dateButton">
              <span class="text-xs font-semibold">D${day.day}</span>
              <span class="text-xs leading-tight text-center">${day.port || ''}</span>
            </button>
      `
    })
    
    html += `
          </div>
          
          <!-- Right: Scrollable Content Area -->
          <div class="flex-1 overflow-y-auto" data-cruise-search-target="contentArea" data-action="scroll->cruise-search#handleContentScroll">
            <div class="p-4 space-y-6">
    `
    
    // Render day content
    itinerary.forEach((day: any, index: number) => {
      const images = day.images || []
      const description = (day.description || '').replace(/\n/g, '<br>')
      
      html += `
              <div class="scroll-mt-4" data-day="${day.day}">
                <!-- Day Header -->
                <div class="flex items-center gap-3 mb-3">
                  <div class="flex-none w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center">
                    <span class="text-sm font-semibold text-primary">D${day.day}</span>
                  </div>
                  <div class="flex-1 min-w-0">
                    <div class="text-base font-semibold text-gray-900">${day.port || ''}</div>
                    ${day.title ? `<div class="text-sm text-gray-500 truncate">${day.title}</div>` : ''}
                  </div>
                </div>
                
                <!-- Images -->
                ${images.length > 0 ? `
                <div class="${images.length === 1 ? '' : 'grid grid-cols-2 gap-2'} mb-3">
                  ${images.map((img: string) => `
                    <img src="${img}" alt="${day.port}" class="w-full ${images.length === 1 ? 'h-48' : 'h-32'} object-cover rounded-lg" />
                  `).join('')}
                </div>
                ` : ''}
                
                <!-- Description -->
                ${description ? `
                <div class="text-sm text-gray-600 leading-relaxed">
                  ${description}
                </div>
                ` : ''}
              </div>
      `
    })
    
    html += `
            </div>
          </div>
        </div>
      </div>
    `
    
    this.itineraryContentTarget.innerHTML = html
  }
  
  // Scroll to specific day
  scrollToDay(event: Event): void {
    const button = event.currentTarget as HTMLElement
    const day = button.dataset.day
    
    if (!day) return
    
    const contentArea = this.element.querySelector('[data-cruise-search-target="contentArea"]') as HTMLElement
    const dayContent = contentArea?.querySelector(`[data-day="${day}"]`) as HTMLElement
    
    if (dayContent) {
      dayContent.scrollIntoView({ behavior: 'smooth', block: 'start' })
    }
  }
  
  // Handle content scroll to update active date button
  handleContentScroll(event: Event): void {
    const contentArea = event.currentTarget as HTMLElement
    const dayContents = Array.from(contentArea.querySelectorAll('[data-day]')) as HTMLElement[]
    const dateButtons = Array.from(this.element.querySelectorAll('[data-cruise-search-target="dateButton"]')) as HTMLElement[]
    
    if (dayContents.length === 0 || dateButtons.length === 0) return
    
    // Find the current visible day
    let currentDay: string | null = null
    const scrollTop = contentArea.scrollTop
    const viewportTop = scrollTop + 100 // Offset for better UX
    
    for (const dayContent of dayContents) {
      const offsetTop = dayContent.offsetTop
      if (offsetTop <= viewportTop) {
        currentDay = dayContent.dataset.day || null
      } else {
        break
      }
    }
    
    if (!currentDay && dayContents.length > 0) {
      currentDay = dayContents[0].dataset.day || null
    }
    
    // Update active state
    dateButtons.forEach(button => {
      const isActive = button.dataset.day === currentDay
      if (isActive) {
        button.classList.remove('text-gray-500', 'hover:bg-gray-100')
        button.classList.add('bg-yellow-400', 'text-gray-900')
      } else {
        button.classList.remove('bg-yellow-400', 'text-gray-900')
        button.classList.add('text-gray-500', 'hover:bg-gray-100')
      }
    })
  }
}
