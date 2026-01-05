import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "modal",
    "packageBtn",
    "monthTab",
    "calendar",
    "dateBtn",
    "adultCount",
    "childCount"
  ]

  declare readonly modalTarget: HTMLElement
  declare readonly packageBtnTargets: HTMLElement[]
  declare readonly monthTabTargets: HTMLElement[]
  declare readonly calendarTarget: HTMLElement
  declare readonly dateBtnTargets: HTMLElement[]
  declare readonly adultCountTarget: HTMLElement
  declare readonly childCountTarget: HTMLElement

  private selectedPackageId: number | null = null
  private selectedDate: string | null = null
  private adultQuantity: number = 1
  private childQuantity: number = 0

  connect(): void {
    console.log("Booking modal controller connected")
    
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
    
    this.selectedPackageId = packageId
    this.updatePackageButtons(packageId)
    
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

  selectMonth(event: Event): void {
    const btn = event.currentTarget as HTMLElement
    const month = btn.dataset.month

    // Update tab styles
    this.monthTabTargets.forEach(tabEl => {
      if (tabEl.dataset.month === month) {
        tabEl.classList.remove("text-foreground-muted")
        tabEl.classList.add("text-red-500", "border-b-2", "border-red-500")
      } else {
        tabEl.classList.remove("text-red-500", "border-b-2", "border-red-500")
        tabEl.classList.add("text-foreground-muted")
      }
    })

    // TODO: Update calendar display for selected month
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
  }

  decreaseAdult(): void {
    if (this.adultQuantity > 1) {
      this.adultQuantity--
      this.adultCountTarget.textContent = this.adultQuantity.toString()
    }
  }

  increaseChild(): void {
    this.childQuantity++
    this.childCountTarget.textContent = this.childQuantity.toString()
  }

  decreaseChild(): void {
    if (this.childQuantity > 0) {
      this.childQuantity--
      this.childCountTarget.textContent = this.childQuantity.toString()
    }
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
