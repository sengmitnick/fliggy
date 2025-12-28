import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = [
    "departureCity",
    "arrivalCity",
    "departureCityInput",
    "arrivalCityInput",
    "selectedDate",
    "dateInput",
    "studentTicket",
    "highSpeedOnly"
  ]

  static values = {
    departureCity: String,
    arrivalCity: String,
    date: String
  }

  declare readonly departureCityTarget: HTMLElement
  declare readonly arrivalCityTarget: HTMLElement
  declare readonly departureCityInputTarget: HTMLInputElement
  declare readonly arrivalCityInputTarget: HTMLInputElement
  declare readonly selectedDateTarget: HTMLElement
  declare readonly dateInputTarget: HTMLInputElement
  declare readonly studentTicketTarget: HTMLInputElement
  declare readonly highSpeedOnlyTarget: HTMLInputElement
  declare departureCityValue: string
  declare arrivalCityValue: string
  declare dateValue: string

  private selectedDateObj: Date = new Date()

  connect(): void {
    console.log("TrainSearch connected")
    // Initialize default values
    if (!this.departureCityValue) this.departureCityValue = "北京市"
    if (!this.arrivalCityValue) this.arrivalCityValue = "杭州市"
    if (!this.dateValue) {
      this.selectedDateObj = new Date()
      // Set to tomorrow by default
      this.selectedDateObj.setDate(this.selectedDateObj.getDate() + 1)
      this.dateValue = this.formatDate(this.selectedDateObj)
    } else {
      this.selectedDateObj = new Date(this.dateValue)
    }

    // Update initial display
    this.updateCityDisplay()
    this.updateDateDisplay()
  }

  // Switch cities
  switchCities(): void {
    const temp = this.departureCityValue
    this.departureCityValue = this.arrivalCityValue
    this.arrivalCityValue = temp
    
    this.updateCityDisplay()
  }

  // Update city display
  private updateCityDisplay(): void {
    this.departureCityTarget.textContent = this.departureCityValue
    this.arrivalCityTarget.textContent = this.arrivalCityValue
    this.departureCityInputTarget.value = this.departureCityValue
    this.arrivalCityInputTarget.value = this.arrivalCityValue
  }

  // Update date display
  private updateDateDisplay(): void {
    const month = this.selectedDateObj.getMonth() + 1
    const day = this.selectedDateObj.getDate()
    const dayName = this.getDayName(this.selectedDateObj)
    
    this.selectedDateTarget.innerHTML = `
      ${month}<span class="text-sm">月</span>${day}<span class="text-sm">日</span> <span class="text-sm">${dayName}</span>
    `
    this.dateInputTarget.value = this.dateValue
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

  // Toggle student ticket
  toggleStudentTicket(): void {
    console.log("Student ticket toggled:", this.studentTicketTarget.checked)
  }

  // Toggle high speed only
  toggleHighSpeedOnly(): void {
    console.log("High speed only toggled:", this.highSpeedOnlyTarget.checked)
  }

  // Handle search form submission (Turbo handles actual submission)
  // This is just for any pre-submission UI feedback if needed
  search(): void {
    console.log("Searching trains:", {
      from: this.departureCityValue,
      to: this.arrivalCityValue,
      date: this.dateValue
    })
  }
}
