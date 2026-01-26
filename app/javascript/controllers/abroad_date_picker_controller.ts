import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = ["modal", "dateButton", "dateScroll", "selectedDate", "dateDisplay"]
  static values = {
    currentDate: String
  }

  declare readonly modalTarget: HTMLElement
  declare readonly dateButtonTargets: HTMLButtonElement[]
  declare readonly dateScrollTarget: HTMLElement
  declare readonly hasSelectedDateTarget: boolean
  declare readonly selectedDateTarget: HTMLElement
  declare readonly currentDateValue: string
  declare readonly hasDateDisplayTarget: boolean
  declare readonly dateDisplayTargets: HTMLElement[]

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
      
      // If controller exists (index or search page with controller), update date via controller
      if (searchController && 'updateDate' in searchController) {
        (searchController as any).updateDate(dateStr)
        this.closeModal()
      } else {
        // No search controller - could be search page or show page
        const currentUrl = new URL(window.location.href)
        
        // Check if we're on a show page (has /abroad_tickets/:id pattern)
        const isShowPage = /\/abroad_tickets\/\d+$/.test(currentUrl.pathname)
        
        if (isShowPage) {
          // On show page: update date display without navigation
          this.updateDateDisplay(dateStr)
          this.closeModal()
        } else {
          // On search page: update date parameter
          currentUrl.searchParams.set('date', dateStr)
          window.Turbo.visit(currentUrl.toString())
        }
      }
    }
  }

  openCalendar(): void {
    this.openModal()
  }
  
  // Update date display on show page
  private updateDateDisplay(dateStr: string): void {
    const date = new Date(`${dateStr}T00:00:00`)
    const month = date.getMonth() + 1
    const day = date.getDate()
    const year = date.getFullYear()
    const weekdays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六']
    const weekday = weekdays[date.getDay()]
    
    // Update all date display targets
    if (this.hasDateDisplayTarget) {
      this.dateDisplayTargets.forEach(target => {
        const type = target.dataset.dateType
        
        if (type === 'short') {
          // Format: "1月26日"
          target.textContent = `${month}月${day}日`
        } else if (type === 'weekday') {
          // Format: "周日"
          target.textContent = weekday
        } else if (type === 'full') {
          // Format: "2026年01月26日 周日"
          target.textContent = `${year}年${String(month).padStart(2, '0')}月${String(day).padStart(2, '0')}日 ${weekday}`
        }
      })
    }
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
