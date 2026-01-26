import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = [
    "productCard",
    "dateModal",
    "countModal",
    "calendarModal",
    "adultCount",
    "childCount",
    "selectedDate",
    "totalPrice"
  ]

  static values = {
    guideId: String,
    selectedDate: String,
    adultCount: Number,
    childCount: Number,
    pricePerPerson: Number
  }

  declare readonly productCardTargets: HTMLElement[]
  declare readonly dateModalTarget?: HTMLElement
  declare readonly countModalTarget?: HTMLElement
  declare readonly calendarModalTarget?: HTMLElement
  declare readonly adultCountTarget?: HTMLElement
  declare readonly childCountTarget?: HTMLElement
  declare readonly selectedDateTarget?: HTMLElement
  declare readonly totalPriceTarget?: HTMLElement
  
  declare guideIdValue: string
  declare selectedDateValue: string
  declare adultCountValue: number
  declare childCountValue: number
  declare pricePerPersonValue: number

  connect(): void {
    console.log("DeepBooking controller connected")
    // Initialize default values
    this.adultCountValue = 1
    this.childCountValue = 0
    
    // Get price from first product card if available
    if (this.productCardTargets && this.productCardTargets.length > 0) {
      const priceElement = this.productCardTargets[0].querySelector('.text-xl.font-bold.text-\\[\\#ff5336\\]')
      if (priceElement) {
        this.pricePerPersonValue = parseInt(priceElement.textContent || "192")
      } else {
        this.pricePerPersonValue = 192
      }
    } else {
      this.pricePerPersonValue = 192
    }
  }

  disconnect(): void {
    console.log("DeepBooking disconnected")
  }

  // 选择日期
  selectDate(event: Event): void {
    const button = event.currentTarget as HTMLButtonElement
    const date = button.dataset.date
    
    if (!date) return
    
    this.selectedDateValue = date
    console.log("Selected date:", date)
    
    // Update UI to show selected date
    const dateButtons = this.element.querySelectorAll('[data-action*="selectDate"]')
    dateButtons.forEach((btn) => {
      btn.classList.remove('bg-[#ffeeb8]', 'border-[#ffeeb8]')
      btn.classList.add('bg-[#f5f7fa]')
    })
    
    button.classList.remove('bg-[#f5f7fa]')
    button.classList.add('bg-[#ffeeb8]', 'border-[#ffeeb8]')
  }

  // 打开日历弹窗
  openCalendar(event: Event): void {
    event.preventDefault()
    console.log("Opening calendar modal")
    
    // Create calendar modal
    this.createCalendarModal()
  }

  // 创建日历模态框
  async createCalendarModal(): Promise<void> {
    const today = new Date()
    const startDate = new Date(today.getFullYear(), today.getMonth(), 1)
    const endDate = new Date(today.getFullYear(), today.getMonth() + 2, 0) // 2个月后
    
    console.log('[Calendar] Fetching available dates:', {
      guideId: this.guideIdValue,
      startDate: this.formatDate(startDate),
      endDate: this.formatDate(endDate)
    })
    
    // 从后端API获取可约日期
    let availableDates: Set<string>
    try {
      const url = `/deep_travels/${this.guideIdValue}/available_dates?start_date=${this.formatDate(startDate)}&end_date=${this.formatDate(endDate)}`
      console.log('[Calendar] Fetching URL:', url)
      
      const response = await fetch(url)
      console.log('[Calendar] Response status:', response.status)
      
      const data = await response.json()
      console.log('[Calendar] Response data:', data)
      
      availableDates = new Set(data.available_dates)
      console.log('[Calendar] Available dates count:', availableDates.size)
    } catch (error) {
      console.error('[Calendar] Failed to fetch available dates:', error)
      // 如果API失败，使用空集合
      availableDates = new Set()
    }
    
    const calendarHTML = this.generateCalendarHTML(startDate, endDate, today, availableDates)
    
    const modalHTML = `
      <div class="fixed inset-0 bg-white z-50 max-w-[414px] mx-auto" data-deep-booking-target="calendarModal">
        <!-- Header -->
        <div class="sticky top-0 bg-white border-b border-gray-200 z-10">
          <div class="flex items-center justify-between px-4 py-4">
            <button 
              data-action="click->deep-booking#closeCalendar" 
              class="text-2xl text-gray-600">
              ×
            </button>
            <div class="text-base font-bold">选择日期</div>
            <div class="w-8"></div>
          </div>
          
          <!-- Weekday Headers -->
          <div class="flex text-center text-sm text-gray-600 py-2 border-b border-gray-100">
            <div class="flex-1">日</div>
            <div class="flex-1">一</div>
            <div class="flex-1">二</div>
            <div class="flex-1">三</div>
            <div class="flex-1">四</div>
            <div class="flex-1">五</div>
            <div class="flex-1">六</div>
          </div>
        </div>

        <!-- Calendar Content -->
        <div class="overflow-y-auto pb-20" style="height: calc(100vh - 120px);">
          ${calendarHTML}
        </div>
      </div>
    `
    
    this.element.insertAdjacentHTML('beforeend', modalHTML)
  }

  // 生成日历HTML
  generateCalendarHTML(startDate: Date, endDate: Date, today: Date, availableDates: Set<string>): string {
    let html = ''
    let currentMonth = startDate.getMonth()
    let currentYear = startDate.getFullYear()
    
    while (currentYear < endDate.getFullYear() || 
           (currentYear === endDate.getFullYear() && currentMonth <= endDate.getMonth())) {
      
      const monthStr = `${currentYear}年${String(currentMonth + 1).padStart(2, '0')}月`
      html += `<div class="text-center py-4 text-lg font-bold text-gray-800">${monthStr}</div>`
      
      // 获取当月第一天和最后一天
      const firstDay = new Date(currentYear, currentMonth, 1)
      const lastDay = new Date(currentYear, currentMonth + 1, 0)
      
      // 生成周
      const currentDate = new Date(firstDay)
      currentDate.setDate(1 - firstDay.getDay()) // 从周日开始
      
      while (currentDate <= lastDay) {
        html += '<div class="flex">'
        
        for (let i = 0; i < 7; i++) {
          const dateStr = this.formatDate(currentDate)
          const isCurrentMonth = currentDate.getMonth() === currentMonth
          const isToday = this.formatDate(currentDate) === this.formatDate(today)
          const isAvailable = availableDates.has(dateStr)
          const isSelected = dateStr === this.selectedDateValue
          
          if (!isCurrentMonth) {
            html += '<div class="flex-1 py-3"></div>'
          } else if (!isAvailable) {
            // 不可选日期 - 灰色显示
            html += `
              <div class="flex-1 py-2 flex flex-col items-center relative opacity-40">
                <div class="text-2xl font-bold mt-3 text-gray-400">${currentDate.getDate()}</div>
                <div class="text-xs text-gray-400 mt-1">不可约</div>
              </div>
            `
          } else {
            // 可选日期
            const bgClass = isSelected ? 'bg-[#ffeeb8] rounded-lg' : ''
            const topLabel = isSelected 
              ? '<div class="absolute top-1 text-xs font-bold" style="color: #FF8C00;">已选</div>' 
              : (isToday ? '<div class="absolute top-1 text-xs text-orange-500 font-bold">今天</div>' : '')
            html += `
              <button 
                data-action="click->deep-booking#selectCalendarDate"
                data-date="${dateStr}"
                class="flex-1 py-2 flex flex-col items-center relative ${bgClass}">
                ${topLabel}
                <div class="text-2xl font-bold mt-3 ${isSelected ? 'text-gray-900' : 'text-gray-800'}">${currentDate.getDate()}</div>
                <div class="text-xs ${isSelected ? 'text-gray-900 font-bold' : 'text-green-600'} mt-1">可约</div>
              </button>
            `
          }
          
          currentDate.setDate(currentDate.getDate() + 1)
        }
        
        html += '</div>'
      }
      
      currentMonth++
      if (currentMonth > 11) {
        currentMonth = 0
        currentYear++
      }
    }
    
    return html
  }

  // 从日历中选择日期
  selectCalendarDate(event: Event): void {
    event.preventDefault()
    const button = event.currentTarget as HTMLButtonElement
    const date = button.dataset.date
    
    if (!date) return
    
    this.selectedDateValue = date
    console.log("Selected date from calendar:", date)
    
    // 更新页面上的日期按钮状态
    const dateButtons = this.element.querySelectorAll('[data-action*="selectDate"]')
    dateButtons.forEach((btn) => {
      btn.classList.remove('bg-[#ffeeb8]', 'border-[#ffeeb8]')
      btn.classList.add('bg-[#f5f7fa]')
      
      if (btn.getAttribute('data-date') === date) {
        btn.classList.remove('bg-[#f5f7fa]')
        btn.classList.add('bg-[#ffeeb8]', 'border-[#ffeeb8]')
      }
    })
    
    // 关闭日历
    this.closeCalendar()
  }

  // 关闭日历
  closeCalendar(): void {
    const modal = this.element.querySelector('[data-deep-booking-target="calendarModal"]')
    if (modal) {
      modal.remove()
    }
  }

  // 格式化日期为 YYYY-MM-DD
  formatDate(date: Date): string {
    const year = date.getFullYear()
    const month = String(date.getMonth() + 1).padStart(2, '0')
    const day = String(date.getDate()).padStart(2, '0')
    return `${year}-${month}-${day}`
  }

  // 打开人数选择弹窗
  openCountModal(event: Event): void {
    event.preventDefault()
    
    if (!this.selectedDateValue) {
      this.showToast("请先选择出行日期")
      return
    }
    
    console.log("Opening count modal")
    
    // Create modal HTML
     
    const modalHTML = `
      <div class="fixed inset-0 bg-black/60 z-50" 
           data-action="click->deep-booking#closeCountModal" 
           data-deep-booking-target="countModal">
        <div class="absolute bottom-0 w-full max-w-[414px] bg-white z-50 rounded-t-2xl px-5 pt-5 pb-8 animate-slide-up" 
             data-action="click->deep-booking#stopPropagation">
          
          <!-- 弹窗标题栏 -->
          <div class="flex justify-between items-center mb-8 relative">
            <div class="w-full text-center">
              <h3 class="text-lg font-bold text-gray-900">预约人数</h3>
            </div>
            <button class="absolute right-0 top-0 p-1" data-action="click->deep-booking#closeCountModal">
              <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="text-gray-500">
                <path d="M18 6L6 18M6 6l12 12" />
              </svg>
            </button>
          </div>

          <!-- 列表项：成人 -->
          <div class="flex justify-between items-center mb-8">
            <div>
              <div class="text-lg font-medium text-gray-900">成人</div>
              <div class="text-sm text-gray-400 mt-1">单价: ¥${this.pricePerPersonValue}</div>
            </div>
            <div class="flex items-center gap-4">
              <button class="w-7 h-7 rounded-full border flex items-center justify-center transition-colors ${
  this.adultCountValue <= 1
    ? 'border-gray-300 text-gray-300 cursor-not-allowed'
    : 'border-blue-custom text-blue-custom hover:bg-blue-50'
}"
                      data-action="click->deep-booking#decrementAdult"
                      ${this.adultCountValue <= 1 ? 'disabled' : ''}>
                <svg width="12" height="2" viewBox="0 0 12 2" fill="currentColor">
                  <rect width="12" height="2" rx="1"/>
                </svg>
              </button>
              
              <span class="text-lg font-medium w-4 text-center" data-deep-booking-target="adultCount">${this.adultCountValue}</span>
              
              <button class="w-7 h-7 rounded-full border border-blue-custom flex items-center justify-center text-blue-custom hover:bg-blue-50"
                      data-action="click->deep-booking#incrementAdult">
                <svg width="12" height="12" viewBox="0 0 12 12" fill="currentColor">
                  <rect y="5" width="12" height="2" rx="1"/>
                  <rect x="5" width="2" height="12" rx="1"/>
                </svg>
              </button>
            </div>
          </div>

          <!-- 列表项：儿童 -->
          <div class="flex justify-between items-center mb-10">
            <div>
              <div class="text-lg font-medium text-gray-900">儿童</div>
              <div class="text-sm text-gray-400 mt-1">单价: ¥${Math.round(this.pricePerPersonValue * 0.8)}</div>
            </div>
            <div class="flex items-center gap-4">
              <button class="w-7 h-7 rounded-full border flex items-center justify-center transition-colors ${
  this.childCountValue <= 0
    ? 'border-gray-300 text-gray-300 cursor-not-allowed'
    : 'border-blue-custom text-blue-custom hover:bg-blue-50'
}"
                      data-action="click->deep-booking#decrementChild"
                      ${this.childCountValue <= 0 ? 'disabled' : ''}>
                <svg width="12" height="2" viewBox="0 0 12 2" fill="currentColor">
                  <rect width="12" height="2" rx="1"/>
                </svg>
              </button>
              
              <span class="text-lg font-medium w-4 text-center" data-deep-booking-target="childCount">${this.childCountValue}</span>
              
              <button class="w-7 h-7 rounded-full border border-blue-custom flex items-center justify-center text-blue-custom hover:bg-blue-50"
                      data-action="click->deep-booking#incrementChild">
                <svg width="12" height="12" viewBox="0 0 12 12" fill="currentColor">
                  <rect y="5" width="12" height="2" rx="1"/>
                  <rect x="5" width="2" height="12" rx="1"/>
                </svg>
              </button>
            </div>
          </div>

          <!-- 底部按钮 -->
          <button class="w-full bg-[#FF5A43] text-white text-lg font-bold py-3.5 rounded-full shadow-lg active:opacity-90 transition-opacity"
                  data-action="click->deep-booking#confirmBooking">
            立即预约
          </button>
          
        </div>
      </div>
    `
     
    
    this.element.insertAdjacentHTML('beforeend', modalHTML)
  }

  // 关闭人数选择弹窗
  closeCountModal(event: Event): void {
    event.preventDefault()
    const modal = document.querySelector('[data-deep-booking-target="countModal"]')
    if (modal) {
      modal.remove()
    }
  }

  // 阻止事件冒泡
  stopPropagation(event: Event): void {
    event.stopPropagation()
  }

  // 增加成人数量
  incrementAdult(event: Event): void {
    event.preventDefault()
    this.adultCountValue++
    this.updateCountDisplay()
  }

  // 减少成人数量
  decrementAdult(event: Event): void {
    event.preventDefault()
    if (this.adultCountValue > 1) {
      this.adultCountValue--
      this.updateCountDisplay()
    }
  }

  // 增加儿童数量
  incrementChild(event: Event): void {
    event.preventDefault()
    this.childCountValue++
    this.updateCountDisplay()
  }

  // 减少儿童数量
  decrementChild(event: Event): void {
    event.preventDefault()
    if (this.childCountValue > 0) {
      this.childCountValue--
      this.updateCountDisplay()
    }
  }

  // 更新数量显示
  updateCountDisplay(): void {
    const modal = document.querySelector('[data-deep-booking-target="countModal"]')
    if (!modal) return

    // Update adult count
    const adultCountEl = modal.querySelector('[data-deep-booking-target="adultCount"]')
    if (adultCountEl) {
      adultCountEl.textContent = this.adultCountValue.toString()
    }

    // Update child count
    const childCountEl = modal.querySelector('[data-deep-booking-target="childCount"]')
    if (childCountEl) {
      childCountEl.textContent = this.childCountValue.toString()
    }

    // Update button states
    const decrementAdultBtn = modal.querySelector('[data-action*="decrementAdult"]') as HTMLButtonElement
    if (decrementAdultBtn) {
      if (this.adultCountValue <= 1) {
        decrementAdultBtn.disabled = true
        decrementAdultBtn.classList.remove('border-blue-custom', 'text-blue-custom', 'hover:bg-blue-50')
        decrementAdultBtn.classList.add('border-gray-300', 'text-gray-300', 'cursor-not-allowed')
      } else {
        decrementAdultBtn.disabled = false
        decrementAdultBtn.classList.remove('border-gray-300', 'text-gray-300', 'cursor-not-allowed')
        decrementAdultBtn.classList.add('border-blue-custom', 'text-blue-custom', 'hover:bg-blue-50')
      }
    }

    const decrementChildBtn = modal.querySelector('[data-action*="decrementChild"]') as HTMLButtonElement
    if (decrementChildBtn) {
      if (this.childCountValue <= 0) {
        decrementChildBtn.disabled = true
        decrementChildBtn.classList.remove('border-blue-custom', 'text-blue-custom', 'hover:bg-blue-50')
        decrementChildBtn.classList.add('border-gray-300', 'text-gray-300', 'cursor-not-allowed')
      } else {
        decrementChildBtn.disabled = false
        decrementChildBtn.classList.remove('border-gray-300', 'text-gray-300', 'cursor-not-allowed')
        decrementChildBtn.classList.add('border-blue-custom', 'text-blue-custom', 'hover:bg-blue-50')
      }
    }
  }

  // 确认预约 - 跳转到填写订单页
  confirmBooking(event: Event): void {
    event.preventDefault()
    
    // 构建跳转URL
    const url = `/deep_travel_bookings/new?guide_id=${this.guideIdValue}&date=${this.selectedDateValue}&adult_count=${this.adultCountValue}&child_count=${this.childCountValue}`
    
    console.log("Confirming booking:", {
      guideId: this.guideIdValue,
      date: this.selectedDateValue,
      adultCount: this.adultCountValue,
      childCount: this.childCountValue,
      url
    })
    
    // Navigate to booking form page
    window.location.href = url
  }

  // 显示提示消息
  showToast(message: string): void {
    // Use existing toast functionality if available
    if (typeof (window as any).showToast === 'function') {
      (window as any).showToast(message)
    } else {
      alert(message)
    }
  }
}

// Add custom styles
const style = document.createElement('style')
style.textContent = `
  .border-blue-custom {
    border-color: #4E6EF2;
  }
  .text-blue-custom {
    color: #4E6EF2;
  }
  @keyframes slide-up {
    from {
      transform: translateY(100%);
    }
    to {
      transform: translateY(0);
    }
  }
  .animate-slide-up {
    animation: slide-up 0.3s ease-out;
  }
`
document.head.appendChild(style)
