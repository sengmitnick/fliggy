import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = ["type"]

  declare readonly typeTargets: HTMLElement[]
  declare readonly hasTypeTarget: boolean

  connect(): void {
    console.log("AbroadPassengerSelector connected")
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

    // Update the URL parameters to include the selected passenger type
    if (selectedType) {
      const url = new URL(window.location.href)
      const ticketId = url.searchParams.get("abroad_ticket_id")
      const seatCategory = url.searchParams.get("seat_category")
      
      if (ticketId && seatCategory) {
        // Update the booking button links
        const bookingButtons = document.querySelectorAll('a[href*="new_abroad_ticket_order"]')
        bookingButtons.forEach((button) => {
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
}
