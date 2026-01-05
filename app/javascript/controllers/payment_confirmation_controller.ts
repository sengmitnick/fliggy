import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "passwordModal",
    "fingerprintModal",
    "statusModal",
    "passwordDots",
    "passwordAmount",
    "statusAmount",
    "statusUserEmail",
    "statusIcon",
    "statusText",
    "statusDots"
  ]

  static values = {
    amount: String,
    userEmail: String,
    paymentUrl: String,
    successUrl: String
  }

  declare readonly passwordModalTarget: HTMLElement
  declare readonly fingerprintModalTarget: HTMLElement
  declare readonly statusModalTarget: HTMLElement
  declare readonly passwordDotsTarget: HTMLElement
  declare readonly passwordAmountTarget: HTMLElement
  declare readonly statusAmountTarget: HTMLElement
  declare readonly statusUserEmailTarget: HTMLElement
  declare readonly statusIconTarget: HTMLElement
  declare readonly statusTextTarget: HTMLElement
  declare readonly statusDotsTarget: HTMLElement
  declare readonly amountValue: string
  declare readonly userEmailValue: string
  declare readonly paymentUrlValue: string
  declare readonly successUrlValue: string

  private password: string = ""

  connect(): void {
    // Initialize controller
  }

  showPasswordModal(): void {
    this.password = ""
    this.updatePasswordDots()
    this.passwordAmountTarget.textContent = this.amountValue
    this.passwordModalTarget.classList.remove('hidden')
  }

  closePasswordModal(): void {
    this.passwordModalTarget.classList.add('hidden')
  }

  showFingerprintModal(): void {
    this.fingerprintModalTarget.classList.remove('hidden')
  }

  closeFingerprintModal(): void {
    this.fingerprintModalTarget.classList.add('hidden')
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
    const dots = this.passwordDotsTarget.querySelectorAll('.password-dot')
    dots.forEach((dot, index) => {
      if (index < this.password.length) {
        dot.classList.add('active')
      } else {
        dot.classList.remove('active')
      }
    })
  }

  processFingerprintPayment(): void {
    // Simulate fingerprint verification
    this.closeFingerprintModal()
    this.showPayingStatus()

    setTimeout(() => {
      this.showPaymentSuccess()
      setTimeout(() => {
        window.location.href = this.successUrlValue
      }, 2000)
    }, 2000)
  }

  cancelFingerprintPayment(): void {
    this.closeFingerprintModal()
  }

  processPasswordPayment(): void {
    // Do NOT close modal here - wait for verification result
    // First verify password before showing payment status
    this.verifyPasswordThenPay()
  }

  async verifyPasswordThenPay(): Promise<void> {
    try {
      // Call verify API first
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

      if (!verifyResponse.ok || !verifyData.success) {
        // Password is wrong - show toast and reset
        const message = verifyData.message || '支付密码错误'
        
        // 如果是需要设置支付密码，直接跳转
        if (message.includes('请先设置支付密码') || message.includes('设置支付密码')) {
          this.passwordModalTarget.classList.add('hidden')
          window.location.href = '/profile/edit_pay_password'
          return
        }
        
        if (typeof (window as any).showToast === 'function') {
          (window as any).showToast(message)
        } else {
          alert(message)
        }
        // Clear password and stay on password input page
        this.password = ""
        this.updatePasswordDots()
        this.passwordModalTarget.classList.remove('hidden')
        return
      }

      // Password is correct - proceed with payment
      this.passwordModalTarget.classList.add('hidden')
      this.showPayingStatus()
      
      // Process actual payment
      await this.processActualPayment()
      
    } catch (error) {
      console.error('验证支付密码失败:', error)
      if (typeof (window as any).showToast === 'function') {
        (window as any).showToast('网络错误，请重试')
      } else {
        alert('网络错误，请重试')
      }
      this.password = ""
      this.updatePasswordDots()
      this.passwordModalTarget.classList.remove('hidden')
    }
  }

  async processActualPayment(): Promise<void> {
    try {
      const response = await fetch(this.paymentUrlValue, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content || ''
        },
        body: JSON.stringify({}) // Password already verified, just trigger payment
      })

      if (response.ok) {
        // Show success status
        this.showPaymentSuccess()
        // Redirect after showing success
        setTimeout(() => {
          window.location.href = this.successUrlValue
        }, 2000)
      } else {
        const data = await response.json()
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
    this.statusAmountTarget.textContent = this.amountValue
    this.statusUserEmailTarget.textContent = this.userEmailValue
    this.statusIconTarget.textContent = '💳'
    this.statusTextTarget.textContent = '正在付款'
    this.statusDotsTarget.style.display = 'block'
    this.statusModalTarget.classList.remove('hidden')
  }

  showPaymentSuccess(): void {
    this.statusIconTarget.textContent = '✓'
    this.statusTextTarget.textContent = '付款成功'
    this.statusDotsTarget.style.display = 'none'
  }

  closeStatusModal(): void {
    this.statusModalTarget.classList.add('hidden')
  }
}
