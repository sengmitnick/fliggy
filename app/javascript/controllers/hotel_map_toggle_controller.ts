import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = ["mapContainer", "closeButton", "expandButton"]
  
  declare readonly mapContainerTarget: HTMLElement
  declare readonly closeButtonTarget: HTMLElement
  declare readonly expandButtonTarget: HTMLElement
  
  private isExpanded: boolean = false

  connect(): void {
    console.log("HotelMapToggle connected")
  }

  toggle(): void {
    this.isExpanded = !this.isExpanded
    
    if (this.isExpanded) {
      // 扩大地图
      this.mapContainerTarget.style.height = "600px"
      this.expandButtonTarget.classList.add("hidden")
      this.closeButtonTarget.classList.remove("hidden")
      
      // 滚动到地图顶部
      this.mapContainerTarget.scrollIntoView({ behavior: 'smooth', block: 'start' })
    } else {
      // 缩小地图
      this.mapContainerTarget.style.height = "128px"
      this.expandButtonTarget.classList.remove("hidden")
      this.closeButtonTarget.classList.add("hidden")
    }
  }

  // 从外部按钮（如定位按钮）触发地图扩展
  toggleAndScroll(event: Event): void {
    event.preventDefault()
    
    // 查找页面上的地图容器
    const mapContainer = document.querySelector('[data-hotel-map-toggle-target="mapContainer"]') as HTMLElement
    if (!mapContainer) {
      console.error("找不到地图容器")
      return
    }
    
    // 查找地图控制器实例
    const mapController = this.application.getControllerForElementAndIdentifier(
      mapContainer.closest('[data-controller~="hotel-map-toggle"]') as HTMLElement,
      "hotel-map-toggle"
    ) as any
    
    if (mapController) {
      // 如果地图已展开，则不做任何操作
      if (mapController.isExpanded) {
        mapContainer.scrollIntoView({ behavior: 'smooth', block: 'start' })
      } else {
        // 触发地图展开
        mapController.toggle()
      }
    } else {
      console.error("找不到地图控制器")
    }
  }
}
