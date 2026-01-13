import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static values = {
    transferType: String,
    serviceType: String,
    flightId: String,
    trainId: String
  }

  declare readonly transferTypeValue: string
  declare readonly serviceTypeValue: string
  declare readonly flightIdValue: string
  declare readonly trainIdValue: string

  connect(): void {
    console.log("TransferSearch connected")
  }

  handleSearch(event: Event): void {
    event.preventDefault()
    
    // Get location_to from the hidden input
    const locationInput = document.querySelector('[data-location-selector-target="locationInput"]') as HTMLInputElement
    const locationTo = locationInput?.value
    
    if (!locationTo || locationTo.trim() === '') {
      // Show alert if location not selected
      alert('请先选择下车点')
      
      // Trigger modal open
      const modalButton = document.querySelector('[data-action="click->location-selector#openModal"]') as HTMLButtonElement
      if (modalButton) {
        modalButton.click()
      }
      return
    }
    
    // Get location_from based on flight or train
    let locationFrom = ''
    if (this.flightIdValue) {
      // For flights, get airport from the page
      const flightLocationElement = document.querySelector('.text-xl.font-bold.text-text-primary') as HTMLElement
      locationFrom = flightLocationElement?.textContent?.trim() || ''
    } else if (this.trainIdValue) {
      // For trains, get station from the page
      const trainLocationElement = document.querySelector('.text-xl.font-bold.text-text-primary') as HTMLElement
      locationFrom = trainLocationElement?.textContent?.trim() || ''
    }
    
    // Build URL with all parameters
    const params = new URLSearchParams()
    params.append('transfer_type', this.transferTypeValue)
    params.append('service_type', this.serviceTypeValue)
    params.append('location_to', locationTo)
    
    if (locationFrom) {
      params.append('location_from', locationFrom)
    }
    
    if (this.flightIdValue) {
      params.append('flight_id', this.flightIdValue)
    }
    
    if (this.trainIdValue) {
      params.append('train_id', this.trainIdValue)
    }
    
    // Navigate to packages page
    window.location.href = `/transfers/packages?${params.toString()}`
  }
}
