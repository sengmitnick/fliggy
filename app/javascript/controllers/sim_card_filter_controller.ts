import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = ["price", "productCard"]
  static values = {
    delivery: String,
    days: Number,
    data: String
  }

  declare readonly priceTargets: HTMLElement[]
  declare readonly productCardTargets: HTMLElement[]
  declare deliveryValue: string
  declare daysValue: number
  declare dataValue: string

  connect(): void {
    console.log("SimCardFilter connected")
    // Set initial selection for mail delivery
    const mailButton = this.element.querySelector('[data-method="mail"]')
    if (mailButton) {
      mailButton.classList.add('font-medium')
    }
  }

  selectDelivery(event: Event): void {
    const button = event.currentTarget as HTMLElement
    const method = button.dataset.method
    
    const allButtons = this.element.querySelectorAll('[data-method]')
    allButtons.forEach(b => {
      b.classList.remove('font-medium')
      b.classList.add('text-gray-700')
    })
    
    button.classList.add('font-medium')
    
    // Update value and recalculate prices
    if (method) {
      this.deliveryValue = method
      this.updateAllPrices()
    }
  }

  selectDays(event: Event): void {
    const button = event.currentTarget as HTMLElement
    const days = button.dataset.days
    
    const allButtons = this.element.querySelectorAll('[data-days]')
    allButtons.forEach(b => {
      b.classList.remove('bg-[#FFF8D8]', 'border-[#FFCC00]', 'font-medium')
      b.classList.add('bg-gray-50', 'text-gray-700')
      // Remove checkmark
      b.querySelectorAll('.absolute').forEach(el => el.remove())
    })
    
    button.classList.add('bg-[#FFF8D8]', 'border-[#FFCC00]', 'font-medium')
    button.classList.remove('bg-gray-50', 'text-gray-700')
    
    // Add checkmark
    const checkmarkHTML = `
      <div class="absolute bottom-0 right-0 w-3 h-3 bg-[#FFCC00] rounded-tl-lg"></div>
      <svg class="absolute bottom-0.5 right-0.5 w-1.5 h-1.5 text-black z-10" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="4" d="M5 13l4 4L19 7"></path>
      </svg>
    `
    button.insertAdjacentHTML('beforeend', checkmarkHTML)
    
    // Update value and recalculate prices
    if (days) {
      this.daysValue = parseInt(days)
      this.updateAllPrices()
    }
  }

  selectData(event: Event): void {
    const button = event.currentTarget as HTMLElement
    const data = button.dataset.data
    
    const allButtons = this.element.querySelectorAll('[data-data]')
    allButtons.forEach(b => {
      b.classList.remove('bg-[#FFF8D8]', 'border-[#FFCC00]', 'font-medium')
      b.classList.add('bg-gray-50', 'text-gray-700')
      // Remove checkmark
      b.querySelectorAll('.absolute').forEach(el => el.remove())
    })
    
    button.classList.add('bg-[#FFF8D8]', 'border-[#FFCC00]', 'font-medium')
    button.classList.remove('bg-gray-50', 'text-gray-700')
    
    // Add checkmark
    const checkmarkHTML = `
      <div class="absolute bottom-0 right-0 w-3 h-3 bg-[#FFCC00] rounded-tl-lg"></div>
      <svg class="absolute bottom-0.5 right-0.5 w-1.5 h-1.5 text-black z-10" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="4" d="M5 13l4 4L19 7"></path>
      </svg>
    `
    button.insertAdjacentHTML('beforeend', checkmarkHTML)
    
    // Update value and recalculate prices
    if (data) {
      this.dataValue = data
      this.updateAllPrices()
    }
  }

  private updateAllPrices(): void {
    this.productCardTargets.forEach((card, index) => {
      const basePrice = parseFloat(card.dataset.basePrice || '0')
      const newPrice = this.calculatePrice(basePrice)
      
      const priceElement = this.priceTargets[index]
      if (priceElement) {
        priceElement.textContent = newPrice.toFixed(1)
      }
    })

    // Update total price if a card is selected
    this.updateTotalPriceForSelectedCard()
    
    // Trigger quantity-based total price update
    this.triggerQuantityUpdate()
  }

  private updateTotalPriceForSelectedCard(): void {
    // Find the selected card (with yellow border)
    const selectedCard = this.productCardTargets.find(card => 
      card.classList.contains('border-[#FFCC00]')
    )

    if (selectedCard) {
      const priceElement = selectedCard.querySelector('[data-sim-card-filter-target="price"]')
      const totalPriceElement = document.querySelector('[data-sim-card-booking-target="totalPrice"]')
      
      if (priceElement && totalPriceElement) {
        const price = priceElement.textContent || '9.9'
        totalPriceElement.textContent = price
      }
    }
  }

  private triggerQuantityUpdate(): void {
    // Find the sim-card-booking controller and trigger its update
    const bookingController = document.querySelector('[data-controller="sim-card-booking"]')
    if (bookingController) {
      // Dispatch a custom event to trigger the booking controller's update
      const event = new CustomEvent('price-changed')
      bookingController.dispatchEvent(event)
    }
  }

  private calculatePrice(basePrice: number): number {
    let price = basePrice
    
    // Delivery method adjustment
    if (this.deliveryValue === 'pickup') {
      price -= 5 // 自取便宜5元
    }
    
    // Days multiplier
    const daysMultiplier: {[key: number]: number} = {
      1: 1,
      3: 2.5,
      4: 3.2,
      5: 3.8,
      7: 5,
      10: 6.5,
      15: 9,
      30: 15
    }
    
    const multiplier = daysMultiplier[this.daysValue] || 1
    price = basePrice * multiplier
    
    // Data plan adjustment
    const dataAdjustment: {[key: string]: number} = {
      '共3GB': 0,
      '共5GB': 10,
      '共10GB': 20,
      '无限量': 30
    }
    
    price += (dataAdjustment[this.dataValue] || 0)
    
    // Apply delivery discount after calculation
    if (this.deliveryValue === 'pickup') {
      price -= 5
    }
    
    return Math.max(price, 0.1) // Minimum price 0.1
  }
}
