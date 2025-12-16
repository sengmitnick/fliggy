import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = [
    "paymentModal", 
    "processingModal", 
    "passwordModal",
    "statusModal",
    "amount", 
    "processingAmount", 
    "passwordAmount",
    "statusAmount",
    "spinner",
    "buttonText",
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

  declare readonly paymentModalTarget: HTMLElement
  declare readonly processingModalTarget: HTMLElement
  declare readonly passwordModalTarget: HTMLElement
  declare readonly statusModalTarget: HTMLElement
  declare readonly amountTarget: HTMLElement
  declare readonly processingAmountTarget: HTMLElement
  declare readonly passwordAmountTarget: HTMLElement
  declare readonly statusAmountTarget: HTMLElement
  declare readonly spinnerTarget: HTMLElement
  declare readonly buttonTextTarget: HTMLElement
  declare readonly statusIconTarget: HTMLElement
  declare readonly statusTextTarget: HTMLElement
  declare readonly statusDotsTarget: HTMLElement
  declare readonly dot1Target: HTMLElement
  declare readonly dot2Target: HTMLElement
  declare readonly dot3Target: HTMLElement
  declare readonly dot4Target: HTMLElement
  declare readonly dot5Target: HTMLElement
  declare readonly dot6Target: HTMLElement

  private currentAmount: string = ""
  private bookingId: string = ""
  private password: string = ""
  private dotTargets: HTMLElement[] = []

  showPaymentModal(event: Event): void {
    const button = event.currentTarget as HTMLButtonElement
    this.currentAmount = button.dataset.amount || ""
    this.bookingId = button.dataset.bookingId || ""
    
    this.amountTarget.textContent = this.currentAmount
    this.paymentModalTarget.classList.remove('hidden')
  }

  closePaymentModal(): void {
    this.paymentModalTarget.classList.add('hidden')
  }

  confirmPayment(): void {
    // 显示loading状态
    this.spinnerTarget.classList.remove('hidden')
    this.buttonTextTarget.textContent = '处理中...'
    
    // 关闭支付弹窗
    setTimeout(() => {
      this.closePaymentModal()
      // 显示"正在校验指纹..."弹窗
      this.showProcessingModal()
    }, 500)
  }

  showProcessingModal(): void {
    this.processingAmountTarget.textContent = this.currentAmount
    this.processingModalTarget.classList.remove('hidden')
    
    // Note: 不会自动切换，等待用户点击"使用密码"或指纹验证完成
  }

  switchToPasswordPay(): void {
    // 关闭指纹验证弹窗
    this.closeProcessingModal()
    // 显示密码支付弹窗
    this.showPasswordModal()
  }

  showPasswordModal(): void {
    this.passwordAmountTarget.textContent = this.currentAmount
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
    
    // 最多6位密码
    if (this.password.length < 6) {
      this.password += digit
      this.updatePasswordDots()
      
      // 如果输入满6位，自动进行支付
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
    // 关闭密码弹窗
    this.closePasswordModal()
    // 直接进入"正在付款"状态
    this.showPayingStatus()
  }

  closeProcessingModal(): void {
    this.processingModalTarget.classList.add('hidden')
  }

  showPayingStatus(): void {
    this.statusAmountTarget.textContent = this.currentAmount
    this.statusIconTarget.textContent = '💳'
    this.statusTextTarget.textContent = '正在付款'
    this.statusDotsTarget.style.display = 'block'
    this.statusModalTarget.classList.remove('hidden')
    
    // 2秒后显示"付款成功"
    setTimeout(() => {
      this.showPaymentSuccess()
    }, 2000)
  }

  showPaymentSuccess(): void {
    this.statusIconTarget.textContent = '✓'
    this.statusTextTarget.textContent = '付款成功'
    this.statusDotsTarget.style.display = 'none'
    
    // 2秒后跳转到支付成功页面
    setTimeout(() => {
      this.redirectToSuccessPage()
    }, 2000)
  }

  closeStatusModal(): void {
    this.statusModalTarget.classList.add('hidden')
  }

  redirectToSuccessPage(): void {
    // 提交表单更新订单状态为已支付
    fetch(`/bookings/${this.bookingId}/pay`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content || ''
      }
    }).then(response => {
      if (response.ok) {
        // 跳转到支付成功页面
        window.location.href = `/bookings/${this.bookingId}/success`
      }
    }).catch(error => {
      console.error('支付失败:', error)
      alert('支付失败，请重试')
      this.closeStatusModal()
    })
  }
}
