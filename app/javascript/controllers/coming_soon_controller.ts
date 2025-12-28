import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  show(event: Event): void {
    event.preventDefault()
    
    // Prevent multiple toasts - remove existing ones first
    const existingToast = document.querySelector('.coming-soon-toast')
    if (existingToast) {
      existingToast.remove()
    }
    
    const toast = document.createElement('div')
    toast.className = [
      'coming-soon-toast',
      'fixed top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2',
      'bg-gray-800 text-white px-6 py-3 rounded-lg shadow-lg z-50',
      'animate-fade-in whitespace-nowrap'
    ].join(' ')
    toast.textContent = '功能开发中，敬请期待...'
    
    document.body.appendChild(toast)
    
    setTimeout(() => {
      toast.classList.add('animate-fade-out')
      setTimeout(() => {
        // Safe removal - check if toast still exists and has parent
        if (toast.parentNode) {
          toast.parentNode.removeChild(toast)
        }
      }, 300)
    }, 2000)
  }
}
