import { Controller } from "@hotwired/stimulus"

interface CalendarDay {
  date: Date
  dayOfMonth: number
  isCurrentMonth: boolean
  isToday: boolean
  isSelected: boolean
  isDisabled: boolean
}

export default class extends Controller<HTMLElement> {
  static targets = [
    // stimulus-validator: disable-next-line
    "modal",
    // stimulus-validator: disable-next-line
    "titleText",
    // stimulus-validator: disable-next-line
    "dateSection",
    // stimulus-validator: disable-next-line
    "timeSection",
    // stimulus-validator: disable-next-line
    "calendar",
    // stimulus-validator: disable-next-line
    "monthLabel",
    // stimulus-validator: disable-next-line
    "timeGrid",
    // stimulus-validator: disable-next-line
    "selectedDateDisplay",
    // stimulus-validator: disable-next-line
    "confirmButton"
  ]

  static values = {
    // stimulus-validator: disable-next-line
    pickerType: String, // 'pickup' or 'return'
  }

  // stimulus-validator: disable-next-line
  declare readonly modalTarget: HTMLElement
  // stimulus-validator: disable-next-line
  declare readonly titleTextTarget: HTMLElement
  // stimulus-validator: disable-next-line
  declare readonly dateSectionTarget: HTMLElement
  // stimulus-validator: disable-next-line
  declare readonly timeSectionTarget: HTMLElement
  // stimulus-validator: disable-next-line
  declare readonly calendarTarget: HTMLElement
  // stimulus-validator: disable-next-line
  declare readonly monthLabelTarget: HTMLElement
  // stimulus-validator: disable-next-line
  declare readonly timeGridTarget: HTMLElement
  // stimulus-validator: disable-next-line
  declare readonly selectedDateDisplayTarget: HTMLElement
  // stimulus-validator: disable-next-line
  declare readonly confirmButtonTarget: HTMLElement
  declare pickerTypeValue: string

  private currentMonth: Date = new Date()
  private selectedDate: Date | null = null
  private selectedTime: string = '10:00'

  connect(): void {
    console.log("CarDatetimePicker connected")
  }

  disconnect(): void {
    console.log("CarDatetimePicker disconnected")
  }

  openModal(pickerType: string = 'pickup'): void {
    this.pickerTypeValue = pickerType
    this.titleTextTarget.textContent = pickerType === 'pickup' ? '选择取车时间' : '选择还车时间'
    
    // Reset to current month
    this.currentMonth = new Date()
    this.selectedDate = null
    this.selectedTime = '10:00'
    
    // Show date section, hide time section
    this.dateSectionTarget.classList.remove('hidden')
    this.timeSectionTarget.classList.add('hidden')
    
    this.renderCalendar()
    this.modalTarget.classList.remove('hidden')
    document.body.style.overflow = 'hidden'
  }

  closeModal(): void {
    this.modalTarget.classList.add('hidden')
    document.body.style.overflow = ''
  }

  cancel(): void {
    this.closeModal()
  }

  previousMonth(): void {
    this.currentMonth = new Date(this.currentMonth.getFullYear(), this.currentMonth.getMonth() - 1, 1)
    this.renderCalendar()
  }

  nextMonth(): void {
    this.currentMonth = new Date(this.currentMonth.getFullYear(), this.currentMonth.getMonth() + 1, 1)
    this.renderCalendar()
  }

  selectDate(event: Event): void {
    const button = event.currentTarget as HTMLButtonElement
    const dateStr = button.dataset.date
    if (!dateStr) return

    this.selectedDate = this.parseLocalDate(dateStr)
    
    // Switch to time selection
    this.dateSectionTarget.classList.add('hidden')
    this.timeSectionTarget.classList.remove('hidden')
    
    // Update selected date display
    this.selectedDateDisplayTarget.textContent = this.formatDateDisplay(this.selectedDate)
    
    // Clear previous time selection
    this.timeGridTarget.querySelectorAll('button').forEach(btn => {
      btn.classList.remove('bg-blue-500', 'text-white', 'border-blue-500')
      btn.classList.add('border-gray-300')
    })
  }

  selectTime(event: Event): void {
    const button = event.currentTarget as HTMLButtonElement
    const time = button.dataset.time
    if (!time) return

    this.selectedTime = time

    // Update UI to show selected state
    this.timeGridTarget.querySelectorAll('button').forEach(btn => {
      btn.classList.remove('bg-blue-500', 'text-white', 'border-blue-500')
      btn.classList.add('border-gray-300')
    })
    button.classList.add('bg-blue-500', 'text-white', 'border-blue-500')
    button.classList.remove('border-gray-300')
  }

  confirm(): void {
    if (!this.selectedDate) {
      alert('请先选择日期')
      return
    }

    // Combine date and time
    const [hours, minutes] = this.selectedTime.split(':').map(Number)
    const dateTime = new Date(this.selectedDate)
    dateTime.setHours(hours, minutes, 0, 0)

    // Dispatch event to car-rental-tabs controller
    const event = new CustomEvent('car-datetime-picker:datetime-selected', {
      detail: {
        pickerType: this.pickerTypeValue,
        dateTime: dateTime,
        dateTimeString: dateTime.toISOString()
      },
      bubbles: true
    })
    document.dispatchEvent(event)

    this.closeModal()
  }

  private renderCalendar(): void {
    const year = this.currentMonth.getFullYear()
    const month = this.currentMonth.getMonth()
    
    // Update month label
    this.monthLabelTarget.textContent = `${year}年${month + 1}月`
    
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
        isDisabled: true
      })
    }
    
    // Current month days
    const today = new Date()
    today.setHours(0, 0, 0, 0)
    
    for (let day = 1; day <= daysInMonth; day++) {
      const date = new Date(year, month, day)
      date.setHours(0, 0, 0, 0)
      const isToday = date.getTime() === today.getTime()
      const isSelected = this.selectedDate && 
        date.getFullYear() === this.selectedDate.getFullYear() &&
        date.getMonth() === this.selectedDate.getMonth() &&
        date.getDate() === this.selectedDate.getDate()
      const isDisabled = date < today
      
      days.push({
        date,
        dayOfMonth: day,
        isCurrentMonth: true,
        isToday,
        isSelected: isSelected || false,
        isDisabled
      })
    }
    
    // Next month days
    const remainingDays = 42 - days.length
    for (let day = 1; day <= remainingDays; day++) {
      const date = new Date(year, month + 1, day)
      days.push({
        date,
        dayOfMonth: day,
        isCurrentMonth: false,
        isToday: false,
        isSelected: false,
        isDisabled: true
      })
    }
    
    // Render calendar grid
    let html = '<div class="grid grid-cols-7 gap-1">'
    
    days.forEach((day) => {
      const dateStr = this.formatDate(day.date)
      const classes = [
        'py-3',
        'text-center',
        'rounded-lg',
        'transition-colors'
      ]
      
      if (!day.isCurrentMonth || day.isDisabled) {
        classes.push('text-gray-300', 'cursor-not-allowed')
      } else {
        classes.push('hover:bg-blue-50', 'cursor-pointer')
        
        if (day.isToday) {
          classes.push('font-bold', 'text-blue-600')
        }
        
        if (day.isSelected) {
          classes.push('bg-blue-500', 'text-white', 'font-bold')
        }
      }
      
      const disabled = !day.isCurrentMonth || day.isDisabled
      
      html += `
        <button
          type="button"
          data-action="click->car-datetime-picker#selectDate"
          data-date="${dateStr}"
          class="${classes.join(' ')}"
          ${disabled ? 'disabled' : ''}>
          ${day.dayOfMonth}
        </button>
      `
    })
    
    html += '</div>'
    
    this.calendarTarget.innerHTML = html
  }

  private parseLocalDate(dateStr: string): Date {
    const parts = dateStr.split('-')
    if (parts.length === 3) {
      const year = parseInt(parts[0], 10)
      const month = parseInt(parts[1], 10) - 1
      const day = parseInt(parts[2], 10)
      return new Date(year, month, day)
    }
    return new Date()
  }

  private formatDate(date: Date): string {
    const year = date.getFullYear()
    const month = String(date.getMonth() + 1).padStart(2, '0')
    const day = String(date.getDate()).padStart(2, '0')
    return `${year}-${month}-${day}`
  }

  private formatDateDisplay(date: Date): string {
    const weekdays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六']
    const month = date.getMonth() + 1
    const day = date.getDate()
    const weekday = weekdays[date.getDay()]
    return `${month}月${day}日 ${weekday}`
  }
}
