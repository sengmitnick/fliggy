import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dateTab", "dateContainer"]

  declare readonly dateTabTargets: HTMLElement[]
  declare readonly dateContainerTarget: HTMLElement

  selectDate(event: Event) {
    // Handled by Rails navigation, but we can add visual feedback if needed
  }
}
