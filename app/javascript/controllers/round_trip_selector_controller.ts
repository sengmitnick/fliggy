import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["outboundFlight", "returnFlight", "submitButton", "selectedOutboundId", "selectedReturnId", "totalPrice"]

  selectedOutboundIdValue: string = ""
  selectedReturnIdValue: string = ""
  outboundPrice: number = 0
  returnPrice: number = 0

  connect(): void {
    this.updateSubmitButton()
  }

  selectOutbound(event: Event): void {
    event.preventDefault()
    const card = (event.currentTarget as HTMLElement).closest('[data-flight-id]') as HTMLElement
    if (!card) return

    const flightId = card.dataset.flightId || ""
    const price = parseFloat(card.dataset.price || "0")

    // Remove previous selection
    this.outboundFlightTargets.forEach(el => {
      el.classList.remove('ring-2', 'ring-blue-500', 'bg-blue-50')
    })

    // Add selection to current
    card.classList.add('ring-2', 'ring-blue-500', 'bg-blue-50')

    this.selectedOutboundIdValue = flightId
    this.outboundPrice = price
    
    if (this.hasSelectedOutboundIdTarget) {
      this.selectedOutboundIdTarget.value = flightId
    }

    this.updateSubmitButton()
  }

  selectReturn(event: Event): void {
    event.preventDefault()
    const card = (event.currentTarget as HTMLElement).closest('[data-flight-id]') as HTMLElement
    if (!card) return

    const flightId = card.dataset.flightId || ""
    const price = parseFloat(card.dataset.price || "0")

    // Remove previous selection
    this.returnFlightTargets.forEach(el => {
      el.classList.remove('ring-2', 'ring-blue-500', 'bg-blue-50')
    })

    // Add selection to current
    card.classList.add('ring-2', 'ring-blue-500', 'bg-blue-50')

    this.selectedReturnIdValue = flightId
    this.returnPrice = price
    
    if (this.hasSelectedReturnIdTarget) {
      this.selectedReturnIdTarget.value = flightId
    }

    this.updateSubmitButton()
  }

  private updateSubmitButton(): void {
    if (!this.hasSubmitButtonTarget) return

    const bothSelected = this.selectedOutboundIdValue && this.selectedReturnIdValue

    if (bothSelected) {
      this.submitButtonTarget.classList.remove('opacity-50', 'cursor-not-allowed')
      this.submitButtonTarget.classList.add('cursor-pointer')
      this.submitButtonTarget.removeAttribute('disabled')
      
      // Update total price display
      if (this.hasTotalPriceTarget) {
        const total = this.outboundPrice + this.returnPrice
        this.totalPriceTarget.textContent = `¥${total.toFixed(0)}`
      }
    } else {
      this.submitButtonTarget.classList.add('opacity-50', 'cursor-not-allowed')
      this.submitButtonTarget.classList.remove('cursor-pointer')
      this.submitButtonTarget.setAttribute('disabled', 'disabled')
      
      if (this.hasTotalPriceTarget) {
        this.totalPriceTarget.textContent = '请选择去程和返程航班'
      }
    }
  }

  submit(event: Event): void {
    if (!this.selectedOutboundIdValue || !this.selectedReturnIdValue) {
      event.preventDefault()
      alert('请选择去程和返程航班')
      return
    }

    // Form will submit naturally with hidden inputs
  }

  declare outboundFlightTargets: HTMLElement[]
  declare returnFlightTargets: HTMLElement[]
  declare submitButtonTarget: HTMLButtonElement
  declare selectedOutboundIdTarget: HTMLInputElement
  declare selectedReturnIdTarget: HTMLInputElement
  declare totalPriceTarget: HTMLElement
  declare hasSubmitButtonTarget: boolean
  declare hasSelectedOutboundIdTarget: boolean
  declare hasSelectedReturnIdTarget: boolean
  declare hasTotalPriceTarget: boolean
}
