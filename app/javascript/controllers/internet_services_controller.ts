import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  connect(): void {
    console.log("InternetServices connected")
  }

  switchTab(event: Event): void {
    // Turbo Drive will handle navigation automatically
    // This is just for additional UI feedback if needed
  }
}
