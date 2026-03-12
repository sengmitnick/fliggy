import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = [
    "totalPrice",
    "selectedCarriage",
    "carriageButton",
    "seatButton",
    "selectedSeatCount",
    "passengerCount",
    "checkIcon"
  ]

  declare readonly totalPriceTarget: HTMLElement
  declare readonly selectedCarriageTarget: HTMLInputElement
  declare readonly carriageButtonTargets: HTMLButtonElement[]
  declare readonly seatButtonTargets: HTMLButtonElement[]
  declare readonly selectedSeatCountTarget: HTMLElement
  declare readonly passengerCountTarget: HTMLElement
  declare readonly checkIconTargets: HTMLElement[]

  private basePrice: number = 0
  private bookingOptionFee: number = 0
  private insurancePrice: number = 0
  private currentCarriage: string = ''
  private selectedSeats: Set<string> = new Set()
  private maxSeats: number = 1
  private selectedPassengers: Map<string, any> = new Map()
  private maxPassengers: number = 5 // Allow multiple passengers like flight booking

  connect(): void {
    // Get base price from hidden field (single passenger price from backend)
    const priceField = document.getElementById('booking_total_price') as HTMLInputElement
    if (priceField) {
      const singlePassengerPrice = parseFloat(priceField.value || '0')
      this.basePrice = singlePassengerPrice // Store single passenger price
    }
    
    // Get booking option fee from backend (already included in total_price)
    const bookingOptionField = document.getElementById('booking_option_id') as HTMLInputElement
    if (bookingOptionField && bookingOptionField.value) {
      // The basePrice already includes booking option fee per passenger
      this.bookingOptionFee = 0 // Already included in basePrice
    }
    
    // Allow multiple passengers (like flight booking)
    // Get max passengers from URL parameter
    const urlParams = new URLSearchParams(window.location.search)
    const passengerCount = urlParams.get('passenger_count')
    if (passengerCount) {
      this.maxPassengers = parseInt(passengerCount)
      this.maxSeats = this.maxPassengers
    }
    
    // Filter passengers by type based on homepage selection
    this.filterPassengersByType()
    
    // Load selected passengers from localStorage (from search page)
    this.loadPassengersFromLocalStorage()
    
    this.updateTotalPrice()
  }

  togglePassenger(event: Event): void {
    const target = event.currentTarget as HTMLElement
    const passengerId = target.dataset.passengerId
    const passengerName = target.dataset.passengerName
    const passengerType = target.dataset.passengerType || 'adult'
    const passengerIdNumber = target.dataset.passengerIdNumber || ''
    const passengerPhone = target.dataset.passengerPhone || ''
    
    if (!passengerId || !passengerName) return
    
    // Check if already selected
    if (this.selectedPassengers.has(passengerId)) {
      this.selectedPassengers.delete(passengerId)
      this.updatePassengerUI(target, false)
    } else {
      // Check max limit
      if (this.selectedPassengers.size >= this.maxPassengers) {
        window.showToast(`最多只能选择${this.maxPassengers}位乘车人`)
        return
      }
      
      this.selectedPassengers.set(passengerId, {
        name: passengerName,
        type: passengerType,
        idNumber: passengerIdNumber,
        phone: passengerPhone
      })
      this.updatePassengerUI(target, true)
    }
    
    this.updatePassengerCountDisplay()
    this.updateContactPhone() // Update contact phone when passenger selection changes
  }

  private updatePassengerUI(element: HTMLElement, selected: boolean): void {
    const checkIcon = element.querySelector('[data-train-booking-target="checkIcon"]') as HTMLElement
    if (checkIcon) {
      if (selected) {
        checkIcon.classList.remove('text-gray-300')
        checkIcon.classList.add('text-yellow-400')
      } else {
        checkIcon.classList.add('text-gray-300')
        checkIcon.classList.remove('text-yellow-400')
      }
    }
  }

  private updatePassengerCountDisplay(): void {
    const count = this.selectedPassengers.size
    if (this.passengerCountTarget) {
      this.passengerCountTarget.textContent = `已选${count}人`
    }
    // Update max seats for seat selection
    this.maxSeats = count > 0 ? count : 1
    this.updateSelectedSeatCount()
    // Update total price based on passenger count
    this.updateTotalPrice()
  }

  /**
   * Update contact phone based on passenger selection
   * Logic:
   * - If passengers selected → auto-fill with first selected passenger's phone
   * - If no passengers → keep field empty
   */
  private updateContactPhone(): void {
    const contactPhoneField = document.getElementById('booking_contact_phone') as HTMLInputElement
    if (!contactPhoneField) return
    
    if (this.selectedPassengers.size === 0) {
      // No passengers selected → clear contact phone if it was auto-filled
      // (Don't clear if user manually entered a number)
      return
    }
    
    // Get first selected passenger's phone (preferably adult, fallback to any)
    let firstPhone = ''
    
    // First try to find adult passenger's phone
    for (const [id, passenger] of this.selectedPassengers) {
      if (passenger.type === 'adult' && passenger.phone) {
        firstPhone = passenger.phone
        break
      }
    }
    
    // If no adult found, use first passenger's phone
    if (!firstPhone) {
      const firstPassenger = this.selectedPassengers.values().next().value
      if (firstPassenger && firstPassenger.phone) {
        firstPhone = firstPassenger.phone
      }
    }
    
    // Auto-fill contact phone with first passenger's phone
    if (firstPhone) {
      contactPhoneField.value = firstPhone
    }
  }

  private filterPassengersByType(): void {
    const savedState = localStorage.getItem('passenger_selection')
    if (!savedState) return
    
    try {
      const state = JSON.parse(savedState)
      const adults = state.adults || 0
      const children = state.children || 0
      
      // Get all passenger elements
      const passengerElements = document.querySelectorAll('[data-passenger-type]')
      
      // Determine which passenger types should be selectable
      const allowAdults = adults > 0
      const allowChildren = children > 0
      
      passengerElements.forEach((element: Element) => {
        const htmlElement = element as HTMLElement
        const passengerType = htmlElement.dataset.passengerType
        
        // Find the checkbox within this passenger element
        const checkbox = htmlElement.querySelector('input[type="checkbox"]') as HTMLInputElement
        if (!checkbox) return
        
        if (passengerType === 'child' && !allowChildren) {
          // Disable child passenger checkboxes if no children selected
          checkbox.disabled = true
          checkbox.checked = false
          htmlElement.style.opacity = '0.5'
        } else if (passengerType === 'adult' && !allowAdults) {
          // Disable adult passenger checkboxes if no adults selected
          checkbox.disabled = true
          checkbox.checked = false
          htmlElement.style.opacity = '0.5'
        } else {
          // Enable checkbox if type matches selection
          checkbox.disabled = false
          htmlElement.style.opacity = ''
        }
      })
    } catch (e) {
      console.error('Failed to filter passengers by type:', e)
    }
  }

  private loadPassengersFromLocalStorage(): void {
    const savedState = localStorage.getItem('passenger_selection')
    if (!savedState) return
    
    try {
      const state = JSON.parse(savedState)
      const passengerIds = state.passengerIds || []
      
      // Only apply if passenger names mode was used (not count mode)
      if (passengerIds.length === 0) return
      
      // Find and select passengers by their IDs
      passengerIds.forEach((passengerId: number) => {
        const passengerElement = document.querySelector(`[data-passenger-id="${passengerId}"]`) as HTMLElement
        if (passengerElement) {
          const passengerName = passengerElement.dataset.passengerName || ''
          const passengerType = passengerElement.dataset.passengerType || 'adult'
          const passengerIdNumber = passengerElement.dataset.passengerIdNumber || ''
          const passengerPhone = passengerElement.dataset.passengerPhone || ''
          
          // Add to selected passengers
          this.selectedPassengers.set(passengerId.toString(), {
            name: passengerName,
            type: passengerType,
            idNumber: passengerIdNumber,
            phone: passengerPhone
          })
          
          // Update UI to show selected state
          this.updatePassengerUI(passengerElement, true)
        }
      })
      
      // Update displays after loading all passengers
      this.updatePassengerCountDisplay()
      
      // Auto-fill contact phone if passengers were preselected from homepage
      this.updateContactPhone()
    } catch (e) {
      console.error('Failed to load passengers from localStorage:', e)
    }
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
    if (this.selectedPassengers.size === 0) {
      window.showToast('请选择乘车人')
      return
    }

    // Validate contact phone
    const phoneField = document.getElementById('booking_contact_phone') as HTMLInputElement
    if (!phoneField || !phoneField.value.trim()) {
      window.showToast('请输入联系手机')
      return
    }

    // Fill passenger_ids field with all selected passenger IDs (comma-separated)
    const passengerIds = Array.from(this.selectedPassengers.keys()).join(',')
    const passengerIdsField = document.getElementById('booking_passenger_ids') as HTMLInputElement
    if (passengerIdsField) {
      passengerIdsField.value = passengerIds
    }

    // Fill first passenger info for fallback (in case passenger_ids is empty)
    const firstPassenger = Array.from(this.selectedPassengers.values())[0]
    if (firstPassenger) {
      const nameField = document.getElementById('booking_passenger_name') as HTMLInputElement
      const idNumberField = document.getElementById('booking_passenger_id_number') as HTMLInputElement
      
      if (nameField) nameField.value = firstPassenger.name
      if (idNumberField) idNumberField.value = firstPassenger.idNumber
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
    if (this.selectedPassengers.size === 0) {
      window.showToast('请选择乘车人')
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
    // Calculate total price considering adult and child passengers
    let total = 0
    
    if (this.selectedPassengers.size === 0) {
      // No passenger selected, use single adult base price
      total = this.basePrice + this.insurancePrice
    } else {
      // Calculate total for each passenger type
      this.selectedPassengers.forEach((passenger) => {
        const passengerType = passenger.type || 'adult'
        let passengerPrice = this.basePrice
        
        // Child ticket is 50% of adult price
        if (passengerType === 'child') {
          passengerPrice = this.basePrice * 0.5
        }
        
        total += passengerPrice + this.insurancePrice
      })
    }
    
    if (this.totalPriceTarget) {
      this.totalPriceTarget.textContent = `¥${total.toFixed(1)}`
    }
  }
}
