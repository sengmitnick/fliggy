import { Controller } from "@hotwired/stimulus"

interface CalendarDay {
  date: Date
  dayOfMonth: number
  isCurrentMonth: boolean
  isToday: boolean
  isSelected: boolean
  isInRange: boolean
  isDisabled: boolean
  label?: string
  holiday?: string
}

export default class extends Controller<HTMLElement> {
  static targets = [
    // stimulus-validator: disable-next-line
    "modal",
    // stimulus-validator: disable-next-line
    "calendar",
    // stimulus-validator: disable-next-line
    "monthLabel",
    // stimulus-validator: disable-next-line
    "promptText",
    "checkInInput", "checkOutInput", "checkInDisplay", "checkOutDisplay",
    "nightsDisplay"
  ]

  declare readonly hasCheckInInputTarget: boolean
  declare readonly hasCheckOutInputTarget: boolean
  
  static values = {
    // stimulus-validator: disable-next-line
    checkIn: String,
    // stimulus-validator: disable-next-line
    checkOut: String,
    // stimulus-validator: disable-next-line
    selectingCheckIn: Boolean,
    displayMode: { type: String, default: 'nights' } // 'nights' for hotels, 'days' for insurance
  }

  // stimulus-validator: disable-next-line
  declare readonly modalTarget: HTMLElement
  // stimulus-validator: disable-next-line
  declare readonly calendarTarget: HTMLElement
  // stimulus-validator: disable-next-line
  declare readonly monthLabelTarget: HTMLElement
  // stimulus-validator: disable-next-line
  declare readonly promptTextTarget: HTMLElement
  declare readonly checkInInputTarget: HTMLInputElement
  declare readonly checkOutInputTarget: HTMLInputElement
  declare readonly checkInDisplayTarget: HTMLElement
  declare readonly checkOutDisplayTarget: HTMLElement
  declare readonly hasNightsDisplayTarget: boolean
  declare readonly nightsDisplayTarget: HTMLElement

  declare checkInValue: string
  declare checkOutValue: string
  declare selectingCheckInValue: boolean
  declare displayModeValue: string

  private currentMonth: Date = new Date()
  private checkInDate: Date | null = null
  private checkOutDate: Date | null = null

  connect(): void {
    // Only initialize if input targets exist (modal view)
    if (this.hasCheckInInputTarget && this.hasCheckOutInputTarget) {
      if (this.checkInInputTarget.value) {
        this.checkInDate = this.parseLocalDate(this.checkInInputTarget.value)
      }
      if (this.checkOutInputTarget.value) {
        this.checkOutDate = this.parseLocalDate(this.checkOutInputTarget.value)
      }
      this.updateDisplay()
    }
  }

  private parseLocalDate(dateStr: string): Date {
    // Parse date string as local date (YYYY-MM-DD)
    const parts = dateStr.split('-')
    if (parts.length === 3) {
      const year = parseInt(parts[0], 10)
      const month = parseInt(parts[1], 10) - 1 // Month is 0-indexed
      const day = parseInt(parts[2], 10)
      return new Date(year, month, day)
    }
    return new Date()
  }

  openModal(): void {
    this.selectingCheckInValue = true
    this.promptTextTarget.textContent = "请选择入住日期"
    this.currentMonth = new Date()
    this.renderMultiMonthCalendar()
    this.modalTarget.classList.remove('hidden')
    document.body.style.overflow = 'hidden'
  }

  closeModal(): void {
    this.modalTarget.classList.add('hidden')
    document.body.style.overflow = ''
  }

  selectDate(event: Event): void {
    const button = event.currentTarget as HTMLButtonElement
    const dateStr = button.dataset.date
    if (!dateStr) return

    const selectedDate = this.parseLocalDate(dateStr)
    
    if (this.selectingCheckInValue) {
      // Selecting check-in date
      this.checkInDate = selectedDate
      this.checkOutDate = null // Reset check-out when changing check-in
      this.selectingCheckInValue = false
      this.promptTextTarget.textContent = "请选择离店日期"
    } else {
      // Selecting check-out date
      if (this.checkInDate && selectedDate <= this.checkInDate) {
        // If selected date is before or same as check-in, make it the new check-in
        this.checkInDate = selectedDate
        this.checkOutDate = null
        this.promptTextTarget.textContent = "请选择离店日期"
      } else {
        this.checkOutDate = selectedDate
      }
    }

    this.renderMultiMonthCalendar()
  }

  confirm(): void {
    // Always allow confirm - even if dates are reset/cleared
    if (this.checkInDate && this.checkOutDate) {
      this.checkInInputTarget.value = this.formatDate(this.checkInDate)
      this.checkOutInputTarget.value = this.formatDate(this.checkOutDate)
      this.updateDisplay()
      
      // Dispatch event to notify hotel-search controller
      this.dispatchDateUpdateEvent()
    } else {
      // If dates are cleared (after reset), clear the inputs
      if (this.hasCheckInInputTarget) {
        this.checkInInputTarget.value = ''
      }
      if (this.hasCheckOutInputTarget) {
        this.checkOutInputTarget.value = ''
      }
      
      // Dispatch event with empty dates to clear filter
      const dateUpdateEvent = new CustomEvent('hotel-date-picker:dates-selected', {
        detail: {
          checkIn: '',
          checkOut: ''
        },
        bubbles: true
      })
      document.dispatchEvent(dateUpdateEvent)
    }
    
    this.closeModal()
  }

  reset(): void {
    this.checkInDate = null
    this.checkOutDate = null
    this.selectingCheckInValue = true
    this.promptTextTarget.textContent = "请选择入住日期"
    
    // Clear the input fields
    if (this.hasCheckInInputTarget) {
      this.checkInInputTarget.value = ''
    }
    if (this.hasCheckOutInputTarget) {
      this.checkOutInputTarget.value = ''
    }
    
    this.renderMultiMonthCalendar()
    this.updateDisplay()
  }

  previousMonth(): void {
    this.currentMonth = new Date(this.currentMonth.getFullYear(), this.currentMonth.getMonth() - 1, 1)
    this.renderMultiMonthCalendar()
  }

  nextMonth(): void {
    this.currentMonth = new Date(this.currentMonth.getFullYear(), this.currentMonth.getMonth() + 1, 1)
    this.renderMultiMonthCalendar()
  }

  private renderMultiMonthCalendar(): void {
    // Render 3 consecutive months
    let html = ''
    
    for (let i = 0; i < 3; i++) {
      const displayMonth = new Date(this.currentMonth.getFullYear(), this.currentMonth.getMonth() + i, 1)
      html += this.renderSingleMonth(displayMonth)
    }
    
    this.calendarTarget.innerHTML = html
    
    // Update month label to show first month
    const year = this.currentMonth.getFullYear()
    const month = this.currentMonth.getMonth()
    this.monthLabelTarget.textContent = `${year}年${month + 1}月`
  }

  private renderSingleMonth(displayMonth: Date): string {
    const year = displayMonth.getFullYear()
    const month = displayMonth.getMonth()
    
    // Month header
    let html = `<div class="mb-6">
      <div class="text-lg font-bold text-gray-900 mb-3">${year}年${month + 1}月</div>
    `
    
    const firstDay = new Date(year, month, 1)
    const lastDay = new Date(year, month + 1, 0)
    const daysInMonth = lastDay.getDate()
    const startingDayOfWeek = firstDay.getDay()
    
    const days: CalendarDay[] = []
    
    // Previous month days
    const prevMonthLastDay = new Date(year, month, 0).getDate()
    for (let i = startingDayOfWeek - 1; i >= 0; i--) {
      const day = prevMonthLastDay - i
      const date = new Date(year, month - 1, day)
      days.push({
        date,
        dayOfMonth: day,
        isCurrentMonth: false,
        isToday: false,
        isSelected: false,
        isInRange: false,
        isDisabled: this.isDateDisabled(date)
      })
    }
    
    // Current month days
    const today = new Date()
    today.setHours(0, 0, 0, 0)
    
    for (let day = 1; day <= daysInMonth; day++) {
      const date = new Date(year, month, day)
      const isToday = date.getTime() === today.getTime()
      const isSelected = this.isDateSelected(date)
      const isInRange = this.isDateInRange(date)
      
      days.push({
        date,
        dayOfMonth: day,
        isCurrentMonth: true,
        isToday,
        isSelected,
        isInRange,
        isDisabled: this.isDateDisabled(date),
        label: this.getDateLabel(date),
        holiday: this.getHoliday(date)
      })
    }
    
    // Next month days
    const remainingDays = 42 - days.length // 6 rows * 7 days
    for (let day = 1; day <= remainingDays; day++) {
      const date = new Date(year, month + 1, day)
      days.push({
        date,
        dayOfMonth: day,
        isCurrentMonth: false,
        isToday: false,
        isSelected: false,
        isInRange: false,
        isDisabled: this.isDateDisabled(date)
      })
    }
    
    html += this.renderDays(days)
    html += '</div>' // Close month container
    
    return html
  }

  private renderDays(days: CalendarDay[]): string {
    const weekdays = ['日', '一', '二', '三', '四', '五', '六']
    
    let html = '<div class="grid grid-cols-7 gap-1 mb-2">'
    weekdays.forEach(day => {
      html += `<div class="text-center text-sm text-gray-500 py-2">${day}</div>`
    })
    html += '</div>'
    
    html += '<div class="grid grid-cols-7 gap-1">'
    
    days.forEach(day => {
      const dateStr = this.formatDate(day.date)
      const baseClasses = "relative h-12 flex flex-col items-center justify-center text-sm rounded-lg"
      
      let classes = baseClasses
      let textColor = day.isCurrentMonth ? 'text-gray-900' : 'text-gray-300'
      let bgColor = ''
      
      if (day.isDisabled) {
        classes += ' opacity-40 cursor-not-allowed'
      } else {
        classes += ' cursor-pointer hover:bg-gray-100'
      }
      
      if (day.isSelected) {
        bgColor = 'bg-yellow-400'
        textColor = 'text-white font-bold'
      } else if (day.isInRange) {
        bgColor = 'bg-yellow-50'
      }
      
      if (day.isToday && !day.isSelected) {
        classes += ' border-2 border-blue-500'
      }
      
      const label = day.label || day.holiday || ''
      const labelClass = day.holiday ? 'text-red-500' : 'text-blue-500'
      
      html += `
        <button 
          data-date="${dateStr}"
          data-action="click->hotel-date-picker#selectDate"
          class="${classes} ${bgColor} ${textColor}"
          ${day.isDisabled ? 'disabled' : ''}
        >
          <span class="font-medium">${day.dayOfMonth}</span>
          ${label ? `<span class="text-xs ${labelClass} absolute bottom-0">${label}</span>` : ''}
        </button>
      `
    })
    
    html += '</div>'
    return html
  }

  private isDateDisabled(date: Date): boolean {
    const today = new Date()
    today.setHours(0, 0, 0, 0)
    return date < today
  }

  private isDateSelected(date: Date): boolean {
    if (this.checkInDate && this.isSameDay(date, this.checkInDate)) return true
    if (this.checkOutDate && this.isSameDay(date, this.checkOutDate)) return true
    return false
  }

  private isDateInRange(date: Date): boolean {
    if (!this.checkInDate || !this.checkOutDate) return false
    return date > this.checkInDate && date < this.checkOutDate
  }

  private isSameDay(date1: Date, date2: Date): boolean {
    return date1.getFullYear() === date2.getFullYear() &&
           date1.getMonth() === date2.getMonth() &&
           date1.getDate() === date2.getDate()
  }

  private formatDate(date: Date): string {
    const year = date.getFullYear()
    const month = String(date.getMonth() + 1).padStart(2, '0')
    const day = String(date.getDate()).padStart(2, '0')
    return `${year}-${month}-${day}`
  }

  private getDateLabel(date: Date): string {
    const today = new Date()
    today.setHours(0, 0, 0, 0)
    const targetDate = new Date(date)
    targetDate.setHours(0, 0, 0, 0)
    
    const diffTime = targetDate.getTime() - today.getTime()
    const diffDays = Math.round(diffTime / (1000 * 60 * 60 * 24))
    
    if (diffDays === 0) return '今天'
    if (diffDays === 1) return '明天'
    if (diffDays === 2) return '后天'
    
    const weekdays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六']
    return weekdays[date.getDay()]
  }

  private getHoliday(date: Date): string {
    // Simple holiday mapping - can be expanded
    const month = date.getMonth() + 1
    const day = date.getDate()
    
    if (month === 1 && day === 1) return '元旦'
    if (month === 2 && day === 14) return '情人节'
    if (month === 5 && day === 1) return '劳动节'
    if (month === 6 && day === 1) return '儿童节'
    if (month === 10 && day === 1) return '国庆节'
    if (month === 12 && day === 25) return '圣诞节'
    
    return ''
  }

  private updateDisplay(): void {
    if (this.checkInDate) {
      const month = this.checkInDate.getMonth() + 1
      const day = this.checkInDate.getDate()
      this.checkInDisplayTarget.textContent = `${month}月${day}日`
      
      // Update label below check-in date
      const checkInLabel = this.checkInDisplayTarget.nextElementSibling
      if (checkInLabel) {
        checkInLabel.textContent = this.getDateLabel(this.checkInDate)
      }
    }
    
    if (this.checkOutDate) {
      const month = this.checkOutDate.getMonth() + 1
      const day = this.checkOutDate.getDate()
      this.checkOutDisplayTarget.textContent = `${month}月${day}日`
      
      // Update label below check-out date
      const checkOutLabel = this.checkOutDisplayTarget.nextElementSibling
      if (checkOutLabel) {
        checkOutLabel.textContent = this.getDateLabel(this.checkOutDate)
      }
    }
    
    if (this.checkInDate && this.checkOutDate && this.hasNightsDisplayTarget) {
      const diffDays = Math.floor((this.checkOutDate.getTime() - this.checkInDate.getTime()) / (1000 * 60 * 60 * 24))
      
      if (this.displayModeValue === 'days') {
        // For insurance: show total days (including start and end date)
        const days = diffDays + 1
        this.nightsDisplayTarget.textContent = `${days}天`
      } else {
        // For hotels: show nights (excluding end date)
        this.nightsDisplayTarget.textContent = `${diffDays}晚`
      }
    }
  }

  // Dispatch date update event for hotel-search controller
  private dispatchDateUpdateEvent(): void {
    if (!this.checkInDate || !this.checkOutDate) return
    
    const dateUpdateEvent = new CustomEvent('hotel-date-picker:dates-selected', {
      detail: {
        checkIn: this.formatDate(this.checkInDate),
        checkOut: this.formatDate(this.checkOutDate)
      },
      bubbles: true
    })
    document.dispatchEvent(dateUpdateEvent)
    console.log('Hotel date picker: Dispatched dates update event', {
      checkIn: this.formatDate(this.checkInDate),
      checkOut: this.formatDate(this.checkOutDate)
    })
  }
}
