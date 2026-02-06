import { Controller } from "@hotwired/stimulus"

/**
 * 用车时间选择器控制器
 * 
 * 功能：
 * - 提供 iOS 风格的滚动式日期时间选择器
 * - 支持日期、小时、分钟的精确选择
 * - 通过滚动交互选择时间（CSS scroll-snap 实现吸附效果）
 * - 将选择的时间显示在触发按钮上
 * 
 * 使用场景：
 * - "送我到机场/车站" 模式下选择用车时间
 * - 用户需要提前预约接送服务的时间
 * 
 * 技术实现：
 * - 三列滚动选择器：日期 | 小时 | 分钟
 * - 每个选项高度固定为 48px (Tailwind h-12)
 * - 使用 scroll 事件监听并计算当前选中的值
 * - 选中项居中显示，带有高亮背景条
 */
export default class extends Controller {
  static targets = ["modal", "dateScroll", "hourScroll", "minuteScroll"]

  declare readonly modalTarget: HTMLElement          // 弹窗容器
  declare readonly dateScrollTarget: HTMLElement     // 日期滚动列
  declare readonly hourScrollTarget: HTMLElement     // 小时滚动列
  declare readonly minuteScrollTarget: HTMLElement   // 分钟滚动列

  // 当前选中的值
  private selectedDate: string = ""      // 格式: "2024-01-15"
  private selectedHour: number = 0       // 范围: 0-23
  private selectedMinute: number = 0     // 范围: 0-59
  
  private displayElement: HTMLElement | null = null  // 用于显示选中时间的 <h2> 元素
  private isScrolling: boolean = false               // 滚动状态标志（当前未使用，预留）

  /**
   * 打开时间选择器弹窗
   * 
   * 流程：
   * 1. 保存触发按钮的显示元素引用（用于后续更新显示文本）
   * 2. 显示弹窗并锁定 body 滚动
   * 3. 初始化为当前时间
   * 4. 滚动到对应的初始位置（今天、当前小时、当前分钟）
   */
  openModal(event: Event): void {
    event.preventDefault()
    
    // 保存触发按钮内的 <h2> 元素引用，用于后续显示选中的时间
    const button = event.currentTarget as HTMLElement
    this.displayElement = button.closest('.flex-1')?.querySelector('h2') || null
    
    // 显示弹窗
    this.modalTarget.classList.remove("hidden")
    document.body.style.overflow = "hidden"  // 阻止背景页面滚动
    
    // 初始化为当前时间
    const now = new Date()
    this.selectedDate = new Date(now.getFullYear(), now.getMonth(), now.getDate()).toISOString().split('T')[0]
    this.selectedHour = now.getHours()
    this.selectedMinute = now.getMinutes()
    
    // 延迟执行滚动，确保 DOM 已经渲染完成
    setTimeout(() => {
      this.scrollToDate(0)                   // 滚动到今天（索引 0）
      this.scrollToHour(this.selectedHour)   // 滚动到当前小时
      this.scrollToMinute(this.selectedMinute) // 滚动到当前分钟
    }, 100)
  }

  /**
   * 关闭时间选择器弹窗
   * 
   * 功能：
   * - 隐藏弹窗
   * - 恢复 body 滚动
   */
  closeModal(event?: Event): void {
    if (event) {
      event.preventDefault()
    }
    this.modalTarget.classList.add("hidden")
    document.body.style.overflow = ""  // 恢复背景页面滚动
  }

  /**
   * 阻止事件冒泡
   * 
   * 用途：
   * - 点击弹窗内容区域时，阻止事件冒泡到背景遮罩
   * - 防止点击弹窗内容时意外关闭弹窗
   */
  stopPropagation(event: Event): void {
    event.stopPropagation()
  }

  /**
   * 滚动到指定日期（按索引）
   * 
   * @param index - 日期索引（0=今天, 1=明天, 2=后天, ...）
   * 
   * 计算方式：
   * - 每个选项高度 = 48px
   * - scrollTop = index * 48
   */
  scrollToDate(index: number): void {
    const itemHeight = 48 // h-12 = 48px
    const scrollTop = index * itemHeight
    this.dateScrollTarget.scrollTop = scrollTop
  }

  /**
   * 滚动到指定小时
   * 
   * @param hour - 小时值（0-23）
   */
  scrollToHour(hour: number): void {
    const itemHeight = 48
    const scrollTop = hour * itemHeight
    this.hourScrollTarget.scrollTop = scrollTop
  }

  /**
   * 滚动到指定分钟
   * 
   * @param minute - 分钟值（0-59）
   */
  scrollToMinute(minute: number): void {
    const itemHeight = 48
    const scrollTop = minute * itemHeight
    this.minuteScrollTarget.scrollTop = scrollTop
  }

  /**
   * 更新选中的日期
   * 
   * 触发时机：用户滚动日期列时
   * 
   * 计算逻辑：
   * 1. 获取当前滚动位置 scrollTop
   * 2. 计算选中项索引 = Math.round(scrollTop / 48)
   * 3. 从对应的 DOM 元素中读取 data-date 属性
   */
  updateDate(): void {
    if (this.isScrolling) return
    
    const scrollTop = this.dateScrollTarget.scrollTop
    const itemHeight = 48
    const index = Math.round(scrollTop / itemHeight)
    
    const items = this.dateScrollTarget.querySelectorAll('[data-date]')
    if (items[index]) {
      const dateElement = items[index] as HTMLElement
      this.selectedDate = dateElement.dataset.date || ""
    }
  }

  /**
   * 更新选中的小时
   * 
   * 触发时机：用户滚动小时列时
   * 
   * 计算逻辑：
   * 1. 计算索引 = Math.round(scrollTop / 48)
   * 2. 限制范围在 0-23 之间
   */
  updateHour(): void {
    if (this.isScrolling) return
    
    const scrollTop = this.hourScrollTarget.scrollTop
    const itemHeight = 48
    const hour = Math.round(scrollTop / itemHeight)
    
    this.selectedHour = Math.max(0, Math.min(23, hour))
  }

  /**
   * 更新选中的分钟
   * 
   * 触发时机：用户滚动分钟列时
   * 
   * 计算逻辑：
   * 1. 计算索引 = Math.round(scrollTop / 48)
   * 2. 限制范围在 0-59 之间
   */
  updateMinute(): void {
    if (this.isScrolling) return
    
    const scrollTop = this.minuteScrollTarget.scrollTop
    const itemHeight = 48
    const minute = Math.round(scrollTop / itemHeight)
    
    this.selectedMinute = Math.max(0, Math.min(59, minute))
  }

  /**
   * 确认选择时间
   * 
   * 流程：
   * 1. 验证日期是否已选择
   * 2. 读取当前滚动位置对应的日期文本（"今天 01/15" 或 "01月15日 周一"）
   * 3. 格式化时间为 "HH:MM" 格式
   * 4. 拼接完整的显示文本
   * 5. 更新触发按钮的显示文本
   * 6. 关闭弹窗并显示提示
   * 
   * 显示格式示例：
   * - "今天 01/15 14:30"
   * - "明天 01/16 09:00"
   * - "01月17日 周三 18:45"
   */
  confirm(event: Event): void {
    event.preventDefault()

    // 验证：确保日期已选择
    if (!this.selectedDate) {
      window.showToast('请选择日期')
      return
    }

    // 读取日期文本（从滚动位置对应的 DOM 元素中获取）
    const scrollTop = this.dateScrollTarget.scrollTop
    const itemHeight = 48
    const index = Math.round(scrollTop / itemHeight)
    const items = this.dateScrollTarget.querySelectorAll('[data-date]')
    
    let dateText = ""
    if (items[index]) {
      const span = items[index].querySelector('span')
      if (span) {
        dateText = span.textContent || ""
      }
    }

    // 格式化时间：补零到两位数（例如："09:05"）
    const timeText = `${String(this.selectedHour).padStart(2, '0')}:${String(this.selectedMinute).padStart(2, '0')}`
    
    // 拼接完整的显示文本
    const displayText = `${dateText} ${timeText}`

    // 更新触发按钮的显示文本
    if (this.displayElement) {
      this.displayElement.textContent = displayText
      // 更新样式：从灰色占位文本变为黑色正常文本
      this.displayElement.classList.remove('text-text-muted')
      this.displayElement.classList.add('text-text-primary')
    }

    // 注意：这里没有使用隐藏的 <input> 存储值
    // 因为 transfer_search_controller.ts 会直接读取显示文本来验证
    // 如果将来需要提交表单，可以在这里添加隐藏字段存储 ISO 格式的日期时间
    
    this.closeModal()
    window.showToast('用车时间已选择')
  }
}
