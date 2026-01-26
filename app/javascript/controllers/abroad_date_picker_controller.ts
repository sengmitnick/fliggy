import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = ["modal", "dateButton", "dateScroll", "selectedDate"]
  static values = {
    currentDate: String
  }

  declare readonly modalTarget: HTMLElement
  declare readonly dateButtonTargets: HTMLButtonElement[]
  declare readonly dateScrollTarget: HTMLElement
  declare readonly hasSelectedDateTarget: boolean
  declare readonly selectedDateTarget: HTMLElement
  declare readonly currentDateValue: string

  connect(): void {
    console.log("AbroadDatePicker connected")
    
    // Listen for open date picker event
    this.element.addEventListener('abroad-ticket-search:open-date-picker', () => {
      this.openModal()
    })
    
    // Update past dates based on client timezone
    this.updatePastDates()
    
    // Scroll to selected date on page load
    this.scrollToSelectedDate()
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
      
      // Try to find the abroad-ticket-search controller
      const searchController = this.application.getControllerForElementAndIdentifier(
        this.element,
        'abroad-ticket-search'
      )
      
      // If controller exists (index page), update date via controller
      if (searchController && 'updateDate' in searchController) {
        (searchController as any).updateDate(dateStr)
        this.closeModal()
      } else {
        // If no controller (search page), navigate to new URL
        const currentUrl = new URL(window.location.href)
        currentUrl.searchParams.set('date', dateStr)
        window.Turbo.visit(currentUrl.toString())
      }
    }
  }

  openCalendar(): void {
    this.openModal()
  }
  
  // Scroll to selected date to make it visible
  private scrollToSelectedDate(): void {
    if (this.hasSelectedDateTarget && this.dateScrollTarget) {
      // Use requestAnimationFrame to ensure DOM is fully rendered
      requestAnimationFrame(() => {
        const selectedElement = this.selectedDateTarget
        const scrollContainer = this.dateScrollTarget
        
        // Calculate scroll position to center the selected date
        const elementLeft = selectedElement.offsetLeft
        const elementWidth = selectedElement.offsetWidth
        const containerWidth = scrollContainer.offsetWidth
        
        // Center the selected date in view
        const scrollPosition = elementLeft - (containerWidth / 2) + (elementWidth / 2)
        
        scrollContainer.scrollTo({
          left: Math.max(0, scrollPosition),
          behavior: 'smooth'
        })
      })
    }
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
