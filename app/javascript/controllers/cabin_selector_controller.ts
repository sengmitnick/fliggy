import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = ["button", "hiddenInput"]
  static values = {
    selected: String
  }

  declare readonly buttonTargets: HTMLButtonElement[]
  declare readonly hiddenInputTarget: HTMLInputElement
  declare selectedValue: string

  connect(): void {
    console.log("CabinSelector connected")
    // Check if there's a previously selected value from form
    const currentValue = this.hiddenInputTarget.value
    if (currentValue) {
      // Restore previous selection when returning from search
      this.selectCabin(currentValue)
    } else {
      // Default to 'all' on first load
      this.selectCabin("all")
    }
  }

  selectCabin(cabinType: string): void {
    this.selectedValue = cabinType
    
    // Update hidden input value for form submission
    this.hiddenInputTarget.value = cabinType
    
    // Update button styles
    this.buttonTargets.forEach(button => {
      const buttonType = button.dataset.cabinType
      
      if (buttonType === cabinType) {
        // Selected state
        button.classList.remove("bg-white", "text-gray-700", "border-gray-300")
        button.classList.add("text-gray-900", "font-medium", "border-gray-900")
        button.style.background = "#FFFBF0"
        button.style.borderWidth = "2px"
      } else {
        // Unselected state
        button.classList.remove("text-gray-900", "font-medium", "border-gray-900")
        button.classList.add("bg-white", "text-gray-700", "border-gray-300")
        button.style.background = "white"
        button.style.borderWidth = "1px"
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
