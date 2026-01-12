import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = ["quantity", "totalPrice", "contactName", "contactPhone", "dateRange",
    "mailTab", "pickupTab", "addressSection", "mailAddress"]
  
  declare readonly quantityTarget: HTMLElement
  declare readonly totalPriceTarget: HTMLElement
  declare readonly contactNameTarget: HTMLInputElement
  declare readonly contactPhoneTarget: HTMLInputElement
  declare readonly dateRangeTarget: HTMLElement
  declare readonly mailTabTarget: HTMLElement
  declare readonly pickupTabTarget: HTMLElement
  declare readonly addressSectionTarget: HTMLElement
  declare readonly mailAddressTarget: HTMLElement
  declare readonly hasTotalPriceTarget: boolean
  declare readonly hasMailTabTarget: boolean
  declare readonly hasPickupTabTarget: boolean
  declare readonly hasAddressSectionTarget: boolean
  declare readonly hasMailAddressTarget: boolean

  private selectedPlanId: string = ""
  private dailyPrice: number = 17
  private days: number = 7
  private currentDeliveryMethod: string = 'pickup'

  connect(): void {
    // 初始化默认选中的套餐价格
    const firstPlan = this.element.querySelector('[data-wifi-id]')
    if (firstPlan) {
      const id = firstPlan.getAttribute('data-wifi-id')
      const price = firstPlan.getAttribute('data-wifi-price')
      if (id) this.selectedPlanId = id
      if (price) this.dailyPrice = parseFloat(price)
    }
    this.updateTotalPrice()
    this.updatePaymentButton()
  }

  selectPlan(event: Event): void {
    const card = event.currentTarget as HTMLElement
    const planId = card.dataset.wifiId || ""
    const price = parseFloat(card.dataset.wifiPrice || "17")
    
    this.selectedPlanId = planId
    this.dailyPrice = price
    this.updateTotalPrice()
    
    // 更新支付按钮的orderableId
    this.updatePaymentButton()
    
    // Update UI - remove all selections first
    const allCards = this.element.querySelectorAll('[data-wifi-id]')
    allCards.forEach(c => {
      c.classList.remove('bg-[#FFFDF2]', 'border-[#FFDD00]')
      c.classList.add('bg-white')
      const checkmark = c.querySelector('.bg-[#FFDD00]')
      if (checkmark) {
        checkmark.outerHTML = '<div class="w-5 h-5 ml-2 border border-gray-300 rounded-full"></div>'
      }
    })
    
    // Add selection to clicked card
    card.classList.add('bg-[#FFFDF2]', 'border-[#FFDD00]')
    card.classList.remove('bg-white')
    const circle = card.querySelector('.border-gray-300')
    if (circle) {
      const checkmarkSVG = '<svg class="w-3.5 h-3.5 text-black" fill="none" stroke="currentColor" viewBox="0 0 24 24">'
        + '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M5 13l4 4L19 7"></path></svg>'
      const checkmarkHTML = `<div class="w-5 h-5 ml-2 bg-[#FFDD00] rounded-full flex items-center justify-center">${
        checkmarkSVG  }</div>`
      circle.outerHTML = checkmarkHTML
    }
  }

  selectDelivery(event: Event): void {
    event.preventDefault()
    const button = event.currentTarget as HTMLElement
    const method = button.dataset.method
    
    if (!method) return
    
    this.currentDeliveryMethod = method
    
    // 更新Tab样式
    if (this.hasMailTabTarget && this.hasPickupTabTarget) {
      this.mailTabTarget.classList.remove('font-bold', 'bg-white', 'shadow-sm', 'text-gray-800')
      this.mailTabTarget.classList.add('text-gray-500')
      this.pickupTabTarget.classList.remove('font-bold', 'bg-white', 'shadow-sm', 'text-gray-800')
      this.pickupTabTarget.classList.add('text-gray-500')
      
      if (method === 'mail') {
        this.mailTabTarget.classList.remove('text-gray-500')
        this.mailTabTarget.classList.add('font-bold', 'bg-white', 'shadow-sm', 'text-gray-800')
        // 显示邮寄地址，隐藏自取地址
        if (this.hasAddressSectionTarget) this.addressSectionTarget.classList.add('hidden')
        if (this.hasMailAddressTarget) this.mailAddressTarget.classList.remove('hidden')
      } else {
        this.pickupTabTarget.classList.remove('text-gray-500')
        this.pickupTabTarget.classList.add('font-bold', 'bg-white', 'shadow-sm', 'text-gray-800')
        // 显示自取地址，隐藏邮寄地址
        if (this.hasAddressSectionTarget) this.addressSectionTarget.classList.remove('hidden')
        if (this.hasMailAddressTarget) this.mailAddressTarget.classList.add('hidden')
      }
    }
  }

  increase(): void {
    const currentQty = parseInt(this.quantityTarget.textContent || "1")
    this.quantityTarget.textContent = (currentQty + 1).toString()
    this.updateTotalPrice()
  }

  decrease(): void {
    const currentQty = parseInt(this.quantityTarget.textContent || "1")
    if (currentQty > 1) {
      this.quantityTarget.textContent = (currentQty - 1).toString()
      this.updateTotalPrice()
    }
  }

  private updateTotalPrice(): void {
    const quantity = parseInt(this.quantityTarget.textContent || "1")
    const total = this.dailyPrice * this.days * quantity
    if (this.hasTotalPriceTarget) {
      this.totalPriceTarget.textContent = total.toFixed(0)
    }
  }

  private updatePaymentButton(): void {
    console.log('[WiFi] updatePaymentButton called, selectedPlanId:', this.selectedPlanId)
    const paymentLink = this.element.querySelector('a#wifi-payment-link') as HTMLAnchorElement
    console.log('[WiFi] Found paymentLink:', paymentLink)
    if (paymentLink && this.selectedPlanId) {
      // 更新link的href，修改orderable_id参数
      const url = new URL(paymentLink.href)
      url.searchParams.set('orderable_id', this.selectedPlanId)
      paymentLink.href = url.toString()
      console.log('[WiFi] Updated paymentLink href to:', paymentLink.href)
    }
  }
}
