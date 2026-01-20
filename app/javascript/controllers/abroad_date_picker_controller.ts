import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = ["modal", "dateButton"]
  static values = {
    currentDate: String
  }

  declare readonly modalTarget: HTMLElement
  declare readonly dateButtonTargets: HTMLButtonElement[]
  declare readonly currentDateValue: string

  connect(): void {
    console.log("AbroadDatePicker connected")
    
    // Listen for open date picker event
    this.element.addEventListener('abroad-ticket-search:open-date-picker', () => {
      this.openModal()
    })
    
    // Update past dates based on client timezone
    this.updatePastDates()
  }

  openModal(): void {
    this.modalTarget.classList.remove("hidden")
    document.body.style.overflow = 'hidden'
  }

  closeModal(): void {
    this.modalTarget.classList.add("hidden")
    document.body.style.overflow = ''
  }

  selectDate(event: Event): void {
    const target = event.currentTarget as HTMLElement
    const dateStr = target.dataset.date

    if (dateStr) {
      // Check if date is not in the past
      const selectedDate = new Date(`${dateStr}T00:00:00`)
      const today = new Date()
      today.setHours(0, 0, 0, 0)
      selectedDate.setHours(0, 0, 0, 0)
      
      if (selectedDate < today) {
        return // Don't select past dates
      }
      
      // Find the abroad-ticket-search controller and call its updateDate method
      const searchController = this.application.getControllerForElementAndIdentifier(
        this.element,
        'abroad-ticket-search'
      )
      
      if (searchController && 'updateDate' in searchController) {
        (searchController as any).updateDate(dateStr)
      }
      
      this.closeModal()
    }
  }

  openCalendar(): void {
    this.openModal()
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
}
