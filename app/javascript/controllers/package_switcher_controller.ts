import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = ["card", "details"]
  static values = {
    selectedId: Number
  }

  declare readonly cardTargets: HTMLElement[]
  declare readonly detailsTarget: HTMLElement
  declare selectedIdValue: number

  connect(): void {
    console.log("PackageSwitcher connected")
    
    // Listen for package selection changes from booking modal
    window.addEventListener("booking-modal:package-changed", (event: Event) => {
      const customEvent = event as CustomEvent
      const packageId = customEvent.detail.packageId
      if (packageId && packageId !== this.selectedIdValue) {
        this.syncPackageSelection(packageId)
      }
    })
    
    // Listen for sync requests from booking modal
    window.addEventListener("booking-modal:request-sync", () => {
      const syncEvent = new CustomEvent("package:selected", {
        detail: { packageId: this.selectedIdValue }
      })
      window.dispatchEvent(syncEvent)
    })
  }

  selectPackage(event: Event): void {
    const card = event.currentTarget as HTMLElement
    const packageId = parseInt(card.dataset.packageId || "0")
    
    if (packageId === this.selectedIdValue) {
      return // Already selected
    }

    // Update selected ID
    this.selectedIdValue = packageId
    this.updatePackageUI(packageId)
    
    // Notify booking modal
    const customEvent = new CustomEvent("package:selected", {
      detail: { packageId }
    })
    window.dispatchEvent(customEvent)
  }

  private syncPackageSelection(packageId: number): void {
    this.selectedIdValue = packageId
    this.updatePackageUI(packageId)
  }

  private updatePackageUI(packageId: number): void {
    // Update card styles
    this.cardTargets.forEach(cardEl => {
      const cardPackageId = parseInt(cardEl.dataset.packageId || "0")
      
      if (cardPackageId === packageId) {
        // Selected state
        cardEl.classList.remove('bg-white', 'border-gray-100', 'border')
        cardEl.classList.add('bg-[#FFF9E6]', 'border-2', 'border-[#FFD700]')
        
        // Show checkmark, hide select text
        const checkmark = cardEl.querySelector('svg[viewBox="0 0 20 20"]')
        if (checkmark) {
          checkmark.classList.remove('hidden')
        }
      } else {
        // Unselected state
        cardEl.classList.remove('bg-[#FFF9E6]', 'border-2', 'border-[#FFD700]')
        cardEl.classList.add('bg-white', 'border', 'border-gray-100')
        
        // Hide checkmark
        const checkmark = cardEl.querySelector('svg[viewBox="0 0 20 20"]')
        if (checkmark) {
          checkmark.classList.add('hidden')
        }
      }
    })

    // Update details section
    const detailsContainer = this.detailsTarget
    const allDetails = detailsContainer.querySelectorAll('[data-package-id]')
    
    allDetails.forEach(detail => {
      const detailElement = detail as HTMLElement
      const detailPackageId = parseInt(detailElement.dataset.packageId || "0")
      
      if (detailPackageId === packageId) {
        detailElement.classList.remove('hidden')
      } else {
        detailElement.classList.add('hidden')
      }
    })
  }
}
