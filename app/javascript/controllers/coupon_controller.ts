import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = ["modal"]

  declare readonly modalTarget: HTMLElement

  connect(): void {
    // 页面加载后自动显示优惠券弹窗
    this.modalTarget.classList.remove('hidden')
  }

  claimCoupons(): void {
    // 领取优惠券
    alert('优惠券已领取成功！')
    this.closeModal()
  }

  closeModal(): void {
    this.modalTarget.classList.add('hidden')
  }
}
