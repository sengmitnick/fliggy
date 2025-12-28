import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = [
    // stimulus-validator: disable-next-line
    "modal",
    "selectedDate",
    "dateInput"
  ]

  static values = {
    currentDate: String
  }

  // stimulus-validator: disable-next-line
  declare readonly modalTarget: HTMLElement
  declare readonly selectedDateTarget: HTMLElement
  declare readonly dateInputTarget: HTMLInputElement
  declare readonly hasSelectedDateTarget: boolean
  declare readonly hasDateInputTarget: boolean
  declare currentDateValue: string

  private selectedDateObj: Date = new Date()

  connect(): void {
    console.log("DatePicker connected")
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
    this.modalTarget.classList.remove('hidden')
    document.body.style.overflow = 'hidden'
  }

  // Close date picker modal
  closeModal(): void {
    this.modalTarget.classList.add('hidden')
    document.body.style.overflow = ''
  }

  // Select a date
  selectDate(event: Event): void {
    const button = event.currentTarget as HTMLElement
    const dateStr = button.dataset.date || ''
    
    if (!dateStr) return

    this.selectedDateObj = new Date(dateStr)
    this.currentDateValue = dateStr
    if (this.hasSelectedDateTarget) {
      this.updateDisplayedDate()
    }
    if (this.hasDateInputTarget) {
      this.dateInputTarget.value = dateStr
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
}
