import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = ["modal", "selectedDate", "dateInput"]
  static values = {
    currentDate: String,
    minDate: String
  }

  declare readonly modalTarget: HTMLElement
  declare readonly selectedDateTarget: HTMLElement
  declare readonly dateInputTarget: HTMLInputElement
  declare currentDateValue: string
  declare minDateValue: string

  private selectedDateObj: Date | null = null

  connect(): void {
    console.log("ReturnDatePicker connected")
    // Initialize with departure date + 1 if no return date is set
    if (this.currentDateValue) {
      this.selectedDateObj = new Date(this.currentDateValue)
    } else if (this.minDateValue) {
      const minDate = new Date(this.minDateValue)
      minDate.setDate(minDate.getDate() + 1)
      this.selectedDateObj = minDate
      this.currentDateValue = this.formatDate(this.selectedDateObj)
    }
    if (this.selectedDateObj) {
      this.updateDisplayedDate()
    }
  }

  openModal(): void {
    this.modalTarget.classList.remove('hidden')
    document.body.style.overflow = 'hidden'
  }

  closeModal(): void {
    this.modalTarget.classList.add('hidden')
    document.body.style.overflow = ''
  }

  selectDate(event: Event): void {
    const button = event.currentTarget as HTMLElement
    const dateStr = button.dataset.date || ''
    
    if (!dateStr) return

    this.selectedDateObj = new Date(dateStr)
    this.currentDateValue = dateStr
    this.updateDisplayedDate()
    this.dateInputTarget.value = dateStr
    this.closeModal()
  }

  private updateDisplayedDate(): void {
    if (!this.selectedDateObj) return
    
    const month = this.selectedDateObj.getMonth() + 1
    const day = this.selectedDateObj.getDate()
    const dayName = this.getDayName(this.selectedDateObj)
    
    this.selectedDateTarget.innerHTML = `
      ${month}<span class="text-lg font-medium mx-0.5">月</span>${day}<span class="text-lg font-medium ml-0.5 mr-2">日</span>
      <span class="text-base text-gray-500 font-medium">${dayName}</span>
    `
  }

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

  private formatDate(date: Date): string {
    const year = date.getFullYear()
    const month = String(date.getMonth() + 1).padStart(2, '0')
    const day = String(date.getDate()).padStart(2, '0')
    return `${year}-${month}-${day}`
  }
}
