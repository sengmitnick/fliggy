import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="deep-travel"
export default class extends Controller {
  static targets = ["video", "videoContainer", "tab", "content"]

  declare readonly videoTarget: HTMLVideoElement
  declare readonly videoContainerTarget: HTMLElement
  declare readonly tabTargets: HTMLElement[]
  declare readonly contentTargets: HTMLElement[]

  connect() {
    console.log("Deep travel controller connected")
  }

  playVideo(event: Event) {
    const video = event.currentTarget as HTMLVideoElement
    if (video.paused) {
      video.play()
    } else {
      video.pause()
    }
  }

  toggleFullscreen(event: Event) {
    const container = (event.currentTarget as HTMLElement).closest('[data-deep-travel-target="videoContainer"]') as HTMLElement
    if (!document.fullscreenElement) {
      container.requestFullscreen()
    } else {
      document.exitFullscreen()
    }
  }

  switchTab(event: Event) {
    const clickedTab = event.currentTarget as HTMLElement
    const tabName = clickedTab.dataset.tab

    // Update tab styles
    this.tabTargets.forEach(tab => {
      if (tab === clickedTab) {
        tab.classList.add('text-gray-900', 'border-b-2', 'border-yellow-400', 'bg-yellow-50')
        tab.classList.remove('text-gray-600')
      } else {
        tab.classList.remove('text-gray-900', 'border-b-2', 'border-yellow-400', 'bg-yellow-50')
        tab.classList.add('text-gray-600')
      }
    })

    // Show/hide content
    this.contentTargets.forEach(content => {
      if (content.dataset.content === tabName) {
        content.classList.remove('hidden')
      } else {
        content.classList.add('hidden')
      }
    })
  }
}
