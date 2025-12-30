import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = [
    "modal",
    "backdrop",
    "paymentOption",
    "paymentMethodInput"
  ]

  static values = {
    totalPrice: String
  }

  declare readonly modalTarget: HTMLElement
  declare readonly backdropTarget: HTMLElement
  declare readonly paymentOptionTargets: HTMLElement[]
  declare readonly paymentMethodInputTarget: HTMLInputElement
  declare readonly totalPriceValue: string

  connect(): void {
    console.log("PaymentModal connected")
  }

  // 打开弹窗
  open(event: Event): void {
    event.preventDefault()
    this.modalTarget.classList.remove("hidden")
    this.backdropTarget.classList.remove("hidden")
    document.body.style.overflow = "hidden"
  }

  // 关闭弹窗
  close(event?: Event): void {
    if (event) {
      event.preventDefault()
    }
    this.modalTarget.classList.add("hidden")
    this.backdropTarget.classList.add("hidden")
    document.body.style.overflow = ""
  }

  // 点击背景关闭
  closeOnBackdrop(event: Event): void {
    if (event.target === event.currentTarget) {
      this.close()
    }
  }

  // 选择支付方式
  selectPayment(event: Event): void {
    const target = event.currentTarget as HTMLElement
    const paymentMethod = target.dataset.paymentMethod

    // 移除所有选中状态
    this.paymentOptionTargets.forEach(option => {
      option.classList.remove("border-blue-500", "bg-blue-50")
      option.classList.add("border-gray-200")
      const checkmark = option.querySelector(".checkmark")
      if (checkmark) {
        checkmark.classList.add("hidden")
      }
    })

    // 添加选中状态
    target.classList.remove("border-gray-200")
    target.classList.add("border-blue-500", "bg-blue-50")
    const checkmark = target.querySelector(".checkmark")
    if (checkmark) {
      checkmark.classList.remove("hidden")
    }

    // 更新隐藏的表单字段
    if (paymentMethod) {
      this.paymentMethodInputTarget.value = paymentMethod
    }
  }

  // 确认付款 - 提交表单
  confirmPayment(event: Event): void {
    event.preventDefault()
    const form = this.element.closest("form") as HTMLFormElement
    if (form) {
      form.requestSubmit()
    }
  }
}
