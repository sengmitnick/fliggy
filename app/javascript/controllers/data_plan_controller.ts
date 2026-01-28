import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = ["totalPrice", "paymentButton", "typeTab", "planCard"]
  declare readonly totalPriceTarget: HTMLElement
  declare readonly hasTotalPriceTarget: boolean
  declare readonly paymentButtonTarget: HTMLAnchorElement
  declare readonly hasPaymentButtonTarget: boolean
  declare readonly typeTabTargets: HTMLElement[]
  declare readonly planCardTargets: HTMLElement[]

  private selectedPlanId: string = ""
  private selectedPrice: number = 35
  private currentPlanType: string = "天包"

  connect(): void {
    console.log("DataPlan connected")
    // 初始化时只显示天包
    this.filterPlansByType("天包")
  }

  switchPlanType(event: Event): void {
    const tab = event.currentTarget as HTMLElement
    const planType = tab.dataset.planType || "天包"
    
    this.currentPlanType = planType
    
    // 更新所有标签的样式
    this.typeTabTargets.forEach(t => {
      // 移除对勾
      const checkmark = t.querySelector('.bg-\\[\\#FFD200\\]')
      if (checkmark) checkmark.remove()
      
      // 设置为未选中状态：灰色背景
      t.classList.remove('bg-[#FFF8D6]', 'border-[#FFEBA4]')
      t.classList.add('bg-gray-100', 'border-gray-200')
      
      // 设置文字为灰色
      const span = t.querySelector('span')
      if (span) {
        span.classList.remove('text-gray-800')
        span.classList.add('text-gray-600')
      }
    })
    
    // 设置当前标签为选中状态：黄色背景
    tab.classList.remove('bg-gray-100', 'border-gray-200')
    tab.classList.add('bg-[#FFF8D6]', 'border-[#FFEBA4]')
    
    // 设置文字为深色
    const currentSpan = tab.querySelector('span')
    if (currentSpan) {
      currentSpan.classList.remove('text-gray-600')
      currentSpan.classList.add('text-gray-800')
    }
    
    // 添加选中标记到当前标签
    const checkmarkHTML = `
      <div class="ml-1 w-2 h-2 bg-[#FFD200] rounded-full flex items-center justify-center text-[6px]">✓</div>
    `
    tab.insertAdjacentHTML('beforeend', checkmarkHTML)
    
    // 过滤套餐卡片
    this.filterPlansByType(planType)
  }

  filterPlansByType(planType: string): void {
    let firstVisibleCard: HTMLElement | null = null
    
    this.planCardTargets.forEach(card => {
      const cardPlanType = card.dataset.planType || ""
      if (cardPlanType === planType) {
        card.classList.remove('hidden')
        if (!firstVisibleCard) firstVisibleCard = card
      } else {
        card.classList.add('hidden')
      }
    })
    
    // 自动选择第一个可见的套餐
    if (firstVisibleCard) {
      this.selectPlanCard(firstVisibleCard)
    }
  }

  selectPlanCard(card: HTMLElement): void {
    const planId = card.dataset.planId || ""
    const price = parseFloat(card.dataset.planPrice || "35")
    
    this.selectedPlanId = planId
    this.selectedPrice = price
    
    // 更新总价
    if (this.hasTotalPriceTarget) {
      this.totalPriceTarget.textContent = price.toFixed(0)
    }
    
    // 更新支付按钮URL
    if (this.hasPaymentButtonTarget) {
      const url = new URL(this.paymentButtonTarget.href, window.location.href)
      url.searchParams.set('orderable_id', planId)
      this.paymentButtonTarget.href = url.toString()
    }
    
    // 更新UI - 移除所有选中状态
    this.planCardTargets.forEach(c => {
      if (!c.classList.contains('hidden')) {
        c.classList.remove('bg-[#FFF9E6]', 'border-[#FFD200]')
        c.classList.add('bg-[#F7F8FA]')
        c.classList.remove('border')
        // 移除对勾
        const checkmark = c.querySelector('.absolute.bottom-0.right-0')
        if (checkmark) checkmark.remove()
      }
    })
    
    // 添加选中状态到点击的卡片
    card.classList.add('bg-[#FFF9E6]', 'border', 'border-[#FFD200]')
    card.classList.remove('bg-[#F7F8FA]')
    
    // 添加对勾
    const checkmarkHTML = `
      <div class="absolute bottom-0 right-0 w-0 h-0 border-solid border-[0_0_20px_24px] border-transparent border-b-[#FFD200] rounded-br-lg">
        <svg class="absolute bottom-[-16px] right-[2px] w-2 h-2 text-black" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="4">
          <path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7"></path>
        </svg>
      </div>
    `
    card.insertAdjacentHTML('beforeend', checkmarkHTML)
  }

  selectPlan(event: Event): void {
    const card = event.currentTarget as HTMLElement
    this.selectPlanCard(card)
  }

  checkout(event: Event): void {
    event.preventDefault()
    
    // Get selected plan info
    const orderableType = 'InternetDataPlan'
    const orderableId = this.selectedPlanId
    const price = this.selectedPrice
    
    // Get validity days from selected plan
    const selectedCard = this.element.querySelector(`[data-plan-id="${orderableId}"]`) as HTMLElement
    let days = '1' // default
    if (selectedCard) {
      // Try to extract days from plan name (e.g., "中国香港1天")
      const planName = selectedCard.querySelector('.font-bold')?.textContent || ''
      const daysMatch = planName.match(/(\d+)天/)
      if (daysMatch) {
        days = daysMatch[1]
      }
    }
    
    // Navigate to order page with params
    const baseUrl = '/internet_orders/new'
    const params = `orderable_type=${orderableType}&orderable_id=${orderableId}`
    const priceParams = `days=${days}&price=${price}&total=${price}`
    const url = `${baseUrl}?${params}&${priceParams}`
    window.location.href = url
  }
}
