import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form"]
  
  declare readonly formTarget: HTMLFormElement
  declare readonly hasFormTarget: boolean

  connect(): void {
    console.log("Car order controller connected")
  }

  async createOrder(event: Event): Promise<void> {
    event.preventDefault()
    const button = event.currentTarget as HTMLButtonElement
    
    // Validate form data
    if (!this.hasFormTarget) {
      alert('表单未找到')
      return
    }

    // Get form data
    const formData = new FormData(this.formTarget)
    
    // Validate required fields
    const driverName = formData.get('car_order[driver_name]')
    const driverIdNumber = formData.get('car_order[driver_id_number]')
    const contactPhone = formData.get('car_order[contact_phone]')
    
    if (!driverName || !driverIdNumber || !contactPhone) {
      alert('请选择驾驶人并填写完整信息')
      return
    }

    // Prepare order data
    const orderData = {
      car_order: {
        car_id: formData.get('car_order[car_id]'),
        driver_name: driverName,
        driver_id_number: driverIdNumber,
        contact_phone: contactPhone,
        pickup_datetime: formData.get('car_order[pickup_datetime]'),
        return_datetime: formData.get('car_order[return_datetime]'),
        pickup_location: formData.get('car_order[pickup_location]'),
        total_price: formData.get('car_order[total_price]')
      }
    }
    
    // Disable button during submission
    button.disabled = true
    const originalText = button.innerHTML
    button.innerHTML = '<span class="font-bold text-lg">创建中...</span>'
    
    try {
      // Create order via AJAX
      const csrfToken = document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content || ''
      const response = await fetch('/car_orders', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': csrfToken,
          'Accept': 'application/json'
        },
        body: JSON.stringify(orderData)
      })
      
      const data = await response.json()
      
      if (response.ok && data.success) {
        // Order created successfully, trigger payment modal
        this.triggerPaymentModal(
          orderData.car_order.total_price as string, 
          data.pay_url, 
          data.success_url
        )
      } else {
        throw new Error(data.errors?.join(', ') || '创建订单失败')
      }
    } catch (error) {
      console.error('Error creating order:', error)
      const message = error instanceof Error ? error.message : '创建订单失败，请重试'
      if (typeof (window as any).showToast === 'function') {
        (window as any).showToast(message)
      } else {
        alert(message)
      }
      button.disabled = false
      button.innerHTML = originalText
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
