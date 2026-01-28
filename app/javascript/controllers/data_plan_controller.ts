import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = ["totalPrice", "paymentButton"]
  declare readonly totalPriceTarget: HTMLElement
  declare readonly hasTotalPriceTarget: boolean
  declare readonly paymentButtonTarget: HTMLAnchorElement
  declare readonly hasPaymentButtonTarget: boolean

  private selectedPlanId: string = ""
  private selectedPrice: number = 35

  connect(): void {
    console.log("DataPlan connected")
  }

  selectPlan(event: Event): void {
    const card = event.currentTarget as HTMLElement
    const planId = card.dataset.planId || ""
    const price = parseFloat(card.dataset.planPrice || "35")
    
    this.selectedPlanId = planId
    this.selectedPrice = price
    
    // Update total price
    if (this.hasTotalPriceTarget) {
      this.totalPriceTarget.textContent = price.toFixed(0)
    }
    
    // Update payment button URL
    if (this.hasPaymentButtonTarget) {
      const url = new URL(this.paymentButtonTarget.href)
      url.searchParams.set('orderable_id', planId)
      this.paymentButtonTarget.href = url.toString()
    }
    
    // Update UI - remove all selections first
    const allCards = this.element.querySelectorAll('[data-plan-id]')
    allCards.forEach(c => {
      c.classList.remove('bg-[#FFF9E6]', 'border-[#FFD200]')
      c.classList.add('bg-[#F7F8FA]')
      // Remove checkmark if exists
      const checkmark = c.querySelector('.absolute')
      if (checkmark) checkmark.remove()
    })
    
    // Add selection to clicked card
    card.classList.add('bg-[#FFF9E6]', 'border-[#FFD200]')
    card.classList.remove('bg-[#F7F8FA]')
    
    // Add checkmark
    const checkmarkHTML = `
      <div class="absolute bottom-0 right-0 w-0 h-0 border-solid border-[0_0_20px_24px] border-transparent border-b-[#FFD200] rounded-br-lg">
        <svg class="absolute bottom-[-16px] right-[2px] w-2 h-2 text-black" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="4">
          <path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7"></path>
        </svg>
      </div>
    `
    card.insertAdjacentHTML('beforeend', checkmarkHTML)
  }

  checkout(event: Event): void {
    event.preventDefault()
    
    // Get selected plan info
    const orderableType = 'InternetDataPlan'
    const orderableId = this.selectedPlanId
    const price = this.selectedPrice
    
    // Get validity days from selected plan
    const selectedCard = this.element.querySelector(`[data-plan-id="${orderableId}"]`) as HTMLElement
    let days = '1' // default
    if (selectedCard) {
      // Try to extract days from plan name (e.g., "中国香港1天")
      const planName = selectedCard.querySelector('.font-bold')?.textContent || ''
      const daysMatch = planName.match(/(\d+)天/)
      if (daysMatch) {
        days = daysMatch[1]
      }
    }
    
    // Navigate to order page with params
    const baseUrl = '/internet_orders/new'
    const params = `orderable_type=${orderableType}&orderable_id=${orderableId}`
    const priceParams = `days=${days}&price=${price}&total=${price}`
    const url = `${baseUrl}?${params}&${priceParams}`
    window.location.href = url
  }
}
