import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = ["modal", "content"]

  declare readonly modalTarget: HTMLElement
  declare readonly contentTarget: HTMLElement

  connect(): void {
    console.log("QrcodeModal controller connected")
  }

  // 显示二维码弹窗
  show(event: Event): void {
    event.preventDefault()
    this.modalTarget.classList.remove("hidden")
    // 添加淡入动画
    setTimeout(() => {
      this.contentTarget.classList.add("scale-100", "opacity-100")
    }, 10)
  }

  // 隐藏二维码弹窗
  hide(event: Event): void {
    event.preventDefault()
    // 添加淡出动画
    this.contentTarget.classList.remove("scale-100", "opacity-100")
    setTimeout(() => {
      this.modalTarget.classList.add("hidden")
    }, 200)
  }

  // 点击背景关闭弹窗
  backdropClick(event: Event): void {
    if (event.target === this.modalTarget) {
      this.hide(event)
    }
  }
}
