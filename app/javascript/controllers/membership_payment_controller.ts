import { Controller } from "@hotwired/stimulus"

// Membership payment controller - for direct payment confirmation
// Different from payment-confirmation controller which handles async payment flow
export default class extends Controller {
  static targets = [
    "passwordModal",
    "passwordDots",
    "passwordAmount"
  ]

  declare readonly passwordModalTarget: HTMLElement
  declare readonly hasPasswordModalTarget: boolean
  declare readonly passwordDotsTarget: HTMLElement
  declare readonly hasPasswordDotsTarget: boolean
  declare readonly passwordAmountTarget: HTMLElement
  declare readonly hasPasswordAmountTarget: boolean

  private password: string = ""
  private formElement: HTMLFormElement | null = null

  connect(): void {
    console.log("Membership payment controller connected")
    // The controller is bound to the form element itself
    this.formElement = this.element as HTMLFormElement
    console.log("Form element:", this.formElement)
  }

  showPasswordModal(event: Event): void {
    event.preventDefault()
    
    // Validate form fields before showing payment modal
    if (!this.validateForm()) {
      return
    }

    if (!this.hasPasswordModalTarget) {
      console.error("Password modal target not found")
      return
    }
    
    this.password = ""
    if (this.hasPasswordDotsTarget) {
      this.updatePasswordDots()
    }
    
    // Get amount from data attribute
    const amountElement = this.element.querySelector('[data-membership-payment-amount]') as HTMLElement
    const amount = amountElement?.dataset.membershipPaymentAmount || '0'
    
    if (this.hasPasswordAmountTarget) {
      this.passwordAmountTarget.textContent = amount
    }
    
    this.passwordModalTarget.classList.remove('hidden')
  }

  closePasswordModal(): void {
    if (this.hasPasswordModalTarget) {
      this.passwordModalTarget.classList.add('hidden')
    }
    this.password = ""
    if (this.hasPasswordDotsTarget) {
      this.updatePasswordDots()
    }
  }

  inputPassword(event: Event): void {
    const button = event.currentTarget as HTMLButtonElement
    const number = button.dataset.number

    if (!number) return

    if (this.password.length < 6) {
      this.password += number
      this.updatePasswordDots()

      if (this.password.length === 6) {
        this.verifyAndSubmit()
      }
    }
  }

  deletePassword(): void {
    if (this.password.length > 0) {
      this.password = this.password.slice(0, -1)
      this.updatePasswordDots()
    }
  }

  private updatePasswordDots(): void {
    if (!this.hasPasswordDotsTarget) return
    
    const dots = this.passwordDotsTarget.querySelectorAll('.password-dot')
    dots.forEach((dot, index) => {
      if (index < this.password.length) {
        dot.classList.add('active')
      } else {
        dot.classList.remove('active')
      }
    })
  }

  private async verifyAndSubmit(): Promise<void> {
    console.log("Starting password verification...")
    try {
      // Verify password first
      const verifyResponse = await fetch('/profile/verify_pay_password', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content || ''
        },
        body: JSON.stringify({
          pay_password: this.password
        })
      })

      const verifyData = await verifyResponse.json()
      console.log("Password verification response:", verifyData)

      if (!verifyResponse.ok || !verifyData.success) {
        const message = verifyData.message || '支付密码错误'
        console.log("Password verification failed:", message)
        
        // If need to set password, redirect
        if (message.includes('请先设置支付密码') || message.includes('设置支付密码')) {
          this.closePasswordModal()
          window.location.href = '/profile/edit_pay_password'
          return
        }
        
        // Show error toast
        if (typeof (window as any).showToast === 'function') {
          (window as any).showToast(message)
        } else {
          alert(message)
        }
        
        // Clear password and keep modal open
        this.password = ""
        this.updatePasswordDots()
        return
      }

      // Password verified, submit the form
      console.log("Password verified successfully, submitting form...")
      console.log("Form element before submit:", this.formElement)
      this.closePasswordModal()
      if (this.formElement) {
        console.log("Calling requestSubmit()...")
        this.formElement.requestSubmit()
      } else {
        console.error("Form element is null!")
      }
      
    } catch (error) {
      console.error('验证支付密码失败:', error)
      if (typeof (window as any).showToast === 'function') {
        (window as any).showToast('网络错误，请重试')
      } else {
        alert('网络错误，请重试')
      }
      this.password = ""
      this.updatePasswordDots()
    }
  }

  private validateForm(): boolean {
    const contactNameInput = this.element.querySelector('input[name="membership_order[contact_name]"]') as HTMLInputElement
    const contactPhoneInput = this.element.querySelector('input[name="membership_order[contact_phone]"]') as HTMLInputElement
    const shippingAddressInput = this.element.querySelector('input[name="membership_order[shipping_address]"]') as HTMLInputElement

    if (!contactNameInput?.value || !contactPhoneInput?.value || !shippingAddressInput?.value) {
      if (typeof (window as any).showToast === 'function') {
        (window as any).showToast('请先选择收货地址')
      } else {
        alert('请先选择收货地址')
      }
      return false
    }

    return true
  }
}
