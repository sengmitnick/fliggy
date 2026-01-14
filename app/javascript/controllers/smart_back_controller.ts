import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static values = {
    fallback: { type: String, default: "/" }
  }

  declare readonly fallbackValue: string

  connect(): void {
    // No console.log needed
  }

  /**
   * Smart back navigation based on referrer
   * - If user came from same site: go back
   * - If user came from external site or direct access: go to fallback
   */
  goBack(event: Event): void {
    event.preventDefault()
    
    const referrer = document.referrer
    const currentHost = window.location.host
    
    // Check if referrer is from same site
    if (referrer && referrer.includes(currentHost)) {
      // Check if there's actual history
      if (window.history.length > 1) {
        window.history.back()
        return
      }
    }
    
    // Fallback: go to specified path or root
    window.location.href = this.fallbackValue
  }
}
