import './base';

// Global toast function with improved styling
window.showToast = function(message: string): void {
  // Remove existing toast if any
  const existingToast = document.querySelector('.toast-message')
  if (existingToast) {
    existingToast.remove()
  }
  
  // Create toast element with icon
  const toast = document.createElement('div')
  toast.className = 'toast-message fixed top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 z-50'
  toast.style.animation = 'fadeIn 0.3s ease-in-out'
  toast.innerHTML = `
    <div class="flex items-center gap-3 bg-gray-900 text-white px-5 py-4 rounded-xl shadow-2xl backdrop-blur-sm" style="min-width: 280px; max-width: 90vw;">
      <svg class="w-6 h-6 flex-shrink-0 text-yellow-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
          d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/>
      </svg>
      <span class="flex-1 text-sm leading-relaxed">${message}</span>
    </div>
  `
  
  document.body.appendChild(toast)
  
  // Auto dismiss after 2.5 seconds
  setTimeout(() => {
    toast.style.animation = 'fadeOut 0.3s ease-in-out'
    setTimeout(() => {
      if (toast.parentNode) {
        toast.parentNode.removeChild(toast)
      }
    }, 300)
  }, 2500)
}

// Add CSS animations
const style = document.createElement('style')
style.textContent = `
  @keyframes fadeIn {
    from {
      opacity: 0;
      transform: translate(-50%, -50%) scale(0.9);
    }
    to {
      opacity: 1;
      transform: translate(-50%, -50%) scale(1);
    }
  }
  
  @keyframes fadeOut {
    from {
      opacity: 1;
      transform: translate(-50%, -50%) scale(1);
    }
    to {
      opacity: 0;
      transform: translate(-50%, -50%) scale(0.9);
    }
  }
`
document.head.appendChild(style)
