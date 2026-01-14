import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]

  declare readonly inputTarget: HTMLInputElement

  search(event: Event): void {
    event.preventDefault()
    let query = this.inputTarget.value.trim()
    
    // 如果输入框为空，使用 placeholder 的值
    if (query === "") {
      query = this.inputTarget.placeholder
    }
    
    // TODO: Implement actual search functionality
    window.showToast(`搜索"${query}"功能即将上线，敬请期待`)
  }

  clear(): void {
    this.inputTarget.value = ""
    this.inputTarget.focus()
  }
}
