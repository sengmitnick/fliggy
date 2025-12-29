import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = [
    "modal",
    "overlay",
    "directPriorityButton",
    "pricePriorityButton",
    "timeSortButton",
    "flightList"
  ]

  declare readonly modalTarget: HTMLElement
  declare readonly overlayTarget: HTMLElement
  declare readonly directPriorityButtonTarget: HTMLButtonElement
  declare readonly pricePriorityButtonTarget: HTMLButtonElement
  declare readonly timeSortButtonTarget: HTMLButtonElement
  declare readonly flightListTarget: HTMLElement

  // Sort state
  private currentSort: string = "default" // default, direct_priority, price_asc, departure_early, departure_late, arrival_early, arrival_late, duration_short
  private directPriorityActive: boolean = false
  private pricePriorityActive: boolean = false

  connect(): void {
    console.log("FlightSort controller connected")
  }

  // Toggle direct flight priority
  toggleDirectPriority(): void {
    this.directPriorityActive = !this.directPriorityActive
    
    if (this.directPriorityActive) {
      this.currentSort = "direct_priority"
      this.directPriorityButtonTarget.classList.add("border-b-2", "border-black")
      this.directPriorityButtonTarget.querySelector("span")?.classList.add("font-bold")
      this.directPriorityButtonTarget.querySelector("span")?.classList.remove("text-gray-600")
    } else {
      this.currentSort = "default"
      this.directPriorityButtonTarget.classList.remove("border-b-2", "border-black")
      this.directPriorityButtonTarget.querySelector("span")?.classList.remove("font-bold")
      this.directPriorityButtonTarget.querySelector("span")?.classList.add("text-gray-600")
    }
    
    this.applySort()
  }

  // Toggle price priority (low price first)
  togglePricePriority(): void {
    this.pricePriorityActive = !this.pricePriorityActive
    
    if (this.pricePriorityActive) {
      this.currentSort = "price_asc"
      this.pricePriorityButtonTarget.classList.add("border-b-2", "border-black")
      this.pricePriorityButtonTarget.querySelector("span")?.classList.add("font-bold")
      this.pricePriorityButtonTarget.querySelector("span")?.classList.remove("text-gray-600")
    } else {
      this.currentSort = "default"
      this.pricePriorityButtonTarget.classList.remove("border-b-2", "border-black")
      this.pricePriorityButtonTarget.querySelector("span")?.classList.remove("font-bold")
      this.pricePriorityButtonTarget.querySelector("span")?.classList.add("text-gray-600")
    }
    
    this.applySort()
  }

  // Open time sort modal
  openTimeSortModal(): void {
    this.modalTarget.classList.remove("hidden")
    this.overlayTarget.classList.remove("hidden")
    
    // Animate modal
    setTimeout(() => {
      this.modalTarget.classList.remove("translate-y-full")
      this.overlayTarget.classList.remove("opacity-0")
    }, 10)
  }

  // Close modal
  closeModal(): void {
    this.modalTarget.classList.add("translate-y-full")
    this.overlayTarget.classList.add("opacity-0")
    
    setTimeout(() => {
      this.modalTarget.classList.add("hidden")
      this.overlayTarget.classList.add("hidden")
    }, 300)
  }

  // Apply sort option from time sort modal
  applySortOption(event: Event): void {
    const button = event.currentTarget as HTMLButtonElement
    const sortType = button.dataset.sortType
    
    if (!sortType) return
    
    this.currentSort = sortType
    
    // Update time sort button text and state
    this.updateTimeSortButtonText(sortType)
    
    this.applySort()
    this.closeModal()
  }

  // Update time sort button text based on selected sort
  private updateTimeSortButtonText(sortType: string): void {
    const textMap: { [key: string]: string } = {
      "departure_early": "起飞早-晚",
      "departure_late": "起飞晚-早",
      "arrival_early": "到达早-晚",
      "arrival_late": "到达晚-早",
      "duration_short": "耗时短-长"
    }
    
    const buttonText = textMap[sortType]
    if (buttonText) {
      const span = this.timeSortButtonTarget.querySelector("span")
      if (span) {
        span.textContent = buttonText
      }
      
      // Update button active state
      this.timeSortButtonTarget.classList.add("border-b-2", "border-black")
      this.timeSortButtonTarget.querySelector("span")?.classList.add("font-bold")
      this.timeSortButtonTarget.querySelector("span")?.classList.remove("text-gray-600")
    }
  }

  // Apply the current sort to flight list
  private applySort(): void {
    const flightCards = Array.from(this.flightListTarget.children) as HTMLElement[]
    
    if (flightCards.length === 0) return
    
    let sortedCards: HTMLElement[] = []
    
    switch (this.currentSort) {
      case "direct_priority":
        // Sort by direct flights first (no transfer indicator)
        sortedCards = flightCards.sort((a, b) => {
          const aDirect = !a.textContent?.includes("中国香港") && !a.textContent?.includes("杭州")
          const bDirect = !b.textContent?.includes("中国香港") && !b.textContent?.includes("杭州")
          
          if (aDirect && !bDirect) return -1
          if (!aDirect && bDirect) return 1
          
          // Then sort by price
          const aPrice = this.extractPrice(a)
          const bPrice = this.extractPrice(b)
          return aPrice - bPrice
        })
        break
        
      case "price_asc":
        // Sort by price ascending
        sortedCards = flightCards.sort((a, b) => {
          return this.extractPrice(a) - this.extractPrice(b)
        })
        break
        
      
      case "departure_early":
        // Sort by departure time early to late
        sortedCards = flightCards.sort((a, b) => {
          return this.extractDepartureTime(a) - this.extractDepartureTime(b)
        })
        break
        
      case "departure_late":
        // Sort by departure time late to early
        sortedCards = flightCards.sort((a, b) => {
          return this.extractDepartureTime(b) - this.extractDepartureTime(a)
        })
        break
        
      case "arrival_early":
        // Sort by arrival time early to late
        sortedCards = flightCards.sort((a, b) => {
          return this.extractArrivalTime(a) - this.extractArrivalTime(b)
        })
        break
        
      case "arrival_late":
        // Sort by arrival time late to early
        sortedCards = flightCards.sort((a, b) => {
          return this.extractArrivalTime(b) - this.extractArrivalTime(a)
        })
        break
        
      case "duration_short":
        // Sort by duration short to long
        sortedCards = flightCards.sort((a, b) => {
          return this.extractDuration(a) - this.extractDuration(b)
        })
        break
        
      default:
        sortedCards = flightCards
    }
    
    // Re-append cards in sorted order
    sortedCards.forEach(card => {
      this.flightListTarget.appendChild(card)
    })
    
    // Add animation
    this.flightListTarget.classList.add("opacity-50")
    setTimeout(() => {
      this.flightListTarget.classList.remove("opacity-50")
    }, 150)
  }

  // Extract price from flight card
  private extractPrice(card: HTMLElement): number {
    const priceText = card.querySelector(".text-red-500.font-bold")?.textContent
    if (!priceText) return 0
    
    const match = priceText.match(/¥(\d+)/)
    return match ? parseInt(match[1]) : 0
  }

  // Extract departure time from flight card (convert to minutes since midnight)
  private extractDepartureTime(card: HTMLElement): number {
    const timeText = card.querySelector(".text-3xl.font-bold")?.textContent
    if (!timeText) return 0
    
    const match = timeText.match(/(\d+):(\d+)/)
    if (!match) return 0
    
    const hours = parseInt(match[1])
    const minutes = parseInt(match[2])
    return hours * 60 + minutes
  }

  // Extract arrival time from flight card
  private extractArrivalTime(card: HTMLElement): number {
    const timeElements = card.querySelectorAll(".text-3xl.font-bold")
    if (timeElements.length < 2) return 0
    
    const timeText = timeElements[1].textContent
    if (!timeText) return 0
    
    const match = timeText.match(/(\d+):(\d+)/)
    if (!match) return 0
    
    const hours = parseInt(match[1])
    const minutes = parseInt(match[2])
    
    // Handle next day arrivals (if time is earlier than departure)
    const departureTime = this.extractDepartureTime(card)
    const arrivalTime = hours * 60 + minutes
    
    return arrivalTime < departureTime ? arrivalTime + 24 * 60 : arrivalTime
  }

  // Extract duration from flight card
  private extractDuration(card: HTMLElement): number {
    const durationText = card.textContent
    if (!durationText) return 0
    
    // Look for patterns like "总4h", "总18h40m", etc.
    const match = durationText.match(/总(\d+)h(?:(\d+)m)?/)
    if (!match) return 0
    
    const hours = parseInt(match[1])
    const minutes = match[2] ? parseInt(match[2]) : 0
    return hours * 60 + minutes
  }
}
