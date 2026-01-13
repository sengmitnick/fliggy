import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = ["regionButton", "regionContent", "ticketTypeButton", "ticketTypeContent"]

  declare readonly regionButtonTargets: HTMLElement[]
  declare readonly regionContentTargets: HTMLElement[]
  declare readonly ticketTypeButtonTargets: HTMLElement[]
  declare readonly ticketTypeContentTargets: HTMLElement[]
  declare readonly hasRegionButtonTarget: boolean
  declare readonly hasTicketTypeButtonTarget: boolean

  connect(): void {
    console.log("AbroadRegionSelector connected")
  }

  selectRegion(event: Event): void {
    const clickedButton = event.currentTarget as HTMLElement
    const region = clickedButton.dataset.region

    // Update button states
    if (this.hasRegionButtonTarget) {
      this.regionButtonTargets.forEach((button) => {
        button.classList.remove("text-yellow-600", "font-bold", "border-b-2", "border-yellow-600")
        button.classList.add("text-gray-500")
      })
    }

    clickedButton.classList.remove("text-gray-500")
    clickedButton.classList.add("text-yellow-600", "font-bold", "border-b-2", "border-yellow-600")

    // Update content visibility
    this.regionContentTargets.forEach((content) => {
      if (content.dataset.region === region) {
        content.classList.remove("hidden")
      } else {
        content.classList.add("hidden")
      }
    })
  }

  selectTicketType(event: Event): void {
    const clickedButton = event.currentTarget as HTMLElement
    const ticketType = clickedButton.dataset.ticketType

    // Update button states
    if (this.hasTicketTypeButtonTarget) {
      this.ticketTypeButtonTargets.forEach((button) => {
        button.classList.remove("bg-yellow-500", "text-white")
        button.classList.add("bg-gray-100", "text-gray-700")
      })
    }

    clickedButton.classList.remove("bg-gray-100", "text-gray-700")
    clickedButton.classList.add("bg-yellow-500", "text-white")

    // Update content visibility
    this.ticketTypeContentTargets.forEach((content) => {
      if (content.dataset.ticketType === ticketType) {
        content.classList.remove("hidden")
      } else {
        content.classList.add("hidden")
      }
    })
  }

  swapStations(): void {
    const originSelect = document.querySelector('[name="origin"]') as HTMLSelectElement
    const destinationSelect = document.querySelector('[name="destination"]') as HTMLSelectElement

    if (originSelect && destinationSelect) {
      const temp = originSelect.value
      originSelect.value = destinationSelect.value
      destinationSelect.value = temp
    }
  }
}
