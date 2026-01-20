import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = ["modal", "overlay", "contactModal", "contactOverlay"]

  declare readonly modalTarget: HTMLElement
  declare readonly overlayTarget: HTMLElement
  declare readonly contactModalTarget: HTMLElement
  declare readonly contactOverlayTarget: HTMLElement

  connect(): void {
    console.log("CommunicationTimeline connected")
  }

  disconnect(): void {
    console.log("CommunicationTimeline disconnected")
  }

  open(): void {
    this.modalTarget.classList.remove('hidden')
    this.overlayTarget.classList.remove('hidden')
    document.body.style.overflow = 'hidden'
  }

  close(): void {
    this.modalTarget.classList.add('hidden')
    this.overlayTarget.classList.add('hidden')
    document.body.style.overflow = ''
  }

  openContactModal(): void {
    this.contactModalTarget.classList.remove('hidden')
    this.contactOverlayTarget.classList.remove('hidden')
    document.body.style.overflow = 'hidden'
  }

  closeContactModal(): void {
    this.contactModalTarget.classList.add('hidden')
    this.contactOverlayTarget.classList.add('hidden')
    document.body.style.overflow = ''
  }

  stopPropagation(event: Event): void {
    event.stopPropagation()
  }
}
