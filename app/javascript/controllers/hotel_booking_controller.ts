import { Controller } from "@hotwired/stimulus"
import type PaymentConfirmationController from "./payment_confirmation_controller"

export default class extends Controller<HTMLElement> {
  static targets = ["insuranceModal", "confirmModal", "form"]

  declare readonly insuranceModalTarget: HTMLElement
  declare readonly confirmModalTarget: HTMLElement
  declare readonly formTarget: HTMLFormElement

  private bookingId: string | null = null

  get paymentConfirmationController(): PaymentConfirmationController {
    return this.application.getControllerForElementAndIdentifier(
      this.element,
      "payment-confirmation"
    ) as PaymentConfirmationController
  }

  // Handle insurance option selection in form
  selectInsuranceOption(event: Event): void {
    const radio = event.currentTarget as HTMLInputElement
    const insuranceType = radio.dataset.insuranceType || 'none'
    const insurancePrice = radio.dataset.insurancePrice || '0'
    
    // Update hidden fields
    this.setInsuranceValues(insuranceType, insurancePrice)
    
    // Update visual indicators (border and checkmark)
    const allCards = document.querySelectorAll('[data-insurance-card]')
    allCards.forEach(card => {
      card.classList.remove('border-orange-400', 'border-gray-400')
      card.classList.add('border-2', 'border-gray-300')
    })
    
    // Add style to selected card
    const selectedCard = radio.closest('[data-insurance-card]') as HTMLElement
    if (selectedCard) {
      selectedCard.classList.remove('border-gray-300')
      if (insuranceType === 'none') {
        selectedCard.classList.add('border-gray-400')
      } else {
        selectedCard.classList.add('border-orange-400')
      }
    }
  }

  setInsuranceValues(insuranceType: string, insurancePrice: string): void {
    const insuranceTypeField = document.getElementById('hotel_booking_insurance_type') as HTMLInputElement
    const insurancePriceField = document.getElementById('hotel_booking_insurance_price') as HTMLInputElement
    
    if (insuranceTypeField) {
      insuranceTypeField.value = insuranceType
    }
    
    if (insurancePriceField) {
      insurancePriceField.value = insurancePrice
    }
  }

  // Handle submit button click
  handleSubmit(event: Event): void {
    event.preventDefault()
    
    // Validate required fields
    const guestNameField = document.getElementById('hotel_booking_guest_name') as HTMLInputElement
    const guestPhoneField = document.getElementById('hotel_booking_guest_phone') as HTMLInputElement
    
    const guestName = guestNameField?.value?.trim() || ''
    const guestPhone = guestPhoneField?.value?.trim() || ''
    
    if (!guestName) {
      alert('请填写入住人姓名')
      guestNameField?.focus()
      return
    }
    
    if (!guestPhone) {
      alert('请填写联系手机')
      guestPhoneField?.focus()
      return
    }
    
    // Validate phone number format (simple validation)
    const phoneRegex = /^1[3-9]\d{9}$/
    if (!phoneRegex.test(guestPhone)) {
      alert('请填写正确的手机号码')
      guestPhoneField?.focus()
      return
    }
    
    // Check if user has selected insurance
    const insuranceTypeField = document.getElementById('hotel_booking_insurance_type') as HTMLInputElement
    const insuranceType = insuranceTypeField?.value || 'none'
    
    if (insuranceType === 'none') {
      // User hasn't selected insurance, show insurance recommendation modal
      this.showInsuranceModal()
    } else {
      // User has selected insurance, proceed to confirmation
      this.showConfirmModal()
    }
  }

  showInsuranceModal(): void {
    this.insuranceModalTarget.classList.remove('hidden')
  }

  closeInsuranceModal(): void {
    this.insuranceModalTarget.classList.add('hidden')
  }

  // Select recommended insurance from modal
  selectRecommendedInsurance(event: Event): void {
    const button = event.currentTarget as HTMLButtonElement
    const insuranceType = button.dataset.insuranceType || 'hotel_cancellation'
    const insurancePrice = button.dataset.insurancePrice || '16'
    
    // Update insurance values
    this.setInsuranceValues(insuranceType, insurancePrice)
    
    // Update UI to show selected insurance
    const targetRadio = document.querySelector(`input[name="insurance_selection"][value="${insuranceType}"]`) as HTMLInputElement
    if (targetRadio) {
      targetRadio.checked = true
      // Trigger change event to update visual indicators
      targetRadio.dispatchEvent(new Event('change', { bubbles: true }))
    }
    
    // Close insurance modal and show confirmation
    this.closeInsuranceModal()
    this.showConfirmModal()
  }

  // Skip insurance selection
  skipInsurance(): void {
    this.setInsuranceValues('none', '0')
    this.closeInsuranceModal()
    this.showConfirmModal()
  }

  showConfirmModal(): void {
    this.confirmModalTarget.classList.remove('hidden')
    
    // Wait 10 seconds then submit form (simulating room locking process)
    setTimeout(() => {
      this.submitForm()
    }, 10000)
  }

  closeConfirmModal(): void {
    this.confirmModalTarget.classList.add('hidden')
  }

  submitForm(): void {
    console.log('Submitting form:', this.formTarget)
    
    // Submit form via fetch to get booking ID
    const formData = new FormData(this.formTarget)
    
    fetch(this.formTarget.action, {
      method: 'POST',
      body: formData,
      headers: {
        'X-CSRF-Token': document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content || '',
        'Accept': 'application/json'
      }
    })
    .then(response => response.json())
    .then(data => {
      if (data.success && data.booking_id) {
        this.bookingId = data.booking_id
        
        // Close confirm modal
        this.closeConfirmModal()
        
        // Update payment-confirmation controller URLs with actual booking ID
        const paymentController = this.paymentConfirmationController
        paymentController.paymentUrlValue = `/hotel_bookings/${this.bookingId}/pay`
        paymentController.successUrlValue = `/hotel_bookings/${this.bookingId}/success`
        
        // Start payment flow
        paymentController.startPaymentFlow()
      } else {
        console.error('Form submission failed:', data)
        alert('预订失败，请重试')
        this.closeConfirmModal()
      }
    })
    .catch(error => {
      console.error('Form submission error:', error)
      alert('预订失败，请重试')
      this.closeConfirmModal()
    })
  }
}
