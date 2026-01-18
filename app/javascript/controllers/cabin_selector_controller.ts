import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = ["button", "hiddenInput"]
  static values = {
    selected: String
  }

  declare readonly buttonTargets: HTMLButtonElement[]
  declare readonly hiddenInputTargets: HTMLInputElement[]
  declare selectedValue: string

  connect(): void {
    console.log("CabinSelector connected")
    // Check if there's a previously selected value from form
    // Use the first hiddenInput to get the value (they should all have the same value)
    const currentValue = this.hiddenInputTargets[0]?.value
    // Handle both empty string and undefined - default to 'all'
    const cabinValue = currentValue && currentValue !== '' ? currentValue : 'all'
    this.selectCabin(cabinValue)
  }

  selectCabin(cabinType: string): void {
    this.selectedValue = cabinType
    
    // Update ALL hidden input values for form submission (both single/round-trip and multi-city forms)
    this.hiddenInputTargets.forEach(input => {
      input.value = cabinType
    })
    
    // Update button styles
    this.buttonTargets.forEach(button => {
      const buttonType = button.dataset.cabinType
      
      if (buttonType === cabinType) {
        // Selected state - white background with subtle shadow
        button.classList.add("bg-white", "shadow-sm", "text-gray-900")
        button.classList.remove("text-gray-600")
      } else {
        // Unselected state - transparent background
        button.classList.remove("bg-white", "shadow-sm", "text-gray-900")
        button.classList.add("text-gray-600")
      }
    })
  }

  select(event: Event): void {
    const button = event.currentTarget as HTMLButtonElement
    const cabinType = button.dataset.cabinType
    
    if (cabinType) {
      // If already selected, do nothing (must keep one selected)
      if (this.selectedValue === cabinType) {
        return
      }
      this.selectCabin(cabinType)
    }
  }
}
