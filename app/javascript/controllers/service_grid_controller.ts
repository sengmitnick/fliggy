import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = ["page", "dot"]
  
  declare readonly pageTargets: HTMLElement[]
  declare readonly dotTargets: HTMLElement[]

  private currentPage: number = 0
  private touchStartX: number = 0
  private touchEndX: number = 0
  private minSwipeDistance: number = 50 // 最小滑动距离（像素）

  connect(): void {
    this.showPage(0)
    // 添加触摸事件监听
    this.element.addEventListener('touchstart', this.handleTouchStart.bind(this), { passive: true })
    this.element.addEventListener('touchend', this.handleTouchEnd.bind(this), { passive: true })
  }

  disconnect(): void {
    // 清理事件监听
    this.element.removeEventListener('touchstart', this.handleTouchStart.bind(this))
    this.element.removeEventListener('touchend', this.handleTouchEnd.bind(this))
  }

  // 处理触摸开始
  private handleTouchStart(event: TouchEvent): void {
    this.touchStartX = event.changedTouches[0].screenX
  }

  // 处理触摸结束
  private handleTouchEnd(event: TouchEvent): void {
    this.touchEndX = event.changedTouches[0].screenX
    this.handleSwipe()
  }

  // 处理滑动逻辑
  private handleSwipe(): void {
    const swipeDistance = this.touchEndX - this.touchStartX
    
    // 向左滑动（下一页）
    if (swipeDistance < -this.minSwipeDistance) {
      this.nextPage()
    }
    // 向右滑动（上一页）
    else if (swipeDistance > this.minSwipeDistance) {
      this.prevPage()
    }
  }

  goToPage(event: Event): void {
    const target = event.currentTarget as HTMLElement
    const pageIndex = parseInt(target.getAttribute('data-page') || '0', 10)
    if (pageIndex >= 0 && pageIndex < this.pageTargets.length) {
      this.showPage(pageIndex)
    }
  }

  nextPage(): void {
    const nextIndex = (this.currentPage + 1) % this.pageTargets.length
    this.showPage(nextIndex)
  }

  prevPage(): void {
    const prevIndex = (this.currentPage - 1 + this.pageTargets.length) % this.pageTargets.length
    this.showPage(prevIndex)
  }

  private showPage(pageIndex: number): void {
    // Hide all pages
    this.pageTargets.forEach((page, index) => {
      if (index === pageIndex) {
        page.classList.remove("hidden")
      } else {
        page.classList.add("hidden")
      }
    })

    // Update dots
    this.dotTargets.forEach((dot, index) => {
      const button = dot as HTMLButtonElement
      if (index === pageIndex) {
        button.classList.remove("bg-gray-300", "w-1.5", "h-1.5")
        button.classList.add("w-6", "h-1")
        button.style.background = "#FFD700"
      } else {
        button.classList.remove("w-6", "h-1")
        button.classList.add("bg-gray-300", "w-1.5", "h-1.5")
        button.style.background = ""
      }
    })

    this.currentPage = pageIndex
  }
}

