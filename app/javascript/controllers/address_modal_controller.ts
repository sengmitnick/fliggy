import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = ["modal", "addressList"]

  declare readonly modalTarget: HTMLElement
  declare readonly addressListTarget: HTMLElement

  connect(): void {
    console.log('[AddressModal] Controller connected')
    // Controller connected, but we'll load addresses when modal opens
  }

  open(event: Event): void {
    console.log('[AddressModal] Opening modal')
    event.preventDefault()
    this.modalTarget.classList.remove('hidden')
    document.body.style.overflow = 'hidden'
    // Load addresses when modal opens
    console.log('[AddressModal] Calling loadAddresses()')
    this.loadAddresses()
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
          <span class="text-base font-bold text-primary">${addressName}</span>
          <span class="ml-2 text-sm text-secondary">${addressPhone}</span>
        </div>
        <div class="bg-surface-elevated rounded-lg p-3">
          <div class="text-sm text-secondary">
            ${addressFull}
          </div>
        </div>
      `
    }

    // Update hidden fields for membership order form
    const contactNameInput = document.querySelector('[name="membership_order[contact_name]"]') as HTMLInputElement
    const contactPhoneInput = document.querySelector('[name="membership_order[contact_phone]"]') as HTMLInputElement
    const shippingAddressInput = document.querySelector('[name="membership_order[shipping_address]"]') as HTMLInputElement
    
    if (contactNameInput) {
      contactNameInput.value = addressName
    }
    if (contactPhoneInput) {
      contactPhoneInput.value = addressPhone
    }
    if (shippingAddressInput) {
      shippingAddressInput.value = addressFull
    }

    // Store selected address ID for booking (for other forms like sim card)
    const bookingForm = document.querySelector('[data-address-id-input]') as HTMLInputElement
    if (bookingForm) {
      bookingForm.value = addressId || ''
    }

    this.close()
  }

  private async loadAddresses(): Promise<void> {
    console.log('[AddressModal] loadAddresses() called')
    try {
      console.log('[AddressModal] Fetching /addresses.json')
      const response = await fetch('/addresses.json', {
        credentials: 'same-origin'
      })
      console.log('[AddressModal] Response status:', response.status)
      const addresses = await response.json()
      console.log('[AddressModal] Loaded addresses:', addresses.length)
      
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
