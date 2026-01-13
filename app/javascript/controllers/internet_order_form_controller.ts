import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = ["quantity", "totalPrice"]
  declare readonly quantityTarget: HTMLElement
  declare readonly totalPriceTarget: HTMLElement
  declare readonly hasTotalPriceTarget: boolean

  private basePrice: number = 0

  connect(): void {
    console.log("InternetOrderForm connected")
    const totalPriceField = this.element.querySelector('[data-internet-order-form-target="totalPriceField"]') as HTMLInputElement
    if (totalPriceField) {
      this.basePrice = parseFloat(totalPriceField.value) || 0
    }
  }

  selectAddress(event: Event): void {
    const radio = event.target as HTMLInputElement
    const selectedIndex = parseInt(radio.value)
    
    // 找到所有地址的label
    const labels = this.element.querySelectorAll('[data-internet-order-form-target="mailSection"] label')
    
    labels.forEach((label, index) => {
      // 更新样式
      if (index === selectedIndex) {
        label.classList.add('border-[#FFDD00]', 'bg-[#FFFEF8]')
        label.classList.remove('border-gray-200')
      } else {
        label.classList.remove('border-[#FFDD00]', 'bg-[#FFFEF8]')
        label.classList.add('border-gray-200')
      }
      
      // Enable/disable对应的hidden fields
      const hiddenFields = label.querySelectorAll('input[type="hidden"]')
      hiddenFields.forEach((field) => {
        (field as HTMLInputElement).disabled = (index !== selectedIndex)
      })
    })
  }

  selectPassenger(event: Event): void {
    const radio = event.target as HTMLInputElement
    const selectedIndex = parseInt(radio.value)
    
    // 找到所有乘客的label
    const labels = this.element.querySelectorAll('[data-internet-order-form-target="pickupSection"] label')
    
    labels.forEach((label, index) => {
      // 更新样式
      if (index === selectedIndex) {
        label.classList.add('border-[#FFDD00]', 'bg-[#FFFEF8]')
        label.classList.remove('border-gray-200')
      } else {
        label.classList.remove('border-[#FFDD00]', 'bg-[#FFFEF8]')
        label.classList.add('border-gray-200')
      }
      
      // Enable/disable对应的hidden fields
      const hiddenFields = label.querySelectorAll('input[type="hidden"]')
      hiddenFields.forEach((field) => {
        (field as HTMLInputElement).disabled = (index !== selectedIndex)
      })
    })
  }

  increase(): void {
    const currentQty = parseInt(this.quantityTarget.textContent || "1")
    const newQty = currentQty + 1
    this.quantityTarget.textContent = newQty.toString()
    this.updateQuantityField(newQty)
    this.updateTotalPrice(newQty)
  }

  decrease(): void {
    const currentQty = parseInt(this.quantityTarget.textContent || "1")
    if (currentQty > 1) {
      const newQty = currentQty - 1
      this.quantityTarget.textContent = newQty.toString()
      this.updateQuantityField(newQty)
      this.updateTotalPrice(newQty)
    }
  }

  updateRentalDays(event: Event): void {
    const input = event.target as HTMLInputElement
    const days = parseInt(input.value) || 1
    this.updateTotalPrice(days)
    
    // 更新rental_info的hidden fields
    const rentalDaysField = this.element.querySelector('[data-internet-order-form-target="rentalDaysField"]') as HTMLInputElement
    if (rentalDaysField) {
      rentalDaysField.value = days.toString()
      
      // 计算return_date
      const pickupDateField = rentalDaysField.closest('div')?.querySelector('input[name*="[pickup_date]"]') as HTMLInputElement
      const returnDateField = rentalDaysField.closest('div')?.querySelector('input[name*="[return_date]"]') as HTMLInputElement
      
      if (pickupDateField && returnDateField) {
        const pickupDate = new Date(pickupDateField.value)
        const returnDate = new Date(pickupDate)
        returnDate.setDate(returnDate.getDate() + days)
        returnDateField.value = returnDate.toISOString().split('T')[0]
      }
    }
  }

  selectDeliveryMethod(event: Event): void {
    const radio = event.target as HTMLInputElement
    const mailSection = this.element.querySelector('[data-internet-order-form-target="mailSection"]')
    const pickupSection = this.element.querySelector('[data-internet-order-form-target="pickupSection"]')
    const mailLabel = this.element.querySelector('[data-internet-order-form-target="mailLabel"]')
    const pickupLabel = this.element.querySelector('[data-internet-order-form-target="pickupLabel"]')

    if (radio.value === 'mail') {
      mailSection?.classList.remove('hidden')
      pickupSection?.classList.add('hidden')
      mailLabel?.classList.add('border-[#FFDD00]', 'bg-[#FFFEF8]')
      pickupLabel?.classList.remove('border-[#FFDD00]', 'bg-[#FFFEF8]')
    } else {
      mailSection?.classList.add('hidden')
      pickupSection?.classList.remove('hidden')
      pickupLabel?.classList.add('border-[#FFDD00]', 'bg-[#FFFEF8]')
      mailLabel?.classList.remove('border-[#FFDD00]', 'bg-[#FFFEF8]')
    }
  }

  private updateQuantityField(quantity: number): void {
    const quantityField = this.element.querySelector('[data-internet-order-form-target="quantityField"]') as HTMLInputElement
    if (quantityField) {
      quantityField.value = quantity.toString()
    }
  }

  private updateTotalPrice(multiplier: number): void {
    const total = this.basePrice * multiplier
    if (this.hasTotalPriceTarget) {
      this.totalPriceTarget.textContent = total.toFixed(0)
    }
    const totalPriceField = this.element.querySelector('[data-internet-order-form-target="totalPriceField"]') as HTMLInputElement
    if (totalPriceField) {
      totalPriceField.value = total.toString()
    }
  }
}
