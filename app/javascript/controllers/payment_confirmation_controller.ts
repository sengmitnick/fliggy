import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = [
    "processingModal",
    "passwordModal",
    "statusModal",
    "processingAmount",
    "passwordAmount",
    "statusAmount",
    "userEmail",
    "statusUserEmail",
    "statusIcon",
    "statusText",
    "statusDots",
    "dot1",
    "dot2",
    "dot3",
    "dot4",
    "dot5",
    "dot6"
  ]

  static values = {
    amount: String,
    userEmail: String,
    paymentUrl: String,
    successUrl: String
  }

  declare readonly processingModalTarget: HTMLElement
  declare readonly passwordModalTarget: HTMLElement
  declare readonly statusModalTarget: HTMLElement
  declare readonly processingAmountTarget: HTMLElement
  declare readonly passwordAmountTarget: HTMLElement
  declare readonly statusAmountTarget: HTMLElement
  declare readonly userEmailTarget: HTMLElement
  declare readonly statusUserEmailTarget: HTMLElement
  declare readonly statusIconTarget: HTMLElement
  declare readonly statusTextTarget: HTMLElement
  declare readonly statusDotsTarget: HTMLElement
  declare readonly dot1Target: HTMLElement
  declare readonly dot2Target: HTMLElement
  declare readonly dot3Target: HTMLElement
  declare readonly dot4Target: HTMLElement
  declare readonly dot5Target: HTMLElement
  declare readonly dot6Target: HTMLElement

  declare amountValue: string
  declare userEmailValue: string
  declare paymentUrlValue: string
  declare successUrlValue: string

  private password: string = ""

  connect(): void {
    console.log("PaymentConfirmation controller connected")
  }

  // Public method to start payment flow (called from parent controller)
  startPaymentFlow(): void {
    this.showProcessingModal()
  }

  showProcessingModal(): void {
    this.processingAmountTarget.textContent = this.amountValue
    this.userEmailTarget.textContent = this.userEmailValue
    this.processingModalTarget.classList.remove('hidden')
  }

  closeProcessingModal(): void {
    this.processingModalTarget.classList.add('hidden')
  }

  switchToPasswordPay(): void {
    this.closeProcessingModal()
    this.showPasswordModal()
  }

  showPasswordModal(): void {
    this.passwordAmountTarget.textContent = this.amountValue
    this.password = ""
    this.updatePasswordDots()
    this.passwordModalTarget.classList.remove('hidden')
  }

  closePasswordModal(): void {
    this.passwordModalTarget.classList.add('hidden')
    this.password = ""
    this.updatePasswordDots()
  }

  inputPassword(event: Event): void {
    const button = event.currentTarget as HTMLButtonElement
    const digit = button.dataset.digit || ""
    
    if (this.password.length < 6) {
      this.password += digit
      this.updatePasswordDots()
      
      if (this.password.length === 6) {
        setTimeout(() => {
          this.processPasswordPayment()
        }, 300)
      }
    }
  }

  deletePassword(): void {
    if (this.password.length > 0) {
      this.password = this.password.slice(0, -1)
      this.updatePasswordDots()
    }
  }

  updatePasswordDots(): void {
    const dots = [
      this.dot1Target,
      this.dot2Target,
      this.dot3Target,
      this.dot4Target,
      this.dot5Target,
      this.dot6Target
    ]
    
    dots.forEach((dot, index) => {
      if (index < this.password.length) {
        dot.classList.add('bg-blue-500')
        dot.classList.remove('border-gray-300')
        dot.classList.add('border-blue-500')
      } else {
        dot.classList.remove('bg-blue-500')
        dot.classList.add('border-gray-300')
        dot.classList.remove('border-blue-500')
      }
    })
  }

  processPasswordPayment(): void {
    this.closePasswordModal()
    this.showPayingStatus()
  }

  showPayingStatus(): void {
    this.statusAmountTarget.textContent = this.amountValue
    this.statusUserEmailTarget.textContent = this.userEmailValue
    this.statusIconTarget.textContent = '💳'
    this.statusTextTarget.textContent = '正在付款'
    this.statusDotsTarget.style.display = 'block'
    this.statusModalTarget.classList.remove('hidden')
    
    setTimeout(() => {
      this.showPaymentSuccess()
    }, 2000)
  }

  showPaymentSuccess(): void {
    this.statusIconTarget.textContent = '✓'
    this.statusTextTarget.textContent = '付款成功'
    this.statusDotsTarget.style.display = 'none'
    
    setTimeout(() => {
      this.redirectToSuccessPage()
    }, 2000)
  }

  closeStatusModal(): void {
    this.statusModalTarget.classList.add('hidden')
  }

  redirectToSuccessPage(): void {
    console.log('Redirecting to success page...')
    console.log('Payment URL:', this.paymentUrlValue)
    console.log('Success URL:', this.successUrlValue)
    
    fetch(this.paymentUrlValue, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content || ''
      }
    }).then(response => {
      console.log('Payment response:', response.status, response.ok)
      if (response.ok) {
        console.log('Payment successful, redirecting to:', this.successUrlValue)
        window.location.href = this.successUrlValue
      } else {
        console.error('Payment failed with status:', response.status)
        alert('支付失败，请重试')
        this.closeStatusModal()
      }
    }).catch(error => {
      console.error('支付失败:', error)
      alert('支付失败，请重试')
      this.closeStatusModal()
    })
  }
}
