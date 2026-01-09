import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab"]
  
  declare readonly tabTargets: HTMLElement[]
  private activeTabType: string = 'domestic'
  
  connect() {
    // 初始化时读取当前激活的标签
    const activeTab = this.element.querySelector('[data-tab-type].bg-white') as HTMLElement
    this.activeTabType = activeTab?.dataset.tabType || 'domestic'
    
    // Listen for city selector international switch event
    document.addEventListener('city-selector:switch-to-international', this.handleInternationalSwitch.bind(this))
  }
  
  disconnect() {
    document.removeEventListener('city-selector:switch-to-international', this.handleInternationalSwitch.bind(this))
  }
  
  // Handle international switch from city selector
  private handleInternationalSwitch(): void {
    console.log('Hotel tabs: Received switch to international event')
    // Find and click the international tab
    const internationalTab = this.tabTargets.find(tab => tab.dataset.tabType === 'international')
    if (internationalTab && this.activeTabType !== 'international') {
      // Simulate click to trigger tab switch
      internationalTab.click()
    }
  }

  switchTab(event: Event) {
    const clickedTab = event.currentTarget as HTMLElement
    const newTabType = clickedTab.dataset.tabType
    
    if (!newTabType) return
    
    // 如果点击的是当前激活的标签，不做任何操作
    if (newTabType === this.activeTabType) {
      return
    }
    
    // 更新激活状态
    this.activeTabType = newTabType
    
    // 移除所有标签的激活样式
    this.tabTargets.forEach((tab: HTMLElement) => {
      tab.classList.remove('bg-white', 'rounded-t-[12px]', 'px-3', 'py-2.5', 'relative')
      tab.classList.add('px-2', 'py-2')
      
      const span = tab.querySelector('span')
      if (span) {
        span.className = 'text-[13px] font-medium text-[#666666]'
      }
      
      // 如果是 button，确保样式正确
      if (tab.tagName === 'BUTTON') {
        tab.classList.add('text-[13px]', 'font-medium', 'text-[#666666]', 'cursor-pointer', 'whitespace-nowrap')
      }
    })
    
    // 为被点击的标签添加激活样式
    clickedTab.classList.remove('px-2', 'py-2')
    clickedTab.classList.add('relative', 'bg-white', 'rounded-t-[12px]', 'px-3', 'py-2.5')
    
    // 如果是 button，需要创建新的结构
    if (clickedTab.tagName === 'BUTTON') {
      const label = clickedTab.textContent?.trim() || ''
      clickedTab.innerHTML = `
        <div class="flex flex-col items-center">
          <span class="text-[15px] font-bold text-[#1a1a1a] leading-tight whitespace-nowrap">${label}</span>
        </div>
      `
    } else {
      // 如果已经是 div，只需要更新 span
      const span = clickedTab.querySelector('span')
      if (span) {
        span.className = 'text-[15px] font-bold text-[#1a1a1a] leading-tight whitespace-nowrap'
      }
    }
    
    // 触发类型切换事件，供其他控制器监听
    this.dispatch('typeChanged', { detail: { type: newTabType } })
    
    // 根据类型筛选酒店列表
    this.filterHotels(newTabType)
  }
  
  filterHotels(type: string) {
    // 根据类型筛选酒店
    // domestic: 国内城市
    // international: 国外和中国港澳
    // hourly: 钟点房（查询所有有钟点房的酒店和民宿）
    // homestay: 民宿
    
    console.log(`切换到类型: ${type}`)
    
    // 构建 URL 参数
    const currentParams = new URLSearchParams(window.location.search)
    
    // 从 city-selector 控制器获取当前选择的城市
    const citySelectorElement = document.querySelector('[data-controller*="city-selector"]')
    if (citySelectorElement) {
      const departureCityInput = citySelectorElement.querySelector('[data-city-selector-target="departureCityInput"]') as HTMLInputElement
      if (departureCityInput && departureCityInput.value) {
        // 将选择的城市添加到 URL 参数中
        currentParams.set('city', departureCityInput.value)
        console.log(`保留选择的城市: ${departureCityInput.value}`)
      }
    }
    
    // 清除可能冲突的参数
    currentParams.delete('type')
    currentParams.delete('room_category')
    
    // 设置 location_type 和筛选参数
    if (type === 'domestic') {
      currentParams.set('location_type', 'domestic')
    } else if (type === 'international') {
      currentParams.set('location_type', 'international')
    } else if (type === 'hourly') {
      // 钟点房：使用 room_category 参数筛选有钟点房的住宿场所
      currentParams.set('location_type', 'domestic')
      currentParams.set('room_category', 'hourly')
    } else if (type === 'homestay') {
      // 民宿：使用 type 参数筛选住宿类型
      currentParams.set('location_type', 'domestic')
      currentParams.set('type', 'homestay')
    }
    
    // 重新加载页面带新参数
    const newUrl = `${window.location.pathname}?${currentParams.toString()}`
    window.location.href = newUrl
  }
}
