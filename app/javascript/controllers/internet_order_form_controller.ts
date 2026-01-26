import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = [
    "quantity", "totalPrice", "quantityField", "totalPriceField", 
    "mailSection", "pickupSection", "mailLabel", "pickupLabel", 
    "rentalDays", "rentalDaysField", "rentalInfoField",
    "quantityDisplay", "rentalDaysDisplay", "totalPriceDisplay"
  ]
  declare readonly quantityTarget: HTMLElement
  declare readonly totalPriceTarget: HTMLElement
  declare readonly hasTotalPriceTarget: boolean
  declare readonly quantityFieldTarget: HTMLInputElement
  declare readonly hasQuantityFieldTarget: boolean
  declare readonly totalPriceFieldTarget: HTMLInputElement
  declare readonly hasTotalPriceFieldTarget: boolean
  declare readonly quantityDisplayTarget: HTMLElement
  declare readonly hasQuantityDisplayTarget: boolean
  declare readonly rentalDaysTarget: HTMLInputElement
  declare readonly hasRentalDaysTarget: boolean
  declare readonly rentalDaysDisplayTarget: HTMLElement
  declare readonly hasRentalDaysDisplayTarget: boolean
  declare readonly totalPriceDisplayTarget: HTMLElement
  declare readonly hasTotalPriceDisplayTarget: boolean

  private basePrice: number = 0
  private formElement: HTMLFormElement | null = null
  private isWifiOrder: boolean = false

  connect(): void {
    console.log("InternetOrderForm connected")
    const totalPriceField = this.element.querySelector('[data-internet-order-form-target="totalPriceField"]') as HTMLInputElement
    if (totalPriceField) {
      this.basePrice = parseFloat(totalPriceField.value) || 0
    }
    
    // Check if this is a WiFi order
    const orderTypeField = this.element.querySelector('input[name="internet_order[order_type]"]') as HTMLInputElement
    this.isWifiOrder = orderTypeField?.value === 'wifi'
    
    // For WiFi orders, recalculate initial total price (quantity × days × daily_price)
    if (this.isWifiOrder && this.hasRentalDaysTarget) {
      const days = parseInt(this.rentalDaysTarget.value) || 7
      const quantity = 1
      const total = this.basePrice * days * quantity
      this.updateAllPriceDisplays(total)
    }
    
    // Store form reference
    this.formElement = this.element.querySelector('form')
    
    // Intercept form submission
    if (this.formElement) {
      this.formElement.addEventListener('submit', this.handleFormSubmit.bind(this))
    }
  }

  disconnect(): void {
    if (this.formElement) {
      this.formElement.removeEventListener('submit', this.handleFormSubmit.bind(this))
    }
  }

  async handleFormSubmit(event: Event): Promise<void> {
    event.preventDefault()
    
    const form = event.target as HTMLFormElement
    const submitButton = form.querySelector('[type="submit"]') as HTMLButtonElement
    
    if (!submitButton) return
    
    // Disable button during submission
    submitButton.disabled = true
    const originalText = submitButton.textContent
    submitButton.textContent = '创建订单中...'
    
    try {
      const formData = new FormData(form)
      const csrfToken = document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content || ''
      
      const response = await fetch(form.action, {
        method: 'POST',
        headers: {
          'Accept': 'application/json',
          'X-CSRF-Token': csrfToken
        },
        body: formData
      })
      
      const data = await response.json()
      
      if (response.ok && data.success) {
        // Order created successfully, trigger payment modal
        const totalPrice = this.hasTotalPriceFieldTarget ? this.totalPriceFieldTarget.value : '0'
        this.triggerPaymentModal(totalPrice, data.payment_url, data.success_url)
        
        // Keep button disabled until payment completes
        submitButton.textContent = '等待支付...'
      } else {
        throw new Error(data.message || '创建订单失败')
      }
    } catch (error) {
      console.error('Error creating order:', error)
      const message = error instanceof Error ? error.message : '创建订单失败，请重试'
      if (typeof (window as any).showToast === 'function') {
        (window as any).showToast(message)
      } else {
        alert(message)
      }
      submitButton.disabled = false
      submitButton.textContent = originalText || '确认支付'
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

  selectAddress(event: Event): void {
    const radio = event.target as HTMLInputElement
    const selectedIndex = parseInt(radio.value)
    
    // 找到所有地址的label
    const labels = this.element.querySelectorAll('[data-internet-order-form-target="mailSection"] label')
    
    labels.forEach((label, index) => {
      // 更新样式
      if (index === selectedIndex) {
        label.classList.add('border-[#FFDD00]', 'bg-[#FFFEF8]')
        label.classList.remove('border-gray-200')
      } else {
        label.classList.remove('border-[#FFDD00]', 'bg-[#FFFEF8]')
        label.classList.add('border-gray-200')
      }
      
      // Enable/disable对应的hidden fields
      const hiddenFields = label.querySelectorAll('input[type="hidden"]')
      hiddenFields.forEach((field) => {
        (field as HTMLInputElement).disabled = (index !== selectedIndex)
      })
    })
  }

  selectPassenger(event: Event): void {
    const radio = event.target as HTMLInputElement
    const selectedIndex = parseInt(radio.value)
    
    // 找到所有乘客的label
    const labels = this.element.querySelectorAll('[data-internet-order-form-target="pickupSection"] label')
    
    labels.forEach((label, index) => {
      // 更新样式
      if (index === selectedIndex) {
        label.classList.add('border-[#FFDD00]', 'bg-[#FFFEF8]')
        label.classList.remove('border-gray-200')
      } else {
        label.classList.remove('border-[#FFDD00]', 'bg-[#FFFEF8]')
        label.classList.add('border-gray-200')
      }
      
      // Enable/disable对应的hidden fields
      const hiddenFields = label.querySelectorAll('input[type="hidden"]')
      hiddenFields.forEach((field) => {
        (field as HTMLInputElement).disabled = (index !== selectedIndex)
      })
    })
  }

  increase(): void {
    const currentQty = parseInt(this.quantityTarget.textContent || "1")
    const newQty = currentQty + 1
    this.quantityTarget.textContent = newQty.toString()
    
    // Update display in product info section
    if (this.hasQuantityDisplayTarget) {
      this.quantityDisplayTarget.textContent = newQty.toString()
    }
    
    this.updateQuantityField(newQty)
    this.recalculateTotalPrice()
  }

  decrease(): void {
    const currentQty = parseInt(this.quantityTarget.textContent || "1")
    if (currentQty > 1) {
      const newQty = currentQty - 1
      this.quantityTarget.textContent = newQty.toString()
      
      // Update display in product info section
      if (this.hasQuantityDisplayTarget) {
        this.quantityDisplayTarget.textContent = newQty.toString()
      }
      
      this.updateQuantityField(newQty)
      this.recalculateTotalPrice()
    }
  }

  updateRentalDays(event: Event): void {
    const input = event.target as HTMLInputElement
    const days = parseInt(input.value) || 1
    
    // Update display in product info section
    if (this.hasRentalDaysDisplayTarget) {
      this.rentalDaysDisplayTarget.textContent = days.toString()
    }
    
    this.recalculateTotalPrice()
    
    // 更新rental_info的hidden fields
    const rentalDaysField = this.element.querySelector('[data-internet-order-form-target="rentalDaysField"]') as HTMLInputElement
    if (rentalDaysField) {
      rentalDaysField.value = days.toString()
      
      // 计算return_date
      const pickupDateField = rentalDaysField.closest('div')?.querySelector('input[name*="[pickup_date]"]') as HTMLInputElement
      const returnDateField = rentalDaysField.closest('div')?.querySelector('input[name*="[return_date]"]') as HTMLInputElement
      
      if (pickupDateField && returnDateField) {
        const pickupDate = new Date(pickupDateField.value)
        const returnDate = new Date(pickupDate)
        returnDate.setDate(returnDate.getDate() + days)
        returnDateField.value = returnDate.toISOString().split('T')[0]
      }
    }
  }

  selectDeliveryMethod(event: Event): void {
    const radio = event.target as HTMLInputElement
    const mailSection = this.element.querySelector('[data-internet-order-form-target="mailSection"]')
    const pickupSection = this.element.querySelector('[data-internet-order-form-target="pickupSection"]')
    const mailLabel = this.element.querySelector('[data-internet-order-form-target="mailLabel"]')
    const pickupLabel = this.element.querySelector('[data-internet-order-form-target="pickupLabel"]')

    if (radio.value === 'mail') {
      mailSection?.classList.remove('hidden')
      pickupSection?.classList.add('hidden')
      mailLabel?.classList.add('border-[#FFDD00]', 'bg-[#FFFEF8]')
      pickupLabel?.classList.remove('border-[#FFDD00]', 'bg-[#FFFEF8]')
    } else {
      mailSection?.classList.add('hidden')
      pickupSection?.classList.remove('hidden')
      pickupLabel?.classList.add('border-[#FFDD00]', 'bg-[#FFFEF8]')
      mailLabel?.classList.remove('border-[#FFDD00]', 'bg-[#FFFEF8]')
    }
  }

  private updateQuantityField(quantity: number): void {
    const quantityField = this.element.querySelector('[data-internet-order-form-target="quantityField"]') as HTMLInputElement
    if (quantityField) {
      quantityField.value = quantity.toString()
    }
  }

  private recalculateTotalPrice(): void {
    let total: number
    
    if (this.isWifiOrder) {
      // WiFi: total = quantity × days × daily_price
      const quantity = parseInt(this.quantityTarget.textContent || "1")
      const days = this.hasRentalDaysTarget ? (parseInt(this.rentalDaysTarget.value) || 7) : 7
      total = this.basePrice * quantity * days
    } else {
      // SIM card or data plan: total = quantity × price
      const quantity = parseInt(this.quantityTarget.textContent || "1")
      total = this.basePrice * quantity
    }
    
    this.updateAllPriceDisplays(total)
  }
  
  private updateAllPriceDisplays(total: number): void {
    const totalStr = total.toFixed(0)
    
    // Update bottom bar total price
    if (this.hasTotalPriceTarget) {
      this.totalPriceTarget.textContent = totalStr
    }
    
    // Update product info section total price
    if (this.hasTotalPriceDisplayTarget) {
      this.totalPriceDisplayTarget.textContent = totalStr
    }
    
    // Update hidden field
    const totalPriceField = this.element.querySelector('[data-internet-order-form-target="totalPriceField"]') as HTMLInputElement
    if (totalPriceField) {
      totalPriceField.value = total.toString()
    }
  }
}
