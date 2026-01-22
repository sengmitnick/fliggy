import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = ["radio", "totalPrice"]
  static values = {
    basePrice: Number,
    adultCount: Number,
    childCount: Number
  }

  declare readonly radioTargets: HTMLInputElement[]
  declare readonly totalPriceTarget: HTMLElement
  declare readonly basePriceValue: number
  declare readonly adultCountValue: number
  declare readonly childCountValue: number

  private currentBasePrice: number = 0
  private currentQuantity: number = 0

  connect(): void {
    console.log("InsuranceSelector connected")
    // 初始化当前值
    this.currentBasePrice = this.basePriceValue
    this.currentQuantity = this.adultCountValue + this.childCountValue
    // 监听数量变化事件
    window.addEventListener("booking-quantity:changed", this.handleQuantityChange.bind(this))
  }

  disconnect(): void {
    console.log("InsuranceSelector disconnected")
    window.removeEventListener("booking-quantity:changed", this.handleQuantityChange.bind(this))
  }

  handleQuantityChange(event: Event): void {
    const customEvent = event as CustomEvent
    const { basePrice, quantity } = customEvent.detail
    
    // 更新当前值
    this.currentBasePrice = basePrice
    this.currentQuantity = quantity
    
    // 重新计算总价
    this.updatePrice()
  }

  updatePrice(): void {
    const selectedRadio = this.radioTargets.find((radio) => radio.checked)
    if (!selectedRadio) return

    const insuranceType = selectedRadio.value
    // 使用当前的数量值，如果没有更新过则使用初始值
    const totalPeople = this.currentQuantity > 0 ? this.currentQuantity : (this.adultCountValue + this.childCountValue)
    let insurancePrice = 0

    if (insuranceType === "standard") {
      insurancePrice = 15 * totalPeople
    } else if (insuranceType === "premium") {
      insurancePrice = 35 * totalPeople
    }

    // 使用当前的基础价格，如果没有更新过则使用初始值
    const basePrice = this.currentBasePrice > 0 ? this.currentBasePrice : this.basePriceValue
    const totalPrice = basePrice + insurancePrice
    this.totalPriceTarget.textContent = `¥${Math.round(totalPrice)}`
  }
}
