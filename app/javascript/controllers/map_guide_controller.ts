import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = [
    "modal",
    "pickupTab",
    "returnTab",
    "pickupMethod",
    "pickupAddress",
    "storeAddress",
    "businessHours"
  ]

  static values = {
    pickupLocation: String,
    returnLocation: String,
    pickupMethod: String,
    storeAddress: String,
    businessHours: String
  }

  declare readonly modalTarget: HTMLElement
  declare readonly pickupTabTarget: HTMLButtonElement
  declare readonly returnTabTarget: HTMLButtonElement
  declare readonly pickupMethodTarget: HTMLElement
  declare readonly pickupAddressTarget: HTMLElement
  declare readonly storeAddressTarget: HTMLElement
  declare readonly businessHoursTarget: HTMLElement

  declare readonly pickupLocationValue: string
  declare readonly returnLocationValue: string
  declare readonly pickupMethodValue: string
  declare readonly storeAddressValue: string
  declare readonly businessHoursValue: string

  connect(): void {
    console.log("MapGuide connected")
  }

  disconnect(): void {
    console.log("MapGuide disconnected")
  }

  openModal(): void {
    this.modalTarget.classList.remove('hidden')
    document.body.style.overflow = 'hidden'
  }

  closeModal(): void {
    this.modalTarget.classList.add('hidden')
    document.body.style.overflow = ''
  }

  switchTab(event: Event): void {
    const button = event.currentTarget as HTMLButtonElement
    const tab = button.dataset.tab

    if (tab === 'pickup') {
      // 切换到取车门店
      this.pickupTabTarget.classList.add('border-b-2', 'border-black', 'font-bold')
      this.pickupTabTarget.classList.remove('text-gray-400')
      this.returnTabTarget.classList.remove('border-b-2', 'border-black', 'font-bold')
      this.returnTabTarget.classList.add('text-gray-400')

      // 更新显示内容为取车信息
      if (this.pickupLocationValue) {
        this.pickupAddressTarget.textContent = this.pickupLocationValue
      }
    } else if (tab === 'return') {
      // 切换到还车门店
      this.returnTabTarget.classList.add('border-b-2', 'border-black', 'font-bold')
      this.returnTabTarget.classList.remove('text-gray-400')
      this.pickupTabTarget.classList.remove('border-b-2', 'border-black', 'font-bold')
      this.pickupTabTarget.classList.add('text-gray-400')

      // 更新显示内容为还车信息
      if (this.returnLocationValue) {
        this.pickupAddressTarget.textContent = this.returnLocationValue
      } else {
        // 如果没有还车地址，显示与取车相同
        this.pickupAddressTarget.textContent = this.pickupLocationValue || '同取车地址'
      }
    }
  }
}
