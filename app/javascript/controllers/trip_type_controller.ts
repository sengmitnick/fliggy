import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = [
    "tab", 
    "returnDateSection", 
    "tripTypeInput", 
    "returnDateInput",
    "oneWayRoundTripForm",
    "multiCityForm",
    "promotionBanner"
  ]
  static values = {
    currentType: { type: String, default: "one_way" }
  }

  declare readonly tabTargets: HTMLElement[]
  declare readonly returnDateSectionTarget: HTMLElement
  declare readonly tripTypeInputTarget: HTMLInputElement
  declare readonly returnDateInputTarget: HTMLInputElement
  declare readonly oneWayRoundTripFormTarget: HTMLElement
  declare readonly multiCityFormTarget: HTMLElement
  declare readonly promotionBannerTarget: HTMLElement
  declare readonly hasTripTypeInputTarget: boolean
  declare readonly hasReturnDateSectionTarget: boolean
  declare readonly hasReturnDateInputTarget: boolean
  declare readonly hasOneWayRoundTripFormTarget: boolean
  declare readonly hasMultiCityFormTarget: boolean
  declare readonly hasPromotionBannerTarget: boolean
  declare currentTypeValue: string

  connect(): void {
    console.log("TripType connected")
    this.updateUI()
  }

  // 切换行程类型
  selectType(event: Event): void {
    const button = event.currentTarget as HTMLElement
    const tripType = button.dataset.tripType || 'one_way'
    
    this.currentTypeValue = tripType
    this.updateUI()
    
    // 如果切换到往返且返程日期为空，设置默认返程日期为去程+1天
    if (tripType === 'round_trip' && this.hasReturnDateInputTarget) {
      if (!this.returnDateInputTarget.value) {
        const departureDateInput = document.querySelector('[data-date-picker-target="dateInput"]') as HTMLInputElement
        if (departureDateInput && departureDateInput.value) {
          const departureDate = new Date(departureDateInput.value)
          departureDate.setDate(departureDate.getDate() + 1)
          const returnDateStr = this.formatDate(departureDate)
          this.returnDateInputTarget.value = returnDateStr
          
          // 触发返程日期选择器更新显示
          const returnDateController = this.application.getControllerForElementAndIdentifier(
            this.element,
            'return-date-picker'
          )
          if (returnDateController && 'currentDateValue' in returnDateController) {
            (returnDateController as any).currentDateValue = returnDateStr
          }
        }
      }
    }
  }

  // 更新UI状态
  private updateUI(): void {
    // 更新按钮状态
    this.tabTargets.forEach(tab => {
      const isActive = tab.dataset.tripType === this.currentTypeValue
      
      if (isActive) {
        tab.classList.remove('text-gray-500')
        tab.classList.add('font-bold', 'border-b-2', 'border-black')
      } else {
        tab.classList.remove('font-bold', 'border-b-2', 'border-black')
        tab.classList.add('text-gray-500')
      }
    })

    // 更新隐藏表单字段
    if (this.hasTripTypeInputTarget) {
      this.tripTypeInputTarget.value = this.currentTypeValue
    }

    // 展示/隐藏返程日期选择
    if (this.hasReturnDateSectionTarget) {
      if (this.currentTypeValue === 'round_trip') {
        this.returnDateSectionTarget.classList.remove('hidden')
      } else {
        this.returnDateSectionTarget.classList.add('hidden')
      }
    }

    // 展示/隐藏单程往返表单 vs 多程表单
    if (this.hasOneWayRoundTripFormTarget && this.hasMultiCityFormTarget) {
      if (this.currentTypeValue === 'multi_city') {
        this.oneWayRoundTripFormTarget.classList.add('hidden')
        this.multiCityFormTarget.classList.remove('hidden')
        
        // 触发自定义事件通知 multi-city 控制器初始化
        const multiCityEvent = new CustomEvent('trip-type:multi-city-shown', {
          bubbles: true
        })
        this.element.dispatchEvent(multiCityEvent)
      } else {
        this.oneWayRoundTripFormTarget.classList.remove('hidden')
        this.multiCityFormTarget.classList.add('hidden')
      }
    }

    // 多程模式下隐藏促销横幅
    if (this.hasPromotionBannerTarget) {
      if (this.currentTypeValue === 'multi_city') {
        this.promotionBannerTarget.classList.add('hidden')
      } else {
        this.promotionBannerTarget.classList.remove('hidden')
      }
    }
  }

  private formatDate(date: Date): string {
    const year = date.getFullYear()
    const month = String(date.getMonth() + 1).padStart(2, '0')
    const day = String(date.getDate()).padStart(2, '0')
    return `${year}-${month}-${day}`
  }
}
