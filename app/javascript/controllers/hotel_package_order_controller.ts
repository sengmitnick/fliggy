import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = [
    "quantityInput",
    "totalPrice",
    "bottomPrice",
    "decreaseBtn",
    "increaseBtn",
    "stockupTab",
    "instantTab",
    "bookingTypeInput",
    "contactNameInput",
    "contactPhoneInput"
  ]

  declare readonly quantityInputTarget: HTMLInputElement
  declare readonly totalPriceTarget: HTMLElement
  declare readonly bottomPriceTarget: HTMLElement
  declare readonly decreaseBtnTarget: HTMLButtonElement
  declare readonly increaseBtnTarget: HTMLButtonElement
  declare readonly stockupTabTarget: HTMLElement
  declare readonly instantTabTarget: HTMLElement
  declare readonly bookingTypeInputTarget: HTMLInputElement
  declare readonly contactNameInputTarget: HTMLInputElement
  declare readonly contactPhoneInputTarget: HTMLInputElement

  connect(): void {
    console.log("HotelPackageOrder connected")
    this.updateButtonStates()
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

    // Update top price (with 2 decimals)
    this.totalPriceTarget.textContent = `¥${totalPrice.toFixed(2)}`
    
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

  selectPassenger(event: Event): void {
    const label = event.currentTarget as HTMLElement
    const name = label.dataset.passengerName || ""
    const phone = label.dataset.passengerPhone || ""
    
    // Update hidden fields
    this.contactNameInputTarget.value = name
    this.contactPhoneInputTarget.value = phone
  }

  handleSubmit(event: Event): void {
    // Validate contact info before submission
    if (!this.contactNameInputTarget.value || !this.contactPhoneInputTarget.value) {
      event.preventDefault()
      alert('请选择联系人')
      return
    }
    // Form will be submitted normally to create pending order
  }
}
