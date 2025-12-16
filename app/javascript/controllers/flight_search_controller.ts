import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static values = {
    departure: String,
    destination: String,
    date: String
  }

  declare readonly departureValue: string
  declare readonly destinationValue: string
  declare readonly dateValue: string

  connect(): void {
    console.log("FlightSearch connected", {
      departure: this.departureValue,
      destination: this.destinationValue,
      date: this.dateValue
    })
  }
}
