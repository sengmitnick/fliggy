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
    const container = document.querySelector('.bg-white.px-4.py-4 > div:has(> h3.text-base.font-semibold.text-foreground)')
    if (!container) return
    
    // 找到所有已存在的出行人表单
    const existingForms = container.querySelectorAll('.mb-4.p-4.bg-surface.rounded-lg.border.border-border')
    const currentCount = existingForms.length
    
    if (this.quantity > currentCount) {
      // 需要添加表单
      const formsToAdd = this.quantity - currentCount
      const lastForm = existingForms[existingForms.length - 1] as HTMLElement
      
      for (let i = 0; i < formsToAdd; i++) {
        const newForm = this.createTravelerForm(currentCount + i, 'adult')
        // 在“更多出行人”按钮之前插入
        const addButton = container.querySelector('button[type="button"].w-full')
        if (addButton) {
          addButton.parentElement?.insertBefore(newForm, addButton)
        }
      }
    } else if (this.quantity < currentCount) {
      // 需要删除表单
      const formsToRemove = currentCount - this.quantity
      for (let i = 0; i < formsToRemove; i++) {
        const lastForm = existingForms[currentCount - 1 - i] as HTMLElement
        lastForm.remove()
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
        <button type="button" class="w-6 h-6 text-foreground-muted">
          <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" 
                  d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z">
            </path>
          </svg>
        </button>
      </div>
      
      <div class="space-y-3">
        <div class="flex items-center py-2 border-b border-border">
          <label class="text-sm text-foreground-muted w-16">姓名</label>
          <input type="text" 
                 name="tour_group_booking[booking_travelers_attributes][${index}][traveler_name]" 
                 placeholder="请输入姓名"
                 class="flex-1 text-sm text-foreground focus:outline-none" />
          <button type="button" class="text-blue-500">
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
