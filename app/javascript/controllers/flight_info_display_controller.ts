import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["info"]
  static values = { cabinClass: String }

  declare readonly infoTarget: HTMLElement
  declare readonly cabinClassValue: string

  connect(): void {
    this.updateDisplay()
  }

  private updateDisplay(): void {
    const savedState = localStorage.getItem('passenger_selection')
    let displayText = '1成人' // Default
    
    if (savedState) {
      try {
        const state = JSON.parse(savedState)
        const passengerNames = state.passengerNames || []
        
        // If user selected specific passengers, display count based on passengerNames
        if (passengerNames.length > 0) {
          displayText = `${passengerNames.length}位乘机人`
        } else {
          // If user selected by count only
          const adults = state.adults || 1
          const children = state.children || 0
          
          displayText = `${adults}成人`
          
          // Add children if any
          if (children > 0) {
            displayText += ` ${children}儿童`
          }
        }
      } catch (e) {
        console.error('Failed to load passenger selection from localStorage:', e)
      }
    }
    
    // Add cabin class if business/first class
    if (this.cabinClassValue === 'business') {
      displayText += ' · 公务舱'
    } else if (this.cabinClassValue === 'first_class') {
      displayText += ' · 头等舱'
    }
    
    this.infoTarget.textContent = displayText
  }
}
