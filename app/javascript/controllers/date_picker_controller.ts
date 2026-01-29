import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = [
    "modal",
    "selectedDate",
    "dateInput",
    "dateButton",
    "exactTab",
    "fuzzyTab",
    "exactDateContent",
    "fuzzyDateContent",
    "monthButton"
  ]

  static values = {
    currentDate: String
  }

  declare readonly modalTarget: HTMLElement
  declare readonly hasModalTarget: boolean
  declare readonly selectedDateTarget: HTMLElement
  declare readonly dateInputTarget: HTMLInputElement
  // stimulus-validator: disable-next-line - 在 shared/_date_picker_modal.html.erb 中
  declare readonly dateButtonTargets: HTMLButtonElement[]
  declare readonly hasSelectedDateTarget: boolean
  declare readonly hasDateInputTarget: boolean
  // stimulus-validator: disable-next-line - 在 shared/_date_picker_modal.html.erb 中
  declare readonly exactTabTarget: HTMLButtonElement
  // stimulus-validator: disable-next-line - 在 shared/_date_picker_modal.html.erb 中
  declare readonly fuzzyTabTarget: HTMLButtonElement
  // stimulus-validator: disable-next-line - 在 shared/_date_picker_modal.html.erb 中
  declare readonly exactDateContentTarget: HTMLElement
  // stimulus-validator: disable-next-line - 在 shared/_date_picker_modal.html.erb 中
  declare readonly fuzzyDateContentTarget: HTMLElement
  // stimulus-validator: disable-next-line - 在 shared/_date_picker_modal.html.erb 中
  declare readonly monthButtonTargets: HTMLButtonElement[]
  declare currentDateValue: string

  private selectedDateObj: Date = new Date()
  private currentMultiCitySegmentId: string | null = null
  private selectedMonths: Set<string> = new Set()

  connect(): void {
    console.log("DatePicker connected")
    // Send client's local date to server for timezone-aware filtering
    const clientToday = this.formatDate(new Date())
    
    // Initialize with today's date using client timezone
    this.selectedDateObj = new Date()
    this.currentDateValue = this.formatDate(this.selectedDateObj)
    
    // Update displayed date immediately with client timezone
    if (this.hasSelectedDateTarget) {
      this.updateDisplayedDate()
    }
    
    // Update hidden input with client timezone date
    if (this.hasDateInputTarget) {
      this.dateInputTarget.value = this.currentDateValue
    }
    
    // Only access modal if it exists in this controller's scope
    if (!this.hasModalTarget) {
      console.log("DatePicker: No modal target found, skipping modal setup")
      return
    }
    
    const modalElement = this.modalTarget
    
    // Store client's today date as data attribute for server to use
    if (modalElement) {
      modalElement.dataset.clientToday = clientToday
    }
    
    // Update past date buttons based on client timezone
    this.updatePastDates()
    
    // Listen for multi-city events
    // eslint-disable-next-line no-undef
    this.element.addEventListener('multi-city:open-date-picker', this.handleMultiCityOpen.bind(this) as unknown as EventListener)
  }

  disconnect(): void {
    // eslint-disable-next-line no-undef
    this.element.removeEventListener('multi-city:open-date-picker', this.handleMultiCityOpen.bind(this) as unknown as EventListener)
  }

  // Handle multi-city date picker request
  private handleMultiCityOpen(event: CustomEvent): void {
    const { segmentId } = event.detail
    console.log('Date picker: Received multi-city open request', { segmentId })
    this.currentMultiCitySegmentId = segmentId
    this.openModal()
  }

  // Open check-in date picker
  openCheckIn(): void {
    const checkInDate = prompt("请输入入住日期 (YYYY-MM-DD)", this.formatDate(new Date()))
    if (checkInDate) {
      const url = new URL(window.location.href)
      url.searchParams.set('check_in', checkInDate)
      window.location.href = url.toString()
    }
  }

  // Open check-out date picker
  openCheckOut(): void {
    const tomorrow = new Date()
    tomorrow.setDate(tomorrow.getDate() + 1)
    const checkOutDate = prompt("请输入离店日期 (YYYY-MM-DD)", this.formatDate(tomorrow))
    if (checkOutDate) {
      const url = new URL(window.location.href)
      url.searchParams.set('check_out', checkOutDate)
      window.location.href = url.toString()
    }
  }

  // Open date picker modal
  openModal(): void {
    if (!this.hasModalTarget) return
    this.modalTarget.classList.remove('hidden')
    document.body.style.overflow = 'hidden'
  }

  // Close date picker modal
  closeModal(): void {
    if (!this.hasModalTarget) return
    this.modalTarget.classList.add('hidden')
    document.body.style.overflow = ''
  }

  // Select a date
  selectDate(event: Event): void {
    const button = event.currentTarget as HTMLElement
    const dateStr = button.dataset.date || ''
    
    if (!dateStr) return

    // Prevent selecting dates before today (using client timezone)
    const selectedDate = new Date(`${dateStr}T00:00:00`)
    const today = new Date()
    today.setHours(0, 0, 0, 0)
    selectedDate.setHours(0, 0, 0, 0)
    
    if (selectedDate < today) {
      console.log('Cannot select past dates (client timezone check)')
      return
    }

    this.selectedDateObj = selectedDate
    this.currentDateValue = dateStr
    
    // Check if this is for multi-city
    if (this.currentMultiCitySegmentId) {
      console.log('Date picker: Multi-city mode, dispatching event', {
        segmentId: this.currentMultiCitySegmentId,
        date: dateStr
      })
      
      // Trigger event to update multi-city segment
      const updateEvent = new CustomEvent('date-picker:date-selected', {
        detail: {
          segmentId: this.currentMultiCitySegmentId,
          date: dateStr
        },
        bubbles: true
      })
      document.dispatchEvent(updateEvent)
      
      // Reset multi-city state
      this.currentMultiCitySegmentId = null
      this.closeModal()
    } else if (window.location.pathname.includes('/flights/search')) {
      // Search page mode - reload with new date
      console.log('Date picker: Search page mode, reloading with new date')
      const url = new URL(window.location.href)
      url.searchParams.set('date', dateStr)
      window.location.href = url.toString()
    } else {
      console.log('Date picker: Regular mode')
      // Regular single/round trip selection
      if (this.hasSelectedDateTarget) {
        this.updateDisplayedDate()
      }
      if (this.hasDateInputTarget) {
        this.dateInputTarget.value = dateStr
      }
      this.closeModal()
    }
  }

  // Update the displayed date in the main view
  private updateDisplayedDate(): void {
    const month = this.selectedDateObj.getMonth() + 1
    const day = this.selectedDateObj.getDate()
    const dayName = this.getDayName(this.selectedDateObj)
    
    this.selectedDateTarget.innerHTML = `
      ${month}<span class="text-lg font-medium mx-0.5">月</span>${day}<span class="text-lg font-medium ml-0.5 mr-2">日</span>
      <span class="text-base text-gray-500 font-medium">${dayName}</span>
    `
  }

  // Get day name in Chinese
  private getDayName(date: Date): string {
    const today = new Date()
    today.setHours(0, 0, 0, 0)
    const targetDate = new Date(date)
    targetDate.setHours(0, 0, 0, 0)
    
    const diffTime = targetDate.getTime() - today.getTime()
    const diffDays = Math.round(diffTime / (1000 * 60 * 60 * 24))
    
    if (diffDays === 0) return '今天'
    if (diffDays === 1) return '明天'
    if (diffDays === 2) return '后天'
    
    const weekdays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六']
    return weekdays[date.getDay()]
  }

  // Format date as YYYY-MM-DD
  private formatDate(date: Date): string {
    const year = date.getFullYear()
    const month = String(date.getMonth() + 1).padStart(2, '0')
    const day = String(date.getDate()).padStart(2, '0')
    return `${year}-${month}-${day}`
  }

  // Generate calendar data
  generateCalendar(): Array<any> {
    const result = []
    const startDate = new Date()
    
    // Generate next 60 days
    for (let i = 0; i < 60; i++) {
      const date = new Date(startDate)
      date.setDate(startDate.getDate() + i)
      
      result.push({
        date: this.formatDate(date),
        day: date.getDate(),
        month: date.getMonth() + 1,
        year: date.getFullYear(),
        weekday: date.getDay(),
        isToday: this.isToday(date),
        isSelected: this.formatDate(date) === this.currentDateValue
      })
    }
    
    return result
  }

  // Check if date is today
  private isToday(date: Date): boolean {
    const today = new Date()
    return date.getDate() === today.getDate() &&
           date.getMonth() === today.getMonth() &&
           date.getFullYear() === today.getFullYear()
  }

  // Update date buttons to disable past dates based on client timezone
  private updatePastDates(): void {
    const today = new Date()
    today.setHours(0, 0, 0, 0)
    const todayStr = this.formatDate(today)
    
    this.dateButtonTargets.forEach(button => {
      const dateStr = button.dataset.date
      if (!dateStr) return
      
      const buttonDate = new Date(`${dateStr}T00:00:00`)
      buttonDate.setHours(0, 0, 0, 0)
      
      // Check if this is today (client timezone)
      const todayMarker = button.querySelector('[data-today-marker]') as HTMLElement
      if (dateStr === todayStr && todayMarker) {
        todayMarker.classList.remove('hidden')
      }
      
      if (buttonDate < today) {
        // Disable past dates
        button.disabled = true
        button.classList.add('opacity-30', 'cursor-not-allowed')
      } else {
        // Enable current and future dates
        button.disabled = false
        button.classList.remove('opacity-30', 'cursor-not-allowed')
      }
    })
    
    console.log(`DatePicker: Updated ${this.dateButtonTargets.length} date buttons based on client timezone (today: ${todayStr})`)
  }

  // Switch to exact date tab
  switchToExactDate(): void {
    this.exactTabTarget.classList.add('font-bold', 'border-b-2', 'border-black')
    this.exactTabTarget.classList.remove('text-gray-500')
    this.fuzzyTabTarget.classList.remove('font-bold', 'border-b-2', 'border-black')
    this.fuzzyTabTarget.classList.add('text-gray-500')
    
    this.exactDateContentTarget.classList.remove('hidden')
    this.fuzzyDateContentTarget.classList.add('hidden')
  }

  // Switch to fuzzy date tab
  switchToFuzzyDate(): void {
    this.fuzzyTabTarget.classList.add('font-bold', 'border-b-2', 'border-black')
    this.fuzzyTabTarget.classList.remove('text-gray-500')
    this.exactTabTarget.classList.remove('font-bold', 'border-b-2', 'border-black')
    this.exactTabTarget.classList.add('text-gray-500')
    
    this.fuzzyDateContentTarget.classList.remove('hidden')
    this.exactDateContentTarget.classList.add('hidden')
  }

  // Toggle month selection
  toggleMonth(event: Event): void {
    const button = event.currentTarget as HTMLButtonElement
    const month = button.dataset.month
    
    if (!month) return

    if (this.selectedMonths.has(month)) {
      // Deselect
      this.selectedMonths.delete(month)
      button.classList.remove('bg-yellow-100', 'border-yellow-500')
      button.classList.add('bg-gray-50')
      
      // Hide checkmark
      const svg = button.querySelector('svg')
      if (svg) svg.classList.remove('text-gray-700')
      if (svg) svg.classList.add('text-gray-400')
      
      const span = button.querySelector('span')
      if (span) span.classList.remove('text-gray-800', 'font-medium')
      if (span) span.classList.add('text-gray-500')
      
      // Find and hide checkmark by looking for all divs with svg inside
      const checkmarks = button.querySelectorAll('div[class*="absolute"]')
      checkmarks.forEach(div => {
        if (div.querySelector('svg[width="12"]')) {
          div.classList.add('hidden')
        }
      })
    } else {
      // Select
      this.selectedMonths.add(month)
      button.classList.remove('bg-gray-50')
      button.classList.add('bg-yellow-100', 'border-yellow-500')
      
      // Show checkmark style
      const svg = button.querySelector('svg')
      if (svg) svg.classList.remove('text-gray-400')
      if (svg) svg.classList.add('text-gray-700')
      
      const span = button.querySelector('span')
      if (span) span.classList.remove('text-gray-500')
      if (span) span.classList.add('text-gray-800', 'font-medium')
      
      // Find and show checkmark
      const checkmarks = button.querySelectorAll('div[class*="absolute"]')
      checkmarks.forEach(div => {
        if (div.querySelector('svg[width="12"]')) {
          div.classList.remove('hidden')
        }
      })
    }
  }

  // Select quick range (1, 3, or 6 months)
  selectQuickRange(event: Event): void {
    const button = event.currentTarget as HTMLButtonElement
    const rangeStr = button.dataset.range
    
    if (!rangeStr) return
    
    const range = parseInt(rangeStr, 10)
    
    // Clear current selection
    this.clearMonthSelection()
    
    // Select next N months
    const today = new Date()
    const currentMonth = new Date(today.getFullYear(), today.getMonth(), 1)
    
    for (let i = 0; i < range; i++) {
      const targetMonth = new Date(currentMonth)
      targetMonth.setMonth(currentMonth.getMonth() + i)
      const monthValue = `${targetMonth.getFullYear()}-${String(targetMonth.getMonth() + 1).padStart(2, '0')}`
      
      // Find and select the button
      const monthButton = this.monthButtonTargets.find(btn => btn.dataset.month === monthValue)
      if (monthButton && !this.selectedMonths.has(monthValue)) {
        monthButton.click()
      }
    }
  }

  // Clear month selection
  private clearMonthSelection(): void {
    this.monthButtonTargets.forEach(button => {
      const month = button.dataset.month
      if (month && this.selectedMonths.has(month)) {
        // Deselect programmatically
        this.selectedMonths.delete(month)
        button.classList.remove('bg-yellow-100', 'border-yellow-500')
        button.classList.add('bg-gray-50')
        
        const svg = button.querySelector('svg')
        if (svg) svg.classList.remove('text-gray-700')
        if (svg) svg.classList.add('text-gray-400')
        
        const span = button.querySelector('span')
        if (span) span.classList.remove('text-gray-800', 'font-medium')
        if (span) span.classList.add('text-gray-500')
        
        const checkmarks = button.querySelectorAll('div[class*="absolute"]')
        checkmarks.forEach(div => {
          if (div.querySelector('svg[width="12"]')) {
            div.classList.add('hidden')
          }
        })
      }
    })
  }

  // Confirm fuzzy date selection
  confirmFuzzyDate(): void {
    if (this.selectedMonths.size === 0) {
      alert('请至少选择一个月份')
      return
    }

    // Convert selected months to a comma-separated string
    const monthsArray = Array.from(this.selectedMonths).sort()
    const monthsString = monthsArray.join(',')
    
    // Check if this is on search page - reload with first date of first selected month
    if (window.location.pathname.includes('/flights/search')) {
      console.log('Date picker: Search page fuzzy mode, reloading with first date of selected months')
      
      // Get the first day of the first selected month
      const firstMonth = monthsArray[0]
      const [year, month] = firstMonth.split('-')
      const firstDate = `${year}-${month}-01`
      
      const url = new URL(window.location.href)
      url.searchParams.set('date', firstDate)
      // Store fuzzy date info for future use if needed
      url.searchParams.set('fuzzy_months', monthsString)
      window.location.href = url.toString()
      return
    }
    
    // Update the display with fuzzy date info (for other pages)
    if (this.hasSelectedDateTarget) {
      const firstMonth = monthsArray[0]
      const [, month] = firstMonth.split('-')
      const monthNum = parseInt(month, 10)
      
      if (monthsArray.length === 1) {
        this.selectedDateTarget.innerHTML = `
          ${monthNum}<span class="text-lg font-medium mx-0.5">月</span>
          <span class="text-base text-gray-500 font-medium">全月</span>
        `
      } else {
        const lastMonth = monthsArray[monthsArray.length - 1]
        const [, lastMonthStr] = lastMonth.split('-')
        const lastMonthNum = parseInt(lastMonthStr, 10)
        
        this.selectedDateTarget.innerHTML = `
          ${monthNum}<span class="text-lg font-medium mx-0.5">月</span>-${lastMonthNum}<span class="text-lg font-medium mx-0.5">月</span>
          <span class="text-base text-gray-500 font-medium">(${monthsArray.length}个月)</span>
        `
      }
    }
    
    // Store fuzzy date in the hidden input with a special prefix
    if (this.hasDateInputTarget) {
      this.dateInputTarget.value = `fuzzy:${monthsString}`
    }
    
    this.closeModal()
  }
}
