import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = [
    "checkIcon",
    "passengerCount",
    "totalPrice",
    "contactPhone",
    "formData",
    "contactModal",
    "contactItem"
  ]

  declare readonly checkIconTargets: HTMLElement[]
  declare readonly passengerCountTarget: HTMLElement
  declare readonly totalPriceTarget: HTMLElement
  declare readonly contactPhoneTarget: HTMLInputElement
  declare readonly formDataTarget: HTMLElement
  declare readonly contactModalTarget: HTMLElement
  declare readonly contactItemTargets: HTMLElement[]

  private selectedPassengers: Set<string> = new Set()
  private basePrice: number = 0
  private insurancePrice: number = 0
  private insuranceType: string = 'none'
  private submitButton: HTMLButtonElement | null = null // 保存提交按钮引用

  connect(): void {
    console.log("BusTicketOrder connected")
    
    // 监听支付模态框关闭事件
    document.addEventListener('payment-modal-closed', this.handlePaymentModalClosed.bind(this))
    
    // Read initial insurance data from form data element
    this.insuranceType = this.formDataTarget.dataset.insuranceType || 'none'
    this.insurancePrice = parseInt(this.formDataTarget.dataset.insurancePrice || '0')
    
    // Restore selected passengers from URL params
    const selectedIds = this.formDataTarget.dataset.selectedPassengerIds || ''
    if (selectedIds) {
      // Restore previously selected passengers
      const passengerIds = selectedIds.split(',').filter(id => id.trim())
      passengerIds.forEach(passengerId => {
        const passengerElement = this.element.querySelector(`[data-passenger-id="${passengerId}"]`) as HTMLElement
        if (passengerElement) {
          this.selectedPassengers.add(passengerId)
          this.updatePassengerUI(passengerElement, true)
        }
      })
    } else {
      // Auto-select first passenger if no previous selection
      const firstPassenger = this.element.querySelector('[data-passenger-id]') as HTMLElement
      if (firstPassenger) {
        const passengerId = firstPassenger.dataset.passengerId
        if (passengerId) {
          this.selectedPassengers.add(passengerId)
          this.updatePassengerUI(firstPassenger, true)
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
    }
    
    this.updateTotal()
  }

  prepareAddPassenger(event: Event): void {
    // Get the link element
    const link = event.currentTarget as HTMLAnchorElement
    const originalHref = link.getAttribute('href')
    
    if (!originalHref) return
    
    // Build selected passenger IDs query string
    const selectedIds = Array.from(this.selectedPassengers).join(',')
    
    // Update the href with selected_passenger_ids parameter
    const url = new URL(originalHref, window.location.origin)
    if (selectedIds) {
      url.searchParams.set('selected_passenger_ids', selectedIds)
    }
    
    link.href = url.pathname + url.search
  }

  editContactPhone(event: Event): void {
    // Focus on the input field when clicking the container
    this.contactPhoneTarget.focus()
  }

  openContactSelector(): void {
    this.contactModalTarget.classList.remove('hidden')
    document.body.style.overflow = 'hidden'
    this.updateContactSelection()
  }

  closeContactSelector(): void {
    this.contactModalTarget.classList.add('hidden')
    document.body.style.overflow = ''
  }

  selectContact(event: Event): void {
    const element = event.currentTarget as HTMLElement
    const phone = element.dataset.contactPhone || ''
    
    // Fill in the phone field
    this.contactPhoneTarget.value = phone
    
    // Update visual selection state
    this.updateContactSelection()
    
    // Close modal
    this.closeContactSelector()
  }

  private updateContactSelection(): void {
    const currentPhone = this.contactPhoneTarget.value.trim()
    
    this.contactItemTargets.forEach(item => {
      const itemPhone = item.dataset.contactPhone || ''
      const isMatch = currentPhone && itemPhone === currentPhone
      
      const circle = item.querySelector('.w-6.h-6.rounded-full') as HTMLElement
      const checkIcon = circle?.querySelector('svg')
      
      if (isMatch) {
        item.classList.add('bg-blue-50', 'border-blue-500')
        item.classList.remove('bg-surface')
        circle?.classList.add('border-blue-600', 'bg-blue-600')
        circle?.classList.remove('border-gray-300')
        checkIcon?.classList.remove('hidden')
        checkIcon?.classList.add('text-white')
      } else {
        item.classList.remove('bg-blue-50', 'border-blue-500')
        item.classList.add('bg-surface')
        circle?.classList.remove('border-blue-600', 'bg-blue-600')
        circle?.classList.add('border-gray-300')
        checkIcon?.classList.add('hidden')
        checkIcon?.classList.remove('text-white')
      }
    })
  }

  showComingSoon(event: Event): void {
    event.preventDefault()
    event.stopPropagation()
    
    // Use window.showToast to display coming soon message
    if (typeof (window as any).showToast === 'function') {
      (window as any).showToast('精彩即将上线', 'info')
    } else {
      console.warn('showToast function not available')
      alert('精彩即将上线')
    }
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
      
      // Find the check icon container (last div with svg inside)
      const allDivs = cardElement.querySelectorAll('div')
      const checkIconContainer = Array.from(allDivs).find(div => {
        const svg = div.querySelector('svg')
        return svg && div.classList.contains('mt-auto')
      }) as HTMLElement | undefined
      
      if (cardType === this.insuranceType) {
        // Selected card styling
        if (cardType === 'none') {
          cardElement.classList.remove('border-gray-100')
          cardElement.classList.add('border-[#FFD944]')
          if (checkIconContainer) {
            checkIconContainer.classList.remove('text-gray-300')
            checkIconContainer.classList.add('text-[#FFD944]')
          }
        } else if (cardType === 'premium') {
          cardElement.classList.remove('bg-gray-50', 'border-gray-100')
          cardElement.classList.add('bg-[#FFFAED]', 'border-[#FFD944]')
          if (checkIconContainer) {
            checkIconContainer.classList.remove('text-gray-300')
            checkIconContainer.classList.add('text-[#FFD944]')
          }
        } else if (cardType === 'refund') {
          cardElement.classList.remove('bg-gray-50', 'border-gray-100')
          cardElement.classList.add('bg-[#F0F7FF]', 'border-[#5D9CEC]')
          if (checkIconContainer) {
            checkIconContainer.classList.remove('text-gray-300')
            checkIconContainer.classList.add('text-[#5D9CEC]')
          }
        }
      } else {
        // Unselected card styling
        if (cardType === 'none') {
          cardElement.classList.remove('border-[#FFD944]')
          cardElement.classList.add('border-gray-100')
          if (checkIconContainer) {
            checkIconContainer.classList.remove('text-[#FFD944]')
            checkIconContainer.classList.add('text-gray-300')
          }
        } else if (cardType === 'premium') {
          cardElement.classList.remove('bg-[#FFFAED]', 'border-[#FFD944]')
          cardElement.classList.add('bg-gray-50', 'border-gray-100')
          if (checkIconContainer) {
            checkIconContainer.classList.remove('text-[#FFD944]')
            checkIconContainer.classList.add('text-gray-300')
          }
        } else if (cardType === 'refund') {
          cardElement.classList.remove('bg-[#F0F7FF]', 'border-[#5D9CEC]')
          cardElement.classList.add('bg-gray-50', 'border-gray-100')
          if (checkIconContainer) {
            checkIconContainer.classList.remove('text-[#5D9CEC]')
            checkIconContainer.classList.add('text-gray-300')
          }
        }
      }
    })
    
    this.updateTotal()
  }

  async submitOrder(event: Event): Promise<void> {
    event.preventDefault()
    
    const button = event.currentTarget as HTMLButtonElement
    this.submitButton = button // 保存按钮引用
    const busTicketId = button.dataset.busTicketId
    const basePrice = parseInt(button.dataset.basePrice || '0')
    
    // Store base price for calculations
    this.basePrice = basePrice
    
    // Validate passenger selection
    if (this.selectedPassengers.size === 0) {
      alert('请至少选择一位乘车人')
      return
    }
    
    // Validate contact phone
    const contactPhone = this.contactPhoneTarget.value.trim()
    if (!contactPhone) {
      alert('请输入取票电话')
      this.contactPhoneTarget.focus()
      return
    }
    
    // Validate phone format (11 digits)
    const phoneRegex = /^1[3-9]\d{9}$/
    if (!phoneRegex.test(contactPhone)) {
      alert('请输入正确的手机号码')
      this.contactPhoneTarget.focus()
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

  // 处理支付模态框关闭事件，恢复按钮状态
  private handlePaymentModalClosed(event: Event): void {
    if (this.submitButton) {
      this.submitButton.disabled = false
      this.submitButton.textContent = '去支付'
    }
  }
}
