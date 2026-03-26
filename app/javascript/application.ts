import './base';


// Global alert function - 替换浏览器原生 alert，使用相同的模态弹窗样式
window.showAlert = function(message: string): void {
  // Remove existing alert if any
  const existingAlert = document.querySelector('.alert-modal')
  if (existingAlert) {
    existingAlert.remove()
  }
  
  // Create modal backdrop
  const backdrop = document.createElement('div')
  backdrop.className = 'alert-modal fixed inset-0 z-50 flex items-center justify-center'
  backdrop.style.cssText = 'background: rgba(0, 0, 0, 0.3);'
  
  // Create modal content
  const modal = document.createElement('div')
  modal.className = 'bg-white rounded-xl shadow-2xl mx-4'
  modal.style.cssText = 'max-width: 320px; width: 90%;'
  modal.innerHTML = `
    <div class="p-4">
      <div class="flex items-start gap-3">
        <div class="flex-shrink-0 w-10 h-10 rounded-full bg-blue-50 flex items-center justify-center">
          <svg class="w-5 h-5 text-blue-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
          </svg>
        </div>
        <div class="flex-1 pt-1">
          <p class="text-gray-800 text-sm leading-relaxed">${message}</p>
        </div>
        <button class="close-alert flex-shrink-0 w-6 h-6 -mt-1 -mr-1 rounded-full hover:bg-gray-100 flex items-center justify-center transition-colors">
          <svg class="w-4 h-4 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
          </svg>
        </button>
      </div>
      <div class="mt-3 flex justify-end">
        <button class="close-alert px-4 py-2 bg-blue-500 hover:bg-blue-600 text-white text-sm font-medium rounded-lg transition-colors">
          知道了
        </button>
      </div>
    </div>
  `
  
  backdrop.appendChild(modal)
  document.body.appendChild(backdrop)
  
  // Close handlers
  const closeModal = () => {
    if (backdrop.parentNode) {
        backdrop.parentNode.removeChild(backdrop)
      }
  }
  
  // Close on button click
  const closeButtons = backdrop.querySelectorAll('.close-alert')
  closeButtons.forEach(btn => {
    btn.addEventListener('click', closeModal)
  })
  
  // Close on backdrop click
  backdrop.addEventListener('click', (e) => {
    if (e.target === backdrop) {
      closeModal()
    }
  })
}

// Override native alert to use our custom modal
window.alert = window.showAlert

window.showToast = window.showAlert

// Add CSS animations
const style = document.createElement('style')
style.textContent = `
  @keyframes fadeIn {
    from { opacity: 0; }
    to { opacity: 1; }
  }
  
  @keyframes fadeOut {
    from { opacity: 1; }
    to { opacity: 0; }
  }
  
  @keyframes slideUp {
    from {
      opacity: 0;
      transform: translateY(20px);
    }
    to {
      opacity: 1;
      transform: translateY(0);
    }
  }
  
  @keyframes slideDown {
    from {
      opacity: 1;
      transform: translateY(0);
    }
    to {
      opacity: 0;
      transform: translateY(20px);
    }
  }
`
document.head.appendChild(style)
