import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = ["modal", "timeDisplay"]
  static values = {
    currentTimeSlotStart: String,
    currentTimeSlotEnd: String,
    origin: String,
    destination: String,
    region: String,
    date: String
  }

  declare readonly modalTarget: HTMLElement
  declare readonly hasTimeDisplayTarget: boolean
  declare readonly timeDisplayTarget: HTMLElement
  declare readonly currentTimeSlotStartValue: string
  declare readonly currentTimeSlotEndValue: string
  declare readonly originValue: string
  declare readonly destinationValue: string
  declare readonly regionValue: string
  declare readonly dateValue: string

  connect(): void {
    console.log("AbroadTimeSlotPicker connected")
  }

  openModal(): void {
    this.modalTarget.classList.remove("hidden")
    document.body.style.overflow = 'hidden'
  }

  closeModal(): void {
    this.modalTarget.classList.add("hidden")
    document.body.style.overflow = ''
  }

  selectTimeSlot(event: Event): void {
    const button = event.currentTarget as HTMLElement
    const timeSlotStart = button.dataset.timeSlotStart
    const timeSlotEnd = button.dataset.timeSlotEnd

    if (timeSlotStart && timeSlotEnd) {
      // Update the display
      if (this.hasTimeDisplayTarget) {
        this.timeDisplayTarget.textContent = `${timeSlotStart} - ${timeSlotEnd}`
      }

      // Fetch ticket with the selected time slot and redirect to its show page
      const params = new URLSearchParams({
        region: this.regionValue,
        origin: this.originValue,
        destination: this.destinationValue,
        date: this.dateValue,
        time_slot_start: timeSlotStart,
        time_slot_end: timeSlotEnd
      })
      const url = `/abroad_tickets/find_by_time_slot?${params.toString()}`
      this.closeModal()
      window.Turbo.visit(url)
    }
  }
}
