import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = ["seatTab", "optionsContainer"]
  static values = {
    trainId: String,
    selectedSeatType: { type: String, default: "second_class" }
  }

  declare readonly seatTabTargets: HTMLElement[]
  declare readonly optionsContainerTarget: HTMLElement
  declare readonly trainIdValue: string
  declare selectedSeatTypeValue: string

  connect(): void {
    console.log("TrainSeatSelector connected")
    // 默认选中第一个座位类型
    if (this.seatTabTargets.length > 0) {
      this.selectSeat(this.seatTabTargets[0])
    }
  }

  // 选择座位类型
  selectSeat(event: Event | HTMLElement): void {
    const target = event instanceof Event ? event.currentTarget as HTMLElement : event
    const seatType = target.dataset.seatType
    const seatPrice = parseFloat(target.dataset.seatPrice || '0')
    
    if (!seatType) return

    // 更新选中状态
    this.seatTabTargets.forEach(tab => {
      tab.classList.remove('bg-white', 'shadow')
    })
    target.classList.add('bg-white', 'shadow')

    // 显示/隐藏小三角形
    this.seatTabTargets.forEach(tab => {
      const arrow = tab.querySelector('.seat-arrow')
      if (arrow) {
        if (tab === target) {
          arrow.classList.remove('hidden')
        } else {
          arrow.classList.add('hidden')
        }
      }
    })

    // 更新当前选中的座位类型
    this.selectedSeatTypeValue = seatType

    // 更新订票选项中的价格和链接
    this.updateBookingOptions(seatPrice)
  }

  // 更新所有订票选项的价格和链接
  updateBookingOptions(basePrice: number): void {
    // 更新链接的seat_type参数
    const links = this.optionsContainerTarget.querySelectorAll('a[href*="train_bookings/new"]')
    links.forEach((link: Element) => {
      if (link instanceof HTMLAnchorElement) {
        const url = new URL(link.href, window.location.origin)
        url.searchParams.set('seat_type', this.selectedSeatTypeValue)
        link.href = url.toString()
      }
    })

    // 更新价格显示
    const priceElements = this.optionsContainerTarget.querySelectorAll('.booking-option-price')
    priceElements.forEach((priceEl: Element) => {
      if (priceEl instanceof HTMLElement) {
        const extraFee = parseFloat(priceEl.dataset.extraFee || '0')
        const totalPrice = Math.floor(basePrice + extraFee)
        priceEl.textContent = totalPrice.toString()
      }
    })
  }
}
