import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = [
    "checkIcon",
    "passengerCount",
    "totalPrice",
    "contactPhone",
    "formData"
  ]

  declare readonly checkIconTargets: HTMLElement[]
  declare readonly passengerCountTarget: HTMLElement
  declare readonly totalPriceTarget: HTMLElement
  declare readonly contactPhoneTarget: HTMLElement
  declare readonly formDataTarget: HTMLElement

  private selectedPassengers: Set<string> = new Set()
  private basePrice: number = 0
  private insurancePrice: number = 0
  private insuranceType: string = 'none'

  connect(): void {
    console.log("BusTicketOrder connected")
    
    // Read initial insurance data from form data element
    this.insuranceType = this.formDataTarget.dataset.insuranceType || 'none'
    this.insurancePrice = parseInt(this.formDataTarget.dataset.insurancePrice || '0')
    
    // Auto-select first passenger if exists
    const firstPassenger = this.element.querySelector('[data-passenger-id]') as HTMLElement
    if (firstPassenger) {
      const passengerId = firstPassenger.dataset.passengerId
      if (passengerId) {
        this.selectedPassengers.add(passengerId)
        this.updatePassengerUI(firstPassenger, true)
        
        // Update contact phone with first passenger's phone
        const phone = firstPassenger.dataset.passengerPhone
        if (phone) {
          this.contactPhoneTarget.textContent = phone
        }
      }
    }
    
    this.updateTotal()
  }

  togglePassenger(event: Event): void {
    const target = event.currentTarget as HTMLElement
    const passengerId = target.dataset.passengerId
    
    if (!passengerId) return
    
    // Check if already selected
    if (this.selectedPassengers.has(passengerId)) {
      this.selectedPassengers.delete(passengerId)
      this.updatePassengerUI(target, false)
    } else {
      // Check max limit (5 passengers)
      if (this.selectedPassengers.size >= 5) {
        alert('最多只能选择5位乘车人')
        return
      }
      
      this.selectedPassengers.add(passengerId)
      this.updatePassengerUI(target, true)
      
      // If this is the first selection, update contact phone
      if (this.selectedPassengers.size === 1) {
        const phone = target.dataset.passengerPhone
        if (phone) {
          this.contactPhoneTarget.textContent = phone
        }
      }
    }
    
    this.updateTotal()
  }

  selectInsurance(event: Event): void {
    const target = event.currentTarget as HTMLElement
    this.insuranceType = target.dataset.insuranceType || 'none'
    this.insurancePrice = parseInt(target.dataset.insurancePrice || '0')
    
    // Update UI: highlight selected insurance card
    const allInsuranceCards = this.element.querySelectorAll('[data-insurance-type]')
    allInsuranceCards.forEach(card => {
      const cardElement = card as HTMLElement
      const cardType = cardElement.dataset.insuranceType
      const checkIcon = cardElement.querySelector('svg:last-child')
      
      if (cardType === this.insuranceType) {
        // Selected card styling
        if (cardType === 'none') {
          cardElement.classList.add('border-[#FFD944]')
          cardElement.classList.remove('border-gray-100')
          if (checkIcon) checkIcon.classList.remove('text-gray-300')
          if (checkIcon) checkIcon.classList.add('text-[#FFD944]')
        } else if (cardType === 'premium') {
          cardElement.classList.add('bg-[#FFFAED]', 'border-[#FFD944]')
          cardElement.classList.remove('bg-gray-50', 'border-gray-100')
          if (checkIcon) checkIcon.classList.remove('text-gray-300')
          if (checkIcon) checkIcon.classList.add('text-[#FFD944]')
        } else if (cardType === 'refund') {
          cardElement.classList.add('bg-[#F0F7FF]', 'border-[#5D9CEC]')
          cardElement.classList.remove('bg-gray-50', 'border-gray-100')
          if (checkIcon) checkIcon.classList.remove('text-gray-300')
          if (checkIcon) checkIcon.classList.add('text-[#5D9CEC]')
        }
      } else {
        // Unselected card styling
        if (cardType === 'none') {
          cardElement.classList.remove('border-[#FFD944]')
          cardElement.classList.add('border-gray-100')
          if (checkIcon) checkIcon.classList.add('text-gray-300')
          if (checkIcon) checkIcon.classList.remove('text-[#FFD944]')
        } else {
          cardElement.classList.remove('bg-[#FFFAED]', 'bg-[#F0F7FF]', 'border-[#FFD944]', 'border-[#5D9CEC]')
          cardElement.classList.add('bg-gray-50', 'border-gray-100')
          if (checkIcon) checkIcon.classList.add('text-gray-300')
          if (checkIcon) checkIcon.classList.remove('text-[#FFD944]', 'text-[#5D9CEC]')
        }
      }
    })
    
    this.updateTotal()
  }

  async submitOrder(event: Event): Promise<void> {
    event.preventDefault()
    
    const button = event.currentTarget as HTMLButtonElement
    const busTicketId = button.dataset.busTicketId
    const basePrice = parseInt(button.dataset.basePrice || '0')
    
    // Store base price for calculations
    this.basePrice = basePrice
    
    // Validate passenger selection
    if (this.selectedPassengers.size === 0) {
      alert('请至少选择一位乘车人')
      return
    }
    
    // Get passenger details for submission
    const passengerIds = Array.from(this.selectedPassengers)
    const totalPrice = this.calculateTotal()
    const totalInsurancePrice = this.insurancePrice * passengerIds.length
    
    // Prepare order data
    const orderData = {
      bus_ticket_order: {
        bus_ticket_id: busTicketId,
        passenger_ids: passengerIds,
        insurance_type: this.insuranceType,
        insurance_price: totalInsurancePrice,
        total_price: totalPrice
      }
    }
    
    // Disable button during submission
    button.disabled = true
    button.textContent = '创建中...'
    
    try {
      // Create order via AJAX
      const csrfToken = document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content || ''
      const response = await fetch('/bus_ticket_orders', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': csrfToken
        },
        body: JSON.stringify(orderData)
      })
      
      const data = await response.json()
      
      if (response.ok && data.success) {
        // Order created successfully, trigger payment modal
        this.triggerPaymentModal(totalPrice.toString(), data.payment_url, data.success_url)
      } else {
        throw new Error(data.message || '创建订单失败')
      }
    } catch (error) {
      console.error('Error creating order:', error)
      const message = error instanceof Error ? error.message : '创建订单失败，请重试'
      alert(message)
      button.disabled = false
      button.textContent = '去支付'
    }
  }

  private triggerPaymentModal(amount: string, paymentUrl: string, successUrl: string): void {
    // Find payment-confirmation controller and trigger it
    const paymentElement = document.querySelector('[data-controller*="payment-confirmation"]') as HTMLElement
    
    if (!paymentElement) {
      console.error('Payment confirmation controller not found')
      alert('支付系统未加载，请刷新页面重试')
      return
    }
    
    // Get the Stimulus controller instance
    const app = (window as any).Stimulus
    if (!app) {
      console.error('Stimulus not found')
      alert('系统错误，请刷新页面重试')
      return
    }
    
    const paymentController = app.getControllerForElementAndIdentifier(paymentElement, 'payment-confirmation')
    
    if (paymentController) {
      // Set values
      paymentController.amountValue = amount
      // Get current user email from meta tag or element
      const userEmail = document.querySelector<HTMLMetaElement>('meta[name="user-email"]')?.content || 
                       document.querySelector('[data-user-email]')?.getAttribute('data-user-email') ||
                       'demo@example.com'
      paymentController.userEmailValue = userEmail
      paymentController.paymentUrlValue = paymentUrl
      paymentController.successUrlValue = successUrl
      
      // Show password modal
      paymentController.showPasswordModal()
    } else {
      console.error('Payment controller not initialized')
      alert('支付系统未初始化，请刷新页面重试')
    }
  }

  private updatePassengerUI(element: HTMLElement, selected: boolean): void {
    const checkIcon = element.querySelector('[data-bus-ticket-order-target="checkIcon"]') as HTMLElement
    if (checkIcon) {
      if (selected) {
        checkIcon.classList.remove('text-gray-300')
        checkIcon.classList.add('text-[#FFD944]')
      } else {
        checkIcon.classList.add('text-gray-300')
        checkIcon.classList.remove('text-[#FFD944]')
      }
    }
  }

  private updateTotal(): void {
    const passengerCount = this.selectedPassengers.size
    this.passengerCountTarget.textContent = `共${passengerCount}人`
    
    const total = this.calculateTotal()
    this.totalPriceTarget.textContent = total.toString()
  }

  private calculateTotal(): number {
    const passengerCount = this.selectedPassengers.size
    if (passengerCount === 0) return 0
    
    // Get base price from button or formData
    const button = this.element.querySelector('[data-base-price]') as HTMLElement
    const basePrice = parseInt(button?.dataset.basePrice || '0')
    
    return (basePrice + this.insurancePrice) * passengerCount
  }
}
