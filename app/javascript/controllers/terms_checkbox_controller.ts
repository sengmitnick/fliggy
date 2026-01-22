import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = ["checkbox"]

  declare readonly checkboxTarget: HTMLInputElement

  connect(): void {
    console.log("TermsCheckbox connected")
    
    // 检查是否是首次加载订单页面
    const isFirstLoad = !sessionStorage.getItem('orderPageVisited')
    
    if (isFirstLoad) {
      // 首次加载：确保复选框未选中，并清除旧状态
      sessionStorage.removeItem('termsCheckboxState')
      this.checkboxTarget.checked = false
      // 标记页面已访问
      sessionStorage.setItem('orderPageVisited', 'true')
      console.log('首次加载订单页面，条款复选框重置为未选中')
    } else {
      // 非首次加载：恢复保存的状态
      const savedState = sessionStorage.getItem('termsCheckboxState')
      if (savedState === 'true') {
        this.checkboxTarget.checked = true
        console.log('恢复条款复选框状态：已选中')
      }
    }
  }

  // 当复选框状态改变时保存状态
  toggleState(): void {
    const isChecked = this.checkboxTarget.checked
    sessionStorage.setItem('termsCheckboxState', isChecked.toString())
    console.log('条款复选框状态已保存:', isChecked)
  }
}
