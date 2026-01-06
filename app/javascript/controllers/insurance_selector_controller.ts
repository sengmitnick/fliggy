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

  connect(): void {
    console.log("InsuranceSelector connected")
  }

  disconnect(): void {
    console.log("InsuranceSelector disconnected")
  }

  updatePrice(): void {
    const selectedRadio = this.radioTargets.find((radio) => radio.checked)
    if (!selectedRadio) return

    const insuranceType = selectedRadio.value
    const totalPeople = this.adultCountValue + this.childCountValue
    let insurancePrice = 0

    if (insuranceType === "standard") {
      insurancePrice = 15 * totalPeople
    } else if (insuranceType === "premium") {
      insurancePrice = 35 * totalPeople
    }

    const totalPrice = this.basePriceValue + insurancePrice
    this.totalPriceTarget.textContent = `¥${Math.round(totalPrice)}`
  }
}
