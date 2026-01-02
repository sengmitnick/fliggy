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
  toast.className = 'toast-message fixed z-50'
  toast.style.cssText = 'top: 50%; left: 50%; transform: translate(-50%, -50%);'
  toast.style.animation = 'fadeIn 0.3s ease-in-out'
  toast.innerHTML = `
    <div class="flex items-center justify-center text-white px-4 py-3 rounded-lg shadow-2xl backdrop-blur-sm" 
         style="min-width: 200px; max-width: 90vw; background: rgba(31, 41, 55, 0.85);">
      <span class="text-sm">${message}</span>
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
    }
    to {
      opacity: 1;
    }
  }
  
  @keyframes fadeOut {
    from {
      opacity: 1;
    }
    to {
      opacity: 0;
    }
  }
`
document.head.appendChild(style)
