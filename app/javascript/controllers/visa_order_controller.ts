import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = ["totalPrice", "deliveryAddress"]

  declare readonly totalPriceTarget: HTMLElement
  declare readonly deliveryAddressTarget: HTMLInputElement

  connect(): void {
    console.log("VisaOrder controller connected")
  }

  async submitOrder(event: Event): Promise<void> {
    event.preventDefault()
    
    const button = event.currentTarget as HTMLButtonElement
    
    // Get order data from button dataset
    const visaProductId = button.dataset.visaProductId || ''
    const travelerCount = parseInt(button.dataset.travelerCount || '1')
    const totalPrice = parseFloat(button.dataset.totalPrice || '0')
    const insuranceType = button.dataset.insuranceType || 'none'
    const insurancePrice = parseFloat(button.dataset.insurancePrice || '0')
    const contactName = button.dataset.contactName || ''
    const contactPhone = button.dataset.contactPhone || ''
    const deliveryAddress = button.dataset.deliveryAddress || ''

    // Basic validation
    if (!contactName || contactName.trim() === '') {
      alert('请填写联系人姓名')
      return
    }
    
    if (!contactPhone || contactPhone.trim() === '') {
      alert('请填写联系人电话')
      return
    }
    
    if (!deliveryAddress || deliveryAddress.trim() === '') {
      alert('请填写邮寄地址')
      return
    }

    // Prepare order data (simplified - no travelers for now)
    const orderData = {
      visa_order: {
        visa_product_id: visaProductId,
        traveler_count: travelerCount,
        insurance_type: insuranceType,
        insurance_price: insurancePrice,
        total_price: totalPrice,
        contact_name: contactName.trim(),
        contact_phone: contactPhone.trim(),
        delivery_address: deliveryAddress.trim()
      }
    }

    // Disable button during submission
    button.disabled = true
    button.textContent = '创建中...'

    try {
      // Create order via AJAX
      const csrfToken = document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content || ''
      const response = await fetch('/visa_orders', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': csrfToken
        },
        body: JSON.stringify(orderData)
      })

      const data = await response.json()

      if (response.ok && data.success) {
        // Order created successfully, trigger payment modal
        this.triggerPaymentModal(totalPrice.toString(), data.payment_url, data.success_url)
      } else {
        throw new Error(data.message || '创建订单失败')
      }
    } catch (error) {
      console.error('Error creating order:', error)
      const message = error instanceof Error ? error.message : '创建订单失败，请重试'
      alert(message)
      button.disabled = false
      button.textContent = '立刻支付'
    }
  }

  private triggerPaymentModal(amount: string, paymentUrl: string, successUrl: string): void {
    // Find payment-confirmation controller and trigger it
    const paymentElement = document.querySelector('[data-controller*="payment-confirmation"]') as HTMLElement

    if (!paymentElement) {
      console.error('Payment confirmation controller not found')
      alert('支付系统未加载，请刷新页面重试')
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
      paymentController.paymentUrlValue = paymentUrl
      paymentController.successUrlValue = successUrl

      // Show password modal
      paymentController.showPasswordModal()
    } else {
      console.error('Payment controller not initialized')
      alert('支付系统未初始化，请刷新页面重试')
    }
  }
}
