import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = ["container"]

  declare readonly containerTarget: HTMLElement

  connect(): void {
    console.log("BusTicketHistory connected")
  }

  // 清除历史记录
  clear(event: Event): void {
    event.preventDefault()
    
    // 隐藏整个历史记录容器
    this.containerTarget.classList.add('hidden')
    
    // 显示toast提示
    if (typeof (window as any).showToast === 'function') {
      (window as any).showToast('历史记录已清除', 'success')
    }
  }

  // 显示精彩即将上线提示
  showComingSoon(event: Event): void {
    event.preventDefault()
    event.stopPropagation()
    
    // Use window.showToast to display coming soon message
    if (typeof (window as any).showToast === 'function') {
      (window as any).showToast('精彩即将上线', 'info')
    } else {
      console.warn('showToast function not available')
      alert('精彩即将上线')
    }
  }
}
