import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "modal",
    "packageBtn",
    "monthTab",
    "calendar",
    "dateBtn",
    "adultCount",
    "childCount",
    "headerPrice",
    "headerOriginalPrice",
    "selectedPackageName",
    "monthPrice",
    "datePrice",
    "quantitySummary"
  ]

  declare readonly modalTarget: HTMLElement
  declare readonly packageBtnTargets: HTMLElement[]
  declare readonly monthTabTargets: HTMLElement[]
  declare readonly calendarTarget: HTMLElement
  declare readonly dateBtnTargets: HTMLElement[]
  declare readonly adultCountTarget: HTMLElement
  declare readonly childCountTarget: HTMLElement
  declare readonly headerPriceTarget: HTMLElement
  declare readonly headerOriginalPriceTarget: HTMLElement
  declare readonly selectedPackageNameTarget: HTMLElement
  declare readonly monthPriceTargets: HTMLElement[]
  declare readonly datePriceTargets: HTMLElement[]
  declare readonly quantitySummaryTarget: HTMLElement

  private selectedPackageId: number | null = null
  private selectedDate: string | null = null
  private adultQuantity: number = 1
  private childQuantity: number = 0
  private monthsData: Array<{month: number, year: number, firstDay: number, daysInMonth: number}> = []

  connect(): void {
    console.log("Booking modal controller connected")
    
    // Store calendar data for 4 months
    this.generateMonthsData()
    
    // Listen for package selection changes from outside
    window.addEventListener("package:selected", (event: Event) => {
      const customEvent = event as CustomEvent
      const packageId = customEvent.detail.packageId
      if (packageId && packageId !== this.selectedPackageId) {
        this.syncPackageSelection(packageId)
      }
    })
    
    // Listen for bottom bar modal open requests
    window.addEventListener("bottom-bar:open-modal", () => {
      this.open()
    })
  }

  private generateMonthsData(): void {
    // Pre-generate 4 months of calendar data
    const today = new Date()
    this.monthsData = []
    
    for (let i = 0; i < 4; i++) {
      const monthDate = new Date(today.getFullYear(), today.getMonth() + i, 1)
      this.monthsData.push({
        month: monthDate.getMonth() + 1,
        year: monthDate.getFullYear(),
        firstDay: monthDate.getDay(),
        daysInMonth: new Date(monthDate.getFullYear(), monthDate.getMonth() + 1, 0).getDate()
      })
    }
  }

  open(): void {
    // Sync with current external selection when opening
    const event = new CustomEvent("booking-modal:request-sync")
    window.dispatchEvent(event)
    
    this.modalTarget.classList.remove("hidden")
    document.body.style.overflow = "hidden"
  }

  close(): void {
    this.modalTarget.classList.add("hidden")
    document.body.style.overflow = ""
  }

  selectPackage(event: Event): void {
    const btn = event.currentTarget as HTMLElement
    const packageId = parseInt(btn.dataset.packageId || "0")
    const packagePrice = parseInt(btn.dataset.packagePrice || "0")
    const packageChildPrice = parseInt(btn.dataset.packageChildPrice || "0")
    const packageName = btn.dataset.packageName || ""
    
    this.selectedPackageId = packageId
    this.updatePackageButtons(packageId)
    
    // Update all price displays
    this.updatePrices(packagePrice, packageName)
    
    // Notify external package switcher
    const customEvent = new CustomEvent("booking-modal:package-changed", {
      detail: { packageId }
    })
    window.dispatchEvent(customEvent)
  }

  private syncPackageSelection(packageId: number): void {
    this.selectedPackageId = packageId
    this.updatePackageButtons(packageId)
  }

  private updatePackageButtons(packageId: number): void {
    // Update button styles
    this.packageBtnTargets.forEach(btnEl => {
      const btnPackageId = parseInt(btnEl.dataset.packageId || "0")
      
      if (btnPackageId === packageId) {
        btnEl.classList.remove("bg-white", "border-gray-200")
        btnEl.classList.add("bg-[#FFF9E6]", "border-[#FFD700]")
        
        // Add checkmark if not exists
        if (!btnEl.querySelector("svg")) {
          const checkmark = document.createElementNS("http://www.w3.org/2000/svg", "svg")
          checkmark.classList.add("absolute", "top-2", "right-2", "w-5", "h-5")
          checkmark.style.color = "#FFD700"
          checkmark.setAttribute("fill", "currentColor")
          checkmark.setAttribute("viewBox", "0 0 20 20")
          const pathD = 'M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z'
          checkmark.innerHTML = `<path fill-rule="evenodd" d="${pathD}" clip-rule="evenodd"></path>`
          btnEl.appendChild(checkmark)
        }
      } else {
        btnEl.classList.remove("bg-[#FFF9E6]", "border-[#FFD700]")
        btnEl.classList.add("bg-white", "border-gray-200")
        
        // Remove checkmark
        const checkmark = btnEl.querySelector("svg")
        if (checkmark) {
          checkmark.remove()
        }
      }
    })
  }

  private updatePrices(price: number, packageName: string): void {
    const originalPrice = Math.round(price * 1.2)
    
    // Update header prices
    this.headerPriceTarget.innerHTML = `券后价 ¥${price}<span class="text-sm">起</span>`
    this.headerOriginalPriceTarget.textContent = `¥${originalPrice}`
    
    // Update selected package name
    this.selectedPackageNameTarget.textContent = packageName
    
    // Update month tab prices
    this.monthPriceTargets.forEach(el => {
      el.textContent = `¥${price}起`
    })
    
    // Update calendar date prices
    this.datePriceTargets.forEach(el => {
      el.textContent = `¥${price}`
    })
  }

  selectMonth(event: Event): void {
    const btn = event.currentTarget as HTMLElement
    const month = parseInt(btn.dataset.month || "0")

    // Update tab styles
    this.monthTabTargets.forEach(tabEl => {
      if (parseInt(tabEl.dataset.month || "0") === month) {
        tabEl.classList.remove("text-foreground-muted")
        tabEl.classList.add("text-red-500", "border-b-2", "border-red-500")
      } else {
        tabEl.classList.remove("text-red-500", "border-b-2", "border-red-500")
        tabEl.classList.add("text-foreground-muted")
      }
    })

    // Render calendar for selected month
    this.renderCalendar(month)
  }

  private renderCalendar(month: number): void {
    const monthData = this.monthsData.find(m => m.month === month)
    if (!monthData) return

    const today = new Date()
    today.setHours(0, 0, 0, 0)
    
    // Get current package price
    const priceText = this.monthPriceTargets[0]?.textContent || "¥3975起"
    const price = priceText.match(/\d+/)?.[0] || "3975"

    // Clear calendar (keep weekday headers)
    const calendarGrid = this.calendarTarget
    const weekdayHeaders = calendarGrid.querySelectorAll('div.text-center.text-sm.font-medium')
    calendarGrid.innerHTML = ''
    
    // Re-add weekday headers
    weekdayHeaders.forEach(header => calendarGrid.appendChild(header))

    // Add empty cells for days before month starts
    for (let i = 0; i < monthData.firstDay; i++) {
      const emptyCell = document.createElement('div')
      emptyCell.className = 'aspect-square'
      calendarGrid.appendChild(emptyCell)
    }

    // Add date buttons for each day
    for (let day = 1; day <= monthData.daysInMonth; day++) {
      const date = new Date(monthData.year, monthData.month - 1, day)
      date.setHours(0, 0, 0, 0)
      
      const isPast = date < today
      const isWeekend = date.getDay() === 0 || date.getDay() === 6
      const dateString = `${monthData.year}-${String(monthData.month).padStart(2, '0')}-${String(day).padStart(2, '0')}`

      const btn = document.createElement('button')
      btn.type = 'button'
      btn.className = `aspect-square rounded-lg text-sm flex flex-col items-center justify-center ${isPast ? 'text-gray-300 cursor-not-allowed' : 'hover:bg-gray-50'}`
      btn.dataset.bookingModalTarget = 'dateBtn'
      btn.dataset.date = dateString
      btn.dataset.month = String(month)
      btn.dataset.action = 'click->booking-modal#selectDate'
      
      if (isPast) {
        btn.disabled = true
      }

      // Holiday indicator
      if (isWeekend && !isPast) {
        const holiday = document.createElement('span')
        holiday.className = 'text-xs text-[#FFD700]'
        holiday.textContent = '休'
        btn.appendChild(holiday)
      }

      // Day number
      const dayNum = document.createElement('div')
      dayNum.className = `font-medium ${isPast ? '' : 'text-foreground'}`
      dayNum.textContent = String(day)
      btn.appendChild(dayNum)

      // Price
      if (!isPast) {
        const priceEl = document.createElement('div')
        priceEl.className = 'text-xs text-red-500'
        priceEl.dataset.bookingModalTarget = 'datePrice'
        priceEl.textContent = `¥${price}`
        btn.appendChild(priceEl)
      }

      calendarGrid.appendChild(btn)
    }
  }

  selectDate(event: Event): void {
    const btn = event.currentTarget as HTMLButtonElement
    const date = btn.dataset.date

    if (!date || btn.disabled) return

    this.selectedDate = date

    // Update date button styles
    this.dateBtnTargets.forEach(dateBtn => {
      if (dateBtn.dataset.date === date) {
        dateBtn.style.background = "#FFD700"
        dateBtn.style.color = "#000"
      } else {
        dateBtn.style.background = ""
        dateBtn.style.color = ""
      }
    })
  }

  increaseAdult(): void {
    this.adultQuantity++
    this.adultCountTarget.textContent = this.adultQuantity.toString()
    this.updateQuantitySummary()
  }

  decreaseAdult(): void {
    if (this.adultQuantity > 1) {
      this.adultQuantity--
      this.adultCountTarget.textContent = this.adultQuantity.toString()
      this.updateQuantitySummary()
    }
  }

  increaseChild(): void {
    this.childQuantity++
    this.childCountTarget.textContent = this.childQuantity.toString()
    this.updateQuantitySummary()
  }

  decreaseChild(): void {
    if (this.childQuantity > 0) {
      this.childQuantity--
      this.childCountTarget.textContent = this.childQuantity.toString()
      this.updateQuantitySummary()
    }
  }

  private updateQuantitySummary(): void {
    let summary = `购买数量: 成人${this.adultQuantity}`
    if (this.childQuantity > 0) {
      summary += `、儿童${this.childQuantity}`
    }
    this.quantitySummaryTarget.textContent = summary
  }

  addToCart(): void {
    if (!this.validateSelection()) {
      return
    }

    console.log("Adding to cart:", {
      packageId: this.selectedPackageId,
      date: this.selectedDate,
      adults: this.adultQuantity,
      children: this.childQuantity
    })

    alert("已加入购物车")
    this.close()
  }

  buyNow(): void {
    if (!this.validateSelection()) {
      return
    }

    // 获取当前页面的 product_id（从 URL 中获取）
    const productId = window.location.pathname.split('/').pop()
    
    // 构建订单页面 URL
    const params = new URLSearchParams({
      product_id: productId || '',
      package_id: (this.selectedPackageId || '').toString(),
      travel_date: this.selectedDate || '',
      adult_count: this.adultQuantity.toString(),
      child_count: this.childQuantity.toString()
    })
    
    // 跳转到订单页面
    window.location.href = `/tour_group_bookings/new?${params.toString()}`
  }

  private validateSelection(): boolean {
    if (!this.selectedDate) {
      alert("请选择出行日期")
      return false
    }

    if (this.adultQuantity < 1) {
      alert("至少需要1位成人")
      return false
    }

    return true
  }
}
