import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = ["modal", "nameInput", "phoneInput", "emailInput"]

  declare readonly modalTarget: HTMLElement
  declare readonly nameInputTarget: HTMLInputElement
  declare readonly phoneInputTarget: HTMLInputElement
  declare readonly emailInputTarget: HTMLInputElement
  declare readonly hasNameInputTarget: boolean
  declare readonly hasPhoneInputTarget: boolean
  declare readonly hasEmailInputTarget: boolean

  async submitOrder(event: Event): Promise<void> {
    event.preventDefault()
    
    const button = event.currentTarget as HTMLButtonElement
    const abroadTicketId = button.dataset.abroadTicketId
    const totalPrice = button.dataset.totalPrice
    
    // Validate form inputs
    if (!this.validateForm()) {
      return
    }
    
    // Get form data from input fields
    const passengerTypeInput = document.getElementById('passenger_type') as HTMLInputElement
    const seatCategoryInput = document.getElementById('seat_category') as HTMLInputElement
    const notesInput = document.getElementById('notes') as HTMLInputElement
    
    const formData = {
      abroad_ticket_order: {
        abroad_ticket_id: abroadTicketId,
        passenger_name: this.nameInputTarget.value,
        contact_phone: this.phoneInputTarget.value,
        contact_email: this.emailInputTarget.value,
        passenger_type: passengerTypeInput?.value || '',
        seat_category: seatCategoryInput?.value || '',
        total_price: totalPrice,
        notes: notesInput?.value || ''
      }
    }
    
    // Disable button during submission
    button.disabled = true
    button.textContent = '创建中...'
    
    try {
      const csrfToken = document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content || ''
      const response = await fetch('/abroad_ticket_orders.json', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-CSRF-Token': csrfToken
        },
        body: JSON.stringify(formData)
      })
      
      const data = await response.json()
      
      if (response.ok && data.success) {
        // Order created successfully, trigger payment modal
        this.triggerPaymentModal(totalPrice || '0', data.payment_url, data.success_url)
      } else {
        throw new Error(data.message || '创建订单失败')
      }
    } catch (error) {
      console.error('Error creating order:', error)
      const message = error instanceof Error ? error.message : '创建订单失败，请重试'
      alert(message)
      button.disabled = false
      button.textContent = '立即预订'
    }
  }

  private validateForm(): boolean {
    if (!this.hasNameInputTarget || !this.nameInputTarget.value.trim()) {
      alert('请输入姓名')
      return false
    }
    
    if (!this.hasPhoneInputTarget || !this.phoneInputTarget.value.trim()) {
      alert('请输入手机号')
      return false
    }
    
    if (!this.hasEmailInputTarget || !this.emailInputTarget.value.trim()) {
      alert('请输入邮箱')
      return false
    }
    
    // Email format validation
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
    if (!emailRegex.test(this.emailInputTarget.value)) {
      alert('请输入有效的邮箱地址')
      return false
    }
    
    return true
  }

  private triggerPaymentModal(amount: string, paymentUrl: string, successUrl: string): void {
    const paymentElement = document.querySelector('[data-controller*="payment-confirmation"]') as HTMLElement
    
    if (!paymentElement) {
      console.error('Payment confirmation controller not found')
      alert('支付系统未加载，请刷新页面重试')
      return
    }
    
    const app = (window as any).Stimulus
    if (!app) {
      console.error('Stimulus not found')
      alert('系统错误，请刷新页面重试')
      return
    }
    
    const paymentController = app.getControllerForElementAndIdentifier(paymentElement, 'payment-confirmation')
    
    if (paymentController) {
      paymentController.amountValue = amount
      paymentController.userEmailValue = this.emailInputTarget.value
      paymentController.paymentUrlValue = paymentUrl
      paymentController.successUrlValue = successUrl
      
      paymentController.showPasswordModal()
    } else {
      console.error('Payment controller not initialized')
      alert('支付系统未初始化，请刷新页面重试')
    }
  }

  openPassengerSelector(): void {
    this.modalTarget.classList.remove('hidden')
  }

  closePassengerSelector(): void {
    this.modalTarget.classList.add('hidden')
  }

  selectPassenger(event: Event): void {
    const element = event.currentTarget as HTMLElement
    const name = element.dataset.abroadOrderFormNameParam || ''
    const phone = element.dataset.abroadOrderFormPhoneParam || ''
    const email = element.dataset.abroadOrderFormEmailParam || ''
    
    if (this.hasNameInputTarget) {
      this.nameInputTarget.value = name
    }
    
    if (this.hasPhoneInputTarget) {
      this.phoneInputTarget.value = phone
    }
    
    if (this.hasEmailInputTarget && email) {
      this.emailInputTarget.value = email
    }
    
    this.closePassengerSelector()
  }
}
