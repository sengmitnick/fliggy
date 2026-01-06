import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = [
    "statusTitle",
    "statusMessage",
    "progressPercent",
    "progressCircle",
    "seatIcon",
    "seatDisplay",
    "seatBadge",
    "paymentBar",
    "cancelBar"
  ]

  declare readonly statusTitleTarget: HTMLElement
  declare readonly statusMessageTarget: HTMLElement
  declare readonly progressPercentTarget: HTMLElement
  declare readonly progressCircleTarget: SVGCircleElement
  declare readonly seatIconTarget: HTMLElement
  declare readonly seatDisplayTarget: HTMLElement
  declare readonly seatBadgeTarget: HTMLElement
  declare readonly paymentBarTarget: HTMLElement
  declare readonly cancelBarTarget: HTMLElement

  declare readonly hasStatusTitleTarget: boolean
  declare readonly hasStatusMessageTarget: boolean
  declare readonly hasProgressPercentTarget: boolean
  declare readonly hasProgressCircleTarget: boolean
  declare readonly hasSeatIconTarget: boolean
  declare readonly hasSeatDisplayTarget: boolean
  declare readonly hasSeatBadgeTarget: boolean
  declare readonly hasPaymentBarTarget: boolean
  declare readonly hasCancelBarTarget: boolean

  private lockingInterval: number | null = null
  private currentProgress: number = 0

  connect(): void {
    // Start the locking animation
    this.startLockingAnimation()
  }

  disconnect(): void {
    if (this.lockingInterval) {
      clearInterval(this.lockingInterval)
    }
  }

  private startLockingAnimation(): void {
    const totalDuration = 5000 // 5 seconds
    const updateInterval = 50 // Update every 50ms
    const totalSteps = totalDuration / updateInterval
    const progressStep = 100 / totalSteps

    this.lockingInterval = window.setInterval(() => {
      this.currentProgress += progressStep

      if (this.currentProgress >= 100) {
        this.currentProgress = 100
        this.completeLocking()
        if (this.lockingInterval) {
          clearInterval(this.lockingInterval)
        }
      }

      this.updateProgress(this.currentProgress)
    }, updateInterval)
  }

  private updateProgress(progress: number): void {
    // Update percentage text
    if (this.hasProgressPercentTarget) {
      this.progressPercentTarget.textContent = Math.floor(progress).toString()
    }

    // Update circular progress
    if (this.hasProgressCircleTarget) {
      const circumference = 534 // 2 * PI * 85
      const offset = circumference - (progress / 100) * circumference
      this.progressCircleTarget.style.strokeDashoffset = offset.toString()
    }

    // Animate seat icon
    if (this.hasSeatIconTarget) {
      // Pulse animation at certain progress points
      if (progress % 20 < 2) {
        this.seatIconTarget.style.transform = 'scale(1.2)'
        setTimeout(() => {
          if (this.hasSeatIconTarget) {
            this.seatIconTarget.style.transform = 'scale(1)'
          }
        }, 200)
      }
    }
  }

  private completeLocking(): void {
    // Update status title
    if (this.hasStatusTitleTarget) {
      this.statusTitleTarget.textContent = '占座成功'
    }

    // Update status message with countdown
    if (this.hasStatusMessageTarget) {
      const expiryTime = new Date()
      expiryTime.setMinutes(expiryTime.getMinutes() + 15)
      const hours = expiryTime.getHours().toString().padStart(2, '0')
      const minutes = expiryTime.getMinutes().toString().padStart(2, '0')
      const timeString = `${hours}:${minutes}`
      this.statusMessageTarget.innerHTML = `请在<span class="text-red-600">${timeString}</span>内完成支付，超时订单将关闭`
    }

    // Show seat information
    if (this.hasSeatDisplayTarget) {
      this.seatDisplayTarget.style.display = 'inline'
    }

    if (this.hasSeatBadgeTarget) {
      this.seatBadgeTarget.style.display = 'inline-block'
    }

    // Change seat icon to indicate success
    if (this.hasSeatIconTarget) {
      this.seatIconTarget.textContent = '🪑'
      this.seatIconTarget.style.transform = 'scale(1.3)'
      setTimeout(() => {
        if (this.hasSeatIconTarget) {
          this.seatIconTarget.style.transform = 'scale(1)'
        }
      }, 300)
    }

    // Hide cancel button, show payment button
    if (this.hasCancelBarTarget) {
      this.cancelBarTarget.style.display = 'none'
    }

    if (this.hasPaymentBarTarget) {
      this.paymentBarTarget.style.display = 'block'
    }
  }
}
