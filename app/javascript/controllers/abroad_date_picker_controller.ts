import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = ["modal", "selectedDate"]
  static values = {
    currentDate: String
  }

  declare readonly modalTarget: HTMLElement
  declare readonly selectedDateTarget: HTMLElement
  declare readonly currentDateValue: string

  connect(): void {
    console.log("AbroadDatePicker connected")
  }

  openModal(): void {
    this.modalTarget.classList.remove("hidden")
    setTimeout(() => {
      const modalContent = this.modalTarget.querySelector("div")
      if (modalContent) {
        modalContent.style.transform = "translateY(0)"
      }
    }, 10)
  }

  closeModal(): void {
    const modalContent = this.modalTarget.querySelector("div")
    if (modalContent) {
      modalContent.style.transform = "translateY(100%)"
    }
    setTimeout(() => {
      this.modalTarget.classList.add("hidden")
    }, 300)
  }

  selectDate(event: Event): void {
    const target = event.currentTarget as HTMLElement
    const date = target.dataset.date

    if (date) {
      // Update URL and reload
      const url = new URL(window.location.href)
      url.searchParams.set("date", date)
      window.location.href = url.toString()
    }
  }
}
