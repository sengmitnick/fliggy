import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = ["quantity", "itemTotal"]
  static values = {
    unitPrice: Number,
    min: { type: Number, default: 1 },
    max: { type: Number, default: 99 }
  }

  declare readonly quantityTarget: HTMLElement
  declare readonly itemTotalTarget: HTMLElement
  declare readonly hasQuantityTarget: boolean
  declare readonly hasItemTotalTarget: boolean
  declare readonly unitPriceValue: number
  declare readonly minValue: number
  declare readonly maxValue: number

  private quantity: number = 1

  connect(): void {
    console.log("BookingQuantity connected")
    // 从hidden fields读取初始数量
    const adultCountField = document.querySelector<HTMLInputElement>('input[name="tour_group_booking[adult_count]"]')
    const childCountField = document.querySelector<HTMLInputElement>('input[name="tour_group_booking[child_count]"]')
    
    if (adultCountField && childCountField) {
      this.quantity = parseInt(adultCountField.value) + parseInt(childCountField.value)
      this.updateDisplay()
    }
  }

  disconnect(): void {
    console.log("BookingQuantity disconnected")
  }

  increase(): void {
    if (this.quantity < this.maxValue) {
      this.quantity++
      this.updateDisplay()
      this.updateHiddenFields()
      this.notifyPriceChange()
    }
  }

  decrease(): void {
    if (this.quantity > this.minValue) {
      this.quantity--
      this.updateDisplay()
      this.updateHiddenFields()
      this.notifyPriceChange()
    }
  }

  private updateDisplay(): void {
    // 更新数量显示
    if (this.hasQuantityTarget) {
      this.quantityTarget.textContent = this.quantity.toString()
    }
    
    // 更新小计
    if (this.hasItemTotalTarget) {
      const itemTotal = this.unitPriceValue * this.quantity
      this.itemTotalTarget.textContent = `¥${itemTotal}`
    }
  }

  private updateHiddenFields(): void {
    // 更新hidden fields(全部算作成人)
    const adultCountField = document.querySelector<HTMLInputElement>('input[name="tour_group_booking[adult_count]"]')
    const childCountField = document.querySelector<HTMLInputElement>('input[name="tour_group_booking[child_count]"]')
    
    if (adultCountField && childCountField) {
      adultCountField.value = this.quantity.toString()
      childCountField.value = "0"
    }

    // 更新出行人数显示 - 使用更精确的选择器避免误选
    const travelerSections = document.querySelectorAll('.text-base.font-semibold.text-foreground')
    travelerSections.forEach(element => {
      if (element.textContent?.includes('选择') && element.textContent?.includes('位游客')) {
        element.textContent = `选择 ${this.quantity} 位游客`
      }
    })
    
    // 动态更新出行人表单
    this.updateTravelerForms()
  }

  private notifyPriceChange(): void {
    // 通知insurance_selector更新总价
    const basePrice = this.unitPriceValue * this.quantity
    const event = new CustomEvent("booking-quantity:changed", {
      detail: { 
        basePrice: basePrice,
        quantity: this.quantity
      }
    })
    window.dispatchEvent(event)
  }

  private updateTravelerForms(): void {
    // 找到出行人信息容器（包含"选择X位游客"标题的section）
    const travelerSection = document.querySelector('[data-traveler-toggle-target="travelerSection"]')
    if (!travelerSection) {
      console.warn('未找到出行人信息容器')
      return
    }
    
    // 找到所有已存在的出行人表单卡片
    const existingForms = travelerSection.querySelectorAll('.mb-4.p-4.bg-surface.rounded-lg.border.border-border')
    const currentCount = existingForms.length
    
    if (this.quantity > currentCount) {
      // 需要添加表单
      const formsToAdd = this.quantity - currentCount
      
      for (let i = 0; i < formsToAdd; i++) {
        const newIndex = currentCount + i
        const newForm = this.createTravelerForm(newIndex, 'adult')
        
        // 在"更多出行人"按钮之前插入
        const addButton = travelerSection.querySelector('button[type="button"].w-full.py-3')
        if (addButton) {
          travelerSection.insertBefore(newForm, addButton)
        }
      }
    } else if (this.quantity < currentCount) {
      // 需要删除表单（从最后一个开始删除）
      const formsToRemove = currentCount - this.quantity
      for (let i = 0; i < formsToRemove; i++) {
        const lastFormIndex = currentCount - 1 - i
        const formToRemove = existingForms[lastFormIndex] as HTMLElement
        formToRemove.remove()
      }
    }
  }

  private createTravelerForm(index: number, type: 'adult' | 'child'): HTMLElement {
    const div = document.createElement('div')
    div.className = 'mb-4 p-4 bg-surface rounded-lg border border-border'
    div.innerHTML = `
      <div class="flex items-center justify-between mb-3">
        <div class="flex items-center gap-2">
          <div class="w-10 h-10 bg-primary text-white rounded-full flex items-center justify-center font-semibold">
            ${type === 'adult' ? '成' : '儿'}
          </div>
          <span class="text-sm font-medium text-foreground">
            ${type === 'adult' ? '成人' : '儿童'}
          </span>
        </div>
      </div>
      
      <div class="space-y-3">
        <div class="flex items-center py-2 border-b border-border">
          <label class="text-sm text-foreground-muted w-16">姓名</label>
          <input type="text" 
                 name="tour_group_booking[booking_travelers_attributes][${index}][traveler_name]" 
                 placeholder="请输入姓名"
                 data-tour-traveler-selector-target="travelerNameInput"
                 data-traveler-duplicate-validator-target="nameInput"
                 data-action="blur->traveler-duplicate-validator#validateName"
                 class="flex-1 text-sm text-foreground focus:outline-none" />
          <button type="button" 
                  class="text-blue-500"
                  data-action="click->tour-traveler-selector#openModal"
                  data-traveler-index="${index}">
            <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
              <path d="M10 9a3 3 0 100-6 3 3 0 000 6zm-7 9a7 7 0 1114 0H3z"></path>
            </svg>
          </button>
        </div>
        
        <div class="flex items-center py-2">
          <label class="text-sm text-foreground-muted w-16">身份证</label>
          <input type="text" 
                 name="tour_group_booking[booking_travelers_attributes][${index}][id_number]" 
                 placeholder="请输入身份证号"
                 data-tour-traveler-selector-target="travelerIdInput"
                 data-traveler-duplicate-validator-target="idInput"
                 data-action="blur->traveler-duplicate-validator#validateIdNumber"
                 class="flex-1 text-sm text-foreground focus:outline-none" />
        </div>
        
        <input type="hidden" 
               name="tour_group_booking[booking_travelers_attributes][${index}][traveler_type]" 
               value="${type}" />
      </div>
    `
    return div
  }
}
