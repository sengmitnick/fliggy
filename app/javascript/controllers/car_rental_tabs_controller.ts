import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["domesticButton", "internationalButton", "swapToggle", "swapIndicator"]

  declare readonly domesticButtonTarget: HTMLButtonElement
  declare readonly internationalButtonTarget: HTMLButtonElement
  declare readonly swapToggleTarget: HTMLElement
  declare readonly swapIndicatorTarget: HTMLElement

  private isDomestic: boolean = true
  private isSwapEnabled: boolean = false

  connect(): void {
    this.updateDomesticView()
  }

  selectDomestic(): void {
    this.isDomestic = true
    this.updateDomesticView()
  }

  selectInternational(): void {
    this.isDomestic = false
    this.updateInternationalView()
  }

  toggleSwap(): void {
    this.isSwapEnabled = !this.isSwapEnabled
    this.updateSwapToggle()
  }

  private updateDomesticView(): void {
    this.domesticButtonTarget.classList.add("bg-white", "shadow-sm", "font-bold")
    this.domesticButtonTarget.classList.remove("text-gray-500")
    
    this.internationalButtonTarget.classList.remove("bg-white", "shadow-sm", "font-bold")
    this.internationalButtonTarget.classList.add("text-gray-500")
  }

  private updateInternationalView(): void {
    this.internationalButtonTarget.classList.add("bg-white", "shadow-sm", "font-bold")
    this.internationalButtonTarget.classList.remove("text-gray-500")
    
    this.domesticButtonTarget.classList.remove("bg-white", "shadow-sm", "font-bold")
    this.domesticButtonTarget.classList.add("text-gray-500")
  }

  private updateSwapToggle(): void {
    if (this.isSwapEnabled) {
      this.swapIndicatorTarget.classList.remove("left-1")
      this.swapIndicatorTarget.classList.add("left-5")
      this.swapToggleTarget.classList.remove("bg-gray-200")
      this.swapToggleTarget.classList.add("bg-blue-500")
    } else {
      this.swapIndicatorTarget.classList.add("left-1")
      this.swapIndicatorTarget.classList.remove("left-5")
      this.swapToggleTarget.classList.add("bg-gray-200")
      this.swapToggleTarget.classList.remove("bg-blue-500")
    }
  }
}
