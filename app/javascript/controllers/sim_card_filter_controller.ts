import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = ["price", "productCard"]
  static values = {
    delivery: String,
    days: Number,
    data: String,
    region: String
  }

  declare readonly priceTargets: HTMLElement[]
  declare readonly productCardTargets: HTMLElement[]
  declare deliveryValue: string
  declare daysValue: number
  declare dataValue: string
  declare regionValue: string

  connect(): void {
    console.log("SimCardFilter connected")
    // Apply initial filtering based on current values
    this.filterProductCards()
  }

  // Delivery method selection removed - mail is the only option

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
    
    // Update value and filter products
    if (days) {
      this.daysValue = parseInt(days)
      this.filterProductCards()
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
    
    // Update value and filter products
    if (data) {
      this.dataValue = data
      this.filterProductCards()
    }
  }

  private filterProductCards(): void {
    const matchingCards: HTMLElement[] = []
    
    // Filter product cards based on current filter values
    this.productCardTargets.forEach(card => {
      const cardDays = parseInt(card.dataset.validityDays || '0')
      const cardData = card.dataset.dataLimit || ''
      
      const matchesDays = cardDays === this.daysValue
      const matchesData = cardData === this.dataValue
      
      if (matchesDays && matchesData) {
        card.classList.remove('hidden')
        matchingCards.push(card)
      } else {
        card.classList.add('hidden')
        // Remove selection from hidden cards
        this.unselectCard(card)
      }
    })
    
    // If we have matching cards, select the first one
    if (matchingCards.length > 0) {
      this.selectFirstMatchingCard(matchingCards[0])
    } else {
      // No matching cards - show all cards as fallback
      console.warn(`No products found for ${this.daysValue} days and ${this.dataValue} data`)
      this.productCardTargets.forEach(card => card.classList.remove('hidden'))
      if (this.productCardTargets.length > 0) {
        this.selectFirstMatchingCard(this.productCardTargets[0])
      }
    }
  }

  private selectFirstMatchingCard(card: HTMLElement): void {
    // Unselect all cards first
    this.productCardTargets.forEach(c => this.unselectCard(c))
    
    // Select the card
    card.classList.add('border-[#FFCC00]', 'bg-[#FFFEF8]')
    card.classList.remove('border-gray-100', 'bg-white')
    
    // Update the radio button visual (remove empty circle, add checkmark)
    const emptyCircle = card.querySelector('.w-5.h-5.rounded-full.border.border-gray-300')
    if (emptyCircle) {
      emptyCircle.innerHTML = `
        <svg class="w-5 h-5 text-[#FFCC00] fill-current" viewBox="0 0 24 24">
          <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/>
        </svg>
      `
    }
    
    // Update total price with the selected card's price
    this.updateTotalPriceForCard(card)
    
    // Trigger the product-card controller to update the selection
    const productId = card.dataset.productId
    const productType = card.dataset.productType
    if (productId && productType) {
      card.dispatchEvent(new CustomEvent('product-selected', {
        bubbles: true,
        detail: { productId, productType }
      }))
    }
  }

  private unselectCard(card: HTMLElement): void {
    card.classList.remove('border-[#FFCC00]', 'bg-[#FFFEF8]')
    card.classList.add('border-gray-100', 'bg-white')
    
    // Find the container with the radio button (either svg or div)
    const radioContainer = card.querySelector('.flex.items-center.mt-4')
    if (radioContainer) {
      // Find either the svg checkmark or the empty circle div
      const checkmark = radioContainer.querySelector('svg.w-5.h-5')
      const emptyCircle = radioContainer.querySelector('div.w-5.h-5.rounded-full')
      
      if (checkmark) {
        // Replace checkmark with empty circle
        checkmark.outerHTML = '<div class="w-5 h-5 rounded-full border border-gray-300" data-action="click->product-card#select"></div>'
      } else if (!emptyCircle) {
        // No radio button found, create one
        const priceSpan = radioContainer.querySelector('span[data-sim-card-filter-target="price"]')
        if (priceSpan) {
          priceSpan.insertAdjacentHTML('afterend', '<div class="w-5 h-5 rounded-full border border-gray-300 ml-2" data-action="click->product-card#select"></div>')
        }
      }
    }
  }

  private updateTotalPriceForCard(card: HTMLElement): void {
    const priceElement = card.querySelector('[data-sim-card-filter-target="price"]') as HTMLElement
    const totalPriceElement = document.querySelector('[data-sim-card-booking-target="totalPrice"]') as HTMLElement
    const quantityElement = document.querySelector('[data-sim-card-booking-target="quantity"]') as HTMLElement
    
    if (priceElement && totalPriceElement) {
      const price = parseFloat(priceElement.textContent || '0')
      const quantity = quantityElement ? parseInt(quantityElement.textContent || '1') : 1
      const totalPrice = (price * quantity).toFixed(1)
      totalPriceElement.textContent = totalPrice
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
}
