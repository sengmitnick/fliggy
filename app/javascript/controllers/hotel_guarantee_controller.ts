import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = ["modal", "content"]

  declare readonly modalTarget: HTMLElement
  declare readonly contentTarget: HTMLElement

  connect(): void {
    console.log("HotelGuarantee connected")
  }

  open(): void {
    this.modalTarget.classList.remove("hidden")
  }

  close(event?: Event): void {
    if (event) {
      event.stopPropagation()
    }
    this.modalTarget.classList.add("hidden")
  }

  closeOnBackdrop(event: MouseEvent): void {
    if (event.target === this.modalTarget) {
      this.close()
    }
  }

  stopPropagation(event: Event): void {
    event.stopPropagation()
  }
}
