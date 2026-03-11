import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = [
    "modal",
    "container",
    "card",
    "nameInput",
    "idInput",
    "phoneInput",
    "hiddenField"
  ]

  static values = {
    currentIndex: Number,
    usedPassengerIds: Array
  }

  declare readonly modalTarget: HTMLElement
  declare readonly containerTarget: HTMLElement
  declare readonly cardTargets: HTMLElement[]
  declare readonly nameInputTargets: HTMLInputElement[]
  declare readonly idInputTargets: HTMLInputElement[]
  declare readonly phoneInputTargets: HTMLInputElement[]
  declare readonly hiddenFieldTarget: HTMLInputElement
  declare currentIndexValue: number
  declare usedPassengerIdsValue: string[]

  connect(): void {
    console.log("CruiseTravelerSelector connected")
    
    // Initialize used passenger IDs
    if (!this.usedPassengerIdsValue) {
      this.usedPassengerIdsValue = []
    }
    
    // Sync JSON data when inputs change
    this.nameInputTargets.forEach((input, index) => {
      input.addEventListener('blur', () => this.syncPassengerData())
    })
    this.idInputTargets.forEach((input, index) => {
      input.addEventListener('blur', () => this.syncPassengerData())
    })
    this.phoneInputTargets.forEach((input, index) => {
      input.addEventListener('blur', () => this.syncPassengerData())
    })
  }

  disconnect(): void {
    console.log("CruiseTravelerSelector disconnected")
  }

  // Open modal for specific passenger
  openModal(event: Event): void {
    const target = event.currentTarget as HTMLElement
    const index = parseInt(target.dataset.index || '0')
    
    console.log("Opening passenger selector modal for index:", index)
    
    this.currentIndexValue = index
    
    // Update passenger availability in modal
    this.updatePassengerAvailability()
    
    this.modalTarget.classList.remove('hidden')
    document.body.style.overflow = 'hidden'
  }

  // Close modal
  closeModal(): void {
    this.modalTarget.classList.add('hidden')
    document.body.style.overflow = ''
  }

  // Stop propagation for inner clicks
  stopPropagation(event: Event): void {
    event.stopPropagation()
  }

  // Select a passenger from the list
  selectPassenger(event: Event): void {
    const target = event.currentTarget as HTMLElement
    const passengerId = target.dataset.passengerId || ''
    const passengerName = target.dataset.passengerName || ''
    const passengerIdNumber = target.dataset.passengerIdNumber || ''
    const passengerPhone = target.dataset.passengerPhone || ''

    // Check if passenger is already used
    if (this.usedPassengerIdsValue.includes(passengerId)) {
      alert('该乘客已被选择，请选择其他乘客')
      return
    }

    console.log("Selected passenger:", { 
      passengerId, 
      passengerName, 
      passengerIdNumber, 
      passengerPhone,
      index: this.currentIndexValue 
    })

    // Get current input's passenger ID (if any)
    const currentInput = this.nameInputTargets[this.currentIndexValue]
    const currentPassengerId = currentInput?.dataset.selectedPassengerId

    // Remove old passenger ID from used list
    if (currentPassengerId && this.usedPassengerIdsValue.includes(currentPassengerId)) {
      this.usedPassengerIdsValue = this.usedPassengerIdsValue.filter(id => id !== currentPassengerId)
    }

    // Update form inputs for specific passenger
    if (this.nameInputTargets[this.currentIndexValue]) {
      this.nameInputTargets[this.currentIndexValue].value = passengerName
      this.nameInputTargets[this.currentIndexValue].dataset.selectedPassengerId = passengerId
    }
    if (this.idInputTargets[this.currentIndexValue]) {
      this.idInputTargets[this.currentIndexValue].value = passengerIdNumber
    }
    if (this.phoneInputTargets[this.currentIndexValue]) {
      this.phoneInputTargets[this.currentIndexValue].value = passengerPhone
    }

    // Add new passenger ID to used list
    this.usedPassengerIdsValue = [...this.usedPassengerIdsValue, passengerId]

    console.log('已使用的乘客ID列表:', this.usedPassengerIdsValue)

    // Sync passenger data to hidden field
    this.syncPassengerData()

    // Close modal
    this.closeModal()
  }

  // Update passenger cards based on quantity
  updatePassengerCards(quantity: number): void {
    console.log("Updating passenger cards for quantity:", quantity)
    
    const currentCount = this.cardTargets.length
    
    if (quantity > currentCount) {
      // Add new passenger cards
      for (let i = currentCount; i < quantity; i++) {
        this.addPassengerCard(i)
      }
    } else if (quantity < currentCount) {
      // Remove excess passenger cards
      for (let i = currentCount - 1; i >= quantity; i--) {
        this.removePassengerCard(i)
      }
    }
    
    // Sync passenger data after updating cards
    this.syncPassengerData()
  }

  // Add a new passenger card
  private addPassengerCard(index: number): void {
    const cardHTML = `
      <div class="mb-4 p-4 bg-gray-50 rounded-lg border border-gray-200" data-cruise-traveler-selector-target="card" data-index="${index}">
        <div class="flex items-center justify-between mb-3">
          <div class="flex items-center gap-2">
            <div class="w-10 h-10 bg-primary text-white rounded-full flex items-center justify-center font-semibold">
              ${index + 1}
            </div>
            <span class="text-sm font-medium text-gray-900">乘客${index + 1}</span>
          </div>
        </div>
        
        <div class="space-y-3">
          <div class="flex items-center py-2 border-b border-gray-200">
            <label class="text-sm text-gray-600 w-16">姓名</label>
            <input type="text" 
                   placeholder="请输入姓名"
                   data-cruise-traveler-selector-target="nameInput"
                   data-index="${index}"
                   class="flex-1 text-sm text-gray-900 focus:outline-none bg-transparent" />
            <button type="button" 
                    class="text-primary"
                    data-action="click->cruise-traveler-selector#openModal"
                    data-index="${index}">
              <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
                <path d="M10 9a3 3 0 100-6 3 3 0 000 6zm-7 9a7 7 0 1114 0H3z"></path>
              </svg>
            </button>
          </div>
          
          <div class="flex items-center py-2 border-b border-gray-200">
            <label class="text-sm text-gray-600 w-16">身份证</label>
            <input type="text" 
                   placeholder="请输入身份证号"
                   data-cruise-traveler-selector-target="idInput"
                   data-index="${index}"
                   class="flex-1 text-sm text-gray-900 focus:outline-none bg-transparent" />
          </div>
          
          <div class="flex items-center py-2">
            <label class="text-sm text-gray-600 w-16">手机号</label>
            <input type="text" 
                   placeholder="请输入手机号（选填）"
                   data-cruise-traveler-selector-target="phoneInput"
                   data-index="${index}"
                   class="flex-1 text-sm text-gray-900 focus:outline-none bg-transparent" />
          </div>
        </div>
      </div>
    `
    
    this.containerTarget.insertAdjacentHTML('beforeend', cardHTML)
    
    // Re-attach event listeners for new inputs
    const newInputs = this.containerTarget.querySelectorAll(`[data-index="${index}"]`)
    newInputs.forEach(input => {
      input.addEventListener('blur', () => this.syncPassengerData())
    })
  }

  // Remove a passenger card
  private removePassengerCard(index: number): void {
    const card = this.cardTargets.find(c => parseInt(c.dataset.index || '0') === index)
    if (card) {
      card.remove()
    }
  }

  // Sync passenger data from inputs to hidden field JSON
  private syncPassengerData(): void {
    const passengers = []
    
    for (let i = 0; i < this.nameInputTargets.length; i++) {
      const name = this.nameInputTargets[i]?.value.trim() || ''
      const idNumber = this.idInputTargets[i]?.value.trim() || ''
      const phone = this.phoneInputTargets[i]?.value.trim() || ''
      
      // Only include passengers with at least a name
      if (name) {
        passengers.push({
          name: name,
          id_number: idNumber,
          phone: phone,
          passenger_type: 'adult'  // Default to adult for all UI-created passengers
        })
      }
    }
    
    // Update hidden field with JSON data
    this.hiddenFieldTarget.value = JSON.stringify(passengers)
    
    console.log("Synced passenger data:", passengers)
  }

  // Update passenger availability in modal
  private updatePassengerAvailability(): void {
    const passengerItems = this.modalTarget.querySelectorAll('[data-passenger-id]')
    
    passengerItems.forEach((item) => {
      const passengerId = (item as HTMLElement).dataset.passengerId || ''
      const isUsed = this.usedPassengerIdsValue.includes(passengerId)
      
      if (isUsed) {
        // Mark as used
        item.classList.add('opacity-50', 'cursor-not-allowed', 'pointer-events-none')
        item.classList.remove('hover:bg-gray-100', 'cursor-pointer')
        
        // Add "已选择" badge if not exists
        if (!item.querySelector('.used-badge')) {
          const badge = document.createElement('span')
          badge.className = 'used-badge ml-2 px-2 py-0.5 text-xs rounded bg-gray-200 text-gray-600'
          badge.textContent = '已选择'
          
          const nameContainer = item.querySelector('.flex.items-center.mb-1')
          if (nameContainer) {
            nameContainer.appendChild(badge)
          }
        }
      } else {
        // Restore available state
        item.classList.remove('opacity-50', 'cursor-not-allowed', 'pointer-events-none')
        item.classList.add('hover:bg-gray-100', 'cursor-pointer')
        
        // Remove "已选择" badge
        const badge = item.querySelector('.used-badge')
        if (badge) {
          badge.remove()
        }
      }
    })
  }
}
