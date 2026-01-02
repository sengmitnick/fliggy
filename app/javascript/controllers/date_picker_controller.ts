import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = [
    "modal",
    "selectedDate",
    "dateInput",
    "dateButton"
  ]

  static values = {
    currentDate: String
  }

  declare readonly modalTarget: HTMLElement
  declare readonly hasModalTarget: boolean
  declare readonly selectedDateTarget: HTMLElement
  declare readonly dateInputTarget: HTMLInputElement
  declare readonly dateButtonTargets: HTMLButtonElement[]
  declare readonly hasSelectedDateTarget: boolean
  declare readonly hasDateInputTarget: boolean
  declare currentDateValue: string

  private selectedDateObj: Date = new Date()
  private currentMultiCitySegmentId: string | null = null

  connect(): void {
    console.log("DatePicker connected")
    // Send client's local date to server for timezone-aware filtering
    const clientToday = this.formatDate(new Date())
    
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
    
    // Initialize with today's date if no date is set
    if (this.currentDateValue) {
      this.selectedDateObj = new Date(this.currentDateValue)
    } else {
      this.selectedDateObj = new Date()
      this.currentDateValue = this.formatDate(this.selectedDateObj)
    }
    // Only update displayed date if target exists (used in modal-based pickers)
    if (this.hasSelectedDateTarget) {
      this.updateDisplayedDate()
    }
    
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
    } else {
      console.log('Date picker: Regular mode')
      // Regular single/round trip selection
      if (this.hasSelectedDateTarget) {
        this.updateDisplayedDate()
      }
      if (this.hasDateInputTarget) {
        this.dateInputTarget.value = dateStr
      }
    }
    
    this.closeModal()
  }

  // Update the displayed date in the main view
  private updateDisplayedDate(): void {
    const month = this.selectedDateObj.getMonth() + 1
    const day = this.selectedDateObj.getDate()
    const dayName = this.getDayName(this.selectedDateObj)
    
    this.selectedDateTarget.innerHTML = `
      ${month}<span class="text-base text-gray-600">月</span>${day}<span class="text-base text-gray-600">日 ${dayName}</span>
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
    
    this.dateButtonTargets.forEach(button => {
      const dateStr = button.dataset.date
      if (!dateStr) return
      
      const buttonDate = new Date(`${dateStr}T00:00:00`)
      buttonDate.setHours(0, 0, 0, 0)
      
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
    
    console.log(`DatePicker: Updated ${this.dateButtonTargets.length} date buttons based on client timezone`)
  }
}
