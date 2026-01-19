import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = ["dropdown", "overlay"]

  declare readonly dropdownTargets: HTMLElement[]
  declare readonly overlayTarget: HTMLElement

  private activeDropdown: HTMLElement | null = null

  connect(): void {
    console.log("FilterDropdown connected")
  }

  disconnect(): void {
    this.closeAllDropdowns()
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
      this.closeAllDropdowns()
      return
    }

    // 关闭其他下拉菜单，打开当前的
    this.closeAllDropdowns()
    this.openDropdown(dropdown)
  }

  // 打开下拉菜单
  private openDropdown(dropdown: HTMLElement): void {
    this.activeDropdown = dropdown
    dropdown.classList.remove('hidden')
    this.overlayTarget.classList.remove('hidden')
  }

  // 关闭所有下拉菜单
  closeAllDropdowns(): void {
    this.dropdownTargets.forEach(dropdown => {
      dropdown.classList.add('hidden')
    })
    this.overlayTarget.classList.add('hidden')
    this.activeDropdown = null
  }

  // 点击遮罩层关闭
  closeOnOverlay(): void {
    this.closeAllDropdowns()
  }

  // 选择选项后关闭（可选）
  selectOption(): void {
    // 延迟关闭，让链接有时间导航
    setTimeout(() => this.closeAllDropdowns(), 100)
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
