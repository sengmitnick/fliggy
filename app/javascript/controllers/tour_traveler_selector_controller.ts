import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = [
    // stimulus-validator: disable-next-line
    "modal",
    // stimulus-validator: disable-next-line
    "travelerNameInput",
    // stimulus-validator: disable-next-line
    "travelerIdInput"
  ]

  static values = {
    selectedPassengerId: String,
    selectedPassengerName: String,
    selectedPassengerIdNumber: String,
    travelerIndex: Number,
    usedPassengerIds: Array
  }

  // stimulus-validator: disable-next-line
  declare readonly modalTarget: HTMLElement
  // stimulus-validator: disable-next-line
  declare readonly travelerNameInputTargets: HTMLInputElement[]
  // stimulus-validator: disable-next-line
  declare readonly travelerIdInputTargets: HTMLInputElement[]

  declare selectedPassengerIdValue: string
  declare selectedPassengerNameValue: string
  declare selectedPassengerIdNumberValue: string
  declare travelerIndexValue: number
  declare usedPassengerIdsValue: string[]
  declare hasUsedPassengerIdsValue: boolean

  connect(): void {
    console.log("TourTravelerSelector connected")
    // 初始化已使用的出行人ID数组
    if (!this.hasUsedPassengerIdsValue) {
      this.usedPassengerIdsValue = []
    }
  }

  disconnect(): void {
    console.log("TourTravelerSelector disconnected")
  }

  // Open modal for specific traveler
  openModal(event: Event): void {
    const target = event.currentTarget as HTMLElement
    const travelerIndex = parseInt(target.dataset.travelerIndex || '0')
    
    console.log("Opening traveler selector modal for index:", travelerIndex)
    
    this.travelerIndexValue = travelerIndex
    
    // 更新弹窗中出行人的可用状态
    this.updatePassengerAvailability()
    
    this.modalTarget.classList.remove('hidden')
    document.body.style.overflow = 'hidden'
  }

  // Close modal
  closeModal(): void {
    this.modalTarget.classList.add('hidden')
    document.body.style.overflow = ''
  }

  // Select a passenger from the list
  selectPassenger(event: Event): void {
    const target = event.currentTarget as HTMLElement
    const passengerId = target.dataset.passengerId || ''
    const passengerName = target.dataset.passengerName || ''
    const passengerIdNumber = target.dataset.passengerIdNumber || ''

    // 检查该出行人是否已被使用
    if (this.usedPassengerIdsValue.includes(passengerId)) {
      alert('该出行人已被选择，请选择其他出行人')
      return
    }

    console.log("Selected passenger:", { passengerId, passengerName, passengerIdNumber, travelerIndex: this.travelerIndexValue })

    // Store selected values
    this.selectedPassengerIdValue = passengerId
    this.selectedPassengerNameValue = passengerName
    this.selectedPassengerIdNumberValue = passengerIdNumber

    // 获取当前表单字段中已经选择的出行人ID（如果有）
    const currentInput = this.travelerNameInputTargets[this.travelerIndexValue]
    const currentPassengerId = currentInput?.dataset.selectedPassengerId
    
    // 如果当前字段已经有选择的出行人，从已使用列表中移除
    if (currentPassengerId && this.usedPassengerIdsValue.includes(currentPassengerId)) {
      this.usedPassengerIdsValue = this.usedPassengerIdsValue.filter(id => id !== currentPassengerId)
    }

    // Update form inputs for specific traveler
    if (this.travelerNameInputTargets[this.travelerIndexValue]) {
      this.travelerNameInputTargets[this.travelerIndexValue].value = passengerName
      this.travelerNameInputTargets[this.travelerIndexValue].dataset.selectedPassengerId = passengerId
    }
    if (this.travelerIdInputTargets[this.travelerIndexValue]) {
      this.travelerIdInputTargets[this.travelerIndexValue].value = passengerIdNumber
    }

    // 将新选择的出行人ID添加到已使用列表
    this.usedPassengerIdsValue = [...this.usedPassengerIdsValue, passengerId]

    console.log('已使用的出行人ID列表:', this.usedPassengerIdsValue)

    // Close modal
    this.closeModal()
  }

  // Stop propagation for inner clicks
  stopPropagation(event: Event): void {
    event.stopPropagation()
  }

  // 更新弹窗中出行人的可用状态
  private updatePassengerAvailability(): void {
    const passengerItems = this.modalTarget.querySelectorAll('[data-passenger-id]')
    
    passengerItems.forEach((item) => {
      const passengerId = (item as HTMLElement).dataset.passengerId || ''
      const isUsed = this.usedPassengerIdsValue.includes(passengerId)
      
      if (isUsed) {
        // 标记为已使用：添加禁用样式和"已选择"标记
        item.classList.add('opacity-50', 'cursor-not-allowed', 'pointer-events-none')
        item.classList.remove('hover:bg-gray-50', 'cursor-pointer')
        
        // 添加"已选择"徽章（如果还没有）
        if (!item.querySelector('.used-badge')) {
          const badge = document.createElement('span')
          badge.className = 'used-badge ml-2 px-2 py-0.5 text-xs rounded bg-gray-200 text-gray-600'
          badge.textContent = '已选择'
          
          const nameContainer = item.querySelector('.flex.items-center.mb-1')
          if (nameContainer) {
            nameContainer.appendChild(badge)
          }
        }
      } else {
        // 恢复可用状态
        item.classList.remove('opacity-50', 'cursor-not-allowed', 'pointer-events-none')
        item.classList.add('hover:bg-gray-50', 'cursor-pointer')
        
        // 移除"已选择"徽章
        const badge = item.querySelector('.used-badge')
        if (badge) {
          badge.remove()
        }
      }
    })
  }
}
