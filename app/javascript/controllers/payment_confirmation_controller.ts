import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "passwordModal",
    "fingerprintModal",
    "processingModal",
    "statusModal",
    "passwordDots",
    "passwordAmount",
    "processingAmount",
    "userEmail",
    "statusAmount",
    "statusUserEmail",
    "statusIcon",
    "statusText",
    "statusDots",
    "passwordForm",
    "passwordField"
  ]

  static values = {
    amount: String,
    userEmail: String,
    paymentUrl: String,
    successUrl: String
  }

  declare readonly passwordModalTarget: HTMLElement
  declare readonly hasPasswordModalTarget: boolean
  declare readonly hasFingerprintModalTarget: boolean
  declare readonly hasProcessingModalTarget: boolean
  declare readonly statusModalTarget: HTMLElement
  declare readonly hasStatusModalTarget: boolean
  declare readonly passwordDotsTarget: HTMLElement
  declare readonly hasPasswordDotsTarget: boolean
  declare readonly passwordAmountTarget: HTMLElement
  declare readonly hasPasswordAmountTarget: boolean
  declare readonly statusAmountTarget: HTMLElement
  declare readonly hasStatusAmountTarget: boolean
  declare readonly statusUserEmailTarget: HTMLElement
  declare readonly hasStatusUserEmailTarget: boolean
  declare readonly statusIconTarget: HTMLElement
  declare readonly hasStatusIconTarget: boolean
  declare readonly statusTextTarget: HTMLElement
  declare readonly hasStatusTextTarget: boolean
  declare readonly statusDotsTarget: HTMLElement
  declare readonly hasStatusDotsTarget: boolean
  declare readonly passwordFormTarget: HTMLFormElement
  declare readonly hasPasswordFormTarget: boolean
  declare readonly passwordFieldTarget: HTMLInputElement
  declare readonly hasPasswordFieldTarget: boolean
  declare readonly amountValue: string
  declare readonly userEmailValue: string
  declare readonly paymentUrlValue: string
  declare readonly successUrlValue: string

  private password: string = ""
  private boundPasswordVerifiedHandler?: any
  private boundPasswordErrorHandler?: any

  connect(): void {
    console.log("Payment confirmation controller connected")
    
    // Listen for password verification success event
    this.boundPasswordVerifiedHandler = this.onPasswordVerified.bind(this)
    window.addEventListener('payment:password-verified', this.boundPasswordVerifiedHandler)
    
    // Listen for password error event to clear password
    this.boundPasswordErrorHandler = this.onPasswordError.bind(this)
    document.addEventListener('payment:password-error', this.boundPasswordErrorHandler)
  }

  disconnect(): void {
    if (this.boundPasswordVerifiedHandler) {
      window.removeEventListener('payment:password-verified', this.boundPasswordVerifiedHandler)
    }
    if (this.boundPasswordErrorHandler) {
      document.removeEventListener('payment:password-error', this.boundPasswordErrorHandler)
    }
  }

  showPasswordModal(): void {
    if (!this.hasPasswordModalTarget) {
      console.error("Password modal target not found")
      return
    }
    
    this.password = ""
    if (this.hasPasswordDotsTarget) {
      this.updatePasswordDots()
    }
    if (this.hasPasswordAmountTarget) {
      this.passwordAmountTarget.textContent = this.amountValue
    }
    this.passwordModalTarget.classList.remove('hidden')
  }

  closePasswordModal(): void {
    if (this.hasPasswordModalTarget) {
      this.passwordModalTarget.classList.add('hidden')
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
        this.processPasswordPayment()
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

  processPasswordPayment(): void {
    // Submit password verification via Turbo Frame
    this.submitPasswordVerification()
  }

  private submitPasswordVerification(): void {
    if (!this.hasPasswordFormTarget || !this.hasPasswordFieldTarget) {
      console.error("Password form or field target not found")
      return
    }
    
    this.passwordFieldTarget.value = this.password
    this.passwordFormTarget.requestSubmit()
  }

  onPasswordVerified(): void {
    console.log('Password verified! Proceeding with payment...')
    
    if (this.hasPasswordModalTarget) {
      this.passwordModalTarget.classList.add('hidden')
    }
    
    this.showPayingStatus()
    this.processActualPayment()
  }

  onPasswordError(): void {
    console.log('Password error, clearing input...')
    this.password = ""
    this.updatePasswordDots()
  }

  async processActualPayment(): Promise<void> {
    try {
      const response = await fetch(`${this.paymentUrlValue}.json`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-CSRF-Token': document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content || ''
        },
        body: JSON.stringify({}) // Password already verified, just trigger payment
      })

      const data = await response.json()

      if (response.ok && data.success) {
        // Show success status
        this.showPaymentSuccess()
        // Redirect after showing success
        setTimeout(() => {
          window.location.href = this.successUrlValue
        }, 2000)
      } else {
        throw new Error(data.message || '支付失败')
      }
    } catch (error) {
      console.error('支付失败:', error)
      this.closeStatusModal()
      const message = error instanceof Error ? error.message : '支付失败，请重试'
      if (typeof (window as any).showToast === 'function') {
        (window as any).showToast(message)
      } else {
        alert(message)
      }
      this.password = ""
      this.showPasswordModal()
    }
  }

  showPayingStatus(): void {
    if (!this.hasStatusModalTarget) return
    
    if (this.hasStatusAmountTarget) {
      this.statusAmountTarget.textContent = this.amountValue
    }
    if (this.hasStatusUserEmailTarget) {
      this.statusUserEmailTarget.textContent = this.userEmailValue
    }
    if (this.hasStatusIconTarget) {
      this.statusIconTarget.textContent = '💳'
    }
    if (this.hasStatusTextTarget) {
      this.statusTextTarget.textContent = '正在付款'
    }
    if (this.hasStatusDotsTarget) {
      this.statusDotsTarget.style.display = 'block'
    }
    this.statusModalTarget.classList.remove('hidden')
  }

  closeProcessingModal(): void {
    if (this.hasStatusModalTarget) {
      this.statusModalTarget.classList.add('hidden')
    }
  }

  switchToPasswordPay(): void {
    // Close any open modals and show password modal
    this.closeStatusModal()
    this.showPasswordModal()
  }

  showPaymentSuccess(): void {
    if (this.hasStatusIconTarget) {
      this.statusIconTarget.textContent = '✓'
    }
    if (this.hasStatusTextTarget) {
      this.statusTextTarget.textContent = '付款成功'
    }
    if (this.hasStatusDotsTarget) {
      this.statusDotsTarget.style.display = 'none'
    }
  }

  closeStatusModal(): void {
    if (this.hasStatusModalTarget) {
      this.statusModalTarget.classList.add('hidden')
    }
  }
}
