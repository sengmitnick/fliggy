import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = [
    "destinationInput",
    "durationInput",
    "groupSizeInput",
    "destinationButton",
    "durationButton",
    "groupSizeButton",
    "departureDisplay",
    "durationModal",
    "durationOption",
    "durationLabel",
    "clearDurationButton",
    "quickDurationButtons"
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
  declare readonly durationModalTarget: HTMLElement
  declare readonly durationOptionTargets: HTMLElement[]
  declare readonly durationLabelTarget: HTMLElement
  declare readonly clearDurationButtonTarget: HTMLElement
  declare readonly quickDurationButtonsTarget: HTMLElement
  
  declare destinationValue: string
  declare durationValue: string
  declare groupSizeValue: string
  
  private tempSelectedDuration: string = ''

  connect(): void {
    // Listen for city selection changes from city-selector
    this.element.addEventListener('city-selector:city-changed', this.handleCityChanged.bind(this))
    
    // Auto-select group size if provided via URL parameter
    if (this.groupSizeValue) {
      this.autoSelectGroupSize(this.groupSizeValue)
    }
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
      const textSpan = btn.querySelector('span:last-child') as HTMLElement
      if (btn.dataset.destination === cityName) {
        btn.classList.remove('bg-gray-50', 'border-transparent')
        btn.classList.add('bg-[#FFE8CC]', 'border-[#FFD700]', 'shadow-md')
        if (textSpan) {
          textSpan.classList.remove('font-medium')
          textSpan.classList.add('font-bold')
        }
        cityInHotList = true
      } else {
        btn.classList.add('bg-gray-50', 'border-transparent')
        btn.classList.remove('bg-[#FFE8CC]', 'border-[#FFD700]', 'shadow-md')
        if (textSpan) {
          textSpan.classList.add('font-medium')
          textSpan.classList.remove('font-bold')
        }
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
      const textSpan = btn.querySelector('span:first-child') as HTMLElement
      if (btn.dataset.duration === duration) {
        btn.classList.remove('bg-gray-50', 'border-transparent')
        btn.classList.add('bg-[#FFE8CC]', 'border-[#FFD700]', 'shadow-md')
        if (textSpan) {
          textSpan.classList.remove('font-medium')
          textSpan.classList.add('font-bold')
        }
      } else {
        btn.classList.add('bg-gray-50', 'border-transparent')
        btn.classList.remove('bg-[#FFE8CC]', 'border-[#FFD700]', 'shadow-md')
        if (textSpan) {
          textSpan.classList.add('font-medium')
          textSpan.classList.remove('font-bold')
        }
      }
    })
  }

  // Open duration modal
  openDurationModal(): void {
    // Save current duration as temp
    this.tempSelectedDuration = this.durationValue
    
    // Update modal options to show current selection
    this.updateModalOptionStyles(this.tempSelectedDuration)
    
    this.durationModalTarget.classList.remove('hidden')
    document.body.style.overflow = 'hidden'
  }

  // Cancel modal (close button) - restore original selection
  cancelDurationModal(): void {
    this.durationModalTarget.classList.add('hidden')
    document.body.style.overflow = ''
  }

  // Close modal when clicking on backdrop - restore original selection
  closeDurationModalOnBackdrop(event: Event): void {
    if (event.target === event.currentTarget) {
      this.cancelDurationModal()
    }
  }

  // Select duration in modal (temporary selection)
  selectDurationInModal(event: Event): void {
    const button = event.currentTarget as HTMLElement
    const duration = button.dataset.duration || ''
    
    // Update temp selection
    this.tempSelectedDuration = duration
    
    // Update modal option styles
    this.updateModalOptionStyles(duration)
  }

  // Update modal option button styles
  private updateModalOptionStyles(selectedDuration: string): void {
    this.durationOptionTargets.forEach(btn => {
      if (btn.dataset.duration === selectedDuration) {
        btn.classList.remove('bg-gray-100', 'text-gray-700')
        btn.classList.add('bg-[#FFE8CC]', 'text-[#B8860B]', 'font-bold')
      } else {
        btn.classList.add('bg-gray-100', 'text-gray-700')
        btn.classList.remove('bg-[#FFE8CC]', 'text-[#B8860B]', 'font-bold')
      }
    })
  }

  // Clear duration in modal (temporary clear)
  clearDurationInModal(): void {
    this.tempSelectedDuration = ''
    this.updateModalOptionStyles('')
  }

  // Confirm duration selection
  confirmDurationSelection(): void {
    // Apply temp selection to actual value
    this.durationValue = this.tempSelectedDuration
    this.durationInputTarget.value = this.tempSelectedDuration
    
    // Update main duration buttons
    this.updateDurationButtonStyles(this.tempSelectedDuration)
    
    // Update duration label
    this.updateDurationLabel(this.tempSelectedDuration)
    
    const durationNum = parseInt(this.tempSelectedDuration)
    
    // Show/hide UI elements based on selection
    if (this.tempSelectedDuration && durationNum > 3) {
      // Extended duration (>3 days): show X button, hide quick buttons
      this.clearDurationButtonTarget.classList.remove('hidden')
      this.quickDurationButtonsTarget.classList.add('hidden')
      this.quickDurationButtonsTarget.classList.remove('flex', 'gap-3')
    } else {
      // Quick duration (1-3 days) or no selection: hide X button, show quick buttons
      this.clearDurationButtonTarget.classList.add('hidden')
      this.quickDurationButtonsTarget.classList.remove('hidden')
      this.quickDurationButtonsTarget.classList.add('flex', 'gap-3')
    }
    
    // Close modal
    this.durationModalTarget.classList.add('hidden')
    document.body.style.overflow = ''
  }

  // Update duration label text
  private updateDurationLabel(duration: string): void {
    const durationNum = parseInt(duration)
    
    if (duration && durationNum > 3) {
      this.durationLabelTarget.textContent = `玩${duration}天`
    } else {
      this.durationLabelTarget.textContent = '天数'
    }
  }

  // Clear duration selection (restore to quick selection state)
  clearDuration(): void {
    // Clear duration value
    this.durationValue = ''
    this.durationInputTarget.value = ''
    
    // Update label to default
    this.durationLabelTarget.textContent = '天数'
    
    // Hide clear button
    this.clearDurationButtonTarget.classList.add('hidden')
    
    // Show quick duration buttons
    this.quickDurationButtonsTarget.classList.remove('hidden')
    this.quickDurationButtonsTarget.classList.add('flex', 'gap-3')
    
    // Clear all duration button styles
    this.updateDurationButtonStyles('')
  }

  // Update main duration button styles
  private updateDurationButtonStyles(duration: string): void {
    this.durationButtonTargets.forEach(btn => {
      const textSpan = btn.querySelector('span:first-child') as HTMLElement
      if (btn.dataset.duration === duration) {
        btn.classList.remove('bg-gray-50', 'border-transparent')
        btn.classList.add('bg-[#FFE8CC]', 'border-[#FFD700]', 'shadow-md')
        if (textSpan) {
          textSpan.classList.remove('font-medium')
          textSpan.classList.add('font-bold')
        }
      } else {
        btn.classList.add('bg-gray-50', 'border-transparent')
        btn.classList.remove('bg-[#FFE8CC]', 'border-[#FFD700]', 'shadow-md')
        if (textSpan) {
          textSpan.classList.add('font-medium')
          textSpan.classList.remove('font-bold')
        }
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
    this.updateGroupSizeButtons(groupSize)
  }
  
  // Auto-select group size on page load
  private autoSelectGroupSize(groupSize: string): void {
    // Set the hidden input value
    if (this.groupSizeInputTarget) {
      this.groupSizeInputTarget.value = groupSize
    }
    
    // Update button styles
    this.updateGroupSizeButtons(groupSize)
  }
  
  // Update group size button styles
  private updateGroupSizeButtons(groupSize: string): void {
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
