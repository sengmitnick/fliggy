import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  select(event: Event): void {
    event.preventDefault()
    // Update UI to show this card is selected
    const card = this.element
    // Remove selection from all other cards
    document.querySelectorAll('[data-controller="product-card"]').forEach(el => {
      const checkbox = el.querySelector('.w-5.h-5.rounded-full')
      if (checkbox && !checkbox.classList.contains('border')) {
        // Already selected, convert to unselected
        el.classList.remove('border-[#FFCC00]', 'bg-[#FFFEF8]')
        el.classList.add('border-gray-100', 'bg-white')
      }
    })
    // Add selection to this card
    card.classList.remove('border-gray-100', 'bg-white')
    card.classList.add('border-[#FFCC00]', 'bg-[#FFFEF8]')
  }
}
