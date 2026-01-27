import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = ["quantity", "totalPrice"]
  static values = { orderableType: String }
  declare readonly quantityTarget: HTMLElement
  declare readonly totalPriceTarget: HTMLElement
  declare readonly orderableTypeValue: string

  connect(): void {
    this.updateTotalPrice()
    
    // Listen for price-changed events
    this.element.addEventListener('price-changed', () => {
      this.updateTotalPrice()
    })
  }

  decrease(event: Event): void {
    event.preventDefault()
    const currentQty = parseInt(this.quantityTarget.textContent || '1')
    if (currentQty > 1) {
      this.quantityTarget.textContent = (currentQty - 1).toString()
      this.updateTotalPrice()
    }
  }

  increase(event: Event): void {
    event.preventDefault()
    const currentQty = parseInt(this.quantityTarget.textContent || '1')
    this.quantityTarget.textContent = (currentQty + 1).toString()
    this.updateTotalPrice()
  }

  checkout(event: Event): void {
    event.preventDefault()
    
    // Find selected product by checking all product cards
    const allCards = document.querySelectorAll('[data-controller="product-card"]')
    let selectedCard: Element | null = null
    
    // Find the card with yellow border (FFCC00)
    allCards.forEach((card) => {
      const classes = card.className
      if (classes.includes('FFCC00') || classes.includes('border-[#FFCC00]')) {
        selectedCard = card
      }
    })
    
    // Fallback: if no card selected, use the first card (default selected)
    if (!selectedCard && allCards.length > 0) {
      selectedCard = allCards[0]
    }
    
    if (!selectedCard) {
      alert('请选择一个SIM卡产品')
      return
    }

    const orderableId = (selectedCard as HTMLElement).dataset.productId
    const orderableType = this.orderableTypeValue
    const quantity = this.quantityTarget.textContent

    // Get selected filter values from the filter controller element
    const filterElement = document.querySelector('[data-controller~="sim-card-filter"]') as HTMLElement
    let days = '1'
    let data = '共3GB'
    
    if (filterElement) {
      // Read from data-sim-card-filter-days-value and data-sim-card-filter-data-value
      days = filterElement.dataset.simCardFilterDaysValue || '1'
      data = filterElement.dataset.simCardFilterDataValue || '共3GB'
    }

    // Get unit price from selected card
    const unitPrice = this.getSelectedCardPrice()
    
    // Calculate total price
    const qty = parseInt(quantity || '1')
    const totalPrice = unitPrice * qty

    // Navigate to order page with params including filter values, price, quantity, and total
    const baseUrl = '/internet_orders/new'
    const params = `orderable_type=${orderableType}&orderable_id=${orderableId}&quantity=${quantity}`
    const filterParams = `days=${days}&data=${encodeURIComponent(data)}&price=${unitPrice}&total=${totalPrice}`
    const url = `${baseUrl}?${params}&${filterParams}`
    window.location.href = url
  }

  private updateTotalPrice(): void {
    const quantity = parseInt(this.quantityTarget.textContent || '1')
    
    // Get current price from selected card
    const unitPrice = this.getSelectedCardPrice()
    
    const total = unitPrice * quantity
    this.totalPriceTarget.textContent = total.toFixed(1)
  }

  private getSelectedCardPrice(): number {
    // Find the selected card (with yellow border)
    const selectedCard = document.querySelector('[data-controller~="product-card"].border-\\[\\#FFCC00\\]')
    
    if (selectedCard) {
      const priceElement = selectedCard.querySelector('[data-sim-card-filter-target="price"]')
      if (priceElement && priceElement.textContent) {
        return parseFloat(priceElement.textContent)
      }
    }
    
    // Fallback: get price from first card if no card is selected
    const firstCard = document.querySelector('[data-controller~="product-card"]')
    if (firstCard) {
      const priceElement = firstCard.querySelector('[data-sim-card-filter-target="price"]')
      if (priceElement && priceElement.textContent) {
        return parseFloat(priceElement.textContent)
      }
    }
    
    return 9.9 // Default fallback
  }
}
