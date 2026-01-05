import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = ["tab", "section"]
  static values = {
    offset: { type: Number, default: 120 } // Top offset for nav bars (top nav 56px + tab nav 56px + extra 8px)
  }

  declare readonly tabTargets: HTMLElement[]
  declare readonly sectionTargets: HTMLElement[]
  declare readonly offsetValue: number

  private observer: IntersectionObserver | null = null
  private isScrolling = false

  connect(): void {
    console.log("ScrollSpy controller connected")
    this.setupIntersectionObserver()
    
    // Initial active tab on page load
    this.updateActiveTab()
  }

  disconnect(): void {
    if (this.observer) {
      this.observer.disconnect()
    }
  }

  setupIntersectionObserver(): void {
    const options = {
      root: null,
      rootMargin: `-${this.offsetValue}px 0px -50% 0px`, // Active when section is near top
      threshold: 0
    }

    this.observer = new IntersectionObserver((entries) => {
      // Only update if we're not currently auto-scrolling
      if (this.isScrolling) return

      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          const sectionId = entry.target.id
          this.setActiveTab(sectionId)
        }
      })
    }, options)

    // Observe all sections
    this.sectionTargets.forEach((section) => {
      this.observer?.observe(section)
    })
  }

  scrollToSection(event: Event): void {
    event.preventDefault()
    event.stopPropagation()
    
    const target = event.currentTarget as HTMLElement
    const sectionId = target.dataset.section
    
    if (!sectionId) return

    const section = document.getElementById(sectionId)
    if (!section) return

    // Set flag to prevent observer from triggering during auto-scroll
    this.isScrolling = true

    // Calculate scroll position accounting for sticky headers
    const sectionTop = section.getBoundingClientRect().top + window.scrollY
    const scrollTo = sectionTop - this.offsetValue

    // Smooth scroll to section
    window.scrollTo({
      top: scrollTo,
      behavior: "smooth"
    })

    // Immediately update active tab
    this.setActiveTab(sectionId)

    // Reset flag after scroll completes
    setTimeout(() => {
      this.isScrolling = false
    }, 1000) // Increased timeout to ensure smooth scroll completes
  }

  setActiveTab(sectionId: string): void {
    // Remove active class from all tabs
    this.tabTargets.forEach((tab) => {
      tab.classList.remove("border-primary", "text-primary")
      tab.classList.add("border-transparent", "text-foreground-muted")
    })

    // Add active class to matching tab
    const activeTab = this.tabTargets.find((tab) => tab.dataset.section === sectionId)
    if (activeTab) {
      activeTab.classList.remove("border-transparent", "text-foreground-muted")
      activeTab.classList.add("border-primary", "text-primary")
      
      // Scroll tab into view if needed (horizontal scroll)
      activeTab.scrollIntoView({
        behavior: "smooth",
        block: "nearest",
        inline: "center"
      })
    }
  }

  updateActiveTab(): void {
    // Find the first visible section
    const scrollPosition = window.pageYOffset + this.offsetValue + 10

    for (let i = this.sectionTargets.length - 1; i >= 0; i--) {
      const section = this.sectionTargets[i]
      const sectionTop = section.offsetTop

      if (scrollPosition >= sectionTop) {
        this.setActiveTab(section.id)
        break
      }
    }
  }
}
