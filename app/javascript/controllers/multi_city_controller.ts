import { Controller } from "@hotwired/stimulus"

// 行程段接口
interface Segment {
  id: string
  departureCity: string
  destinationCity: string
  date: string
}

export default class extends Controller<HTMLElement> {
  static targets = ["segmentsContainer", "segment", "addButton", "hiddenSegmentsInput"]
  static values = {
    segments: { type: Array, default: [] },
    switchIconUrl: String
  }

  declare readonly segmentsContainerTarget: HTMLElement
  declare readonly segmentTargets: HTMLElement[]
  declare readonly addButtonTarget: HTMLElement
  declare readonly hiddenSegmentsInputTarget: HTMLInputElement
  declare readonly hasSegmentsContainerTarget: boolean
  declare readonly hasAddButtonTarget: boolean
  declare readonly hasHiddenSegmentsInputTarget: boolean
  declare segmentsValue: Segment[]
  declare readonly switchIconUrlValue: string

  connect(): void {
    console.log("MultiCity controller connected")
    
    // Only initialize if the container target is available
    if (!this.hasSegmentsContainerTarget) {
      console.log("MultiCity controller: segmentsContainer not available yet, skipping initialization")
      
      // Listen for the event when multi-city form becomes visible
      document.addEventListener('trip-type:multi-city-shown', this.handleMultiCityShown.bind(this))
      return
    }
    
    this.initializeSegments()
    
    // Listen for city selection events on document for better event capture
    document.addEventListener('city-selector:city-selected', this.handleCitySelected.bind(this))
    console.log('Multi-city: Added event listener for city-selector:city-selected')
    
    // Listen for date selection events
    // eslint-disable-next-line no-undef
    document.addEventListener('date-picker:date-selected', this.handleDateSelected.bind(this) as unknown as EventListener)
    console.log('Multi-city: Added event listener for date-picker:date-selected')
  }

  disconnect(): void {
    document.removeEventListener('city-selector:city-selected', this.handleCitySelected.bind(this))
    document.removeEventListener('date-picker:date-selected', this.handleDateSelected.bind(this))
    document.removeEventListener('trip-type:multi-city-shown', this.handleMultiCityShown.bind(this))
  }

  // Stimulus value changed callback - automatically called when segmentsValue changes
  segmentsValueChanged(): void {
    console.log('Multi-city: segmentsValueChanged triggered')
    // Only render if the container is available
    if (this.hasSegmentsContainerTarget) {
      this.render()
    }
  }

  // Handle when multi-city form is shown
  private handleMultiCityShown(): void {
    console.log('Multi-city: Form is now visible, initializing...')
    
    // Check if targets are now available
    if (this.hasSegmentsContainerTarget) {
      this.initializeSegments()
      
      // Listen for city selection events
      document.addEventListener('city-selector:city-selected', this.handleCitySelected.bind(this))
      console.log('Multi-city: Added event listener for city-selector:city-selected')
      
      // Listen for date selection events
      // eslint-disable-next-line no-undef
      document.addEventListener('date-picker:date-selected', this.handleDateSelected.bind(this) as unknown as EventListener)
      console.log('Multi-city: Added event listener for date-picker:date-selected')
    }
  }

  // Initialize the segments
  private initializeSegments(): void {
    console.log('Multi-city: Initializing segments')
    
    // 初始化默认行程段
    if (this.segmentsValue.length === 0) {
      this.segmentsValue = [
        {
          id: this.generateId(),
          departureCity: "武汉",
          destinationCity: "深圳",
          date: this.formatDate(new Date())
        },
        {
          id: this.generateId(),
          departureCity: "广州",
          destinationCity: "杭州",
          date: this.formatDate(new Date(Date.now() + 3 * 24 * 60 * 60 * 1000)) // 3天后
        }
      ]
    }
    
    this.render()
    this.updateAddButtonState()
  }

  // Handle city selection from city selector
  private handleCitySelected(event: Event): void {
    const customEvent = event as CustomEvent
    console.log('Multi-city: Received city-selector:city-selected event', customEvent.detail)
    const { segmentId, cityType, cityName } = customEvent.detail
    
    console.log('Multi-city: Current segments before update:', JSON.stringify(this.segmentsValue))
    
    const segmentIndex = this.segmentsValue.findIndex(seg => seg.id === segmentId)
    
    if (segmentIndex !== -1) {
      console.log(`Multi-city: Found segment ${segmentId}, updating ${cityType} to ${cityName}`)
      
      // Create a new array with updated segment to trigger Stimulus reactivity
      this.segmentsValue = this.segmentsValue.map((seg, index) => {
        if (index === segmentIndex) {
          console.log('Multi-city: Segment before update:', JSON.stringify(seg))
          
          const updatedSegment = {
            ...seg,
            departureCity: cityType === 'departure' ? cityName : seg.departureCity,
            destinationCity: cityType === 'destination' ? cityName : seg.destinationCity
          }
          
          console.log('Multi-city: Segment after update:', JSON.stringify(updatedSegment))
          return updatedSegment
        }
        return seg
      })
      
      console.log('Multi-city: All segments after update:', JSON.stringify(this.segmentsValue))
      console.log('Multi-city: Segment updated, render will be triggered by valueChanged')
    } else {
      console.warn('Multi-city: Segment not found:', segmentId)
      console.warn('Multi-city: Available segment IDs:', this.segmentsValue.map(s => s.id))
    }
  }

  // Handle date selection from date picker
  private handleDateSelected(event: CustomEvent): void {
    console.log('Multi-city: Received date-picker:date-selected event', event.detail)
    const { segmentId, date } = event.detail
    
    const segmentIndex = this.segmentsValue.findIndex(seg => seg.id === segmentId)
    
    if (segmentIndex !== -1) {
      console.log(`Multi-city: Updating segment ${segmentId} date to ${date}`)
      
      // Create a new array with updated segment to trigger Stimulus reactivity
      this.segmentsValue = this.segmentsValue.map((seg, index) => {
        if (index === segmentIndex) {
          return { ...seg, date }
        }
        return seg
      })
      
      console.log('Multi-city: Segment date updated')
    } else {
      console.warn('Multi-city: Segment not found:', segmentId)
    }
  }

  // 添加新的行程段
  addSegment(): void {
    // 最多支持8个行程段
    if (this.segmentsValue.length >= 8) {
      alert("最多支持8个行程段")
      return
    }

    const lastSegment = this.segmentsValue[this.segmentsValue.length - 1]
    
    // 新行程段的出发地默认为上一段的目的地
    const newSegment: Segment = {
      id: this.generateId(),
      departureCity: lastSegment ? lastSegment.destinationCity : "北京",
      destinationCity: "上海",
      date: lastSegment 
        ? this.formatDate(new Date(new Date(lastSegment.date).getTime() + 24 * 60 * 60 * 1000))
        : this.formatDate(new Date())
    }

    this.segmentsValue = [...this.segmentsValue, newSegment]
    this.render()
    this.updateAddButtonState()
  }

  // 删除行程段
  removeSegment(event: Event): void {
    const button = event.currentTarget as HTMLElement
    const segmentId = button.dataset.segmentId

    // 至少保留2个行程段
    if (this.segmentsValue.length <= 2) {
      alert("至少需要保留2个行程段")
      return
    }

    this.segmentsValue = this.segmentsValue.filter(seg => seg.id !== segmentId)
    this.render()
    this.updateAddButtonState()
  }

  // 更新行程段的城市
  updateCity(event: Event): void {
    const input = event.currentTarget as HTMLInputElement
    const segmentId = input.dataset.segmentId
    const cityType = input.dataset.cityType // 'departure' or 'destination'

    const segment = this.segmentsValue.find(seg => seg.id === segmentId)
    if (segment) {
      if (cityType === 'departure') {
        segment.departureCity = input.value
      } else if (cityType === 'destination') {
        segment.destinationCity = input.value
      }
      this.updateHiddenInput()
    }
  }

  // 更新行程段的日期
  updateDate(event: Event): void {
    const input = event.currentTarget as HTMLInputElement
    const segmentId = input.dataset.segmentId

    const segment = this.segmentsValue.find(seg => seg.id === segmentId)
    if (segment) {
      segment.date = input.value
      this.updateHiddenInput()
    }
  }

  // 打开城市选择器
  openCitySelector(event: Event): void {
    const button = event.currentTarget as HTMLElement
    const segmentId = button.dataset.segmentId
    const cityType = button.dataset.cityType

    console.log(`Multi-city: Opening city selector for segment ${segmentId}, cityType ${cityType}`)
    
    // 触发城市选择器的自定义事件
    const customEvent = new CustomEvent('multi-city:open-city-selector', {
      detail: { segmentId, cityType },
      bubbles: true
    })
    this.element.dispatchEvent(customEvent)
  }

  // 打开日期选择器
  openDatePicker(event: Event): void {
    const button = event.currentTarget as HTMLElement
    const segmentId = button.dataset.segmentId

    // 触发日期选择器的自定义事件
    const customEvent = new CustomEvent('multi-city:open-date-picker', {
      detail: { segmentId },
      bubbles: true
    })
    this.element.dispatchEvent(customEvent)
  }

  // 渲染所有行程段
  private render(): void {
    if (!this.hasSegmentsContainerTarget) {
      console.log("MultiCity: Cannot render, segmentsContainer not available")
      return
    }
    
    console.log('Multi-city: render() called with segments:', JSON.stringify(this.segmentsValue))
    
    this.segmentsContainerTarget.innerHTML = ""

    this.segmentsValue.forEach((segment, index) => {
      console.log(`Multi-city: Creating element for segment ${index}:`, JSON.stringify(segment))
      const segmentElement = this.createSegmentElement(segment, index)
      this.segmentsContainerTarget.appendChild(segmentElement)
    })

    this.updateHiddenInput()
  }

  // 创建单个行程段元素
  private createSegmentElement(segment: Segment, index: number): HTMLElement {
    console.log(`Multi-city: createSegmentElement called for segment ${segment.id}:`, {
      departureCity: segment.departureCity,
      destinationCity: segment.destinationCity,
      date: segment.date
    })
    
    const div = document.createElement("div")
    div.className = "border-b border-gray-100 py-4"
    div.dataset.multiCityTarget = "segment"

    const date = new Date(segment.date)
    const weekday = this.getWeekday(date)

    div.innerHTML = `
      <div class="flex items-center justify-between mb-3">
        <div class="flex items-center gap-2">
          <span class="inline-flex items-center justify-center w-5 h-5 rounded-full bg-blue-500 text-white text-xs font-bold">
            ${index + 1}
          </span>
          <span class="text-sm text-gray-500">第${this.numberToChinese(index + 1)}程</span>
        </div>
        ${this.segmentsValue.length > 2 ? `
          <button 
            type="button"
            data-action="click->multi-city#removeSegment"
            data-segment-id="${segment.id}"
            class="text-gray-400 hover:text-red-500">
            <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
              <path fill-rule="evenodd" 
                d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" 
                clip-rule="evenodd"/>
            </svg>
          </button>
        ` : ''}
      </div>

      <div class="flex items-center justify-between">
        <button 
          type="button"
          data-action="click->multi-city#openCitySelector"
          data-segment-id="${segment.id}"
          data-city-type="departure"
          class="flex-1 text-left">
          <div class="text-[32px] font-bold leading-tight">${segment.departureCity}</div>
        </button>
        
        <div class="mx-4 flex items-center justify-center">
          <img src="${this.switchIconUrlValue}" class="w-12 h-12" alt="切换" />
        </div>
        
        <button 
          type="button"
          data-action="click->multi-city#openCitySelector"
          data-segment-id="${segment.id}"
          data-city-type="destination"
          class="flex-1 text-right">
          <div class="text-[32px] font-bold leading-tight">${segment.destinationCity}</div>
        </button>
      </div>

      <button 
        type="button"
        data-action="click->multi-city#openDatePicker"
        data-segment-id="${segment.id}"
        class="mt-2 text-left">
        <div class="text-lg font-medium text-gray-700">
          ${date.getMonth() + 1}月${date.getDate()}日 ${weekday}
        </div>
      </button>
    `
    
    console.log(`Multi-city: Created HTML for segment ${segment.id}, departure: ${segment.departureCity}, destination: ${segment.destinationCity}`)

    return div
  }

  // 更新添加按钮状态
  private updateAddButtonState(): void {
    if (!this.hasAddButtonTarget) {
      console.log("MultiCity: Cannot update add button state, button not available")
      return
    }
    
    if (this.segmentsValue.length >= 8) {
      this.addButtonTarget.classList.add("opacity-50", "cursor-not-allowed")
      this.addButtonTarget.setAttribute("disabled", "true")
    } else {
      this.addButtonTarget.classList.remove("opacity-50", "cursor-not-allowed")
      this.addButtonTarget.removeAttribute("disabled")
    }
  }

  // 更新隐藏的表单输入
  private updateHiddenInput(): void {
    if (this.hasHiddenSegmentsInputTarget) {
      this.hiddenSegmentsInputTarget.value = JSON.stringify(this.segmentsValue)
    }
  }

  // 生成唯一ID
  private generateId(): string {
    return `segment-${Date.now()}-${Math.random().toString(36).substring(2, 11)}`
  }

  // 格式化日期
  private formatDate(date: Date): string {
    const year = date.getFullYear()
    const month = String(date.getMonth() + 1).padStart(2, '0')
    const day = String(date.getDate()).padStart(2, '0')
    return `${year}-${month}-${day}`
  }

  // 获取星期几
  private getWeekday(date: Date): string {
    const weekdays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六']
    return weekdays[date.getDay()]
  }

  // 数字转中文
  private numberToChinese(num: number): string {
    const chinese = ['一', '二', '三', '四', '五', '六', '七', '八']
    return chinese[num - 1] || num.toString()
  }
}
