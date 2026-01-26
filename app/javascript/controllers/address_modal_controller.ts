import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = ["modal", "addressList"]

  declare readonly modalTarget: HTMLElement
  declare readonly addressListTarget: HTMLElement

  connect(): void {
    // Load addresses when controller connects
    this.loadAddresses()
  }

  open(event: Event): void {
    event.preventDefault()
    this.modalTarget.classList.remove('hidden')
    document.body.style.overflow = 'hidden'
  }

  close(event?: Event): void {
    if (event) {
      event.preventDefault()
    }
    this.modalTarget.classList.add('hidden')
    document.body.style.overflow = ''
  }

  closeOnBackdrop(event: Event): void {
    if (event.target === event.currentTarget) {
      this.close()
    }
  }

  selectAddress(event: Event): void {
    event.preventDefault()
    const target = event.currentTarget as HTMLElement
    const addressId = target.dataset.addressId
    const addressName = target.dataset.addressName || ''
    const addressPhone = target.dataset.addressPhone || ''
    const addressFull = target.dataset.addressFull || ''

    // Update the displayed address in the booking section
    const addressDisplay = document.querySelector('[data-address-display]')
    if (addressDisplay) {
      addressDisplay.innerHTML = `
        <div class="flex items-center mb-2">
          <span class="text-base font-bold">${addressName}</span>
          <span class="ml-2 text-sm text-gray-600">${addressPhone}</span>
        </div>
        <div class="bg-blue-50 rounded-lg p-3">
          <div class="text-sm text-gray-700">
            ${addressFull}
          </div>
        </div>
      `
    }

    // Store selected address ID for booking
    const bookingForm = document.querySelector('[data-address-id-input]') as HTMLInputElement
    if (bookingForm) {
      bookingForm.value = addressId || ''
    }

    this.close()
  }

  private async loadAddresses(): Promise<void> {
    try {
      const response = await fetch('/addresses.json')
      const addresses = await response.json()
      
      if (addresses.length === 0) {
        this.addressListTarget.innerHTML = `
          <div class="text-center py-8 text-gray-500">
            <svg class="w-16 h-16 mx-auto text-gray-300 mb-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"/>
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"/>
            </svg>
            <p>暂无收货地址</p>
          </div>
        `
      } else {
        this.addressListTarget.innerHTML = addresses.map((address: AddressData) => `
          <div class="border-b border-gray-100 last:border-b-0">
            <button 
              class="w-full px-4 py-4 text-left hover:bg-gray-50 transition"
              data-action="click->address-modal#selectAddress"
              data-address-id="${address.id}"
              data-address-name="${this.escapeHtml(address.name)}"
              data-address-phone="${this.escapeHtml(address.phone)}"
              data-address-full="${this.escapeHtml(address.full_address)}">
              <div class="flex items-center mb-2">
                <span class="text-base font-bold">${this.escapeHtml(address.name)}</span>
                ${address.is_default ? '<span class="ml-2 px-2 py-0.5 text-xs rounded" style="background: #FFE8CC; color: #FF6B35;">默认</span>' : ''}
              </div>
              <div class="text-sm text-gray-600 mb-2">
                ${this.escapeHtml(address.phone)}
              </div>
              <div class="bg-blue-50 rounded-lg p-3">
                <div class="text-sm text-gray-700">
                  ${this.escapeHtml(address.full_address)}
                </div>
              </div>
            </button>
          </div>
        `).join('')
      }
    } catch (error) {
      console.error('Failed to load addresses:', error)
      this.addressListTarget.innerHTML = `
        <div class="text-center py-8 text-red-500">
          <p>加载地址失败，请重试</p>
        </div>
      `
    }
  }

  private escapeHtml(text: string): string {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }
}

interface AddressData {
  id: number
  name: string
  phone: string
  full_address: string
  is_default: boolean
}
