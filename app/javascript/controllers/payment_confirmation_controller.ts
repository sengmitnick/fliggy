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
    "statusDots"
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
  declare amountValue: string
  declare readonly userEmailValue: string
  declare readonly paymentUrlValue: string
  declare readonly successUrlValue: string

  private password: string = ""

  connect(): void {
    // Initialize controller
    console.log("Payment confirmation controller connected")
    
    // 监听价格变化事件
    this.element.addEventListener('payment-confirmation:amount-changed', (event: Event) => {
      const customEvent = event as CustomEvent
      if (customEvent.detail && customEvent.detail.amount) {
        this.amountValue = customEvent.detail.amount.toString()
        console.log(`Payment amount synced: ¥${this.amountValue}`)
      }
    })
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
    
    // 触发事件通知外部恢复按钮状态
    this.element.dispatchEvent(new CustomEvent('payment-modal-closed', {
      bubbles: true,
      detail: { reason: 'password-modal-closed' }
    }))
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
          if (this.hasPasswordModalTarget) {
            this.passwordModalTarget.classList.add('hidden')
          }
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
        if (this.hasPasswordModalTarget) {
          this.passwordModalTarget.classList.remove('hidden')
        }
        return
      }

      // Password is correct - proceed with payment
      if (this.hasPasswordModalTarget) {
        this.passwordModalTarget.classList.add('hidden')
      }
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
      if (this.hasPasswordModalTarget) {
        this.passwordModalTarget.classList.remove('hidden')
      }
    }
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
