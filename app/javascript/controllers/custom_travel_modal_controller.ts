import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = [
    "modal",
    "overlay",
    "departureCity",
    "destinationCity",
    "adultsCount",
    "childrenCount",
    "eldersCount",
    "daysCount",
    "departureCityInput",
    "destinationCityInput",
    "adultsInput",
    "childrenInput",
    "eldersInput",
    "daysInput"
  ]

  declare readonly modalTarget: HTMLElement
  declare readonly overlayTarget: HTMLElement
  declare readonly departureCityTarget: HTMLElement
  declare readonly destinationCityTarget: HTMLElement
  declare readonly adultsCountTarget: HTMLElement
  declare readonly childrenCountTarget: HTMLElement
  declare readonly eldersCountTarget: HTMLElement
  declare readonly daysCountTarget: HTMLElement
  declare readonly departureCityInputTarget: HTMLInputElement
  declare readonly destinationCityInputTarget: HTMLInputElement
  declare readonly adultsInputTarget: HTMLInputElement
  declare readonly childrenInputTarget: HTMLInputElement
  declare readonly eldersInputTarget: HTMLInputElement
  declare readonly daysInputTarget: HTMLInputElement

  connect(): void {
    console.log("CustomTravelModal connected")
  }

  // 打开弹窗
  open(): void {
    this.modalTarget.classList.remove('hidden')
    this.overlayTarget.classList.remove('hidden')
    document.body.style.overflow = 'hidden'
  }

  // 关闭弹窗
  close(): void {
    this.modalTarget.classList.add('hidden')
    this.overlayTarget.classList.add('hidden')
    document.body.style.overflow = ''
  }

  // 点击遮罩层关闭
  closeOnOverlay(event: Event): void {
    if (event.target === this.overlayTarget) {
      this.close()
    }
  }

  // 增加成人数量
  increaseAdults(): void {
    const current = parseInt(this.adultsInputTarget.value) || 0
    this.adultsInputTarget.value = (current + 1).toString()
    this.adultsCountTarget.textContent = (current + 1).toString()
  }

  // 减少成人数量
  decreaseAdults(): void {
    const current = parseInt(this.adultsInputTarget.value) || 0
    if (current > 0) {
      this.adultsInputTarget.value = (current - 1).toString()
      this.adultsCountTarget.textContent = (current - 1).toString()
    }
  }

  // 增加儿童数量
  increaseChildren(): void {
    const current = parseInt(this.childrenInputTarget.value) || 0
    this.childrenInputTarget.value = (current + 1).toString()
    this.childrenCountTarget.textContent = (current + 1).toString()
  }

  // 减少儿童数量
  decreaseChildren(): void {
    const current = parseInt(this.childrenInputTarget.value) || 0
    if (current > 0) {
      this.childrenInputTarget.value = (current - 1).toString()
      this.childrenCountTarget.textContent = (current - 1).toString()
    }
  }

  // 增加老人数量
  increaseElders(): void {
    const current = parseInt(this.eldersInputTarget.value) || 0
    this.eldersInputTarget.value = (current + 1).toString()
    this.eldersCountTarget.textContent = (current + 1).toString()
  }

  // 减少老人数量
  decreaseElders(): void {
    const current = parseInt(this.eldersInputTarget.value) || 0
    if (current > 0) {
      this.eldersInputTarget.value = (current - 1).toString()
      this.eldersCountTarget.textContent = (current - 1).toString()
    }
  }

  // 增加天数
  increaseDays(): void {
    const current = parseInt(this.daysInputTarget.value) || 0
    this.daysInputTarget.value = (current + 1).toString()
    this.daysCountTarget.textContent = (current + 1).toString()
  }

  // 减少天数
  decreaseDays(): void {
    const current = parseInt(this.daysInputTarget.value) || 0
    if (current > 1) {
      this.daysInputTarget.value = (current - 1).toString()
      this.daysCountTarget.textContent = (current - 1).toString()
    }
  }

  // 选择出发城市
  selectDepartureCity(event: Event): void {
    const target = event.currentTarget as HTMLElement
    const city = target.dataset.city || ''
    this.departureCityTarget.textContent = city
    this.departureCityInputTarget.value = city
  }

  // 选择目的地城市
  selectDestinationCity(event: Event): void {
    const target = event.currentTarget as HTMLElement
    const city = target.dataset.city || ''
    this.destinationCityTarget.textContent = city
    this.destinationCityInputTarget.value = city
  }
}
