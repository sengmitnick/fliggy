import { Controller } from "@hotwired/stimulus"

// 包车路线搜索页面控制器
// 处理城市选择和日期选择
export default class extends Controller {
  static targets = ["cityName", "dateDisplay", "cityModal", "searchInput", "citiesList"]

  declare readonly cityNameTarget: HTMLElement
  declare readonly dateDisplayTarget: HTMLElement
  declare readonly cityModalTarget: HTMLElement
  declare readonly searchInputTarget: HTMLInputElement
  declare readonly citiesListTarget: HTMLElement

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
      const currentCategory = this.getCurrentCategory()
      window.location.href = `/charter_routes/search?city=${encodeURIComponent(cityName)}&date=${currentDate}&category=${currentCategory}`
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

  // 获取当前选择的城市
  private getCurrentCity(): string {
    return this.cityNameTarget.textContent?.trim() || '武汉'
  }

  // 获取当前选择的日期（从URL参数）
  private getCurrentDate(): string {
    const urlParams = new URLSearchParams(window.location.search)
    const dateParam = urlParams.get('date')
    
    if (dateParam) {
      return dateParam
    }
    
    // 默认返回明天的日期
    const tomorrow = new Date()
    tomorrow.setDate(tomorrow.getDate() + 1)
    return tomorrow.toISOString().split('T')[0]
  }

  // 获取当前选择的类别
  private getCurrentCategory(): string {
    const urlParams = new URLSearchParams(window.location.search)
    return urlParams.get('category') || 'all'
  }

  // 点击模态框背景关闭
  closeOnBackdrop(event: Event): void {
    const target = event.target as HTMLElement
    if (target === this.cityModalTarget) {
      this.closeCitySelector(event)
    }
  }

  // 组件断开连接时清理
  disconnect(): void {
    document.body.style.overflow = ""
  }
}
