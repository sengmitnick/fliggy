import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = [
    "marker",
    "hotelCard"
  ]

  declare readonly markerTargets: HTMLElement[]
  declare readonly hotelCardTargets: HTMLElement[]
  declare readonly hasMarkerTarget: boolean
  declare readonly hasHotelCardTarget: boolean

  connect(): void {
    console.log("HotelMap connected")
  }

  disconnect(): void {
    console.log("HotelMap disconnected")
  }

  // Show hotel info when marker is clicked
  showHotelInfo(event: Event): void {
    event.preventDefault()
    const marker = event.currentTarget as HTMLElement
    const hotelId = marker.dataset.hotelId
    
    if (!hotelId) return
    
    // Find the corresponding hotel card
    const hotelCard = this.hotelCardTargets.find(
      card => card.dataset.hotelId === hotelId
    )
    
    if (hotelCard) {
      // Scroll to the hotel card smoothly
      hotelCard.scrollIntoView({ 
        behavior: 'smooth', 
        block: 'center' 
      })
      
      // Add highlight effect
      hotelCard.classList.add('bg-yellow-50')
      setTimeout(() => {
        hotelCard.classList.remove('bg-yellow-50')
      }, 2000)
    }
  }
}
