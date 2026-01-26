import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  connect(): void {
    console.log("ProductCard connected")
  }

  select(event: Event): void {
    event.preventDefault()
    
    // Deselect all cards first
    document.querySelectorAll('[data-controller~="product-card"]').forEach(card => {
      card.classList.remove('border-[#FFCC00]', 'bg-[#FFFEF8]')
      card.classList.add('border-gray-100', 'bg-white')
      
      // Update checkmark icon - replace with empty circle
      const checkmarkContainer = card.querySelector('.flex.items-center.mt-4')
      if (checkmarkContainer) {
        const icon = checkmarkContainer.querySelector('svg.text-\\[\\#FFCC00\\], .w-5.h-5.rounded-full')
        if (icon) {
          icon.outerHTML = '<div class="w-5 h-5 rounded-full border border-gray-300" ' +
            'data-action="click->product-card#select"></div>'
        }
      }
    })

    // Select this card
    this.element.classList.remove('border-gray-100', 'bg-white')
    this.element.classList.add('border-[#FFCC00]', 'bg-[#FFFEF8]')
    
    // Update checkmark for this card - replace with filled checkmark
    const checkmarkContainer = this.element.querySelector('.flex.items-center.mt-4')
    if (checkmarkContainer) {
      const icon = checkmarkContainer.querySelector('.w-5.h-5')
      if (icon) {
        const checkmarkSvg = '<svg class="w-5 h-5 text-[#FFCC00] fill-current" viewBox="0 0 24 24">'
          + '<path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2z'
          + 'm-2 15l-5-5 1.41-1.41L10 12.17l7.59-7.59L19 6l-9 9z"/>'
          + '</svg>'
        icon.outerHTML = checkmarkSvg
      }
    }
  }
}
