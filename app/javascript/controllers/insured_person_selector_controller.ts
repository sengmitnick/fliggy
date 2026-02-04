import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = [
    "modal",
    "passengerItem"
  ]

  static values = {
    personIndex: Number
  }

  // stimulus-validator: disable-next-line
  declare readonly modalTarget: HTMLElement
  // stimulus-validator: disable-next-line
  declare readonly passengerItemTargets: HTMLElement[]
  declare personIndexValue: number
  declare readonly hasPersonIndexValue: boolean

  private nameInputField: HTMLInputElement | null = null
  private idNumberInputField: HTMLInputElement | null = null
  private selectedPassengers: Map<number, string> = new Map()

  connect(): void {
    console.log("InsuredPersonSelector connected")
    this.updateDisabledStates()
  }

  openModal(event: Event): void {
    event.preventDefault()
    event.stopPropagation()

    const button = event.currentTarget as HTMLElement
    const personIndex = parseInt(button.dataset.personIndex || '0')
    this.personIndexValue = personIndex

    this.nameInputField = this.element.querySelector(
      `input[name="insurance_order[insured_persons][${personIndex}][name]"]`
    )
    this.idNumberInputField = this.element.querySelector(
      `input[name="insurance_order[insured_persons][${personIndex}][id_number]"]`
    )

    this.updateDisabledStates()
    this.modalTarget.classList.remove('hidden')
    document.body.style.overflow = 'hidden'
  }

  closeModal(event?: Event): void {
    if (event) {
      event.preventDefault()
      event.stopPropagation()
    }
    
    this.modalTarget.classList.add('hidden')
    document.body.style.overflow = ''
  }

  stopPropagation(event: Event): void {
    event.stopPropagation()
  }

  selectPassenger(event: Event): void {
    const button = event.currentTarget as HTMLElement
    const passengerId = button.dataset.passengerId || ''
    const passengerName = button.dataset.passengerName || ''
    const passengerIdNumber = button.dataset.passengerIdNumber || ''

    if (this.isPassengerDisabled(button)) {
      return
    }

    const previousPassengerId = this.selectedPassengers.get(this.personIndexValue)
    if (previousPassengerId) {
      this.selectedPassengers.delete(this.personIndexValue)
    }

    this.selectedPassengers.set(this.personIndexValue, passengerId)

    if (this.nameInputField) {
      this.nameInputField.value = passengerName
    }
    if (this.idNumberInputField) {
      this.idNumberInputField.value = passengerIdNumber
    }

    this.updateDisabledStates()
    this.closeModal()
  }

  closeOnBackdrop(event: Event): void {
    if (event.target === event.currentTarget) {
      this.closeModal()
    }
  }

  private updateDisabledStates(): void {
    this.passengerItemTargets.forEach((button) => {
      const passengerId = button.dataset.passengerId || ''
      const isSelected = Array.from(this.selectedPassengers.values()).includes(passengerId)
      const isCurrentSelection = this.selectedPassengers.get(this.personIndexValue) === passengerId
      
      const indicator = button.querySelector('.selected-indicator') as HTMLElement
      
      if (isSelected && !isCurrentSelection) {
        button.classList.add('opacity-50', 'cursor-not-allowed')
        button.classList.remove('hover:border-primary')
        if (indicator) {
          indicator.classList.remove('hidden')
        }
      } else {
        button.classList.remove('opacity-50', 'cursor-not-allowed')
        button.classList.add('hover:border-primary')
        if (indicator) {
          indicator.classList.add('hidden')
        }
      }
    })
  }

  private isPassengerDisabled(button: HTMLElement): boolean {
    const passengerId = button.dataset.passengerId || ''
    const isSelected = Array.from(this.selectedPassengers.values()).includes(passengerId)
    const isCurrentSelection = this.selectedPassengers.get(this.personIndexValue) === passengerId
    
    return isSelected && !isCurrentSelection
  }
}
