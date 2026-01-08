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

  connect(): void {
    console.log("BusDatePicker connected")
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
    
    // Update past date buttons based on client timezone
    this.updatePastDates()
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
    
    // Update displayed date
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
      ${month}<span class="text-base mx-0.5">月</span>${day}<span class="text-base ml-0.5 mr-2">日</span>
    `
    
    // Update the "今天" text after the date
    const dayLabel = this.selectedDateTarget.nextElementSibling
    if (dayLabel) {
      dayLabel.textContent = dayName
    }
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

  // Update past dates to be disabled
  private updatePastDates(): void {
    if (!this.dateButtonTargets) return
    
    const today = new Date()
    today.setHours(0, 0, 0, 0)
    
    this.dateButtonTargets.forEach(button => {
      const dateStr = button.dataset.date
      if (!dateStr) return
      
      const buttonDate = new Date(`${dateStr}T00:00:00`)
      buttonDate.setHours(0, 0, 0, 0)
      
      if (buttonDate < today) {
        button.disabled = true
        button.classList.add('opacity-40', 'cursor-not-allowed')
        button.classList.remove('hover:bg-blue-50')
      }
    })
  }

  // Check if date is today
  private isToday(date: Date): boolean {
    const today = new Date()
    today.setHours(0, 0, 0, 0)
    const compareDate = new Date(date)
    compareDate.setHours(0, 0, 0, 0)
    return compareDate.getTime() === today.getTime()
  }
}
