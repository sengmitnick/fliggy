import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = ["modal", "nameInput", "phoneInput", "emailInput", "contactItem", "insuranceCard", "checkmark", "insurancePriceInput", "quantityInput", "totalPrice"]

  declare readonly modalTarget: HTMLElement
  declare readonly nameInputTarget: HTMLInputElement
  declare readonly phoneInputTarget: HTMLInputElement
  declare readonly emailInputTarget: HTMLInputElement
  declare readonly contactItemTargets: HTMLElement[]
  declare readonly insuranceCardTargets: HTMLElement[]
  declare readonly checkmarkTargets: HTMLElement[]
  declare readonly insurancePriceInputTarget: HTMLInputElement
  declare readonly quantityInputTarget: HTMLInputElement
  declare readonly totalPriceTarget: HTMLElement
  declare readonly hasModalTarget: boolean
  declare readonly hasContactItemTarget: boolean
  declare readonly hasInsuranceCardTarget: boolean

  private selectedInsuranceType: string = 'none'
  private selectedInsurancePrice: number = 0
  private basePrice: number = 0

  connect(): void {
    console.log("CruiseOrderForm connected")
    
    // Get base price from totalPrice element
    this.basePrice = parseFloat(this.totalPriceTarget.dataset.basePrice || '0')
    
    // Initialize with "none" insurance selected by default
    this.selectDefaultInsurance()
  }

  openContactSelector(): void {
    if (this.hasModalTarget) {
      this.modalTarget.classList.remove('hidden')
      this.highlightCurrentContact()
    }
  }

  closeContactSelector(): void {
    if (this.hasModalTarget) {
      this.modalTarget.classList.add('hidden')
    }
  }

  selectContact(event: Event): void {
    const element = event.currentTarget as HTMLElement
    const name = element.dataset.cruiseOrderFormNameParam || ''
    const phone = element.dataset.cruiseOrderFormPhoneParam || ''
    const email = element.dataset.cruiseOrderFormEmailParam || ''
    
    // Fill in the form fields
    this.nameInputTarget.value = name
    this.phoneInputTarget.value = phone
    this.emailInputTarget.value = email
    
    // Update visual selection state
    this.updateContactSelection(element)
    
    // Close modal
    this.closeContactSelector()
  }

  private highlightCurrentContact(): void {
    if (!this.hasContactItemTarget) return
    
    const currentName = this.nameInputTarget.value.trim()
    const currentPhone = this.phoneInputTarget.value.trim()
    
    this.contactItemTargets.forEach(item => {
      const itemName = item.dataset.cruiseOrderFormNameParam || ''
      const itemPhone = item.dataset.cruiseOrderFormPhoneParam || ''
      
      const isMatch = Boolean(currentName && itemName === currentName && 
                     (!currentPhone || itemPhone === currentPhone))
      
      this.setContactVisualState(item, isMatch)
    })
  }

  private updateContactSelection(selectedElement: HTMLElement): void {
    if (!this.hasContactItemTarget) return
    
    this.contactItemTargets.forEach(item => {
      this.setContactVisualState(item, item === selectedElement)
    })
  }

  private setContactVisualState(element: HTMLElement, isSelected: boolean): void {
    const circle = element.querySelector('div.rounded-full')
    const checkIcon = circle?.querySelector('svg')
    
    if (isSelected) {
      element.classList.add('bg-blue-50', 'border-blue-500')
      element.classList.remove('bg-surface')
      circle?.classList.add('border-blue-600', 'bg-blue-600')
      circle?.classList.remove('border-gray-300')
      checkIcon?.classList.remove('hidden')
      checkIcon?.classList.add('text-white')
    } else {
      element.classList.remove('bg-blue-50', 'border-blue-500')
      element.classList.add('bg-surface')
      circle?.classList.remove('border-blue-600', 'bg-blue-600')
      circle?.classList.add('border-gray-300')
      checkIcon?.classList.add('hidden')
      checkIcon?.classList.remove('text-white')
    }
  }

  selectInsurance(event: Event): void {
    const target = event.currentTarget as HTMLElement
    this.selectedInsuranceType = target.dataset.insuranceType || 'none'
    this.selectedInsurancePrice = parseInt(target.dataset.insurancePrice || '0')
    
    // Update hidden form field
    this.insurancePriceInputTarget.value = this.selectedInsurancePrice.toString()
    
    // Update visual state of all insurance cards
    this.updateInsuranceCardsUI()
    
    // Update total price
    this.updateTotalPrice()
  }

  private selectDefaultInsurance(): void {
    // Default to "none" insurance
    this.selectedInsuranceType = 'none'
    this.selectedInsurancePrice = 0
    this.insurancePriceInputTarget.value = '0'
    this.updateInsuranceCardsUI()
  }

  private updateInsuranceCardsUI(): void {
    if (!this.hasInsuranceCardTarget) return
    
    this.insuranceCardTargets.forEach((card, index) => {
      const cardType = card.dataset.insuranceType || 'none'
      const checkmark = this.checkmarkTargets[index]
      
      if (cardType === this.selectedInsuranceType) {
        // Selected card styling
        this.applySelectedStyle(card, checkmark, cardType)
      } else {
        // Unselected card styling
        this.applyUnselectedStyle(card, checkmark, cardType)
      }
    })
  }

  private applySelectedStyle(card: HTMLElement, checkmark: HTMLElement, type: string): void {
    if (type === 'none') {
      card.classList.add('border-[#FFD944]')
      card.classList.remove('border-gray-100')
      checkmark?.classList.remove('text-gray-300')
      checkmark?.classList.add('text-[#FFD944]')
    } else if (type === 'basic') {
      card.classList.add('bg-[#FFFAED]', 'border-[#FFD944]')
      card.classList.remove('bg-gray-50', 'border-gray-100')
      checkmark?.classList.remove('text-gray-300')
      checkmark?.classList.add('text-[#FFD944]')
    } else if (type === 'premium') {
      card.classList.add('bg-[#F0F7FF]', 'border-[#5D9CEC]')
      card.classList.remove('bg-gray-50', 'border-gray-100')
      checkmark?.classList.remove('text-gray-300')
      checkmark?.classList.add('text-[#5D9CEC]')
    }
  }

  private applyUnselectedStyle(card: HTMLElement, checkmark: HTMLElement, type: string): void {
    if (type === 'none') {
      card.classList.remove('border-[#FFD944]')
      card.classList.add('border-gray-100')
      checkmark?.classList.add('text-gray-300')
      checkmark?.classList.remove('text-[#FFD944]')
    } else {
      card.classList.remove('bg-[#FFFAED]', 'bg-[#F0F7FF]', 'border-[#FFD944]', 'border-[#5D9CEC]')
      card.classList.add('bg-gray-50', 'border-gray-100')
      checkmark?.classList.add('text-gray-300')
      checkmark?.classList.remove('text-[#FFD944]', 'text-[#5D9CEC]')
    }
  }

  updateTotalPrice(): void {
    const quantity = parseInt(this.quantityInputTarget.value) || 0
    const pricePerPerson = this.basePrice + this.selectedInsurancePrice
    const totalPrice = pricePerPerson * quantity
    
    this.totalPriceTarget.textContent = totalPrice.toString()
  }
}
