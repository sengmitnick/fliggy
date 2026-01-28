import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = [
    "quantity", "totalPrice", "quantityField", "totalPriceField", 
    "mailSection", "pickupSection", "mailLabel", "pickupLabel", 
    "rentalDays", "rentalDaysField", "rentalInfoField",
    "quantityDisplay", "rentalDaysDisplay", "totalPriceDisplay",
    "addressModal", "addressRadio", "selectedAddressCard",
    "selectedAddressName", "selectedAddressPhone", "selectedAddressText",
    "addressIdField", "addressNameField", "addressPhoneField", "addressFullAddressField",
    "passengerModal", "passengerRadio", "selectedPassengerCard",
    "selectedPassengerName", "selectedPassengerPhone",
    "passengerIdField", "passengerNameField", "passengerPhoneField"
  ]
  static values = {
    deposit: Number
  }
  declare readonly quantityTarget: HTMLElement
  declare readonly hasQuantityTarget: boolean
  declare readonly totalPriceTarget: HTMLElement
  declare readonly hasTotalPriceTarget: boolean
  declare readonly quantityFieldTarget: HTMLInputElement
  declare readonly hasQuantityFieldTarget: boolean
  declare readonly totalPriceFieldTarget: HTMLInputElement
  declare readonly hasTotalPriceFieldTarget: boolean
  declare readonly quantityDisplayTarget: HTMLElement
  declare readonly hasQuantityDisplayTarget: boolean
  declare readonly rentalDaysTarget: HTMLElement
  declare readonly hasRentalDaysTarget: boolean
  declare readonly rentalDaysDisplayTarget: HTMLElement
  declare readonly hasRentalDaysDisplayTarget: boolean
  declare readonly totalPriceDisplayTarget: HTMLElement
  declare readonly hasTotalPriceDisplayTarget: boolean
  declare readonly addressModalTarget: HTMLElement
  declare readonly hasAddressModalTarget: boolean
  declare readonly addressRadioTargets: HTMLElement[]
  declare readonly selectedAddressCardTarget: HTMLElement
  declare readonly hasSelectedAddressCardTarget: boolean
  declare readonly selectedAddressNameTarget: HTMLElement
  declare readonly hasSelectedAddressNameTarget: boolean
  declare readonly selectedAddressPhoneTarget: HTMLElement
  declare readonly hasSelectedAddressPhoneTarget: boolean
  declare readonly selectedAddressTextTarget: HTMLElement
  declare readonly hasSelectedAddressTextTarget: boolean
  declare readonly addressIdFieldTarget: HTMLInputElement
  declare readonly hasAddressIdFieldTarget: boolean
  declare readonly addressNameFieldTarget: HTMLInputElement
  declare readonly hasAddressNameFieldTarget: boolean
  declare readonly addressPhoneFieldTarget: HTMLInputElement
  declare readonly hasAddressPhoneFieldTarget: boolean
  declare readonly addressFullAddressFieldTarget: HTMLInputElement
  declare readonly hasAddressFullAddressFieldTarget: boolean
  
  declare depositValue: number
  declare readonly hasDepositValue: boolean

  private basePrice: number = 0
  private formElement: HTMLFormElement | null = null
  private isWifiOrder: boolean = false
  private selectedAddressId: string | null = null

  connect(): void {
    console.log("InternetOrderForm connected")
    console.log("Deposit value:", this.hasDepositValue ? this.depositValue : 0)
    const totalPriceField = this.element.querySelector('[data-internet-order-form-target="totalPriceField"]') as HTMLInputElement
    if (totalPriceField) {
      this.basePrice = parseFloat(totalPriceField.value) || 0
    }
    
    // Check if this is a WiFi order
    const orderTypeField = this.element.querySelector('input[name="internet_order[order_type]"]') as HTMLInputElement
    this.isWifiOrder = orderTypeField?.value === 'wifi'
    
    // Initialize quantity from params if available
    const urlParams = new URLSearchParams(window.location.search)
    const quantityParam = urlParams.get('quantity')
    const priceParam = urlParams.get('price')
    const totalParam = urlParams.get('total')
    
    if (quantityParam && this.hasQuantityTarget) {
      const qty = parseInt(quantityParam)
      this.quantityTarget.textContent = qty.toString()
      this.updateQuantityField(qty)
    }
    
    // If price param exists, use it as basePrice (overrides database value)
    if (priceParam) {
      this.basePrice = parseFloat(priceParam)
    }
    
    // If total param exists (from previous page), use it directly (includes deposit)
    if (totalParam) {
      const total = parseFloat(totalParam)
      this.updateAllPriceDisplays(total)
    } else if (this.isWifiOrder && this.hasRentalDaysTarget) {
      // For WiFi orders without total param, recalculate (quantity × days × daily_price + deposit)
      const days = parseInt(this.rentalDaysTarget.textContent || '7') || 7
      const quantity = this.hasQuantityTarget ? parseInt(this.quantityTarget.textContent || '1') : 1
      const deposit = this.hasDepositValue ? this.depositValue : 0
      const total = this.basePrice * days * quantity + deposit
      this.updateAllPriceDisplays(total)
    } else if (quantityParam && priceParam) {
      // For SIM cards with params, recalculate total
      const qty = parseInt(quantityParam)
      const total = this.basePrice * qty
      this.updateAllPriceDisplays(total)
    }
    
    // Initialize delivery method button styles based on current selection
    const mailRadio = this.element.querySelector('input[name="internet_order[delivery_method]"][value="mail"]') as HTMLInputElement
    const pickupRadio = this.element.querySelector('input[name="internet_order[delivery_method]"][value="pickup"]') as HTMLInputElement
    const mailLabel = this.element.querySelector('[data-internet-order-form-target="mailLabel"]')
    const pickupLabel = this.element.querySelector('[data-internet-order-form-target="pickupLabel"]')
    
    if (mailRadio?.checked && mailLabel) {
      mailLabel.classList.add('border-[#FFDD00]', 'bg-[#FFFEF8]')
    }
    if (pickupRadio?.checked && pickupLabel) {
      pickupLabel.classList.add('border-[#FFDD00]', 'bg-[#FFFEF8]')
    }
    
    // Store form reference
    this.formElement = this.element.querySelector('form')
    
    // Intercept form submission
    if (this.formElement) {
      this.formElement.addEventListener('submit', this.handleFormSubmit.bind(this))
    }
    
    // Listen for payment modal closed event to restore button
    this.element.addEventListener('payment-modal-closed', this.handlePaymentModalClosed.bind(this))
  }

  disconnect(): void {
    if (this.formElement) {
      this.formElement.removeEventListener('submit', this.handleFormSubmit.bind(this))
    }
    this.element.removeEventListener('payment-modal-closed', this.handlePaymentModalClosed.bind(this))
  }

  handlePaymentModalClosed(event: Event): void {
    console.log('Payment modal closed, restoring button state')
    const form = this.formElement
    if (!form) return
    
    const submitButton = form.querySelector('[type="submit"]') as HTMLButtonElement
    if (submitButton) {
      submitButton.disabled = false
      submitButton.textContent = '确认支付'
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
        
        // Show checkmark icon
        const svg = label.querySelector('svg')
        if (svg) {
          svg.classList.remove('hidden')
        }
      } else {
        label.classList.remove('border-[#FFDD00]', 'bg-[#FFFEF8]')
        label.classList.add('border-gray-200')
        
        // Hide checkmark icon
        const svg = label.querySelector('svg')
        if (svg) {
          svg.classList.add('hidden')
        }
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
        
        // Show checkmark icon
        const svg = label.querySelector('svg')
        if (svg) {
          svg.classList.remove('hidden')
        }
      } else {
        label.classList.remove('border-[#FFDD00]', 'bg-[#FFFEF8]')
        label.classList.add('border-gray-200')
        
        // Hide checkmark icon
        const svg = label.querySelector('svg')
        if (svg) {
          svg.classList.add('hidden')
        }
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

  increaseRentalDays(): void {
    if (!this.hasRentalDaysTarget) return
    
    const currentDays = parseInt(this.rentalDaysTarget.textContent || '7')
    const newDays = currentDays + 1
    this.rentalDaysTarget.textContent = newDays.toString()
    
    // Update display in product info section
    if (this.hasRentalDaysDisplayTarget) {
      this.rentalDaysDisplayTarget.textContent = newDays.toString()
    }
    
    this.updateRentalDaysField(newDays)
    this.recalculateTotalPrice()
  }

  decreaseRentalDays(): void {
    if (!this.hasRentalDaysTarget) return
    
    const currentDays = parseInt(this.rentalDaysTarget.textContent || '7')
    if (currentDays > 1) {
      const newDays = currentDays - 1
      this.rentalDaysTarget.textContent = newDays.toString()
      
      // Update display in product info section
      if (this.hasRentalDaysDisplayTarget) {
        this.rentalDaysDisplayTarget.textContent = newDays.toString()
      }
      
      this.updateRentalDaysField(newDays)
      this.recalculateTotalPrice()
    }
  }

  private updateRentalDaysField(days: number): void {
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
      // WiFi: total = quantity × days × daily_price + deposit
      const quantity = parseInt(this.quantityTarget.textContent || "1")
      const days = this.hasRentalDaysTarget ? (parseInt(this.rentalDaysTarget.textContent || '7') || 7) : 7
      const deposit = this.hasDepositValue ? this.depositValue : 0
      total = this.basePrice * quantity * days + deposit
    } else {
      // SIM card or data plan: total = quantity × price
      const quantity = parseInt(this.quantityTarget.textContent || "1")
      total = this.basePrice * quantity
    }
    
    this.updateAllPriceDisplays(total)
  }
  
  private updateAllPriceDisplays(total: number): void {
    const totalStr = total.toFixed(2)
    
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

  // Address Modal Methods
  openAddressModal(): void {
    if (!this.hasAddressModalTarget) return
    this.addressModalTarget.classList.remove('hidden')
    
    // Highlight currently selected address
    const currentAddressId = this.hasAddressIdFieldTarget ? this.addressIdFieldTarget.value : null
    if (currentAddressId) {
      this.selectedAddressId = currentAddressId
      this.updateAddressRadioButtons()
    }
  }

  closeAddressModal(): void {
    if (!this.hasAddressModalTarget) return
    this.addressModalTarget.classList.add('hidden')
  }

  selectAddressFromModal(event: Event): void {
    const target = event.currentTarget as HTMLElement
    const addressId = target.dataset.addressId
    
    if (!addressId) return
    
    this.selectedAddressId = addressId
    this.updateAddressRadioButtons()
  }

  confirmAddressSelection(): void {
    if (!this.selectedAddressId) {
      this.closeAddressModal()
      return
    }
    
    // Find selected address element in modal
    const selectedElement = this.element.querySelector(`[data-address-id="${this.selectedAddressId}"]`) as HTMLElement
    if (!selectedElement) {
      this.closeAddressModal()
      return
    }
    
    const addressName = selectedElement.dataset.addressName || ''
    const addressPhone = selectedElement.dataset.addressPhone || ''
    const addressFull = selectedElement.dataset.addressFull || ''
    
    // Update display card
    if (this.hasSelectedAddressNameTarget) {
      this.selectedAddressNameTarget.textContent = `${addressName} `
    }
    if (this.hasSelectedAddressPhoneTarget) {
      this.selectedAddressPhoneTarget.textContent = addressPhone
    }
    if (this.hasSelectedAddressTextTarget) {
      this.selectedAddressTextTarget.textContent = addressFull
    }
    
    // Update hidden fields
    if (this.hasAddressIdFieldTarget) {
      this.addressIdFieldTarget.value = this.selectedAddressId
    }
    if (this.hasAddressNameFieldTarget) {
      this.addressNameFieldTarget.value = addressName
    }
    if (this.hasAddressPhoneFieldTarget) {
      this.addressPhoneFieldTarget.value = addressPhone
    }
    if (this.hasAddressFullAddressFieldTarget) {
      this.addressFullAddressFieldTarget.value = addressFull
    }
    
    this.closeAddressModal()
  }

  private updateAddressRadioButtons(): void {
    // Reset all radio buttons
    this.addressRadioTargets.forEach(radio => {
      radio.classList.remove('bg-[#FFDD00]', 'border-[#FFDD00]')
      radio.classList.add('border-gray-300')
      radio.innerHTML = ''
    })
    
    // Highlight selected address
    if (this.selectedAddressId) {
      const selectedElement = this.element.querySelector(`[data-address-id="${this.selectedAddressId}"]`) as HTMLElement
      if (selectedElement) {
        const radio = selectedElement.querySelector('[data-internet-order-form-target="addressRadio"]') as HTMLElement
        if (radio) {
          radio.classList.remove('border-gray-300')
          radio.classList.add('bg-[#FFDD00]', 'border-[#FFDD00]')
          radio.innerHTML = `
            <svg class="w-3 h-3 text-black" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M5 13l4 4L19 7"></path>
            </svg>
          `
        }
      }
    }
  }

  // Passenger Selection Modal Methods (for WiFi contact)
  openPassengerModal(): void {
    const passengerModal = this.element.querySelector('[data-internet-order-form-target="passengerModal"]') as HTMLElement
    if (!passengerModal) return
    
    // Get current selected passenger ID
    const passengerIdField = this.element.querySelector('[data-internet-order-form-target="passengerIdField"]') as HTMLInputElement
    const currentPassengerId = passengerIdField?.value
    
    // Mark the currently selected passenger
    const passengerRadios = this.element.querySelectorAll('[data-internet-order-form-target="passengerRadio"]')
    passengerRadios.forEach((radio) => {
      const parentDiv = radio.closest('[data-passenger-id]') as HTMLElement
      if (parentDiv && parentDiv.dataset.passengerId === currentPassengerId) {
        radio.classList.remove('border-gray-300')
        radio.classList.add('border-blue-500', 'bg-blue-500')
        const checkmarkSvg = '<svg class="w-3 h-3 text-white" fill="currentColor" viewBox="0 0 20 20">'
          + '<path fill-rule="evenodd" '
          + 'd="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" '
          + 'clip-rule="evenodd"></path></svg>'
        radio.innerHTML = checkmarkSvg
      } else {
        radio.classList.add('border-gray-300')
        radio.classList.remove('border-blue-500', 'bg-blue-500')
        radio.innerHTML = ''
      }
    })
    
    passengerModal.classList.remove('hidden')
  }

  closePassengerModal(): void {
    const passengerModal = this.element.querySelector('[data-internet-order-form-target="passengerModal"]') as HTMLElement
    if (!passengerModal) return
    passengerModal.classList.add('hidden')
  }

  selectPassengerFromModal(event: Event): void {
    const target = event.currentTarget as HTMLElement
    const passengerId = target.dataset.passengerId
    
    // Update all radio buttons
    const passengerRadios = this.element.querySelectorAll('[data-internet-order-form-target="passengerRadio"]')
    passengerRadios.forEach((radio) => {
      const parentDiv = radio.closest('[data-passenger-id]') as HTMLElement
      if (parentDiv && parentDiv.dataset.passengerId === passengerId) {
        radio.classList.remove('border-gray-300')
        radio.classList.add('border-blue-500', 'bg-blue-500')
        const checkmarkSvg = '<svg class="w-3 h-3 text-white" fill="currentColor" viewBox="0 0 20 20">'
          + '<path fill-rule="evenodd" '
          + 'd="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" '
          + 'clip-rule="evenodd"></path></svg>'
        radio.innerHTML = checkmarkSvg
      } else {
        radio.classList.add('border-gray-300')
        radio.classList.remove('border-blue-500', 'bg-blue-500')
        radio.innerHTML = ''
      }
    })
  }

  confirmPassengerSelection(): void {
    // Find the selected passenger
    const passengerRadios = this.element.querySelectorAll('[data-internet-order-form-target="passengerRadio"]')
    let selectedPassenger: HTMLElement | null = null
    
    passengerRadios.forEach((radio) => {
      if (radio.classList.contains('bg-blue-500')) {
        selectedPassenger = radio.closest('[data-passenger-id]') as HTMLElement
      }
    })
    
    if (!selectedPassenger) {
      if (typeof (window as any).showToast === 'function') {
        (window as any).showToast('请选择一个联系人')
      }
      return
    }
    
    const passengerId = (selectedPassenger as HTMLElement).dataset.passengerId || ''
    const passengerName = (selectedPassenger as HTMLElement).dataset.passengerName || ''
    const passengerPhone = (selectedPassenger as HTMLElement).dataset.passengerPhone || ''
    
    // Update display
    const nameDisplay = this.element.querySelector('[data-internet-order-form-target="selectedPassengerName"]') as HTMLElement
    const phoneDisplay = this.element.querySelector('[data-internet-order-form-target="selectedPassengerPhone"]') as HTMLElement
    
    if (nameDisplay) {
      nameDisplay.textContent = passengerName
    }
    if (phoneDisplay) {
      phoneDisplay.textContent = passengerPhone
    }
    
    // Update hidden fields
    const passengerIdField = this.element.querySelector('[data-internet-order-form-target="passengerIdField"]') as HTMLInputElement
    const passengerNameField = this.element.querySelector('[data-internet-order-form-target="passengerNameField"]') as HTMLInputElement
    const passengerPhoneField = this.element.querySelector('[data-internet-order-form-target="passengerPhoneField"]') as HTMLInputElement
    
    if (passengerIdField) {
      passengerIdField.value = passengerId
    }
    if (passengerNameField) {
      passengerNameField.value = passengerName
    }
    if (passengerPhoneField) {
      passengerPhoneField.value = passengerPhone
    }
    
    this.closePassengerModal()
  }
}
