import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = ["quantity", "totalPrice"]
  static values = { orderableType: String }
  declare readonly quantityTarget: HTMLElement
  declare readonly totalPriceTarget: HTMLElement
  declare readonly orderableTypeValue: string

  private basePrice: number = 9.9

  connect(): void {
    // Get base price from first product
    const firstProduct = document.querySelector('[data-controller="product-card"]')
    if (firstProduct) {
      const priceEl = firstProduct.querySelector('.text-xl.font-bold.text-\\[\\#FF4400\\]')
      if (priceEl) {
        this.basePrice = parseFloat(priceEl.textContent || '9.9')
      }
    }
    this.updateTotalPrice()
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

    // Navigate to order page with params
    const url = `/internet_orders/new?orderable_type=${orderableType}&orderable_id=${orderableId}&quantity=${quantity}`
    window.location.href = url
  }

  private updateTotalPrice(): void {
    const quantity = parseInt(this.quantityTarget.textContent || '1')
    const total = this.basePrice * quantity
    this.totalPriceTarget.textContent = total.toFixed(1)
  }
}
