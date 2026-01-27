import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = ["quantity", "totalPrice", "contactName", "contactPhone", "dateRange",
    "mailTab", "pickupTab", "addressSection", "mailAddress",
    "datePickerModal", "startDate", "endDate", "addressPickerModal",
    "pickupLocationModal", "pickupLocationCity", "pickupLocationDistrict",
    "cityTab", "cityContent", "pickupLocationRadio"]
  
  declare readonly quantityTarget: HTMLElement
  declare readonly totalPriceTarget: HTMLElement
  declare readonly contactNameTarget: HTMLInputElement
  declare readonly contactPhoneTarget: HTMLInputElement
  declare readonly dateRangeTarget: HTMLElement
  declare readonly mailTabTarget: HTMLElement
  declare readonly pickupTabTarget: HTMLElement
  declare readonly addressSectionTarget: HTMLElement
  declare readonly mailAddressTarget: HTMLElement
  declare readonly hasTotalPriceTarget: boolean
  declare readonly hasContactNameTarget: boolean
  declare readonly hasContactPhoneTarget: boolean
  declare readonly hasMailTabTarget: boolean
  declare readonly hasPickupTabTarget: boolean
  declare readonly hasAddressSectionTarget: boolean
  declare readonly hasMailAddressTarget: boolean
  declare readonly datePickerModalTarget: HTMLElement
  declare readonly startDateTarget: HTMLInputElement
  declare readonly endDateTarget: HTMLInputElement
  declare readonly hasDatePickerModalTarget: boolean
  declare readonly hasStartDateTarget: boolean
  declare readonly hasEndDateTarget: boolean
  declare readonly hasDateRangeTarget: boolean
  declare readonly addressPickerModalTarget: HTMLElement
  declare readonly hasAddressPickerModalTarget: boolean
  declare readonly pickupLocationModalTarget: HTMLElement
  declare readonly pickupLocationCityTarget: HTMLElement
  declare readonly pickupLocationDistrictTarget: HTMLElement
  declare readonly cityTabTargets: HTMLElement[]
  declare readonly cityContentTargets: HTMLElement[]
  declare readonly pickupLocationRadioTargets: HTMLElement[]
  declare readonly hasPickupLocationModalTarget: boolean
  declare readonly hasPickupLocationCityTarget: boolean
  declare readonly hasPickupLocationDistrictTarget: boolean

  private selectedPlanId: string = ""
  private dailyPrice: number = 17
  private days: number = 7
  private currentDeliveryMethod: string = 'pickup'
  private deposit: number = 500  // 押金
  private selectedPickupLocationId: string = ""
  private selectedCity: string = ""
  private tempSelectedPickupLocation: { id: string, city: string, district: string } | null = null

  connect(): void {
    // 初始化默认选中的套餐价格
    const firstPlan = this.element.querySelector('[data-wifi-id]')
    if (firstPlan) {
      const id = firstPlan.getAttribute('data-wifi-id')
      const price = firstPlan.getAttribute('data-wifi-price')
      if (id) this.selectedPlanId = id
      if (price) this.dailyPrice = parseFloat(price)
    }
    this.updateTotalPrice()
  }

  selectPlan(event: Event): void {
    const card = event.currentTarget as HTMLElement
    const planId = card.dataset.wifiId || ""
    const price = parseFloat(card.dataset.wifiPrice || "17")
    
    this.selectedPlanId = planId
    this.dailyPrice = price
    this.updateTotalPrice()
    
    // Update UI - remove all selections first
    const allCards = this.element.querySelectorAll('[data-wifi-id]')
    allCards.forEach(c => {
      c.classList.remove('bg-[#FFFDF2]', 'border', 'border-[#FFDD00]')
      c.classList.add('bg-white')
      // 查找黄色对勾，替换为空心圆圈
      const checkmarkContainer = c.querySelector('.bg-\\[\\#FFDD00\\].rounded-full')
      if (checkmarkContainer) {
        checkmarkContainer.outerHTML = '<div class="w-5 h-5 ml-2 border border-gray-300 rounded-full"></div>'
      }
    })
    
    // Add selection to clicked card
    card.classList.add('bg-[#FFFDF2]', 'border', 'border-[#FFDD00]')
    card.classList.remove('bg-white')
    // 查找空心圆圈，替换为黄色对勾
    const circle = card.querySelector('.border-gray-300.rounded-full')
    if (circle) {
      const checkmarkSVG = '<svg class="w-3.5 h-3.5 text-black" fill="none" stroke="currentColor" viewBox="0 0 24 24">'
        + '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M5 13l4 4L19 7"></path></svg>'
      const checkmarkHTML = `<div class="w-5 h-5 ml-2 bg-[#FFDD00] rounded-full flex items-center justify-center">${
        checkmarkSVG  }</div>`
      circle.outerHTML = checkmarkHTML
    }
  }

  selectDelivery(event: Event): void {
    event.preventDefault()
    const button = event.currentTarget as HTMLElement
    const method = button.dataset.method
    
    if (!method) return
    
    this.currentDeliveryMethod = method
    
    // 更新Tab样式
    if (this.hasMailTabTarget && this.hasPickupTabTarget) {
      this.mailTabTarget.classList.remove('font-bold', 'bg-white', 'shadow-sm', 'text-gray-800')
      this.mailTabTarget.classList.add('text-gray-500')
      this.pickupTabTarget.classList.remove('font-bold', 'bg-white', 'shadow-sm', 'text-gray-800')
      this.pickupTabTarget.classList.add('text-gray-500')
      
      if (method === 'mail') {
        this.mailTabTarget.classList.remove('text-gray-500')
        this.mailTabTarget.classList.add('font-bold', 'bg-white', 'shadow-sm', 'text-gray-800')
        // 显示邮寄地址，隐藏自取地址
        if (this.hasAddressSectionTarget) this.addressSectionTarget.classList.add('hidden')
        if (this.hasMailAddressTarget) this.mailAddressTarget.classList.remove('hidden')
      } else {
        this.pickupTabTarget.classList.remove('text-gray-500')
        this.pickupTabTarget.classList.add('font-bold', 'bg-white', 'shadow-sm', 'text-gray-800')
        // 显示自取地址，隐藏邮寄地址
        if (this.hasAddressSectionTarget) this.addressSectionTarget.classList.remove('hidden')
        if (this.hasMailAddressTarget) this.mailAddressTarget.classList.add('hidden')
      }
    }
  }

  showComingSoon(event: Event): void {
    event.preventDefault()
    if (typeof (window as any).showToast === 'function') {
      (window as any).showToast('精彩即将上线')
    }
  }

  // 打开日期选择器
  openDatePicker(event: Event): void {
    event.preventDefault()
    if (this.hasDatePickerModalTarget) {
      this.datePickerModalTarget.classList.remove('hidden')
      // 初始化为当前日期
      const today = new Date()
      const endDate = new Date(today)
      endDate.setDate(endDate.getDate() + 7)
      
      if (this.hasStartDateTarget) {
        this.startDateTarget.value = this.formatDateForInput(today)
      }
      if (this.hasEndDateTarget) {
        this.endDateTarget.value = this.formatDateForInput(endDate)
      }
    }
  }

  // 关闭日期选择器
  closeDatePicker(): void {
    if (this.hasDatePickerModalTarget) {
      this.datePickerModalTarget.classList.add('hidden')
    }
  }

  // 确认日期选择
  confirmDateSelection(): void {
    this.updateDateDisplay()
    this.closeDatePicker()
  }

  // 更新日期范围（验证结束日期>=开始日期）
  updateDateRange(event: Event): void {
    if (this.hasStartDateTarget && this.hasEndDateTarget) {
      const start = new Date(this.startDateTarget.value)
      const end = new Date(this.endDateTarget.value)
      if (end < start) {
        this.endDateTarget.value = this.startDateTarget.value
      }
      
      // 如果是结束日期变化，自动确认并关闭
      const target = event.target as HTMLInputElement
      if (target === this.endDateTarget && this.endDateTarget.value) {
        this.confirmDateSelection()
      }
    }
  }

  // 更新日期显示
  private updateDateDisplay(): void {
    if (this.hasStartDateTarget && this.hasEndDateTarget && this.hasDateRangeTarget) {
      const start = new Date(this.startDateTarget.value)
      const end = new Date(this.endDateTarget.value)
      const days = Math.ceil((end.getTime() - start.getTime()) / (1000 * 60 * 60 * 24)) + 1
      
      this.days = days
      this.updateTotalPrice()
      
      const startStr = this.formatDateDisplay(start)
      const endStr = this.formatDateDisplay(end)
      this.dateRangeTarget.textContent = `${startStr}-${endStr}(共${days}天)`
    }
  }

  // 格式化日期为input[type="date"]格式 (YYYY-MM-DD)
  private formatDateForInput(date: Date): string {
    const year = date.getFullYear()
    const month = String(date.getMonth() + 1).padStart(2, '0')
    const day = String(date.getDate()).padStart(2, '0')
    return `${year}-${month}-${day}`
  }

  // 格式化日期为显示格式 (MM月DD日)
  private formatDateDisplay(date: Date): string {
    const month = date.getMonth() + 1
    const day = date.getDate()
    return `${month}月${day}日`
  }

  // 打开收货地址选择器
  openAddressPicker(event: Event): void {
    event.preventDefault()
    if (this.hasAddressPickerModalTarget) {
      this.addressPickerModalTarget.classList.remove('hidden')
    }
  }

  // 关闭收货地址选择器
  closeAddressPicker(): void {
    if (this.hasAddressPickerModalTarget) {
      this.addressPickerModalTarget.classList.add('hidden')
    }
  }

  // 选择收货地址
  selectAddress(event: Event): void {
    const card = event.currentTarget as HTMLElement
    const name = card.dataset.addressName || ""
    const phone = card.dataset.addressPhone || ""
    
    // 填充姓名和电话
    if (this.hasContactNameTarget && name) {
      this.contactNameTarget.value = name
    }
    if (this.hasContactPhoneTarget && phone) {
      this.contactPhoneTarget.value = phone
    }
    
    // 关闭模态框
    this.closeAddressPicker()
  }

  // 打开自取地点选择器
  openPickupLocationPicker(event: Event): void {
    event.preventDefault()
    if (this.hasPickupLocationModalTarget) {
      this.pickupLocationModalTarget.classList.remove('hidden')
    }
  }

  // 关闭自取地点选择器
  closePickupLocationPicker(): void {
    if (this.hasPickupLocationModalTarget) {
      this.pickupLocationModalTarget.classList.add('hidden')
      // 重置临时选择
      this.tempSelectedPickupLocation = null
      this.clearPickupLocationRadios()
    }
  }

  // 选择城市
  selectCity(event: Event): void {
    const tab = event.currentTarget as HTMLElement
    const city = tab.dataset.city || ""
    
    // 更新城市Tab样式
    this.cityTabTargets.forEach(t => {
      if (t === tab) {
        t.classList.add('bg-white', 'text-gray-900', 'border-l-2', 'border-[#FFDD00]')
        t.classList.remove('text-gray-600')
      } else {
        t.classList.remove('bg-white', 'text-gray-900', 'border-l-2', 'border-[#FFDD00]')
        t.classList.add('text-gray-600')
      }
    })
    
    // 显示对应城市的地点列表
    this.cityContentTargets.forEach(content => {
      if (content.dataset.city === city) {
        content.classList.remove('hidden')
      } else {
        content.classList.add('hidden')
      }
    })
    
    this.selectedCity = city
  }

  // 选择自取地点
  selectPickupLocation(event: Event): void {
    const locationDiv = event.currentTarget as HTMLElement
    const locationId = locationDiv.dataset.locationId || ""
    const city = locationDiv.dataset.locationCity || ""
    const district = locationDiv.dataset.locationDistrict || ""
    
    // 保存临时选择
    this.tempSelectedPickupLocation = { id: locationId, city, district }
    
    // 清除所有单选框的选中状态
    this.clearPickupLocationRadios()
    
    // 更新当前选中的单选框样式
    const radio = locationDiv.querySelector('[data-wifi-booking-target="pickupLocationRadio"]') as HTMLElement
    if (radio) {
      radio.classList.remove('border-gray-300')
      radio.classList.add('bg-[#FFDD00]', 'border-[#FFDD00]')
      const checkmarkSVG = '<svg class="w-3 h-3 text-black" fill="none" stroke="currentColor" '
        + 'viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" '
        + 'stroke-width="3" d="M5 13l4 4L19 7"></path></svg>'
      radio.innerHTML = checkmarkSVG
    }
  }

  // 确认自取地点选择
  confirmPickupLocation(): void {
    if (this.tempSelectedPickupLocation) {
      this.selectedPickupLocationId = this.tempSelectedPickupLocation.id
      
      // 更新显示
      if (this.hasPickupLocationCityTarget) {
        this.pickupLocationCityTarget.textContent = this.tempSelectedPickupLocation.city
      }
      if (this.hasPickupLocationDistrictTarget) {
        this.pickupLocationDistrictTarget.textContent = this.tempSelectedPickupLocation.district
      }
    }
    
    this.closePickupLocationPicker()
  }

  // 清除所有单选框的选中状态
  private clearPickupLocationRadios(): void {
    this.pickupLocationRadioTargets.forEach(radio => {
      radio.classList.remove('bg-[#FFDD00]', 'border-[#FFDD00]')
      radio.classList.add('border-gray-300')
      radio.innerHTML = ''
    })
  }

  increase(): void {
    const currentQty = parseInt(this.quantityTarget.textContent || "1")
    this.quantityTarget.textContent = (currentQty + 1).toString()
    this.updateTotalPrice()
  }

  decrease(): void {
    const currentQty = parseInt(this.quantityTarget.textContent || "1")
    if (currentQty > 1) {
      this.quantityTarget.textContent = (currentQty - 1).toString()
      this.updateTotalPrice()
    }
  }

  private updateTotalPrice(): void {
    const quantity = parseInt(this.quantityTarget.textContent || "1")
    const total = this.dailyPrice * this.days * quantity + this.deposit  // 加上押金
    if (this.hasTotalPriceTarget) {
      this.totalPriceTarget.textContent = total.toFixed(0)
    }
  }

  checkout(event: Event): void {
    event.preventDefault()
    
    const orderableType = 'InternetWifi'
    const orderableId = this.selectedPlanId
    const quantity = this.quantityTarget.textContent || '1'
    const days = this.days
    const unitPrice = this.dailyPrice
    const qty = parseInt(quantity)
    const totalPrice = (unitPrice * days * qty) + this.deposit
    
    // Navigate to order page with params
    const baseUrl = '/internet_orders/new'
    const params = `orderable_type=${orderableType}&orderable_id=${orderableId}&quantity=${quantity}`
    const priceParams = `days=${days}&price=${unitPrice}&total=${totalPrice}`
    const url = `${baseUrl}?${params}&${priceParams}`
    window.location.href = url
  }
}
