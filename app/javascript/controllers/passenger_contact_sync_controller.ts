import { Controller } from "@hotwired/stimulus"

/**
 * Passenger Contact Sync Controller
 * 
 * Automatically updates contact phone field when passenger checkbox is selected.
 * Listens to checkbox change events and extracts phone number from data attributes.
 */
export default class extends Controller<HTMLElement> {
  static targets = ["checkbox", "phoneInput"]

  declare readonly checkboxTargets: HTMLInputElement[]
  declare readonly phoneInputTarget: HTMLInputElement
  declare readonly hasPhoneInputTarget: boolean

  connect(): void {
    console.log("PassengerContactSync connected")
    console.log("Phone input target available:", this.hasPhoneInputTarget)
    console.log("Checkbox targets count:", this.checkboxTargets.length)
  }

  /**
   * Handle checkbox change event
   * Only updates contact phone if it's currently empty (first passenger selection)
   * Prevents overwriting user's manual input or previously selected contact phone
   */
  syncPhone(event: Event): void {
    const checkbox = event.currentTarget as HTMLInputElement
    
    console.log("[syncPhone] Event triggered")
    console.log("[syncPhone] Checkbox checked:", checkbox.checked)
    console.log("[syncPhone] Checkbox phone data:", checkbox.dataset.passengerPhone)
    
    // Only update phone if checkbox is being checked (not unchecked)
    if (!checkbox.checked) {
      console.log("[syncPhone] Checkbox not checked, skipping")
      return
    }

    console.log("[syncPhone] Has phone input target:", this.hasPhoneInputTarget)
    
    if (this.hasPhoneInputTarget) {
      console.log("[syncPhone] Current phone input value:", `'${this.phoneInputTarget.value}'`)
      console.log("[syncPhone] Is empty:", this.phoneInputTarget.value.trim() === "")
    }

    // Only update if phone input is empty (don't overwrite existing value)
    if (!this.hasPhoneInputTarget) {
      console.log("[syncPhone] No phone input target found, skipping")
      return
    }
    
    if (this.phoneInputTarget.value.trim() !== "") {
      console.log("[syncPhone] Phone input already has value, skipping")
      return
    }

    // Get phone number from data attribute
    const phone = checkbox.dataset.passengerPhone
    
    if (phone) {
      console.log(`[syncPhone] Setting contact phone to: ${phone}`)
      this.phoneInputTarget.value = phone
      console.log("[syncPhone] Phone input value after set:", this.phoneInputTarget.value)
    } else {
      console.log("[syncPhone] No phone data found on checkbox")
    }
  }

  /**
   * Get all checked passenger phones
   * Returns array of phone numbers from all checked passengers
   */
  getCheckedPhones(): string[] {
    return this.checkboxTargets
      .filter(checkbox => checkbox.checked)
      .map(checkbox => checkbox.dataset.passengerPhone || "")
      .filter(phone => phone.length > 0)
  }
}
