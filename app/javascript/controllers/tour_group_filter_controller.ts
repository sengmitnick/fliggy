import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = [
    "destinationInput",
    "durationInput",
    "groupSizeInput",
    "destinationButton",
    "durationButton",
    "groupSizeButton",
    "departureDisplay"
  ]

  static values = {
    destination: String,
    duration: String,
    groupSize: String
  }

  declare readonly destinationInputTarget: HTMLInputElement
  declare readonly durationInputTarget: HTMLInputElement
  declare readonly groupSizeInputTarget: HTMLInputElement
  declare readonly destinationButtonTargets: HTMLElement[]
  declare readonly durationButtonTargets: HTMLElement[]
  declare readonly groupSizeButtonTargets: HTMLElement[]
  declare readonly departureDisplayTarget: HTMLElement
  
  declare destinationValue: string
  declare durationValue: string
  declare groupSizeValue: string

  connect(): void {
    console.log("TourGroupFilter connected")
    // Listen for city selection changes from city-selector
    this.element.addEventListener('city-selector:city-changed', this.handleCityChanged.bind(this))
  }

  disconnect(): void {
    this.element.removeEventListener('city-selector:city-changed', this.handleCityChanged.bind(this))
  }

  // Handle city change from city-selector modal
  private handleCityChanged(event: Event): void {
    const customEvent = event as CustomEvent
    const { cityName } = customEvent.detail
    console.log('TourGroupFilter: City changed to', cityName)
    
    // Update destination value
    this.destinationValue = cityName
    this.destinationInputTarget.value = cityName
    
    // Update hot destination buttons - only highlight if city is in the list
    this.updateHotDestinationButtons(cityName)
  }

  // Update hot destination buttons based on selected city
  private updateHotDestinationButtons(cityName: string): void {
    let cityInHotList = false
    
    this.destinationButtonTargets.forEach(btn => {
      if (btn.dataset.destination === cityName) {
        btn.classList.remove('bg-gray-50')
        btn.classList.add('bg-[#FFE8CC]')
        cityInHotList = true
      } else {
        btn.classList.add('bg-gray-50')
        btn.classList.remove('bg-[#FFE8CC]')
      }
    })
    
    console.log(`City "${cityName}" ${cityInHotList ? 'is' : 'is not'} in hot destination list`)
  }

  // 选择目的地
  selectDestination(event: Event): void {
    const button = event.currentTarget as HTMLElement
    const destination = button.dataset.destination || ''
    
    this.destinationValue = destination
    this.destinationInputTarget.value = destination
    
    // Update "我想去" display text
    this.departureDisplayTarget.textContent = destination
    
    // 更新按钮样式
    this.updateHotDestinationButtons(destination)
  }

  // 选择天数
  selectDuration(event: Event): void {
    const button = event.currentTarget as HTMLElement
    const duration = button.dataset.duration || ''
    
    this.durationValue = duration
    this.durationInputTarget.value = duration
    
    // 更新按钮样式
    this.durationButtonTargets.forEach(btn => {
      if (btn.dataset.duration === duration) {
        btn.classList.remove('bg-gray-50')
        btn.classList.add('bg-[#FFE8CC]')
      } else {
        btn.classList.add('bg-gray-50')
        btn.classList.remove('bg-[#FFE8CC]')
      }
    })
  }

  // 选择团队大小
  selectGroupSize(event: Event): void {
    const button = event.currentTarget as HTMLElement
    const groupSize = button.dataset.groupSize || ''
    
    this.groupSizeValue = groupSize
    this.groupSizeInputTarget.value = groupSize
    
    // 更新单选按钮样式
    this.groupSizeButtonTargets.forEach(btn => {
      const radio = btn.querySelector('.radio-circle') as HTMLElement
      if (btn.dataset.groupSize === groupSize) {
        radio?.classList.add('bg-[#FFD700]')
        radio?.classList.remove('bg-transparent')
      } else {
        radio?.classList.add('bg-transparent')
        radio?.classList.remove('bg-[#FFD700]')
      }
    })
  }
}
