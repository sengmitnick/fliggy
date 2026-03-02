import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    bookingId: Number,
    groupSize: Number
  }

  declare bookingIdValue: number
  declare groupSizeValue: number

  private baseAmount: number = 0
  private currentServicePrice: number = 0

  connect(): void {
    // Initialize default selection visual style on page load
    this.initializeDefaultSelection()
    
    // Store the base amount (without additional services)
    const amountElement = document.querySelector('[data-payment-confirmation-amount-value]') as HTMLElement
    if (amountElement) {
      this.baseAmount = parseInt(amountElement.dataset.paymentConfirmationAmountValue || '0')
    }
  }

  selectInsurance(event: Event): void {
    const radio = event.target as HTMLInputElement
    const card = radio.closest('[data-insurance-card]') as HTMLElement
    
    if (!card) return

    // Remove selection styles from all cards
    const allCards = this.element.querySelectorAll('[data-insurance-card]')
    allCards.forEach(c => {
      const cardElement = c as HTMLElement
      // Reset to default border
      cardElement.classList.remove('border-purple-400', 'bg-purple-50', 'border-orange-400', 'bg-orange-50', 'border-gray-400')
      cardElement.classList.add('border-gray-300')
      
      // Hide checkmark
      const checkmark = cardElement.querySelector('.bg-yellow-400') as HTMLElement
      if (checkmark) {
        checkmark.style.display = 'none'
      }
    })

    // Get insurance type and price from radio button
    const insuranceType = radio.dataset.insuranceType || 'none'
    const pricePerPerson = parseInt(radio.dataset.insurancePrice || '0')

    // Apply selection styles to selected card based on insurance type
    if (insuranceType === 'standard') {
      card.classList.remove('border-gray-300')
      card.classList.add('border-purple-400', 'bg-purple-50')
    } else if (insuranceType === 'premium') {
      card.classList.remove('border-gray-300')
      card.classList.add('border-orange-400', 'bg-orange-50')
    } else {
      // 'none' insurance - just show gray border and checkmark
      card.classList.remove('border-gray-300')
      card.classList.add('border-gray-400')
    }

    // Show checkmark for selected card
    const checkmark = card.querySelector('.bg-yellow-400') as HTMLElement
    if (checkmark) {
      checkmark.style.display = 'flex'
    }

    // Calculate total service price (price per person × number of passengers)
    const totalServicePrice = pricePerPerson * this.groupSizeValue
    const priceDifference = totalServicePrice - this.currentServicePrice
    this.currentServicePrice = totalServicePrice

    // Update the total amount
    const newTotalAmount = this.baseAmount + this.currentServicePrice
    this.updatePriceDisplay(newTotalAmount)

    // Update the additional service detail item visibility and content
    this.updateAdditionalServiceDetail(insuranceType, totalServicePrice)

    // Notify payment-confirmation controller about price change
    this.dispatchPriceChangeEvent(newTotalAmount)

    // Call backend API to persist selection
    this.updateAdditionalService(insuranceType, totalServicePrice)
  }

  private initializeDefaultSelection(): void {
    // Find the default checked radio button (无附加服务)
    const defaultRadio = this.element.querySelector('input[name="additional_service_selection"][checked]') as HTMLInputElement
    
    if (defaultRadio) {
      const card = defaultRadio.closest('[data-insurance-card]') as HTMLElement
      if (card) {
        // Apply default selection style (gray border + checkmark)
        card.classList.remove('border-gray-300')
        card.classList.add('border-gray-400')
        
        // Show checkmark
        const checkmark = card.querySelector('.bg-yellow-400') as HTMLElement
        if (checkmark) {
          checkmark.style.display = 'flex'
        }
      }
    }
  }

  private updateAdditionalServiceDetail(serviceType: string, servicePrice: number): void {
    const serviceItem = document.querySelector('[data-additional-service-item]') as HTMLElement
    const serviceName = document.querySelector('[data-additional-service-name]') as HTMLElement
    const servicePriceElement = document.querySelector('[data-additional-service-price]') as HTMLElement

    if (!serviceItem || !serviceName || !servicePriceElement) return

    if (serviceType === 'none' || servicePrice === 0) {
      // Hide the additional service item if "无附加服务" is selected
      serviceItem.style.display = 'none'
    } else {
      // Show and update the additional service item
      serviceItem.style.display = 'flex'
      
      // Update service name based on type
      let serviceLabelName = '附加服务'
      if (serviceType === 'standard') {
        serviceLabelName = '附加服务（标准版）'
      } else if (serviceType === 'premium') {
        serviceLabelName = '附加服务（尊享版）'
      }
      serviceName.textContent = `${serviceLabelName} × ${this.groupSizeValue}人`
      
      // Update service price
      servicePriceElement.textContent = `¥${servicePrice}`
    }
  }

  private updatePriceDisplay(newAmount: number): void {
    // Update all price displays on the page
    const priceElements = document.querySelectorAll('[data-price-display]')
    priceElements.forEach(element => {
      const priceEl = element as HTMLElement
      priceEl.textContent = `¥${newAmount}`
    })

    // Also update the payment-confirmation controller's amount value
    const paymentContainer = document.querySelector('[data-controller="payment-confirmation"]') as HTMLElement
    if (paymentContainer) {
      paymentContainer.dataset.paymentConfirmationAmountValue = newAmount.toString()
    }
  }

  private dispatchPriceChangeEvent(newAmount: number): void {
    // Dispatch custom event to notify payment-confirmation controller
    const event = new CustomEvent('payment-confirmation:amount-changed', {
      bubbles: true,
      detail: { amount: newAmount }
    })
    this.element.dispatchEvent(event)
  }

  private async updateAdditionalService(serviceType: string, servicePrice: number): Promise<void> {
    try {
      const response = await fetch(`/bookings/${this.bookingIdValue}/update_additional_service`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-CSRF-Token': document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content || ''
        },
        body: JSON.stringify({
          additional_service_type: serviceType,
          additional_service_price: servicePrice
        })
      })

      if (!response.ok) {
        console.error('Failed to update additional service')
      }
    } catch (error) {
      console.error('Error updating additional service:', error)
    }
  }
}
