import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = [
    "modal",
    "overlay",
    "departureCity",
    "destinationCity",
    "adultsCount",
    "childrenCount",
    "eldersCount",
    "daysCount",
    "departureCityInput",
    "destinationCityInput",
    "adultsInput",
    "childrenInput",
    "eldersInput",
    "daysInput",
    "departureDateDisplay",
    "departureDateInput",
    "datePicker",
    "currentMonth",
    "calendarGrid",
    "contactTimeDisplay",
    "contactTimeInput",
    "contactTimePicker",
    "phoneInput"
  ]

  declare readonly modalTarget: HTMLElement
  declare readonly overlayTarget: HTMLElement
  declare readonly departureCityTarget: HTMLElement
  declare readonly destinationCityTarget: HTMLElement
  declare readonly adultsCountTarget: HTMLElement
  declare readonly childrenCountTarget: HTMLElement
  declare readonly eldersCountTarget: HTMLElement
  declare readonly daysCountTarget: HTMLElement
  declare readonly departureCityInputTarget: HTMLInputElement
  declare readonly destinationCityInputTarget: HTMLInputElement
  declare readonly adultsInputTarget: HTMLInputElement
  declare readonly childrenInputTarget: HTMLInputElement
  declare readonly eldersInputTarget: HTMLInputElement
  declare readonly daysInputTarget: HTMLInputElement
  declare readonly departureDateDisplayTarget: HTMLElement
  declare readonly departureDateInputTarget: HTMLInputElement
  declare readonly datePickerTarget: HTMLElement
  declare readonly currentMonthTarget: HTMLElement
  declare readonly calendarGridTarget: HTMLElement
  declare readonly contactTimeDisplayTarget: HTMLElement
  declare readonly contactTimeInputTarget: HTMLInputElement
  declare readonly contactTimePickerTarget: HTMLElement
  declare readonly phoneInputTarget: HTMLInputElement

  private currentDate: Date = new Date()
  private selectedDate: Date | null = null
  private isInitialized: boolean = false

  connect(): void {
    console.log("CustomTravelModal connected")
    // Don't render calendar on connect - wait until modal is opened
  }

  // 打开弹窗
  open(event: Event): void {
    // Get destination from button data attribute
    const button = event.currentTarget as HTMLElement
    const destination = button.dataset.destination
    
    // If destination is provided, set it and make it readonly
    if (destination) {
      this.destinationCityTarget.textContent = destination
      this.destinationCityInputTarget.value = destination
    }
    
    // Initialize calendar on first open
    if (!this.isInitialized) {
      this.renderCalendar()
      this.isInitialized = true
    }
    
    this.modalTarget.classList.remove('hidden')
    this.overlayTarget.classList.remove('hidden')
    document.body.style.overflow = 'hidden'
  }

  // 关闭弹窗
  close(): void {
    this.modalTarget.classList.add('hidden')
    this.overlayTarget.classList.add('hidden')
    document.body.style.overflow = ''
  }

  // 点击遮罩层关闭
  closeOnOverlay(event: Event): void {
    if (event.target === this.overlayTarget) {
      this.close()
    }
  }

  // 增加成人数量
  increaseAdults(): void {
    const current = parseInt(this.adultsInputTarget.value) || 0
    this.adultsInputTarget.value = (current + 1).toString()
    this.adultsCountTarget.textContent = (current + 1).toString()
  }

  // 减少成人数量
  decreaseAdults(): void {
    const current = parseInt(this.adultsInputTarget.value) || 0
    if (current > 0) {
      this.adultsInputTarget.value = (current - 1).toString()
      this.adultsCountTarget.textContent = (current - 1).toString()
    }
  }

  // 增加儿童数量
  increaseChildren(): void {
    const current = parseInt(this.childrenInputTarget.value) || 0
    this.childrenInputTarget.value = (current + 1).toString()
    this.childrenCountTarget.textContent = (current + 1).toString()
  }

  // 减少儿童数量
  decreaseChildren(): void {
    const current = parseInt(this.childrenInputTarget.value) || 0
    if (current > 0) {
      this.childrenInputTarget.value = (current - 1).toString()
      this.childrenCountTarget.textContent = (current - 1).toString()
    }
  }

  // 增加老人数量
  increaseElders(): void {
    const current = parseInt(this.eldersInputTarget.value) || 0
    this.eldersInputTarget.value = (current + 1).toString()
    this.eldersCountTarget.textContent = (current + 1).toString()
  }

  // 减少老人数量
  decreaseElders(): void {
    const current = parseInt(this.eldersInputTarget.value) || 0
    if (current > 0) {
      this.eldersInputTarget.value = (current - 1).toString()
      this.eldersCountTarget.textContent = (current - 1).toString()
    }
  }

  // 增加天数
  increaseDays(): void {
    const current = parseInt(this.daysInputTarget.value) || 0
    this.daysInputTarget.value = (current + 1).toString()
    this.daysCountTarget.textContent = (current + 1).toString()
  }

  // 减少天数
  decreaseDays(): void {
    const current = parseInt(this.daysInputTarget.value) || 0
    if (current > 1) {
      this.daysInputTarget.value = (current - 1).toString()
      this.daysCountTarget.textContent = (current - 1).toString()
    }
  }

  // 选择出发城市
  selectDepartureCity(event: Event): void {
    const target = event.currentTarget as HTMLElement
    const city = target.dataset.city || ''
    this.departureCityTarget.textContent = city
    this.departureCityInputTarget.value = city
  }

  // 选择目的地城市
  selectDestinationCity(event: Event): void {
    const target = event.currentTarget as HTMLElement
    const city = target.dataset.city || ''
    this.destinationCityTarget.textContent = city
    this.destinationCityInputTarget.value = city
  }

  // 切换日期选择器
  toggleDatePicker(): void {
    this.datePickerTarget.classList.toggle('hidden')
  }

  // 切换联系时间选择器
  toggleContactTimePicker(): void {
    this.contactTimePickerTarget.classList.remove('hidden')
    document.body.style.overflow = 'hidden'
  }

  // 关闭联系时间选择器
  closeContactTimePicker(): void {
    this.contactTimePickerTarget.classList.add('hidden')
    document.body.style.overflow = 'hidden' // Keep main modal scroll locked
  }

  // 选择联系时间
  selectContactTime(event: Event): void {
    const target = event.currentTarget as HTMLElement
    const time = target.dataset.time || ''
    this.contactTimeDisplayTarget.textContent = time
    this.contactTimeInputTarget.value = time
    this.closeContactTimePicker()
  }

  // 清除手机号
  clearPhone(): void {
    this.phoneInputTarget.value = ''
    this.phoneInputTarget.focus()
  }

  // 上一个月
  previousMonth(): void {
    this.currentDate.setMonth(this.currentDate.getMonth() - 1)
    this.renderCalendar()
  }

  // 下一个月
  nextMonth(): void {
    this.currentDate.setMonth(this.currentDate.getMonth() + 1)
    this.renderCalendar()
  }

  // 渲染日历
  private renderCalendar(): void {
    const year = this.currentDate.getFullYear()
    const month = this.currentDate.getMonth()
    
    // 更新月份显示
    this.currentMonthTarget.textContent = `${year}年${month + 1}月`
    
    // 获取当月第一天和最后一天
    const firstDay = new Date(year, month, 1)
    const lastDay = new Date(year, month + 1, 0)
    const daysInMonth = lastDay.getDate()
    const startDayOfWeek = firstDay.getDay()
    
    // 清空日历网格
    this.calendarGridTarget.innerHTML = ''
    
    // 添加空白占位符（月份开始前的空白）
    for (let i = 0; i < startDayOfWeek; i++) {
      const emptyDiv = document.createElement('div')
      this.calendarGridTarget.appendChild(emptyDiv)
    }
    
    // 添加日期按钮
    const today = new Date()
    today.setHours(0, 0, 0, 0)
    
    for (let day = 1; day <= daysInMonth; day++) {
      const dateButton = document.createElement('button')
      dateButton.type = 'button'
      dateButton.textContent = day.toString()
      dateButton.className = 'w-8 h-8 rounded-full text-xs hover:bg-gray-100 transition-colors'
      
      const currentDateInLoop = new Date(year, month, day)
      currentDateInLoop.setHours(0, 0, 0, 0)
      
      // 禁用过去的日期
      if (currentDateInLoop < today) {
        dateButton.disabled = true
        dateButton.className = 'w-8 h-8 rounded-full text-xs text-gray-300 cursor-not-allowed'
      } else {
        // 高亮已选择的日期
        if (this.selectedDate && 
            currentDateInLoop.getTime() === this.selectedDate.getTime()) {
          dateButton.className = 'w-8 h-8 rounded-full text-xs bg-[#FFD700] text-gray-800 font-bold'
        }
        
        dateButton.addEventListener('click', () => {
          this.selectDate(currentDateInLoop)
        })
      }
      
      this.calendarGridTarget.appendChild(dateButton)
    }
  }

  // 选择日期
  private selectDate(date: Date): void {
    this.selectedDate = date
    
    // 格式化日期显示
    const year = date.getFullYear()
    const month = (date.getMonth() + 1).toString().padStart(2, '0')
    const day = date.getDate().toString().padStart(2, '0')
    const formattedDate = `${year}-${month}-${day}`
    
    // 更新显示
    this.departureDateDisplayTarget.textContent = `${month}月${day}日`
    this.departureDateDisplayTarget.classList.remove('text-gray-400')
    this.departureDateDisplayTarget.classList.add('text-gray-800', 'font-medium')
    
    // 更新隐藏输入框
    this.departureDateInputTarget.value = formattedDate
    
    // 关闭日期选择器
    this.datePickerTarget.classList.add('hidden')
    
    // 重新渲染日历以高亮选中的日期
    this.renderCalendar()
  }
}
