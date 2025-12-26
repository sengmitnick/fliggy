import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = [
    "tabContent",
    "tabs"
  ]

  declare readonly tabContentTargets: HTMLElement[]
  declare readonly tabsTarget: HTMLElement

  connect(): void {
    console.log("Destination controller connected")
  }

  disconnect(): void {
    console.log("Destination disconnected")
  }

  switchTab(event: Event): void {
    const button = event.currentTarget as HTMLButtonElement
    const tabName = button.dataset.tab
    
    if (!tabName) return

    // Update active tab button
    const allTabButtons = this.tabsTarget.querySelectorAll('.tab-btn')
    allTabButtons.forEach(btn => {
      btn.classList.remove('text-gray-900', 'border-gray-900')
      btn.classList.add('text-gray-500', 'border-transparent')
    })
    
    button.classList.remove('text-gray-500', 'border-transparent')
    button.classList.add('text-gray-900', 'border-gray-900')

    // Show corresponding tab content
    this.tabContentTargets.forEach(content => {
      if (content.dataset.tab === tabName) {
        content.classList.remove('hidden')
      } else {
        content.classList.add('hidden')
      }
    })
  }
}

