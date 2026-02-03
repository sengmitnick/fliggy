import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = ["dropdown", "overlay"]

  declare readonly dropdownTargets: HTMLElement[]
  declare readonly hasOverlayTarget: boolean
  declare readonly overlayTarget: HTMLElement

  private activeDropdown: HTMLElement | null = null

  connect(): void {
    console.log("FilterDropdown connected")
  }

  disconnect(): void {
    this.closeAll()
  }

  // 切换下拉菜单
  toggle(event: Event): void {
    const button = event.currentTarget as HTMLElement
    const dropdownId = button.dataset.dropdownId
    if (!dropdownId) return

    const dropdown = this.dropdownTargets.find(el => el.dataset.dropdownId === dropdownId)
    if (!dropdown) return

    // 如果点击的是已打开的下拉菜单，则关闭它
    if (this.activeDropdown === dropdown) {
      this.closeAll()
      return
    }

    // 关闭其他下拉菜单，打开当前的
    this.closeAll()
    this.openDropdown(dropdown, button)
  }

  // 打开下拉菜单
  private openDropdown(dropdown: HTMLElement, button: HTMLElement): void {
    this.activeDropdown = dropdown
    dropdown.classList.remove('hidden')
    
    // 智能定位：根据按钮位置调整弹窗
    this.adjustDropdownPosition(dropdown, button)
    
    if (this.hasOverlayTarget) {
      this.overlayTarget.classList.remove('hidden')
    }
  }

  // 智能定位逻辑
  private adjustDropdownPosition(dropdown: HTMLElement, button: HTMLElement): void {
    // 跳过fixed定位的弹窗（如出发地大弹窗）
    if (dropdown.classList.contains('fixed')) {
      return
    }

    const buttonRect = button.getBoundingClientRect()
    const dropdownWidth = dropdown.offsetWidth
    const viewportWidth = window.innerWidth
    
    // 计算按钮中心点相对于屏幕的位置
    const buttonCenter = buttonRect.left + buttonRect.width / 2
    const screenCenter = viewportWidth / 2
    
    // 清除所有定位相关的类
    dropdown.classList.remove('left-0', 'right-0', 'left-1/2', '-translate-x-1/2')
    dropdown.style.left = ''
    dropdown.style.right = ''
    dropdown.style.transform = ''
    
    // 判断按钮在屏幕的哪一侧
    if (buttonCenter < screenCenter) {
      // 按钮在屏幕左侧，弹窗左对齐
      dropdown.classList.add('left-0')
    } else {
      // 按钮在屏幕右侧，弹窗右对齐
      dropdown.classList.add('right-0')
    }
    
    // 额外检查：确保弹窗不超出屏幕
    requestAnimationFrame(() => {
      const dropdownRect = dropdown.getBoundingClientRect()
      
      // 如果弹窗超出左侧
      if (dropdownRect.left < 0) {
        dropdown.classList.remove('right-0')
        dropdown.classList.add('left-0')
      }
      
      // 如果弹窗超出右侧
      if (dropdownRect.right > viewportWidth) {
        dropdown.classList.remove('left-0')
        dropdown.classList.add('right-0')
      }
    })
  }

  // 关闭所有下拉菜单
  closeAll(): void {
    this.dropdownTargets.forEach(dropdown => {
      dropdown.classList.add('hidden')
    })
    if (this.hasOverlayTarget) {
      this.overlayTarget.classList.add('hidden')
    }
    this.activeDropdown = null
  }

  // 点击遮罩层关闭
  closeOnOverlay(): void {
    this.closeAll()
  }

  // 选择选项后关闭（可选）
  selectOption(): void {
    // 延迟关闭，让链接有时间导航
    setTimeout(() => this.closeAll(), 100)
  }

  // 切换分组的展开/收起
  toggleGroup(event: Event): void {
    event.preventDefault()
    const button = event.currentTarget as HTMLElement
    const groupIndex = button.dataset.groupIndex
    if (!groupIndex) return

    const groupElement = this.element.querySelector(`[data-group="${groupIndex}"]`) as HTMLElement
    if (!groupElement) return

    const svg = button.querySelector('svg')
    if (!svg) return

    if (groupElement.classList.contains('hidden')) {
      groupElement.classList.remove('hidden')
      svg.style.transform = 'rotate(0deg)'
    } else {
      groupElement.classList.add('hidden')
      svg.style.transform = 'rotate(-90deg)'
    }
  }
}
