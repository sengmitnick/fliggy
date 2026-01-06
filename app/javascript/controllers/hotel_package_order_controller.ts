import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = [
    "quantityInput",
    "totalPrice",
    "bottomPrice",
    "decreaseBtn",
    "increaseBtn",
    "stockupTab",
    "instantTab",
    "bookingTypeInput",
    "contactNameInput",
    "contactPhoneInput",
    "confirmModal",
    "confirmQuantity",
    "confirmContact",
    "confirmBookingType",
    "confirmTotalPrice"
  ]

  declare readonly quantityInputTarget: HTMLInputElement
  declare readonly totalPriceTarget: HTMLElement
  declare readonly bottomPriceTarget: HTMLElement
  declare readonly decreaseBtnTarget: HTMLButtonElement
  declare readonly increaseBtnTarget: HTMLButtonElement
  declare readonly stockupTabTarget: HTMLElement
  declare readonly instantTabTarget: HTMLElement
  declare readonly bookingTypeInputTarget: HTMLInputElement
  declare readonly contactNameInputTarget: HTMLInputElement
  declare readonly contactPhoneInputTarget: HTMLInputElement
  declare readonly confirmModalTarget: HTMLElement
  declare readonly confirmQuantityTarget: HTMLElement
  declare readonly confirmContactTarget: HTMLElement
  declare readonly confirmBookingTypeTarget: HTMLElement
  declare readonly confirmTotalPriceTarget: HTMLElement

  private pendingFormData: FormData | null = null
  private allowSubmission: boolean = false

  connect(): void {
    console.log("HotelPackageOrder connected")
    this.updateButtonStates()
  }

  increaseQuantity(event: Event): void {
    event.preventDefault()
    const currentQuantity = parseInt(this.quantityInputTarget.value) || 1
    const newQuantity = currentQuantity + 1
    
    if (newQuantity <= 99) {
      this.quantityInputTarget.value = newQuantity.toString()
      this.updatePrice()
      this.updateButtonStates()
    }
  }

  decreaseQuantity(event: Event): void {
    event.preventDefault()
    const currentQuantity = parseInt(this.quantityInputTarget.value) || 1
    const newQuantity = currentQuantity - 1
    
    if (newQuantity >= 1) {
      this.quantityInputTarget.value = newQuantity.toString()
      this.updatePrice()
      this.updateButtonStates()
    }
  }

  updatePrice(): void {
    const quantity = parseInt(this.quantityInputTarget.value) || 1
    const unitPrice = parseFloat(this.increaseBtnTarget.dataset.price || "0")
    const totalPrice = quantity * unitPrice

    // Update top price (with 2 decimals)
    this.totalPriceTarget.textContent = `¥${totalPrice.toFixed(2)}`
    
    // Update bottom price (integer only)
    this.bottomPriceTarget.textContent = Math.round(totalPrice).toString()
    
    // Update payment confirmation amount
    this.updatePaymentConfirmationAmount(Math.round(totalPrice))
  }

  updateButtonStates(): void {
    const quantity = parseInt(this.quantityInputTarget.value) || 1
    
    // Update decrease button
    if (quantity <= 1) {
      this.decreaseBtnTarget.classList.remove("border-blue-500", "bg-blue-50", "text-blue-600")
      this.decreaseBtnTarget.classList.add("border-gray-200", "text-gray-300")
      this.decreaseBtnTarget.disabled = true
    } else {
      this.decreaseBtnTarget.classList.remove("border-gray-200", "text-gray-300")
      this.decreaseBtnTarget.classList.add("border-blue-500", "bg-blue-50", "text-blue-600")
      this.decreaseBtnTarget.disabled = false
    }
  }

  selectTab(event: Event): void {
    event.preventDefault()
    const target = event.currentTarget as HTMLElement
    const tabType = target.dataset.tab
    
    if (tabType === "stockup") {
      // Activate stockup tab
      this.stockupTabTarget.classList.remove("bg-[#FCEEA8]", "bg-opacity-60", "text-gray-700")
      this.stockupTabTarget.classList.add("bg-[#F5F8FA]", "z-10")
      this.stockupTabTarget.querySelector("span:first-child")?.classList.remove("font-medium")
      this.stockupTabTarget.querySelector("span:first-child")?.classList.add("font-bold", "text-black")
      
      // Deactivate instant tab
      this.instantTabTarget.classList.remove("bg-[#F5F8FA]", "z-10")
      this.instantTabTarget.classList.add("bg-[#FCEEA8]", "bg-opacity-60", "text-gray-700")
      this.instantTabTarget.querySelector("span:first-child")?.classList.remove("font-bold", "text-black")
      this.instantTabTarget.querySelector("span:first-child")?.classList.add("font-medium")
      
      // Update hidden field
      this.bookingTypeInputTarget.value = "stockup"
    } else if (tabType === "instant") {
      // Activate instant tab
      this.instantTabTarget.classList.remove("bg-[#FCEEA8]", "bg-opacity-60", "text-gray-700")
      this.instantTabTarget.classList.add("bg-[#F5F8FA]", "z-10")
      this.instantTabTarget.querySelector("span:first-child")?.classList.remove("font-medium")
      this.instantTabTarget.querySelector("span:first-child")?.classList.add("font-bold", "text-black")
      
      // Deactivate stockup tab
      this.stockupTabTarget.classList.remove("bg-[#F5F8FA]", "z-10")
      this.stockupTabTarget.classList.add("bg-[#FCEEA8]", "bg-opacity-60", "text-gray-700")
      this.stockupTabTarget.querySelector("span:first-child")?.classList.remove("font-bold", "text-black")
      this.stockupTabTarget.querySelector("span:first-child")?.classList.add("font-medium")
      
      // Update hidden field
      this.bookingTypeInputTarget.value = "instant"
    }
  }

  selectPassenger(event: Event): void {
    const label = event.currentTarget as HTMLElement
    const name = label.dataset.passengerName || ""
    const phone = label.dataset.passengerPhone || ""
    
    // Update hidden fields
    this.contactNameInputTarget.value = name
    this.contactPhoneInputTarget.value = phone
  }

  handleSubmit(event: Event): void {
    // Allow submission if flag is set
    if (this.allowSubmission) {
      console.log('Allowing form submission')
      return
    }
    
    event.preventDefault()
    
    // Validate contact info
    if (!this.contactNameInputTarget.value || !this.contactPhoneInputTarget.value) {
      alert('请选择联系人')
      return
    }
    
    // Store form data for later submission
    // stimulus-validator: disable-next-line
    const form = this.element.querySelector('form') as HTMLFormElement
    if (form) {
      this.pendingFormData = new FormData(form)
    }
    
    // Update modal with current form values
    this.updateConfirmModal()
    
    // Show modal
    this.showConfirmModal()
  }

  updateConfirmModal(): void {
    // Update quantity
    const quantity = this.quantityInputTarget.value
    this.confirmQuantityTarget.textContent = quantity
    
    // Update contact
    const contactName = this.contactNameInputTarget.value
    const contactPhone = this.contactPhoneInputTarget.value
    this.confirmContactTarget.textContent = `${contactName} ${contactPhone}`
    
    // Update booking type
    const bookingType = this.bookingTypeInputTarget.value
    this.confirmBookingTypeTarget.textContent = bookingType === 'stockup' ? '先囤后约' : '立即预约'
    
    // Update total price
    const totalPrice = this.bottomPriceTarget.textContent
    this.confirmTotalPriceTarget.textContent = totalPrice || '0'
  }

  showConfirmModal(): void {
    this.confirmModalTarget.classList.remove('hidden')
    
    // Auto-close and show password modal after 2-3 seconds
    const waitTime = Math.floor(Math.random() * (3000 - 2000 + 1)) + 2000
    setTimeout(() => {
      this.closeConfirmModal()
      this.showPaymentPasswordModal()
    }, waitTime)
  }

  closeConfirmModal(): void {
    this.confirmModalTarget.classList.add('hidden')
  }

  showPaymentPasswordModal(): void {
    // Get payment confirmation controller and show password modal
    const paymentController = this.application.getControllerForElementAndIdentifier(
      this.element,
      'payment-confirmation'
    ) as any
    
    if (paymentController && typeof paymentController.showPasswordModal === 'function') {
      paymentController.showPasswordModal()
      
      // Listen for payment success to submit form
      this.setupPaymentSuccessListener()
    }
  }

  setupPaymentSuccessListener(): void {
    // Override the payment confirmation's processActualPayment to submit our form
    const paymentController = this.application.getControllerForElementAndIdentifier(
      this.element,
      'payment-confirmation'
    ) as any
    
    if (paymentController) {
      // Completely override the processActualPayment method
      paymentController.processActualPayment = async () => {
        // Submit the form immediately - no API call needed
        this.submitFormWithData()
      }
    }
  }

  submitFormWithData(): void {
    // stimulus-validator: disable-next-line
    const form = this.element.querySelector('form') as HTMLFormElement
    if (form) {
      console.log('Setting allowSubmission flag and submitting form...')
      // Set flag to allow submission
      this.allowSubmission = true
      // Submit the form using Turbo
      form.requestSubmit()
    } else {
      console.error('Form not found')
    }
  }

  updatePaymentConfirmationAmount(amount: number): void {
    // Update the payment confirmation controller's amount value
    const paymentController = this.application.getControllerForElementAndIdentifier(
      this.element,
      'payment-confirmation'
    ) as any
    
    if (paymentController) {
      paymentController.amountValue = amount.toString()
    }
  }
}
