import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  connect(): void {
    console.log("SimCardFilter connected")
  }

  selectDelivery(event: Event): void {
    const button = event.currentTarget as HTMLElement
    const method = button.dataset.method
    
    const allButtons = this.element.querySelectorAll('[data-method]')
    allButtons.forEach(b => {
      b.classList.remove('font-medium')
      b.classList.add('text-gray-700')
    })
    
    button.classList.add('font-medium')
  }

  selectDays(event: Event): void {
    const button = event.currentTarget as HTMLElement
    
    const allButtons = this.element.querySelectorAll('[data-days]')
    allButtons.forEach(b => {
      b.classList.remove('bg-[#FFF8D8]', 'border-[#FFCC00]', 'font-medium')
      b.classList.add('bg-gray-50', 'text-gray-700')
      // Remove checkmark
      b.querySelectorAll('.absolute').forEach(el => el.remove())
    })
    
    button.classList.add('bg-[#FFF8D8]', 'border-[#FFCC00]', 'font-medium')
    button.classList.remove('bg-gray-50', 'text-gray-700')
    
    // Add checkmark
    const checkmarkHTML = `
      <div class="absolute bottom-0 right-0 w-3 h-3 bg-[#FFCC00] rounded-tl-lg"></div>
      <svg class="absolute bottom-0.5 right-0.5 w-1.5 h-1.5 text-black z-10" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="4" d="M5 13l4 4L19 7"></path>
      </svg>
    `
    button.insertAdjacentHTML('beforeend', checkmarkHTML)
  }

  selectData(event: Event): void {
    const button = event.currentTarget as HTMLElement
    
    const allButtons = this.element.querySelectorAll('[data-data]')
    allButtons.forEach(b => {
      b.classList.remove('bg-[#FFF8D8]', 'border-[#FFCC00]', 'font-medium')
      b.classList.add('bg-gray-50', 'text-gray-700')
      // Remove checkmark
      b.querySelectorAll('.absolute').forEach(el => el.remove())
    })
    
    button.classList.add('bg-[#FFF8D8]', 'border-[#FFCC00]', 'font-medium')
    button.classList.remove('bg-gray-50', 'text-gray-700')
    
    // Add checkmark
    const checkmarkHTML = `
      <div class="absolute bottom-0 right-0 w-3 h-3 bg-[#FFCC00] rounded-tl-lg"></div>
      <svg class="absolute bottom-0.5 right-0.5 w-1.5 h-1.5 text-black z-10" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="4" d="M5 13l4 4L19 7"></path>
      </svg>
    `
    button.insertAdjacentHTML('beforeend', checkmarkHTML)
  }
}
