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
    console.log('🚀🚀🚀 [TransferSearch] Controller connected - VERSION 2.0 🚀🚀🚀')
    console.log('[TransferSearch] Button element:', this.element)
    console.log('[TransferSearch] Values:', {
      transferType: this.transferTypeValue,
      serviceType: this.serviceTypeValue,
      flightId: this.flightIdValue,
      trainId: this.trainIdValue
    })
  }

  handleSearch(event: Event): void {
    console.log('🔍🔍🔍 [TransferSearch] handleSearch CALLED 🔍🔍🔍')
    event.preventDefault()
    
    // Get location_to from the hidden input by ID
    const locationInput = document.getElementById('transfer-location-to') as HTMLInputElement
    const locationTo = locationInput?.value
    
    console.log('[TransferSearch] locationInput element:', locationInput)
    console.log('[TransferSearch] locationTo:', locationTo)
    
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
    const locationFromElement = document.querySelector('[data-location-from]') as HTMLElement
    if (locationFromElement) {
      locationFrom = locationFromElement.dataset.locationFrom || ''
    }
    
    console.log('[TransferSearch] locationFrom:', locationFrom)
    console.log('[TransferSearch] Building URL with params:', {
      transfer_type: this.transferTypeValue,
      service_type: this.serviceTypeValue,
      location_to: locationTo,
      location_from: locationFrom,
      flight_id: this.flightIdValue,
      train_id: this.trainIdValue
    })
    
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
    
    const finalUrl = `/transfers/packages?${params.toString()}`
    console.log('[TransferSearch] Navigating to:', finalUrl)
    
    // Navigate to packages page
    window.location.href = finalUrl
  }
}
