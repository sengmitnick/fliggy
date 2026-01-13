import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = ["quantity", "totalPrice"]
  declare readonly quantityTarget: HTMLElement
  declare readonly totalPriceTarget: HTMLElement

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

  private updateTotalPrice(): void {
    const quantity = parseInt(this.quantityTarget.textContent || '1')
    const total = this.basePrice * quantity
    this.totalPriceTarget.textContent = total.toFixed(1)
  }
}
