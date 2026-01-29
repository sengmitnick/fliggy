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
    "cityGroup",
    "dateSelectionModal",
    "checkInDateInput",
    "checkOutDateInput",
    "selectedHotelName",
    "selectedPackageName",
    "selectedNightCount"
  ]

  declare readonly hasQuantityInputTarget: boolean
  declare readonly quantityInputTarget?: HTMLInputElement
  declare readonly hasBottomPriceTarget: boolean
  declare readonly bottomPriceTarget?: HTMLElement
  declare readonly hasDecreaseBtnTarget: boolean
  declare readonly decreaseBtnTarget?: HTMLButtonElement
  declare readonly hasIncreaseBtnTarget: boolean
  declare readonly increaseBtnTarget?: HTMLButtonElement
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
  declare readonly hasDateSelectionModalTarget: boolean
  declare readonly dateSelectionModalTarget?: HTMLElement
  declare readonly hasCheckInDateInputTarget: boolean
  declare readonly checkInDateInputTarget?: HTMLInputElement
  declare readonly hasCheckOutDateInputTarget: boolean
  declare readonly checkOutDateInputTarget?: HTMLInputElement
  declare readonly hasSelectedHotelNameTarget: boolean
  declare readonly selectedHotelNameTarget?: HTMLElement
  declare readonly hasSelectedPackageNameTarget: boolean
  declare readonly selectedPackageNameTarget?: HTMLElement
  declare readonly hasSelectedNightCountTarget: boolean
  declare readonly selectedNightCountTarget?: HTMLElement

  private selectedHotelId: string | null = null
  private selectedHotelName: string | null = null
  private selectedPackageOptionId: string | null = null

  connect(): void {
    console.log("HotelPackageOrder connected")
    
    // Only update button states if quantity input exists (stockup mode)
    if (this.hasQuantityInputTarget) {
      this.updateButtonStates()
    }
    
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
    
    if (!this.hasQuantityInputTarget) return
    
    const currentQuantity = parseInt(this.quantityInputTarget!.value) || 1
    const newQuantity = currentQuantity + 1
    
    if (newQuantity <= 99) {
      this.quantityInputTarget!.value = newQuantity.toString()
      this.updatePrice()
      this.updateButtonStates()
    }
  }

  decreaseQuantity(event: Event): void {
    event.preventDefault()
    
    if (!this.hasQuantityInputTarget) return
    
    const currentQuantity = parseInt(this.quantityInputTarget!.value) || 1
    const newQuantity = currentQuantity - 1
    
    if (newQuantity >= 1) {
      this.quantityInputTarget!.value = newQuantity.toString()
      this.updatePrice()
      this.updateButtonStates()
    }
  }

  updatePrice(): void {
    if (!this.hasQuantityInputTarget || !this.hasIncreaseBtnTarget || !this.hasBottomPriceTarget) return
    
    const quantity = parseInt(this.quantityInputTarget!.value) || 1
    const unitPrice = parseFloat(this.increaseBtnTarget!.dataset.price || "0")
    const totalPrice = quantity * unitPrice

    // Update bottom price (integer only)
    this.bottomPriceTarget!.textContent = Math.round(totalPrice).toString()
  }

  updateButtonStates(): void {
    if (!this.hasQuantityInputTarget || !this.hasDecreaseBtnTarget) return
    
    const quantity = parseInt(this.quantityInputTarget!.value) || 1
    
    // Update decrease button
    if (quantity <= 1) {
      this.decreaseBtnTarget!.classList.remove("border-blue-500", "bg-blue-50", "text-blue-600")
      this.decreaseBtnTarget!.classList.add("border-gray-200", "text-gray-300")
      this.decreaseBtnTarget!.disabled = true
    } else {
      this.decreaseBtnTarget!.classList.remove("border-gray-200", "text-gray-300")
      this.decreaseBtnTarget!.classList.add("border-blue-500", "bg-blue-50", "text-blue-600")
      this.decreaseBtnTarget!.disabled = false
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
    
    // Store the selected package option ID for later use
    this.selectedPackageOptionId = packageOptionId || null
    
    // Update visual selection state
    this.packageOptionTargets.forEach((option) => {
      const isSelected = option.dataset.packageOptionId === packageOptionId
      option.dataset.selected = isSelected.toString()
      
      // Remove existing checkmark if any
      const existingCheckmark = option.querySelector('.absolute.top-0.right-0')
      if (existingCheckmark) {
        existingCheckmark.remove()
      }
      
      if (isSelected) {
        option.classList.remove('bg-white', 'border-gray-200')
        option.classList.add('bg-[#FFF9E6]', 'border-[#FFD700]')
        
        // Add checkmark to selected option
        const checkmark = document.createElement('div')
        checkmark.className = 'absolute top-0 right-0 w-4 h-4 bg-[#FFD700] rounded-bl-lg flex items-center justify-center'
        const svgContent = '<svg class="w-2.5 h-2.5 text-white" fill="currentColor" viewBox="0 0 20 20">'
          + '<path fill-rule="evenodd" '
          + 'd="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" '
          + 'clip-rule="evenodd"></path>'
          + '</svg>'
        checkmark.innerHTML = svgContent
        option.appendChild(checkmark)
      } else {
        option.classList.remove('bg-[#FFF9E6]', 'border-[#FFD700]')
        option.classList.add('bg-white', 'border-gray-200')
      }
    })
    
    // Do not reload - just update selection state
    // The selected package option will be used when confirming date selection
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

  // Date selection modal methods
  openDateSelectionModal(event: Event): void {
    event.preventDefault()
    const button = event.currentTarget as HTMLElement
    this.selectedHotelId = button.dataset.hotelId || null
    this.selectedHotelName = button.dataset.hotelName || null
    
    if (this.hasDateSelectionModalTarget) {
      // Update hotel name display
      if (this.hasSelectedHotelNameTarget && this.selectedHotelName) {
        this.selectedHotelNameTarget!.textContent = this.selectedHotelName
      }
      
      // Clear previous dates
      if (this.hasCheckInDateInputTarget) {
        this.checkInDateInputTarget!.value = ''
      }
      if (this.hasCheckOutDateInputTarget) {
        this.checkOutDateInputTarget!.value = ''
      }
      
      this.dateSelectionModalTarget!.classList.remove('hidden')
    }
  }

  // Open date selection for instant booking (from tab click)
  openInstantBookingDateSelection(event: Event): void {
    event.preventDefault()
    
    // Set selectedHotelId to null to indicate this is for instant booking
    this.selectedHotelId = null
    this.selectedHotelName = null
    
    if (this.hasDateSelectionModalTarget) {
      // Clear hotel name display for instant booking
      if (this.hasSelectedHotelNameTarget) {
        this.selectedHotelNameTarget!.textContent = ''
      }
      
      // Clear previous dates
      if (this.hasCheckInDateInputTarget) {
        this.checkInDateInputTarget!.value = ''
      }
      if (this.hasCheckOutDateInputTarget) {
        this.checkOutDateInputTarget!.value = ''
      }
      
      this.dateSelectionModalTarget!.classList.remove('hidden')
    }
  }

  closeDateSelectionModal(event: Event): void {
    event.preventDefault()
    if (this.hasDateSelectionModalTarget) {
      this.dateSelectionModalTarget!.classList.add('hidden')
    }
  }

  updateCheckOutDate(event: Event): void {
    if (!this.hasCheckInDateInputTarget || !this.hasCheckOutDateInputTarget) {
      return
    }
    
    const checkInDate = this.checkInDateInputTarget!.value
    if (!checkInDate) {
      this.checkOutDateInputTarget!.value = ''
      return
    }
    
    // Get night count from the displayed package
    const nightCountText = this.hasSelectedNightCountTarget
      ? this.selectedNightCountTarget!.textContent
      : '1'
    const nightCount = parseInt(nightCountText || '1', 10)
    
    // Calculate check-out date
    const checkIn = new Date(checkInDate)
    const checkOut = new Date(checkIn)
    checkOut.setDate(checkOut.getDate() + nightCount)
    
    // Format to YYYY-MM-DD
    const year = checkOut.getFullYear()
    const month = String(checkOut.getMonth() + 1).padStart(2, '0')
    const day = String(checkOut.getDate()).padStart(2, '0')
    this.checkOutDateInputTarget!.value = `${year}-${month}-${day}`
  }

  confirmDateSelection(event: Event): void {
    event.preventDefault()
    
    if (!this.hasCheckInDateInputTarget || !this.checkInDateInputTarget!.value) {
      window.showToast('请选择入住日期')
      return
    }
    
    const checkInDate = this.checkInDateInputTarget!.value
    const checkOutDate = this.hasCheckOutDateInputTarget
      ? this.checkOutDateInputTarget!.value
      : ''
    
    if (!checkOutDate) {
      window.showToast('离店日期计算失败，请重试')
      return
    }
    
    // Get package_option_id: use selected one from modal, or fall back to URL
    let packageOptionId = this.selectedPackageOptionId
    if (!packageOptionId) {
      const urlParams = new URLSearchParams(window.location.search)
      packageOptionId = urlParams.get('package_option_id')
    }
    
    if (!packageOptionId) {
      window.showToast('套餐信息丢失，请重试')
      return
    }
    
    // Determine booking type based on whether hotel was selected
    const bookingType = this.selectedHotelId ? 'instant' : 'instant'
    
    // Redirect to order page with dates and booking type
    let redirectUrl = `/hotel_package_orders/new?package_option_id=${packageOptionId}`
      + `&booking_type=${bookingType}`
      + `&check_in_date=${checkInDate}`
      + `&check_out_date=${checkOutDate}`
    
    // Add hotel_id if available (from hotel list selection)
    if (this.selectedHotelId) {
      redirectUrl += `&hotel_id=${this.selectedHotelId}`
    }
    
    window.location.href = redirectUrl
  }
}
