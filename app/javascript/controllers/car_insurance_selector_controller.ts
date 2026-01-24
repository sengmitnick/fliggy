import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = ["option", "checkbox", "totalPrice", "originalPrice"]
  static values = {
    basePrice: Number,
    daysCount: Number
  }

  declare readonly optionTargets: HTMLElement[]
  declare readonly checkboxTargets: HTMLElement[]
  declare readonly totalPriceTargets: HTMLElement[]
  declare readonly originalPriceTargets: HTMLElement[]
  declare basePriceValue: number
  declare daysCountValue: number

  connect(): void {
    console.log('CarInsuranceSelector connected', {
      basePrice: this.basePriceValue,
      daysCount: this.daysCountValue,
      optionsCount: this.optionTargets.length
    })
    
    // 页面加载时执行一次价格计算（确保初始价格正确）
    // 但只在底部价格栏的控制器实例中执行，避免重复计算
    if (this.element.classList.contains('fixed') && this.element.classList.contains('bottom-0')) {
      // 等待 DOM 完全加载后执行
      setTimeout(() => this.updatePrice(), 100)
    }
  }

  // 选择保障套餐（单选：基础/优享/尊享，可取消）
  selectProtection(event: Event): void {
    const target = event.currentTarget as HTMLElement
    const protectionType = target.dataset.protectionType
    
    if (!protectionType || protectionType === "basic") {
      // 基础保障不可选择（已含）
      return
    }

    // 检查当前是否已选中
    const checkbox = target.querySelector<HTMLElement>(
      '[data-car-insurance-selector-target="checkbox"]'
    )
    const isCurrentlySelected = checkbox && 
      (checkbox.classList.contains("bg-green-500") || checkbox.classList.contains("bg-orange-400"))

    // 如果点击的是已选中的保障，则取消选中
    if (isCurrentlySelected) {
      if (checkbox) {
        checkbox.classList.remove("bg-green-500", "border-green-500", "bg-orange-400", "border-orange-400")
        checkbox.classList.add("border-gray-300")
        checkbox.innerHTML = ""
      }
      // 移除卡片高亮边框
      const card = target.closest<HTMLElement>('.border-2')
      if (card) {
        card.classList.remove("border-green-500", "border-orange-400")
        card.classList.add("border-gray-200")
      }
      console.log(`Deselected protection: ${protectionType}`)
      this.updatePrice()
      return
    }

    // 否则，移除其他保障的选中状态，选中当前保障
    this.optionTargets.forEach(option => {
      if (option.dataset.category === "protection") {
        const optCheckbox = option.querySelector<HTMLElement>(
          '[data-car-insurance-selector-target="checkbox"]'
        )
        if (optCheckbox) {
          optCheckbox.classList.remove("bg-green-500", "border-green-500", "bg-orange-400", "border-orange-400")
          optCheckbox.classList.add("border-gray-300")
          optCheckbox.innerHTML = ""
        }
        // 移除卡片高亮边框
        const card = option.closest<HTMLElement>('.border-2')
        if (card && card.dataset.protectionType !== "basic") {
          card.classList.remove("border-green-500", "border-orange-400")
          card.classList.add("border-gray-200")
        }
      }
    })

    // 添加选中状态
    if (checkbox) {
      if (protectionType === "premium") {
        checkbox.classList.remove("border-gray-300")
        checkbox.classList.add("bg-green-500", "border-green-500")
      } else if (protectionType === "deluxe") {
        checkbox.classList.remove("border-gray-300")
        checkbox.classList.add("bg-orange-400", "border-orange-400")
      }
      const checkIcon = '<svg class="w-3 h-3 text-white" fill="currentColor" viewBox="0 0 20 20">' +
        '<path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 ' +
        '011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"></path></svg>'
      checkbox.innerHTML = checkIcon
    }

    // 添加卡片高亮边框
    const card = target.closest<HTMLElement>('.border-2')
    if (card) {
      card.classList.remove("border-gray-200")
      if (protectionType === "premium") {
        card.classList.add("border-green-500")
      } else if (protectionType === "deluxe") {
        card.classList.add("border-orange-400")
      }
    }

    console.log(`Selected protection: ${protectionType}`)
    this.updatePrice()
  }

  // 切换平台保险（多选）
  toggleInsurance(event: Event): void {
    const target = event.currentTarget as HTMLElement
    const insuranceType = target.dataset.insuranceType
    
    if (!insuranceType) return

    const checkbox = target.querySelector<HTMLElement>(
      '[data-car-insurance-selector-target="checkbox"]'
    )
    if (!checkbox) return

    // 切换选中状态
    const isSelected = checkbox.classList.contains("border-blue-500")
    
    if (isSelected) {
      // 取消选中
      checkbox.classList.remove("border-blue-500")
      checkbox.classList.add("border-gray-200")
      checkbox.innerHTML = ""
    } else {
      // 选中
      checkbox.classList.remove("border-gray-200")
      checkbox.classList.add("border-blue-500")
      const checkIcon = '<svg class="w-3 h-3 text-blue-500" fill="currentColor" viewBox="0 0 20 20">' +
        '<path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 ' +
        '0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"></path></svg>'
      checkbox.innerHTML = checkIcon
    }

    console.log(`Toggled insurance: ${insuranceType}, selected: ${!isSelected}`)
    this.updatePrice()
  }

  // 更新价格显示
  private updatePrice(): void {
    // 获取基础价格和天数
    const basePrice = this.basePriceValue
    const daysCount = this.daysCountValue
    
    console.log('updatePrice called', { basePrice, daysCount })
    
    if (!basePrice || !daysCount) {
      console.warn('Price calculation skipped: missing basePrice or daysCount')
      return
    }

    // 计算基础租金
    let totalPrice = basePrice * daysCount
    console.log(`Base price: ${basePrice} × ${daysCount} = ${totalPrice}`)

    // 全局查找所有保障和保险选项（跨控制器实例）
    const allOptions = document.querySelectorAll<HTMLElement>(
      '[data-car-insurance-selector-target="option"]'
    )
    console.log(`Found ${allOptions.length} total options`)

    // 查找当前选中的保障套餐（单选）
    allOptions.forEach(option => {
      if (option.dataset.category !== "protection") return
      const checkbox = option.querySelector<HTMLElement>(
        '[data-car-insurance-selector-target="checkbox"]'
      )
      if (checkbox && (checkbox.classList.contains("bg-green-500") || 
        checkbox.classList.contains("bg-orange-400"))) {
        const pricePerDay = parseFloat(option.dataset.price || "0")
        totalPrice += pricePerDay * daysCount
        console.log(`+ Protection: ${option.dataset.protectionType} (${pricePerDay}/day × ${daysCount} = ${pricePerDay * daysCount})`)
      }
    })

    // 累加所有选中的平台保险（多选）
    allOptions.forEach(option => {
      if (option.dataset.category !== "platform") return
      const checkbox = option.querySelector<HTMLElement>(
        '[data-car-insurance-selector-target="checkbox"]'
      )
      if (checkbox && checkbox.classList.contains("border-blue-500")) {
        const pricePerDay = parseFloat(option.dataset.price || "0")
        totalPrice += pricePerDay * daysCount
        console.log(`+ Insurance: ${option.dataset.insuranceType} (${pricePerDay}/day × ${daysCount} = ${pricePerDay * daysCount})`)
      }
    })

    // 更新所有价格显示元素（跨控制器实例）
    const allTotalPriceElements = document.querySelectorAll<HTMLElement>(
      '[data-car-insurance-selector-target="totalPrice"]'
    )
    allTotalPriceElements.forEach(el => {
      el.textContent = Math.round(totalPrice).toString()
    })

    // 更新原价（按1.45倍计算）
    const allOriginalPriceElements = document.querySelectorAll<HTMLElement>(
      '[data-car-insurance-selector-target="originalPrice"]'
    )
    allOriginalPriceElements.forEach(el => {
      el.textContent = `¥${Math.round(totalPrice * 1.45)}`
    })

    console.log(`Total price updated: ¥${Math.round(totalPrice)} ` +
      `(base: ${basePrice * daysCount} for ${daysCount} days)`)
    
    // 同步更新支付确认控制器的金额
    this.updatePaymentAmount(Math.round(totalPrice))
  }

  // 更新支付确认控制器的金额
  private updatePaymentAmount(amount: number): void {
    // 查找 payment-confirmation 控制器实例
    const paymentElement = document.querySelector<HTMLElement>('[data-controller~="payment-confirmation"]')
    if (paymentElement) {
      // 更新 data-payment-confirmation-amount-value 属性
      paymentElement.setAttribute('data-payment-confirmation-amount-value', amount.toString())
      
      // 触发 Stimulus 值变化事件（如果控制器已连接）
      const event = new CustomEvent('payment-confirmation:amount-changed', {
        detail: { amount: amount }
      })
      paymentElement.dispatchEvent(event)
      
      console.log(`Payment amount updated to: ¥${amount}`)
    }
  }
}
