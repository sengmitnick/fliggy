import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = [
    "tabButton", "tabContent"
  ]

  static values = {
    // Add your values here, e.g.:
    // roomId: String,
    // userId: String
  }

  // Declare your targets and values
  declare readonly tabButtonTargets: HTMLButtonElement[]
  declare readonly tabContentTargets: HTMLDivElement[]
  
  private currentTab = 'cover'

  connect(): void {
    console.log("HotelDetail connected")
  }

  disconnect(): void {
    console.log("HotelDetail disconnected")
  }

  // Tab switching functionality
  switchTab(event: Event): void {
    const button = event.currentTarget as HTMLButtonElement
    const tabName = button.dataset.tab
    if (!tabName || tabName === this.currentTab) return
    
    // Update button states
    this.tabButtonTargets.forEach(btn => {
      if (btn.dataset.tab === tabName) {
        btn.classList.remove('text-gray-500', 'border-transparent')
        btn.classList.add('text-gray-900', 'border-orange-500')
      } else {
        btn.classList.remove('text-gray-900', 'border-orange-500')
        btn.classList.add('text-gray-500', 'border-transparent')
      }
    })
    
    // Update content visibility
    this.tabContentTargets.forEach(content => {
      if (content.dataset.tab === tabName) {
        content.classList.remove('hidden')
        content.classList.add('block')
      } else {
        content.classList.remove('block')
        content.classList.add('hidden')
      }
    })
    
    this.currentTab = tabName
  }

  // FORMS: Turbo + Turbo Streams handle everything automatically
  // - Forms submit via AJAX (Turbo Drive)
  // - Server responds with format.turbo_stream
  // - Turbo Streams update DOM automatically
  // - NO manual form handling needed in Stimulus
  //
  // Use Stimulus for:
  // - UI interactions (toggle, show/hide)
  // - Input validation/formatting
  // - Dynamic form fields
}
