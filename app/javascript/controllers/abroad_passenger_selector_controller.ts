import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = ["type", "priceDisplay", "priceDecimal", "passengerCount", "modal", "modalTitle", "countPanel", "adultsCount", "childrenCount", "bookingButton"]

  declare readonly typeTargets: HTMLElement[]
  declare readonly hasTypeTarget: boolean
  declare readonly priceDisplayTargets: HTMLElement[]
  declare readonly hasPriceDisplayTarget: boolean
  declare readonly priceDecimalTargets: HTMLElement[]
  declare readonly hasPriceDecimalTarget: boolean
  declare readonly passengerCountTargets: HTMLElement[]
  declare readonly hasPassengerCountTarget: boolean
  declare readonly modalTarget: HTMLElement
  declare readonly hasModalTarget: boolean
  declare readonly modalTitleTarget: HTMLElement
  declare readonly hasModalTitleTarget: boolean
  declare readonly countPanelTarget: HTMLElement
  declare readonly hasCountPanelTarget: boolean
  declare readonly adultsCountTarget: HTMLElement
  declare readonly hasAdultsCountTarget: boolean
  declare readonly childrenCountTarget: HTMLElement
  declare readonly hasChildrenCountTarget: boolean
  declare readonly bookingButtonTargets: HTMLAnchorElement[]
  declare readonly hasBookingButtonTarget: boolean

  private adults: number = 1
  private children: number = 0
  private confirmedAdults: number = 1
  private confirmedChildren: number = 0

  connect(): void {
    // Initialize counters with confirmed values
    this.updateCounters()
  }

  select(event: Event): void {
    const clickedElement = event.currentTarget as HTMLElement
    const selectedType = clickedElement.dataset.abroadPassengerSelectorTypeParam

    // Remove selected state from all type elements
    if (this.hasTypeTarget) {
      this.typeTargets.forEach((element) => {
        element.classList.remove("bg-[#FFFBF0]", "border", "border-[#FFE5B5]")
        element.classList.add("bg-gray-100")
        
        // Remove checkmark
        const checkmark = element.querySelector(".absolute")
        if (checkmark) {
          checkmark.remove()
        }
      })
    }

    // Add selected state to clicked element
    clickedElement.classList.remove("bg-gray-100")
    clickedElement.classList.add("bg-[#FFFBF0]", "border", "border-[#FFE5B5]")
    
    // Add checkmark
    const checkmarkHTML = `
      <div class="absolute bottom-0 right-0 w-3 h-3 bg-[#FFCC00] rounded-tl-lg rounded-br-lg flex items-center justify-center">
        <svg class="w-2 h-2 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="4" d="M5 13l4 4L19 7"></path>
        </svg>
      </div>
    `
    clickedElement.insertAdjacentHTML("beforeend", checkmarkHTML)

    // Calculate total passenger count and update prices
    if (selectedType) {
      const passengerCount = this.calculatePassengerCount(selectedType)
      this.updatePrices(passengerCount)
      this.updatePassengerCountText(passengerCount)
      
      // Update the booking button links using Stimulus targets
      if (this.hasBookingButtonTarget) {
        this.bookingButtonTargets.forEach((button) => {
          const href = button.getAttribute("href")
          if (href) {
            const newUrl = new URL(href, window.location.origin)
            newUrl.searchParams.set("passenger_type", selectedType)
            button.setAttribute("href", newUrl.toString())
          }
        })
      }
    }
  }

  private calculatePassengerCount(type: string): number {
    // Extract number of adults and children from type string
    // e.g., "1adult" = 1, "2adult" = 2, "2adult1child" = 3, "2adult2child" = 4
    const adultMatch = type.match(/(\d+)adult/)
    const childMatch = type.match(/(\d+)child/)
    
    const adults = adultMatch ? parseInt(adultMatch[1]) : 0
    const children = childMatch ? parseInt(childMatch[1]) : 0
    
    return adults + children
  }

  private updatePrices(passengerCount: number): void {
    if (this.hasPriceDisplayTarget) {
      this.priceDisplayTargets.forEach((priceElement, index) => {
        const basePrice = parseFloat(priceElement.dataset.basePrice || "0")
        const totalPrice = basePrice * passengerCount
        
        // Update integer part
        const integerPart = Math.floor(totalPrice)
        const decimalPart = Math.round((totalPrice % 1) * 100)
        
        priceElement.textContent = integerPart.toString()
        
        // Update decimal part using target
        if (this.hasPriceDecimalTarget && this.priceDecimalTargets[index]) {
          this.priceDecimalTargets[index].textContent = `.${decimalPart.toString().padStart(2, "0")}`
        }
      })
    }
  }

  private updatePassengerCountText(count: number): void {
    if (this.hasPassengerCountTarget) {
      this.passengerCountTargets.forEach((element) => {
        element.textContent = `${count}人共`
      })
    }
  }

  // Modal methods
  openModal(event: Event): void {
    event.preventDefault()
    event.stopPropagation()
    
    if (!this.hasModalTarget) return
    
    this.modalTarget.classList.remove("hidden")
    document.body.style.overflow = "hidden"
  }

  closeModal(event: Event): void {
    event.preventDefault()
    event.stopPropagation()
    
    if (!this.hasModalTarget) return
    
    // Restore to confirmed state when closing without confirming
    this.adults = this.confirmedAdults
    this.children = this.confirmedChildren
    this.updateCounters()
    
    this.modalTarget.classList.add("hidden")
    document.body.style.overflow = ""
  }

  stopPropagation(event: Event): void {
    event.stopPropagation()
  }

  incrementAdults(event: Event): void {
    event.preventDefault()
    event.stopPropagation()
    
    if (this.adults < 9) {
      this.adults++
      this.updateCounters()
    }
  }

  decrementAdults(event: Event): void {
    event.preventDefault()
    event.stopPropagation()
    
    if (this.adults > 1) {
      this.adults--
      this.updateCounters()
    }
  }

  incrementChildren(event: Event): void {
    event.preventDefault()
    event.stopPropagation()
    
    if (this.children < 8) {
      this.children++
      this.updateCounters()
    }
  }

  decrementChildren(event: Event): void {
    event.preventDefault()
    event.stopPropagation()
    
    if (this.children > 0) {
      this.children--
      this.updateCounters()
    }
  }

  reset(event: Event): void {
    event.preventDefault()
    event.stopPropagation()
    
    this.adults = 1
    this.children = 0
    this.updateCounters()
  }

  confirm(event: Event): void {
    event.preventDefault()
    event.stopPropagation()
    
    // Save confirmed state
    this.confirmedAdults = this.adults
    this.confirmedChildren = this.children
    
    // Generate passenger type string
    const passengerType = this.generatePassengerType(this.adults, this.children)
    
    // Update prices and display
    const totalCount = this.adults + this.children
    this.updatePrices(totalCount)
    this.updatePassengerCountText(totalCount)
    
    // Update booking button links using Stimulus targets
    if (this.hasBookingButtonTarget) {
      this.bookingButtonTargets.forEach((button) => {
        const href = button.getAttribute("href")
        if (href) {
          const newUrl = new URL(href, window.location.origin)
          newUrl.searchParams.set("passenger_type", passengerType)
          button.setAttribute("href", newUrl.toString())
        }
      })
    }
    
    // Deselect all preset type buttons
    if (this.hasTypeTarget) {
      this.typeTargets.forEach((element) => {
        element.classList.remove("bg-[#FFFBF0]", "border", "border-[#FFE5B5]")
        element.classList.add("bg-gray-100")
        const checkmark = element.querySelector(".absolute")
        if (checkmark) {
          checkmark.remove()
        }
      })
    }
    
    // Close modal
    this.modalTarget.classList.add("hidden")
    document.body.style.overflow = ""
  }

  private updateCounters(): void {
    if (this.hasAdultsCountTarget) {
      this.adultsCountTarget.textContent = this.adults.toString()
    }
    if (this.hasChildrenCountTarget) {
      this.childrenCountTarget.textContent = this.children.toString()
    }
    if (this.hasModalTitleTarget) {
      this.modalTitleTarget.textContent = `当前已选: ${this.adults}成人 ${this.children}儿童`
    }
  }

  private generatePassengerType(adults: number, children: number): string {
    let type = `${adults}adult`
    if (children > 0) {
      type += `${children}child`
    }
    return type
  }
}
