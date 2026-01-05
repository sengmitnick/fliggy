import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = ["slide", "indicator"]
  
  static values = {
    index: { type: Number, default: 0 },
    autoplay: { type: Boolean, default: false },
    interval: { type: Number, default: 5000 }
  }

  // Declare your targets and values
  declare readonly slideTargets: HTMLElement[]
  declare readonly indicatorTargets?: HTMLElement[]
  declare readonly hasIndicatorTarget: boolean
  declare indexValue: number
  declare readonly autoplayValue: boolean
  declare readonly intervalValue: number
  
  private autoplayTimer?: number

  connect(): void {
    console.log("Carousel controller connected")
    this.showSlide(this.indexValue)
    
    if (this.autoplayValue) {
      this.startAutoplay()
    }
  }

  disconnect(): void {
    console.log("Carousel controller disconnected")
    this.stopAutoplay()
  }

  // Navigate to previous slide
  previous(): void {
    this.stopAutoplay()
    const newIndex = this.indexValue > 0 ? this.indexValue - 1 : this.slideTargets.length - 1
    this.indexValue = newIndex
    this.showSlide(newIndex)
  }

  // Navigate to next slide
  next(): void {
    this.stopAutoplay()
    const newIndex = this.indexValue < this.slideTargets.length - 1 ? this.indexValue + 1 : 0
    this.indexValue = newIndex
    this.showSlide(newIndex)
  }

  // Go to specific slide
  goTo(event: Event): void {
    this.stopAutoplay()
    const target = event.currentTarget as HTMLElement
    const index = parseInt(target.dataset.index || "0")
    this.indexValue = index
    this.showSlide(index)
  }

  // Show specific slide
  private showSlide(index: number): void {
    // Hide all slides
    this.slideTargets.forEach((slide, i) => {
      if (i === index) {
        slide.classList.remove('hidden')
      } else {
        slide.classList.add('hidden')
      }
    })

    // Update indicators if they exist
    if (this.hasIndicatorTarget) {
      this.indicatorTargets?.forEach((indicator, i) => {
        if (i === index) {
          indicator.classList.add('active')
        } else {
          indicator.classList.remove('active')
        }
      })
    }
  }

  // Autoplay functionality
  private startAutoplay(): void {
    this.autoplayTimer = window.setInterval(() => {
      this.next()
    }, this.intervalValue)
  }

  private stopAutoplay(): void {
    if (this.autoplayTimer) {
      clearInterval(this.autoplayTimer)
      this.autoplayTimer = undefined
    }
  }

  // Handle touch/swipe gestures
  private touchStartX = 0
  private touchEndX = 0

  handleTouchStart(event: TouchEvent): void {
    this.touchStartX = event.changedTouches[0].screenX
  }

  handleTouchEnd(event: TouchEvent): void {
    this.touchEndX = event.changedTouches[0].screenX
    this.handleSwipe()
  }

  private handleSwipe(): void {
    const swipeThreshold = 50
    const diff = this.touchStartX - this.touchEndX

    if (Math.abs(diff) > swipeThreshold) {
      if (diff > 0) {
        // Swiped left - next slide
        this.next()
      } else {
        // Swiped right - previous slide
        this.previous()
      }
    }
  }
}
