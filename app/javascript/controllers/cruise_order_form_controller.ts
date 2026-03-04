import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = [
    "modal", "nameInput", "phoneInput", "emailInput", "contactItem",
    "insuranceCard", "checkmark", "insurancePriceInput", "insuranceTypeInput", "quantityInput",
    "totalPrice", "submitBtn", "form", "acceptTermsCheckbox", "termsSection", "termsError",
    "quantityDisplay", "decrementBtn", "passengerCountDisplay"
  ]

  declare readonly modalTarget: HTMLElement
  declare readonly nameInputTarget: HTMLInputElement
  declare readonly phoneInputTarget: HTMLInputElement
  declare readonly emailInputTarget: HTMLInputElement
  declare readonly contactItemTargets: HTMLElement[]
  declare readonly insuranceCardTargets: HTMLElement[]
  declare readonly checkmarkTargets: HTMLElement[]
  declare readonly insurancePriceInputTarget: HTMLInputElement
  declare readonly insuranceTypeInputTarget: HTMLInputElement
  declare readonly quantityInputTarget: HTMLInputElement
  declare readonly totalPriceTarget: HTMLElement
  declare readonly submitBtnTarget: HTMLButtonElement
  declare readonly formTarget: HTMLFormElement
  declare readonly acceptTermsCheckboxTarget: HTMLInputElement
  declare readonly termsSectionTarget: HTMLElement
  declare readonly termsErrorTarget: HTMLElement
  declare readonly quantityDisplayTarget: HTMLElement
  declare readonly decrementBtnTarget: HTMLButtonElement
  declare readonly passengerCountDisplayTarget: HTMLElement
  declare readonly hasModalTarget: boolean
  declare readonly hasContactItemTarget: boolean
  declare readonly hasInsuranceCardTarget: boolean

  private selectedInsuranceType: string = 'none'
  private selectedInsurancePrice: number = 0
  private basePrice: number = 0
  private occupancyRequirement: number = 1

  connect(): void {
    console.log("CruiseOrderForm connected")
    
    // Get base price from totalPrice element
    this.basePrice = parseFloat(this.totalPriceTarget.dataset.basePrice || '0')
    
    // Get occupancy requirement from quantity input
    this.occupancyRequirement = parseInt(this.quantityInputTarget.dataset.occupancyRequirement || '1')
    
    // Restore insurance selection from form values (may come from URL params)
    const insuranceType = this.insuranceTypeInputTarget.value
    const insurancePrice = parseInt(this.insurancePriceInputTarget.value || '0')
    
    if (insuranceType && insuranceType !== 'none') {
      // Restore from URL params (coming back from confirm page)
      this.selectedInsuranceType = insuranceType
      this.selectedInsurancePrice = insurancePrice
    } else {
      // Default to "none" insurance
      this.selectDefaultInsurance()
    }
    
    // Update quantity display from hidden field value
    const quantity = parseInt(this.quantityInputTarget.value) || this.occupancyRequirement
    this.quantityDisplayTarget.textContent = quantity.toString()
    
    // Update UI states
    this.updateInsuranceCardsUI()
    this.updateDecrementButtonState()
    this.updateTotalPrice()
    
    // Add form submit event listener for validation
    this.formTarget.addEventListener('submit', this.validateForm.bind(this))
  }

  validateForm(event: Event): boolean {
    // Sync passenger data from cruise-traveler-selector controller before validation
    const travelerSelectorElement = document.querySelector('[data-controller~="cruise-traveler-selector"]')
    if (travelerSelectorElement) {
      const travelerController = this.application.getControllerForElementAndIdentifier(
        travelerSelectorElement as HTMLElement,
        'cruise-traveler-selector'
      ) as any
      
      if (travelerController && travelerController.syncPassengerData) {
        travelerController.syncPassengerData()
        console.log('Synced passenger data before form submission')
      }
    }
    
    // Check if accept_terms checkbox is checked
    if (!this.acceptTermsCheckboxTarget.checked) {
      event.preventDefault()
      
      // Show error message
      this.termsErrorTarget.classList.remove('hidden')
      
      // Add red border to terms section
      this.termsSectionTarget.classList.add('border-2', 'border-red-300', 'shadow-lg')
      
      // Scroll to terms section
      this.termsSectionTarget.scrollIntoView({ behavior: 'smooth', block: 'center' })
      
      // Shake animation
      this.termsSectionTarget.style.animation = 'shake 0.5s'
      setTimeout(() => {
        this.termsSectionTarget.style.animation = ''
      }, 500)
      
      return false
    }
    return true
  }
  
  clearTermsError(): void {
    // Hide error message when checkbox is checked
    this.termsErrorTarget.classList.add('hidden')
    this.termsSectionTarget.classList.remove('border-2', 'border-red-300', 'shadow-lg')
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
    
    // Update hidden form fields
    this.insurancePriceInputTarget.value = this.selectedInsurancePrice.toString()
    this.insuranceTypeInputTarget.value = this.selectedInsuranceType
    
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
    this.insuranceTypeInputTarget.value = 'none'
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
    
    // Sync amount to payment-confirmation controller
    this.element.dispatchEvent(new CustomEvent('payment-confirmation:amount-changed', {
      bubbles: true,
      detail: { amount: totalPrice }
    }))
  }

  incrementQuantity(): void {
    const currentQuantity = parseInt(this.quantityInputTarget.value) || this.occupancyRequirement
    const newQuantity = currentQuantity + this.occupancyRequirement
    
    this.quantityInputTarget.value = newQuantity.toString()
    this.quantityDisplayTarget.textContent = newQuantity.toString()
    this.passengerCountDisplayTarget.textContent = newQuantity.toString()
    
    // Update passenger cards via cruise-traveler-selector controller
    this.updatePassengerCards(newQuantity)
    
    this.updateDecrementButtonState()
    this.updateTotalPrice()
  }

  decrementQuantity(): void {
    const currentQuantity = parseInt(this.quantityInputTarget.value) || this.occupancyRequirement
    const newQuantity = currentQuantity - this.occupancyRequirement
    
    // Don't allow going below the minimum occupancy requirement
    if (newQuantity >= this.occupancyRequirement) {
      this.quantityInputTarget.value = newQuantity.toString()
      this.quantityDisplayTarget.textContent = newQuantity.toString()
      this.passengerCountDisplayTarget.textContent = newQuantity.toString()
      
      // Update passenger cards via cruise-traveler-selector controller
      this.updatePassengerCards(newQuantity)
      
      this.updateDecrementButtonState()
      this.updateTotalPrice()
    }
  }

  private updateDecrementButtonState(): void {
    const currentQuantity = parseInt(this.quantityInputTarget.value) || this.occupancyRequirement
    
    // Disable decrement button if we're at the minimum
    if (currentQuantity <= this.occupancyRequirement) {
      this.decrementBtnTarget.disabled = true
    } else {
      this.decrementBtnTarget.disabled = false
    }
  }

  // Update passenger cards in cruise-traveler-selector controller
  private updatePassengerCards(quantity: number): void {
    const travelerSelectorElement = document.querySelector('[data-controller~="cruise-traveler-selector"]')
    if (travelerSelectorElement) {
      const travelerController = this.application.getControllerForElementAndIdentifier(
        travelerSelectorElement as HTMLElement,
        'cruise-traveler-selector'
      ) as any
      
      if (travelerController && travelerController.updatePassengerCards) {
        travelerController.updatePassengerCards(quantity)
      }
    }
  }

  handleOrderCreated(event: CustomEvent): void {
    const [data, status, xhr] = event.detail
    
    if (data.success) {
      console.log('Order created successfully:', data)
      
      // Get payment-confirmation controller from the element
      const paymentController = this.application.getControllerForElementAndIdentifier(
        this.element,
        'payment-confirmation'
      ) as any
      
      if (paymentController) {
        // Set payment data
        paymentController.amountValue = data.amount.toString()
        paymentController.paymentUrlValue = data.payment_url
        paymentController.successUrlValue = data.success_url
        
        // Show payment modal
        paymentController.showPasswordModal()
      } else {
        console.error('Payment confirmation controller not found')
        alert('创建订单成功，但无法打开支付窗口')
      }
    } else {
      const errorMessage = data.errors ? data.errors.join(', ') : '未知错误'
      alert(`创建订单失败：${errorMessage}`)
      this.resetSubmitButton()
    }
  }

  handleOrderError(event: CustomEvent): void {
    const [data, status, xhr] = event.detail
    console.error('Order creation failed:', event.detail)
    
    // 尝试解析 JSON 错误响应
    if (data && data.errors) {
      const errorMessage = data.errors.join('\n')
      alert(`创建订单失败：\n\n${errorMessage}`)
    } else if (xhr && xhr.responseText) {
      try {
        const errorData = JSON.parse(xhr.responseText)
        if (errorData.errors) {
          alert(`创建订单失败：\n\n${errorData.errors.join('\n')}`)
        } else {
          alert('创建订单失败，请检查表单信息')
        }
      } catch {
        alert('创建订单失败，请检查表单信息')
      }
    } else {
      alert('创建订单失败，请检查表单信息')
    }
    
    this.resetSubmitButton()
  }

  private resetSubmitButton(): void {
    if (this.submitBtnTarget) {
      this.submitBtnTarget.disabled = false
      this.submitBtnTarget.textContent = '立即支付'
    }
  }
}
