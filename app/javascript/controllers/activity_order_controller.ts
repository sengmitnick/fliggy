import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "submitButton"]

  declare readonly formTarget: HTMLFormElement
  declare readonly submitButtonTarget: HTMLButtonElement

  async submit(event: Event) {
    event.preventDefault()

    if (!this.validateForm()) {
      return
    }

    const formData = new FormData(this.formTarget)
    const totalPrice = this.calculateTotalPrice()
    formData.set('activity_order[total_price]', totalPrice.toString())

    this.submitButtonTarget.disabled = true
    this.submitButtonTarget.textContent = '处理中...'

    try {
      const response = await fetch(this.formTarget.action, {
        method: 'POST',
        body: formData,
        headers: {
          'Accept': 'application/json',
          'X-CSRF-Token': this.getCSRFToken()
        }
      })

      const data = await response.json()

      if (data.success) {
        this.triggerPaymentModal(totalPrice.toString(), data.pay_url, data.success_url)
      } else {
        const errorMessage = data.errors && Array.isArray(data.errors) 
          ? data.errors.join('\n') 
          : (data.message || '订单创建失败，请稍后重试')
        alert(errorMessage)
        this.submitButtonTarget.disabled = false
        this.submitButtonTarget.textContent = '去付款'
      }
    } catch (error) {
      console.error('订单创建失败:', error)
      alert('订单创建失败，请稍后重试')
      this.submitButtonTarget.disabled = false
      this.submitButtonTarget.textContent = '去付款'
    }
  }

  private validateForm(): boolean {
    const passengerCheckboxes = this.formTarget.querySelectorAll('input[name="activity_order[passenger_ids][]"]:checked')
    if (passengerCheckboxes.length === 0) {
      alert('请至少选择一位出行人')
      return false
    }

    const visitDateInput = this.formTarget.querySelector('input[name="activity_order[visit_date]"]') as HTMLInputElement
    if (!visitDateInput || !visitDateInput.value) {
      alert('请选择出行日期')
      return false
    }

    const contactPhoneInput = this.formTarget.querySelector('input[name="activity_order[contact_phone]"]') as HTMLInputElement
    if (!contactPhoneInput || !contactPhoneInput.value.trim()) {
      alert('请输入联系电话')
      return false
    }

    return true
  }

  private calculateTotalPrice(): number {
    const basePriceElement = document.getElementById('base_price_display')
    const insurancePriceElement = document.getElementById('insurance_price_display')
    const totalPriceElement = document.getElementById('total_price_display')

    if (!basePriceElement || !insurancePriceElement || !totalPriceElement) {
      console.error('价格元素未找到')
      return 0
    }

    const basePrice = parseFloat(basePriceElement.textContent || '0')
    const insurancePrice = parseFloat(insurancePriceElement.textContent || '0')
    
    return basePrice + insurancePrice
  }

  private triggerPaymentModal(amount: string, payUrl: string, successUrl: string) {
    // Find the payment confirmation controller element
    const paymentElement = document.querySelector('[data-controller*="payment-confirmation"]') as HTMLElement
    if (!paymentElement) {
      console.error('Payment controller element not found')
      alert('支付系统未找到，请刷新页面重试')
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
      paymentController.paymentUrlValue = payUrl
      paymentController.successUrlValue = successUrl
      
      // Show password modal
      paymentController.showPasswordModal()
    } else {
      console.error('Payment controller not initialized')
      alert('支付系统未初始化，请刷新页面重试')
    }
  }

  private getCSRFToken(): string {
    const token = document.querySelector('meta[name="csrf-token"]') as HTMLMetaElement
    return token ? token.content : ''
  }
}
