import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = [
    "packageSelector",
    "priceDisplay"
  ]

  static values = {
    selectedPackageId: Number
  }

  // Declare your targets and values
  declare readonly packageSelectorTarget?: HTMLElement
  declare readonly priceDisplayTarget?: HTMLElement
  declare selectedPackageIdValue: number

  connect(): void {
    console.log("TourDetail controller connected")
  }

  disconnect(): void {
    console.log("TourDetail controller disconnected")
  }

  // Navigate to packages tab
  selectPackage(): void {
    const currentUrl = new URL(window.location.href)
    currentUrl.searchParams.set('tab', 'packages')
    window.location.href = currentUrl.toString()
  }

  // Select a specific package
  selectThisPackage(event: Event): void {
    const target = event.currentTarget as HTMLElement
    const packageId = target.dataset.packageId
    
    if (packageId) {
      this.selectedPackageIdValue = parseInt(packageId)
      
      // Navigate back to overview tab with selected package
      const currentUrl = new URL(window.location.href)
      currentUrl.searchParams.set('tab', 'overview')
      currentUrl.searchParams.set('package_id', packageId)
      window.location.href = currentUrl.toString()
    }
  }

  // Scroll to specific section (for smooth navigation)
  scrollToSection(event: Event): void {
    const target = event.currentTarget as HTMLElement
    const sectionId = target.dataset.section
    
    if (sectionId) {
      const section = document.getElementById(sectionId)
      if (section) {
        section.scrollIntoView({ behavior: 'smooth', block: 'start' })
      }
    }
  }
}
