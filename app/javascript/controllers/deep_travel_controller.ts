import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="deep-travel"
// Note: This controller is attached to the guide categories container but has no active functionality yet.
// All methods below are unused - they were intended for future video/tab features.
export default class extends Controller {
  connect() {
    console.log("Deep travel controller connected")
  }

  // Unused methods - kept for future feature implementation
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

    // Note: These methods will be used when tab/video features are implemented
    console.log('Tab switching not yet implemented:', tabName)
  }
}
