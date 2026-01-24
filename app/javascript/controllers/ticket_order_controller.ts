import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  async createOrder(event: Event): Promise<void> {
    event.preventDefault()
    
    const button = event.currentTarget as HTMLButtonElement
    const originalText = button.textContent || ''
    
    // Disable button to prevent double submission
    button.disabled = true
    button.textContent = '处理中...'
    
    try {
      // Get form data
      const form = document.querySelector('form[action*="ticket_orders"]') as HTMLFormElement
      if (!form) {
        throw new Error('找不到订单表单')
      }
      
      const formData = new FormData(form)
      
      // Get ticket ID from URL
      const ticketId = window.location.pathname.match(/\/tickets\/(\d+)/)?.[1]
      if (!ticketId) {
        throw new Error('无效的门票ID')
      }
      
      // Get quantity
      const quantity = parseInt(formData.get('ticket_order[quantity]') as string) || 1
      
      // Get selected passengers (checkboxes)
      const selectedPassengers = Array.from(
        form.querySelectorAll('input[name="ticket_order[passenger_ids][]"]:checked')
      ) as HTMLInputElement[]
      
      // Validate passenger selection matches quantity
      if (selectedPassengers.length === 0) {
        alert('请选择出行人')
        return
      }
      
      if (selectedPassengers.length !== quantity) {
        alert(`请选择 ${quantity} 位出行人，当前已选择 ${selectedPassengers.length} 位`)
        return
      }
      
      // Get visit date
      const visitDate = formData.get('ticket_order[visit_date]')
      if (!visitDate) {
        alert('请选择游玩日期')
        return
      }
      
      // Get contact phone
      const contactPhone = formData.get('ticket_order[contact_phone]')
      if (!contactPhone) {
        alert('请输入联系电话')
        return
      }
      
      // Get insurance selection
      const insuranceRadio = document.querySelector('input[name="insurance_type"]:checked') as HTMLInputElement
      const insuranceType = insuranceRadio?.value || 'none'
      const insurancePrice = parseInt(insuranceRadio?.dataset.price || '0')
      
      // Get supplier ID from form
      const supplierId = formData.get('ticket_order[supplier_id]')
      if (!supplierId) {
        alert('请选择供应商')
        return
      }
      
      // Calculate total price
      const ticketPriceElement = document.querySelector('[data-ticket-price]') as HTMLElement
      const ticketPrice = parseInt(ticketPriceElement?.dataset.ticketPrice || '0')
      const totalPrice = (ticketPrice + insurancePrice) * quantity
      
      // Collect passenger IDs
      const passengerIds = selectedPassengers.map(input => input.value)
      
      // Prepare order data
      const orderData: any = {
        ticket_order: {
          passenger_ids: passengerIds,
          visit_date: visitDate,
          quantity: quantity,
          contact_phone: contactPhone,
          supplier_id: supplierId,
          insurance_type: insuranceType,
          insurance_price: insurancePrice,
          total_price: totalPrice,
          notes: formData.get('ticket_order[notes]') || ''
        }
      }
      
      // Handle new passenger if needed (not applicable for checkbox selection)
      const newPassengerName = formData.get('new_passenger[name]')
      if (newPassengerName) {
        orderData.new_passenger = {
          name: newPassengerName,
          id_number: formData.get('new_passenger[id_number]'),
          phone: formData.get('new_passenger[phone]'),
          passenger_type: formData.get('new_passenger[passenger_type]')
        }
      }
      
      // Get CSRF token
      const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content')
      
      // Create order via AJAX
      const response = await fetch(`/tickets/${ticketId}/ticket_orders`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': csrfToken || '',
          'Accept': 'application/json'
        },
        body: JSON.stringify(orderData)
      })
      
      const data = await response.json()
      
      if (!response.ok || !data.success) {
        const errorMessage = data.errors?.join(', ') || '创建订单失败'
        alert(errorMessage)
        return
      }
      
      // Order created successfully, trigger payment modal
      this.triggerPaymentModal(totalPrice.toString(), data.pay_url, data.success_url)
      
    } catch (error) {
      console.error('创建订单失败:', error)
      alert(error instanceof Error ? error.message : '创建订单失败，请重试')
    } finally {
      // Re-enable button
      button.disabled = false
      button.textContent = originalText
    }
  }
  
  private triggerPaymentModal(amount: string, payUrl: string, successUrl: string): void {
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
}
