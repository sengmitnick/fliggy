import { Controller } from "@hotwired/stimulus"

// 包车游搜索页面控制器
// 处理城市选择、日期选择、选项卡切换、立即包车等交互
export default class extends Controller {
  static targets = ["cityName", "dateDisplay", "cityModal", "searchInput", "citiesList", "tabButtons", "tabContent"]

  declare readonly cityNameTarget: HTMLElement
  declare readonly dateDisplayTarget: HTMLElement
  declare readonly cityModalTarget: HTMLElement
  declare readonly searchInputTarget: HTMLInputElement
  declare readonly citiesListTarget: HTMLElement
  declare readonly tabButtonsTarget: HTMLElement
  declare readonly tabContentTargets: HTMLElement[]

  // 切换选项卡
  switchTab(event: Event): void {
    event.preventDefault()
    const button = event.currentTarget as HTMLButtonElement
    const tabName = button.dataset.tab

    if (!tabName) return

    // 更新所有按钮样式
    const allButtons = this.tabButtonsTarget.querySelectorAll('button')
    allButtons.forEach((btn) => {
      const btnElement = btn as HTMLButtonElement
      if (btnElement.dataset.tab === tabName) {
        // 激活状态
        btnElement.classList.remove('text-text-secondary')
        btnElement.classList.add('text-primary', 'border-b-2', 'border-primary')
      } else {
        // 非激活状态
        btnElement.classList.remove('text-primary', 'border-b-2', 'border-primary')
        btnElement.classList.add('text-text-secondary')
      }
    })

    // 切换内容显示
    this.tabContentTargets.forEach((content) => {
      if (content.dataset.tab === tabName) {
        content.classList.remove('hidden')
      } else {
        content.classList.add('hidden')
      }
    })
  }

  // 打开城市选择器
  openCitySelector(event: Event): void {
    event.preventDefault()
    this.cityModalTarget.classList.remove("hidden")
    document.body.style.overflow = "hidden"
    
    // 清空搜索框并显示所有城市
    if (this.searchInputTarget) {
      this.searchInputTarget.value = ""
      this.showAllCities()
    }
  }

  // 关闭城市选择器
  closeCitySelector(event: Event): void {
    event.preventDefault()
    this.cityModalTarget.classList.add("hidden")
    document.body.style.overflow = ""
  }

  // 选择城市
  selectCity(event: Event): void {
    event.preventDefault()
    const button = event.currentTarget as HTMLButtonElement
    const cityName = button.dataset.cityName

    if (cityName) {
      // 更新显示的城市名称
      this.cityNameTarget.textContent = cityName
      
      // 关闭模态框
      this.closeCitySelector(event)
      
      // 重新加载页面，传递新的城市参数
      const currentDate = this.getCurrentDate()
      const currentTab = this.getCurrentTab()
      window.location.href = `/chartered_tours/search?city=${encodeURIComponent(cityName)}&departure_date=${currentDate}&tab=${currentTab}`
    }
  }

  // 选择热门城市
  selectHotCity(event: Event): void {
    event.preventDefault()
    const button = event.currentTarget as HTMLButtonElement
    const cityName = button.dataset.cityName

    if (cityName) {
      // 直接导航到新城市页面
      const currentDate = this.getCurrentDate()
      const currentTab = this.getCurrentTab()
      window.location.href = `/chartered_tours/search?city=${encodeURIComponent(cityName)}&departure_date=${currentDate}&tab=${currentTab}`
    }
  }

  // 过滤城市列表（实时搜索）
  filterCities(event: Event): void {
    const searchTerm = (event.target as HTMLInputElement).value.toLowerCase().trim()
    
    if (!searchTerm) {
      this.showAllCities()
      return
    }
    
    // 获取所有城市组和城市按钮
    const cityGroups = this.citiesListTarget.querySelectorAll('.city-group')
    
    cityGroups.forEach((group: Element) => {
      const groupElement = group as HTMLElement
      const cityButtons = groupElement.querySelectorAll('.city-item')
      let hasVisibleCity = false
      
      cityButtons.forEach((button: Element) => {
        const btnElement = button as HTMLButtonElement
        const cityName = (btnElement.dataset.cityDisplay || '').toLowerCase()
        const cityPinyin = (btnElement.dataset.cityPinyin || '').toLowerCase()
        
        // 匹配中文名或拼音
        const matches = cityName.includes(searchTerm) || cityPinyin.includes(searchTerm)
        
        if (matches) {
          btnElement.style.display = ''
          hasVisibleCity = true
        } else {
          btnElement.style.display = 'none'
        }
      })
      
      // 如果该地区没有匹配的城市，隐藏整个地区组
      groupElement.style.display = hasVisibleCity ? '' : 'none'
    })
  }

  // 显示所有城市
  private showAllCities(): void {
    const cityGroups = this.citiesListTarget.querySelectorAll('.city-group')
    const cityButtons = this.citiesListTarget.querySelectorAll('.city-item')
    
    cityGroups.forEach((group: Element) => {
      (group as HTMLElement).style.display = ''
    })
    cityButtons.forEach((button: Element) => {
      (button as HTMLElement).style.display = ''
    })
  }

  // 立即包车 - 跳转到路线列表或直接预订
  startBooking(event: Event): void {
    event.preventDefault()
    
    // 获取当前选择的城市和日期
    const city = this.getCurrentCity()
    const date = this.getCurrentDate()
    
    // 跳转到charter_routes搜索页面
    window.location.href = `/charter_routes/search?city=${encodeURIComponent(city)}&departure_date=${date}`
  }

  // 获取当前选择的城市
  private getCurrentCity(): string {
    return this.cityNameTarget.textContent?.trim() || '武汉'
  }

  // 获取当前选择的日期（从URL参数或dateDisplay目标）
  private getCurrentDate(): string {
    const urlParams = new URLSearchParams(window.location.search)
    // 支持两种参数名：departure_date（新）和 date（兼容旧版）
    const dateParam = urlParams.get('departure_date') || urlParams.get('date')
    
    if (dateParam) {
      return dateParam
    }
    
    // 默认返回明天的日期
    const tomorrow = new Date()
    tomorrow.setDate(tomorrow.getDate() + 1)
    return tomorrow.toISOString().split('T')[0]
  }

  // 获取当前激活的Tab
  private getCurrentTab(): string {
    const urlParams = new URLSearchParams(window.location.search)
    return urlParams.get('tab') || 'recommend'
  }

  // 点击模态框背景关闭
  closeOnBackdrop(event: Event): void {
    const target = event.target as HTMLElement
    if (target === this.cityModalTarget) {
      this.closeCitySelector(event)
    }
    // Note: dateModal is handled by date-picker controller
  }

  // 组件断开连接时清理
  disconnect(): void {
    document.body.style.overflow = ""
  }
}
