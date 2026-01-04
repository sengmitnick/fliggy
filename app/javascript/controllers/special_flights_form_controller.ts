import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLFormElement> {
  connect(): void {
    console.log("SpecialFlightsForm controller connected")
  }

  handleSubmit(event: Event): void {
    event.preventDefault()
    
    const form = this.element as HTMLFormElement
    
    // Get form data
    const formData = new FormData(form)
    const destinationCities = formData.get('destination_cities') as string
    const departureCity = formData.get('departure_city') as string
    const date = formData.get('date') as string
    const sortBy = formData.get('sort_by') as string
    const tripType = formData.get('trip_type') as string
    
    // Check if multiple cities are selected
    const cities = destinationCities.split(',').map(city => city.trim()).filter(city => city !== '')
    const isMultiCity = cities.length > 1
    
    // Build URL based on destination count
    let url: string
    const params = new URLSearchParams()
    
    if (isMultiCity) {
      // Multiple cities -> /flights/combinations
      url = '/flights/combinations'
      params.append('departure_city', departureCity)
      params.append('destination_cities', destinationCities)
      params.append('date', date)
      params.append('sort_by', sortBy)
      params.append('trip_type', tripType)
    } else {
      // Single city -> /flights/search
      url = '/flights/search'
      params.append('departure_city', departureCity)
      params.append('destination_city', cities[0] || destinationCities)
      params.append('date', date)
      params.append('sort_by', sortBy)
      params.append('trip_type', tripType)
    }
    
    // Navigate to the appropriate page
    const fullUrl = `${url}?${params.toString()}`
    console.log('Redirecting to:', fullUrl)
    window.location.href = fullUrl
  }
}
