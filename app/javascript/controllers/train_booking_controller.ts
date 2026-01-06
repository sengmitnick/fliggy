import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = [
    "totalPrice",
    "selectedCarriage",
    "carriageButton",
    "seatButton",
    "selectedSeatCount"
  ]

  declare readonly totalPriceTarget: HTMLElement
  declare readonly selectedCarriageTarget: HTMLInputElement
  declare readonly carriageButtonTargets: HTMLButtonElement[]
  declare readonly seatButtonTargets: HTMLButtonElement[]
  declare readonly selectedSeatCountTarget: HTMLElement

  private basePrice: number = 0
  private insurancePrice: number = 0
  private currentCarriage: string = ''
  private selectedSeats: Set<string> = new Set()
  private maxSeats: number = 1

  connect(): void {
    // Get base price from hidden field
    const priceField = document.getElementById('booking_total_price') as HTMLInputElement
    if (priceField) {
      this.basePrice = parseFloat(priceField.value || '0')
    }
    this.updateTotalPrice()
  }

  selectPassenger(event: Event): void {
    const radio = event.currentTarget as HTMLInputElement
    const passengerName = radio.dataset.passengerName || ''
    const idNumber = radio.dataset.idNumber || ''
    const phone = radio.dataset.phone || ''

    // Update hidden fields
    const nameField = document.getElementById('booking_passenger_name') as HTMLInputElement
    const idField = document.getElementById('booking_passenger_id_number') as HTMLInputElement
    const phoneField = document.getElementById('booking_contact_phone') as HTMLInputElement

    if (nameField) nameField.value = passengerName
    if (idField) idField.value = idNumber
    if (phoneField) phoneField.value = phone
  }

  selectCarriage(event: Event): void {
    const button = event.currentTarget as HTMLButtonElement
    const carriage = button.dataset.carriage || ''

    // Check if clicking the already selected carriage (toggle off)
    if (this.currentCarriage === carriage) {
      // Deselect current carriage
      button.classList.remove('bg-orange-500', 'text-white', 'border-orange-500')
      button.classList.add('bg-white', 'text-gray-700', 'border-gray-300')
      this.selectedCarriageTarget.value = ''
      this.currentCarriage = ''
    } else {
      // Deselect all buttons first
      this.carriageButtonTargets.forEach(btn => {
        btn.classList.remove('bg-orange-500', 'text-white', 'border-orange-500')
        btn.classList.add('bg-white', 'text-gray-700', 'border-gray-300')
      })

      // Select new carriage
      button.classList.remove('bg-white', 'text-gray-700', 'border-gray-300')
      button.classList.add('bg-orange-500', 'text-white', 'border-orange-500')
      this.selectedCarriageTarget.value = carriage
      this.currentCarriage = carriage
    }
  }

  selectSeat(event: Event): void {
    const button = event.currentTarget as HTMLButtonElement
    const seatLetter = button.dataset.seatLetter || ''

    if (!seatLetter) return

    // Toggle seat selection
    if (this.selectedSeats.has(seatLetter)) {
      this.selectedSeats.delete(seatLetter)
      button.classList.remove('bg-orange-500', 'text-white', 'border-orange-500')
      button.classList.add('bg-white', 'text-gray-700', 'border-gray-300')
    } else {
      // Check if max seats reached
      if (this.selectedSeats.size >= this.maxSeats) {
        window.showToast(`最多只能选择${this.maxSeats}个座位`)
        return
      }
      this.selectedSeats.add(seatLetter)
      button.classList.remove('bg-white', 'text-gray-700', 'border-gray-300', 'bg-gray-100', 'text-gray-400')
      button.classList.add('bg-orange-500', 'text-white', 'border-orange-500')
    }

    // Update selected count display
    this.updateSelectedSeatCount()
  }

  private updateSelectedSeatCount(): void {
    if (this.selectedSeatCountTarget) {
      this.selectedSeatCountTarget.textContent = `${this.selectedSeats.size}/${this.maxSeats}`
    }
  }

  toggleNearDoor(event: Event): void {
    const checkbox = event.currentTarget as HTMLInputElement
    // This is just for UI interaction
    // Real implementation would add ¥12 to the price
    if (checkbox.checked) {
      console.log('Near door option selected')
    }
  }

  handleNormalBooking(): void {
    // Validate and submit the form for normal booking
    const form = this.element.querySelector('form') as HTMLFormElement
    if (!form) return

    // Validate passenger selection
    const passengerRadio = document.querySelector('input[name="passenger"]:checked') as HTMLInputElement
    if (!passengerRadio) {
      window.showToast('请选择乘车人')
      return
    }

    // Validate contact phone
    const phoneField = document.getElementById('booking_contact_phone') as HTMLInputElement
    if (!phoneField || !phoneField.value.trim()) {
      window.showToast('请输入联系手机')
      return
    }

    // Set accept_terms to 1 (普通预订自动同意协议)
    const acceptTermsField = document.getElementById('booking_accept_terms') as HTMLInputElement
    if (acceptTermsField) {
      acceptTermsField.value = '1'
    }

    // Use native submit to bypass handleSubmit event listener
    HTMLFormElement.prototype.submit.call(form)
  }

  selectInsuranceOption(event: Event): void {
    const radio = event.currentTarget as HTMLInputElement
    const insuranceType = radio.value
    const insurancePrice = parseFloat(radio.dataset.price || '0')

    const insuranceTypeField = document.getElementById('booking_insurance_type') as HTMLInputElement
    const insurancePriceField = document.getElementById('booking_insurance_price') as HTMLInputElement

    if (insuranceTypeField) insuranceTypeField.value = insuranceType
    if (insurancePriceField) insurancePriceField.value = insurancePrice.toString()

    this.insurancePrice = insurancePrice
    this.updateTotalPrice()
  }

  handleSubmit(event: Event): void {
    event.preventDefault()

    // Validate passenger selection
    const passengerRadio = document.querySelector('input[name="passenger"]:checked') as HTMLInputElement
    if (!passengerRadio) {
      alert('请选择乘车人')
      return
    }

    // Validate contact phone
    const phoneField = document.getElementById('booking_contact_phone') as HTMLInputElement
    if (!phoneField || !phoneField.value.trim()) {
      alert('请输入联系手机')
      return
    }

    // Check terms acceptance
    const visualCheckbox = document.getElementById('visual_accept_terms') as HTMLInputElement
    if (!visualCheckbox || !visualCheckbox.checked) {
      this.showTermsModal()
      return
    }

    // Check insurance selection
    const insuranceTypeField = document.getElementById('booking_insurance_type') as HTMLInputElement
    const insuranceType = insuranceTypeField?.value || 'none'

    if (insuranceType === 'none') {
      this.showInsuranceModal()
    } else {
      this.submitBooking()
    }
  }

  private showTermsModal(): void {
    const modal = document.createElement('div')
    modal.className = 'fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50'
    modal.innerHTML = `
      <div class="bg-white rounded-lg p-6 max-w-md mx-4">
        <h3 class="text-xl font-bold mb-4">用户协议和隐私政策</h3>
        <div class="max-h-60 overflow-y-auto mb-4 text-sm text-gray-600">
          <p class="mb-2">欢迎使用我们的服务。请仔细阅读以下条款：</p>
          <p class="mb-2">1. 服务条款...</p>
          <p class="mb-2">2. 隐私政策...</p>
          <p class="mb-2">3. 退改规则...</p>
        </div>
        <div class="flex space-x-3">
          <button class="flex-1 py-3 border border-gray-300 rounded" data-action="decline">
            不同意
          </button>
          <button class="flex-1 py-3 bg-orange-500 text-white rounded" data-action="accept">
            同意
          </button>
        </div>
      </div>
    `

    const declineBtn = modal.querySelector('[data-action="decline"]')
    const acceptBtn = modal.querySelector('[data-action="accept"]')

    declineBtn?.addEventListener('click', () => {
      document.body.removeChild(modal)
    })

    acceptBtn?.addEventListener('click', () => {
      this.acceptTerms()
      document.body.removeChild(modal)
    })

    document.body.appendChild(modal)
  }

  private acceptTerms(): void {
    const visualCheckbox = document.getElementById('visual_accept_terms') as HTMLInputElement
    const hiddenField = document.getElementById('booking_accept_terms') as HTMLInputElement
    
    if (visualCheckbox) visualCheckbox.checked = true
    if (hiddenField) hiddenField.value = '1'

    // Check insurance again
    const insuranceTypeField = document.getElementById('booking_insurance_type') as HTMLInputElement
    const insuranceType = insuranceTypeField?.value || 'none'

    if (insuranceType === 'none') {
      this.showInsuranceModal()
    } else {
      this.submitBooking()
    }
  }

  private showInsuranceModal(): void {
    const existingModal = document.getElementById('insurance_recommendation_modal')
    if (existingModal) {
      existingModal.classList.remove('hidden')
      return
    }

    const modal = document.createElement('div')
    modal.id = 'insurance_recommendation_modal'
    modal.className = 'fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50'
    modal.innerHTML = `
      <div class="bg-white rounded-lg p-6 max-w-md mx-4">
        <h3 class="text-xl font-bold mb-4">建议购买保险</h3>
        <p class="text-gray-600 mb-6">为了您的出行安全，建议购买出行保险</p>
        
        <div class="space-y-3 mb-6">
          <label class="flex items-center justify-between p-3 border rounded cursor-pointer">
            <div>
              <div class="font-medium">标准保险</div>
              <div class="text-sm text-gray-500">¥30</div>
            </div>
            <input type="radio" name="insurance_modal" value="standard" data-price="30" class="w-5 h-5" />
          </label>
          
          <label class="flex items-center justify-between p-3 border rounded cursor-pointer">
            <div>
              <div class="font-medium">高级保险</div>
              <div class="text-sm text-gray-500">¥50</div>
            </div>
            <input type="radio" name="insurance_modal" value="premium" data-price="50" class="w-5 h-5" />
          </label>
        </div>
        
        <div class="flex space-x-3">
          <button class="flex-1 py-3 border border-gray-300 rounded" data-action="skip-insurance">
            放弃保险
          </button>
          <button class="flex-1 py-3 bg-orange-500 text-white rounded" data-action="select-insurance">
            确认选择
          </button>
        </div>
      </div>
    `

    const skipBtn = modal.querySelector('[data-action="skip-insurance"]')
    const selectBtn = modal.querySelector('[data-action="select-insurance"]')

    skipBtn?.addEventListener('click', () => {
      document.body.removeChild(modal)
      this.submitBooking()
    })

    selectBtn?.addEventListener('click', () => {
      const selectedRadio = modal.querySelector('input[name="insurance_modal"]:checked') as HTMLInputElement
      if (selectedRadio) {
        const insuranceType = selectedRadio.value
        const insurancePrice = parseFloat(selectedRadio.dataset.price || '0')

        const insuranceTypeField = document.getElementById('booking_insurance_type') as HTMLInputElement
        const insurancePriceField = document.getElementById('booking_insurance_price') as HTMLInputElement

        if (insuranceTypeField) insuranceTypeField.value = insuranceType
        if (insurancePriceField) insurancePriceField.value = insurancePrice.toString()

        this.insurancePrice = insurancePrice
        this.updateTotalPrice()
      }
      document.body.removeChild(modal)
      this.submitBooking()
    })

    document.body.appendChild(modal)
  }

  private submitBooking(): void {
    // stimulus-validator: disable-next-line
    const form = this.element.querySelector('form') as HTMLFormElement
    if (form) {
      form.submit()
    }
  }

  private updateTotalPrice(): void {
    const total = this.basePrice + this.insurancePrice
    if (this.totalPriceTarget) {
      this.totalPriceTarget.textContent = `¥${Math.round(total)}`
    }
  }
}
