import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = [
    "quantityInput",
    "bottomPrice",
    "decreaseBtn",
    "increaseBtn",
    "stockupTab",
    "instantTab",
    "bookingTypeInput",
    "contactNameInput",
    "contactPhoneInput",
    "passengerRadio",
    "radioIndicator",
    "radioInner",
    "manualNameInput",
    "manualPhoneInput",
    "contactModal",
    "selectedName",
    "selectedPhone",
    "bookingModal",
    "packageOption",
    "cityFilter",
    "cityGroup"
  ]

  declare readonly quantityInputTarget: HTMLInputElement
  declare readonly bottomPriceTarget: HTMLElement
  declare readonly decreaseBtnTarget: HTMLButtonElement
  declare readonly increaseBtnTarget: HTMLButtonElement
  declare readonly stockupTabTarget: HTMLElement
  declare readonly instantTabTarget: HTMLElement
  declare readonly bookingTypeInputTarget: HTMLInputElement
  declare readonly contactNameInputTarget: HTMLInputElement
  declare readonly contactPhoneInputTarget: HTMLInputElement
  declare readonly passengerRadioTargets: HTMLInputElement[]
  declare readonly radioIndicatorTargets: HTMLElement[]
  declare readonly radioInnerTargets: HTMLElement[]
  declare readonly hasManualNameInputTarget: boolean
  declare readonly manualNameInputTarget?: HTMLInputElement
  declare readonly hasManualPhoneInputTarget: boolean
  declare readonly manualPhoneInputTarget?: HTMLInputElement
  declare readonly hasContactModalTarget: boolean
  declare readonly contactModalTarget?: HTMLElement
  declare readonly hasSelectedNameTarget: boolean
  declare readonly selectedNameTarget?: HTMLElement
  declare readonly hasSelectedPhoneTarget: boolean
  declare readonly selectedPhoneTarget?: HTMLElement
  declare readonly hasBookingModalTarget: boolean
  declare readonly bookingModalTarget?: HTMLElement
  declare readonly packageOptionTargets: HTMLElement[]
  declare readonly cityFilterTargets: HTMLElement[]
  declare readonly cityGroupTargets: HTMLElement[]

  connect(): void {
    console.log("HotelPackageOrder connected")
    this.updateButtonStates()
    
    // Auto-select first passenger if exists
    if (this.passengerRadioTargets.length > 0) {
      const firstRadio = this.passengerRadioTargets[0]
      if (firstRadio.checked) {
        const label = firstRadio.closest('label') as HTMLElement
        const name = label?.dataset.passengerName || ""
        const phone = label?.dataset.passengerPhone || ""
        this.contactNameInputTarget.value = name
        this.contactPhoneInputTarget.value = phone
      }
    }
    
    // Sync manual inputs with hidden fields if they exist
    if (this.hasManualNameInputTarget && this.hasManualPhoneInputTarget) {
      this.manualNameInputTarget!.addEventListener('input', () => {
        this.contactNameInputTarget.value = this.manualNameInputTarget!.value
      })
      this.manualPhoneInputTarget!.addEventListener('input', () => {
        this.contactPhoneInputTarget.value = this.manualPhoneInputTarget!.value
      })
    }
  }

  increaseQuantity(event: Event): void {
    event.preventDefault()
    const currentQuantity = parseInt(this.quantityInputTarget.value) || 1
    const newQuantity = currentQuantity + 1
    
    if (newQuantity <= 99) {
      this.quantityInputTarget.value = newQuantity.toString()
      this.updatePrice()
      this.updateButtonStates()
    }
  }

  decreaseQuantity(event: Event): void {
    event.preventDefault()
    const currentQuantity = parseInt(this.quantityInputTarget.value) || 1
    const newQuantity = currentQuantity - 1
    
    if (newQuantity >= 1) {
      this.quantityInputTarget.value = newQuantity.toString()
      this.updatePrice()
      this.updateButtonStates()
    }
  }

  updatePrice(): void {
    const quantity = parseInt(this.quantityInputTarget.value) || 1
    const unitPrice = parseFloat(this.increaseBtnTarget.dataset.price || "0")
    const totalPrice = quantity * unitPrice

    // Update bottom price (integer only)
    this.bottomPriceTarget.textContent = Math.round(totalPrice).toString()
  }

  updateButtonStates(): void {
    const quantity = parseInt(this.quantityInputTarget.value) || 1
    
    // Update decrease button
    if (quantity <= 1) {
      this.decreaseBtnTarget.classList.remove("border-blue-500", "bg-blue-50", "text-blue-600")
      this.decreaseBtnTarget.classList.add("border-gray-200", "text-gray-300")
      this.decreaseBtnTarget.disabled = true
    } else {
      this.decreaseBtnTarget.classList.remove("border-gray-200", "text-gray-300")
      this.decreaseBtnTarget.classList.add("border-blue-500", "bg-blue-50", "text-blue-600")
      this.decreaseBtnTarget.disabled = false
    }
  }

  selectTab(event: Event): void {
    event.preventDefault()
    const target = event.currentTarget as HTMLElement
    const tabType = target.dataset.tab
    
    if (tabType === "stockup") {
      // Activate stockup tab
      this.stockupTabTarget.classList.remove("bg-[#FCEEA8]", "bg-opacity-60", "text-gray-700")
      this.stockupTabTarget.classList.add("bg-[#F5F8FA]", "z-10")
      this.stockupTabTarget.querySelector("span:first-child")?.classList.remove("font-medium")
      this.stockupTabTarget.querySelector("span:first-child")?.classList.add("font-bold", "text-black")
      
      // Deactivate instant tab
      this.instantTabTarget.classList.remove("bg-[#F5F8FA]", "z-10")
      this.instantTabTarget.classList.add("bg-[#FCEEA8]", "bg-opacity-60", "text-gray-700")
      this.instantTabTarget.querySelector("span:first-child")?.classList.remove("font-bold", "text-black")
      this.instantTabTarget.querySelector("span:first-child")?.classList.add("font-medium")
      
      // Update hidden field
      this.bookingTypeInputTarget.value = "stockup"
    } else if (tabType === "instant") {
      // Activate instant tab
      this.instantTabTarget.classList.remove("bg-[#FCEEA8]", "bg-opacity-60", "text-gray-700")
      this.instantTabTarget.classList.add("bg-[#F5F8FA]", "z-10")
      this.instantTabTarget.querySelector("span:first-child")?.classList.remove("font-medium")
      this.instantTabTarget.querySelector("span:first-child")?.classList.add("font-bold", "text-black")
      
      // Deactivate stockup tab
      this.stockupTabTarget.classList.remove("bg-[#F5F8FA]", "z-10")
      this.stockupTabTarget.classList.add("bg-[#FCEEA8]", "bg-opacity-60", "text-gray-700")
      this.stockupTabTarget.querySelector("span:first-child")?.classList.remove("font-bold", "text-black")
      this.stockupTabTarget.querySelector("span:first-child")?.classList.add("font-medium")
      
      // Update hidden field
      this.bookingTypeInputTarget.value = "instant"
    }
  }

  openContactModal(event: Event): void {
    event.preventDefault()
    if (this.hasContactModalTarget) {
      this.contactModalTarget!.classList.remove('hidden')
    }
  }

  closeContactModal(event: Event): void {
    event.preventDefault()
    if (this.hasContactModalTarget) {
      this.contactModalTarget!.classList.add('hidden')
    }
  }

  selectPassenger(event: Event): void {
    const label = event.currentTarget as HTMLElement
    const name = label.dataset.passengerName || ""
    const phone = label.dataset.passengerPhone || ""
    
    // Update hidden fields
    this.contactNameInputTarget.value = name
    this.contactPhoneInputTarget.value = phone
    
    // Update displayed selected contact if targets exist
    if (this.hasSelectedNameTarget && this.hasSelectedPhoneTarget) {
      this.selectedNameTarget!.textContent = name
      this.selectedPhoneTarget!.textContent = phone
    }
    
    // Update visual radio indicators
    this.radioInnerTargets.forEach((inner) => {
      inner.classList.add('hidden')
    })
    
    this.radioIndicatorTargets.forEach((indicator) => {
      indicator.classList.remove('border-blue-500')
      indicator.classList.add('border-gray-300')
    })
    
    // Find the radio input and check it
    const radioInput = label.querySelector('input[type="radio"]') as HTMLInputElement
    if (radioInput) {
      radioInput.checked = true
      
      // Update the indicator for this radio
      const indicator = label.querySelector('[data-hotel-package-order-target="radioIndicator"]') as HTMLElement
      const inner = label.querySelector('[data-hotel-package-order-target="radioInner"]') as HTMLElement
      
      if (indicator) {
        indicator.classList.remove('border-gray-300')
        indicator.classList.add('border-blue-500')
      }
      if (inner) {
        inner.classList.remove('hidden')
      }
    }
    
    // Close the modal after selection
    if (this.hasContactModalTarget) {
      this.contactModalTarget!.classList.add('hidden')
    }
  }

  handleSubmit(event: Event): void {
    // Validate contact info before submission
    const name = this.contactNameInputTarget.value.trim()
    const phone = this.contactPhoneInputTarget.value.trim()
    
    if (!name) {
      event.preventDefault()
      window.showToast('请输入联系人姓名')
      return
    }
    
    if (!phone) {
      event.preventDefault()
      window.showToast('请输入联系人电话')
      return
    }
    
    // Simple phone validation
    const phoneRegex = /^1[3-9]\d{9}$/
    if (!phoneRegex.test(phone)) {
      event.preventDefault()
      window.showToast('请输入正确的手机号码')
      return
    }
    
    // Form will be submitted normally to create pending order
  }

  // Booking modal methods
  openBookingModal(event: Event): void {
    event.preventDefault()
    if (this.hasBookingModalTarget) {
      this.bookingModalTarget!.classList.remove('hidden')
    }
  }

  closeBookingModal(event: Event): void {
    event.preventDefault()
    if (this.hasBookingModalTarget) {
      this.bookingModalTarget!.classList.add('hidden')
    }
  }

  selectPackageOption(event: Event): void {
    const target = event.currentTarget as HTMLElement
    const packageOptionId = target.dataset.packageOptionId
    
    // Update visual selection state
    this.packageOptionTargets.forEach((option) => {
      const isSelected = option.dataset.packageOptionId === packageOptionId
      option.dataset.selected = isSelected.toString()
      
      if (isSelected) {
        option.classList.remove('bg-white', 'border-gray-200')
        option.classList.add('bg-[#FFF9E6]', 'border-[#FFD700]')
      } else {
        option.classList.remove('bg-[#FFF9E6]', 'border-[#FFD700]')
        option.classList.add('bg-white', 'border-gray-200')
      }
    })
    
    // Optional: You could reload the page with the new package option
    // window.location.href = `/hotel_package_orders/new?package_option_id=${packageOptionId}`
  }

  selectCity(event: Event): void {
    const target = event.currentTarget as HTMLElement
    const selectedCity = target.dataset.city
    
    // Update filter visual state
    this.cityFilterTargets.forEach((filter) => {
      const isSelected = filter.dataset.city === selectedCity
      filter.dataset.selected = isSelected.toString()
      
      if (isSelected) {
        filter.classList.remove('bg-white', 'text-gray-700', 'border-gray-200')
        filter.classList.add('bg-[#FFF9E6]', 'text-[#FF5000]', 'border-[#FFD700]')
      } else {
        filter.classList.remove('bg-[#FFF9E6]', 'text-[#FF5000]', 'border-[#FFD700]')
        filter.classList.add('bg-white', 'text-gray-700', 'border-gray-200')
      }
    })
    
    // Show/hide city groups based on selection
    this.cityGroupTargets.forEach((group) => {
      const groupCity = group.dataset.city
      
      if (selectedCity === 'all') {
        group.classList.remove('hidden')
      } else {
        if (groupCity === selectedCity) {
          group.classList.remove('hidden')
        } else {
          group.classList.add('hidden')
        }
      }
    })
  }
}
