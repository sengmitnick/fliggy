import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = ["travelerSection"]

  declare readonly travelerSectionTarget: HTMLElement

  connect(): void {
    // 初始化时显示出行人信息区域
  }

  toggle(event: Event): void {
    const checkbox = event.target as HTMLInputElement
    
    if (checkbox.checked) {
      // 选中复选框时,隐藏出行人信息区域
      this.travelerSectionTarget.classList.add('hidden')
    } else {
      // 取消选中时,显示出行人信息区域
      this.travelerSectionTarget.classList.remove('hidden')
    }
  }
}
