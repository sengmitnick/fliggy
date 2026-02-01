import { Controller } from "@hotwired/stimulus"

// 包车游搜索页面控制器
// 处理城市选择、日期选择、立即包车等交互
export default class extends Controller {
  static targets = ["cityName", "dateDisplay", "cityModal", "dateModal"]

  declare readonly cityNameTarget: HTMLElement
  declare readonly dateDisplayTarget: HTMLElement
  declare readonly cityModalTarget: HTMLElement
  declare readonly dateModalTarget: HTMLElement

  // 打开城市选择器
  openCitySelector(event: Event): void {
    event.preventDefault()
    this.cityModalTarget.classList.remove("hidden")
    document.body.style.overflow = "hidden"
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
      window.location.href = `/chartered_tours/search?city=${encodeURIComponent(cityName)}&date=${currentDate}&tab=${currentTab}`
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
      window.location.href = `/chartered_tours/search?city=${encodeURIComponent(cityName)}&date=${currentDate}&tab=${currentTab}`
    }
  }

  // 打开日期选择器
  openDatePicker(event: Event): void {
    event.preventDefault()
    this.dateModalTarget.classList.remove("hidden")
    document.body.style.overflow = "hidden"
  }

  // 关闭日期选择器
  closeDatePicker(event: Event): void {
    event.preventDefault()
    this.dateModalTarget.classList.add("hidden")
    document.body.style.overflow = ""
  }

  // 选择日期
  selectDate(event: Event): void {
    event.preventDefault()
    const button = event.currentTarget as HTMLButtonElement
    const dateStr = button.dataset.date

    if (dateStr) {
      // 解析日期并格式化显示
      const date = new Date(dateStr)
      const month = date.getMonth() + 1
      const day = date.getDate()
      this.dateDisplayTarget.textContent = `${month}月${day}日 出发`
      
      // 关闭模态框
      this.closeDatePicker(event)
      
      // 重新加载页面，传递新的日期参数
      const currentCity = this.getCurrentCity()
      const currentTab = this.getCurrentTab()
      window.location.href = `/chartered_tours/search?city=${encodeURIComponent(currentCity)}&date=${dateStr}&tab=${currentTab}`
    }
  }

  // 立即包车 - 跳转到路线列表或直接预订
  startBooking(event: Event): void {
    event.preventDefault()
    
    // 获取当前选择的城市和日期
    const city = this.getCurrentCity()
    const date = this.getCurrentDate()
    
    // 跳转到charter_routes搜索页面
    window.location.href = `/charter_routes/search?city=${encodeURIComponent(city)}&date=${date}`
  }

  // 获取当前选择的城市
  private getCurrentCity(): string {
    return this.cityNameTarget.textContent?.trim() || '武汉'
  }

  // 获取当前选择的日期（从URL参数或dateDisplay目标）
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
    } else if (target === this.dateModalTarget) {
      this.closeDatePicker(event)
    }
  }

  // 组件断开连接时清理
  disconnect(): void {
    document.body.style.overflow = ""
  }
}
