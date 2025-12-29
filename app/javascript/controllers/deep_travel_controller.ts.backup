import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["video", "videoContainer", "tab", "content"]

  connect() {
    console.log("Deep Travel controller connected")
  }

  // Handle tab switching
  switchTab(event: Event) {
    event.preventDefault()
    const target = event.currentTarget as HTMLElement
    const location = target.dataset.location

    // Update active tab styling
    this.tabTargets.forEach(tab => {
      tab.classList.remove('text-gray-900', 'border-b-2', 'border-yellow-400', 'bg-yellow-50')
      tab.classList.add('text-gray-600')
    })

    target.classList.remove('text-gray-600')
    target.classList.add('text-gray-900', 'border-b-2', 'border-yellow-400', 'bg-yellow-50')
  }

  // Play video
  playVideo(event: Event) {
    const video = event.currentTarget as HTMLVideoElement
    if (video.paused) {
      video.play()
    } else {
      video.pause()
    }
  }

  // Handle video fullscreen
  toggleFullscreen(event: Event) {
    const container = (event.currentTarget as HTMLElement).closest('[data-deep-travel-target="videoContainer"]')
    if (!container) return

    if (!document.fullscreenElement) {
      container.requestFullscreen().catch(err => {
        console.log(`Error attempting to enable fullscreen: ${err.message}`)
      })
    } else {
      document.exitFullscreen()
    }
  }

  // Scroll to guide section
  scrollToGuide(event: Event) {
    event.preventDefault()
    const guideId = (event.currentTarget as HTMLElement).dataset.guideId
    const guideElement = document.querySelector(`[data-guide-id="${guideId}"]`)
    
    if (guideElement) {
      guideElement.scrollIntoView({ behavior: 'smooth', block: 'start' })
    }
  }

  // Handle "More" button click
  showMore(event: Event) {
    event.preventDefault()
    console.log("Show more guides clicked")
    // TODO: Implement modal or navigation to full guide list
  }

  // Handle booking button click
  bookGuide(event: Event) {
    event.preventDefault()
    const guideId = (event.currentTarget as HTMLElement).dataset.guideId
    console.log(`Book guide: ${guideId}`)
    // TODO: Implement booking flow
    alert('预约功能即将上线，敬请期待！')
  }
}
