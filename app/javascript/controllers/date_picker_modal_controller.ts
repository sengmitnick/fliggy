import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = ["dateButton"]
  
  declare readonly dateButtonTargets: HTMLButtonElement[]
  
  connect(): void {
    console.log("DatePickerModal connected")
    this.updatePastDates()
  }
  
  // Update buttons to disable past dates based on client timezone
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
    
    console.log(`Updated ${this.dateButtonTargets.length} date buttons based on client timezone`)
  }
}
