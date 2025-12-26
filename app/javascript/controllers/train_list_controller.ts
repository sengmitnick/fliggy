import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = [
    "trainItem"
  ]

  declare readonly trainItemTargets: HTMLElement[]

  connect(): void {
    console.log("TrainList connected")
  }

  disconnect(): void {
    console.log("TrainList disconnected")
  }

  toggleFilter(event: Event): void {
    const button = event.currentTarget as HTMLButtonElement
    button.classList.toggle('bg-primary')
    button.classList.toggle('text-primary-foreground')
    button.classList.toggle('bg-surface-elevated')
    button.classList.toggle('text-foreground')
  }

  toggleStation(event: Event): void {
    const button = event.currentTarget as HTMLButtonElement
    button.classList.toggle('bg-primary')
    button.classList.toggle('text-primary-foreground')
    button.classList.toggle('bg-surface-elevated')
    button.classList.toggle('text-foreground')
  }

  showAdvancedFilters(): void {
    // Show advanced filters modal (future implementation)
    console.log('Show advanced filters')
  }
}
