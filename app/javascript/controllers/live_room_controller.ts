import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = ["wrapper", "slide"]

  declare readonly wrapperTarget: HTMLElement
  declare readonly slideTargets: HTMLElement[]

  private currentIndex: number = 0
  private startY: number = 0
  private startTime: number = 0
  private isDragging: boolean = false

  connect(): void {
    console.log("LiveRoom connected")
    
    // Add touch event listeners
    this.element.addEventListener('touchstart', this.handleTouchStart.bind(this), { passive: true })
    this.element.addEventListener('touchmove', this.handleTouchMove.bind(this), { passive: false })
    this.element.addEventListener('touchend', this.handleTouchEnd.bind(this), { passive: true })
    
    // Initialize first slide
    this.showSlide(0)
  }

  disconnect(): void {
    console.log("LiveRoom disconnected")
    
    // Remove event listeners
    this.element.removeEventListener('touchstart', this.handleTouchStart.bind(this))
    this.element.removeEventListener('touchmove', this.handleTouchMove.bind(this))
    this.element.removeEventListener('touchend', this.handleTouchEnd.bind(this))
  }

  private handleTouchStart(e: TouchEvent): void {
    this.startY = e.touches[0].clientY
    this.startTime = Date.now()
    this.isDragging = true
  }

  private handleTouchMove(e: TouchEvent): void {
    if (!this.isDragging) return
    
    const currentY = e.touches[0].clientY
    const diffY = currentY - this.startY
    
    // Prevent default scroll if swiping vertically
    if (Math.abs(diffY) > 10) {
      e.preventDefault()
    }
  }

  private handleTouchEnd(e: TouchEvent): void {
    if (!this.isDragging) return
    
    const endY = e.changedTouches[0].clientY
    const diffY = endY - this.startY
    const diffTime = Date.now() - this.startTime
    
    this.isDragging = false
    
    // Calculate swipe velocity
    const velocity = Math.abs(diffY) / diffTime
    
    // Determine if swipe is valid (threshold: 50px or fast swipe)
    const isSwipeUp = diffY < -50 || (diffY < -30 && velocity > 0.5)
    const isSwipeDown = diffY > 50 || (diffY > 30 && velocity > 0.5)
    
    if (isSwipeUp) {
      // Swipe up - go to next slide
      this.nextSlide()
    } else if (isSwipeDown) {
      // Swipe down - go to previous slide
      this.prevSlide()
    }
    
    this.startY = 0
    this.startTime = 0
  }

  private nextSlide(): void {
    if (this.currentIndex < this.slideTargets.length - 1) {
      this.showSlide(this.currentIndex + 1)
    }
  }

  private prevSlide(): void {
    if (this.currentIndex > 0) {
      this.showSlide(this.currentIndex - 1)
    }
  }

  private showSlide(index: number): void {
    // Remove active class from all slides
    this.slideTargets.forEach((slide, i) => {
      slide.classList.remove('active', 'prev')
      
      if (i === index) {
        slide.classList.add('active')
      } else if (i === index - 1) {
        slide.classList.add('prev')
      }
    })
    
    this.currentIndex = index
    
    // Hide swipe hint after first swipe
    if (index > 0) {
      const swipeHint = document.querySelector('.live-swipe-hint') as HTMLElement
      if (swipeHint) {
        swipeHint.style.display = 'none'
      }
    }
  }
}
