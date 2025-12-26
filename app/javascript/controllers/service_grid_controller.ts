import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = ["page", "dot"]
  
  declare readonly pageTargets: HTMLElement[]
  declare readonly dotTargets: HTMLElement[]

  private currentPage: number = 0

  connect(): void {
    this.showPage(0)
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

