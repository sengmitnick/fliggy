import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["count", "totalPrice", "nameInput", "idNumberInput", "quantityInput"]
  static values = {
    unitPrice: Number
  }

  declare readonly countTarget: HTMLElement
  declare readonly totalPriceTarget: HTMLElement
  declare readonly nameInputTargets: HTMLInputElement[]
  declare readonly idNumberInputTargets: HTMLInputElement[]
  declare readonly quantityInputTarget: HTMLInputElement
  declare readonly hasQuantityInputTarget: boolean
  declare unitPriceValue: number

  private currentCount: number = 1
  private readonly MAX_COUNT: number = 5
  private readonly MIN_COUNT: number = 1

  connect(): void {
    console.log("Insured person counter connected")
    this.updateTotalPrice()
  }

  increase(event: Event): void {
    event.preventDefault()
    event.stopPropagation()

    if (this.currentCount < this.MAX_COUNT) {
      this.currentCount++
      this.countTarget.textContent = this.currentCount.toString()
      this.addPersonForm()
      this.updateTotalPrice()
    } else {
      alert(`最多可为${this.MAX_COUNT}人投保`)
    }
  }

  decrease(event: Event): void {
    event.preventDefault()
    event.stopPropagation()

    if (this.currentCount > this.MIN_COUNT) {
      this.currentCount--
      this.countTarget.textContent = this.currentCount.toString()
      this.removeLastPersonForm()
      this.updateTotalPrice()
    }
  }

  private addPersonForm(): void {
    const container = document.getElementById('insured-persons-list')
    if (!container) return

    const personIndex = this.currentCount - 1
    const newItem = document.createElement('div')
    newItem.className = 'insured-person-item mb-4 pb-4 border-b border-gray-100'
    newItem.setAttribute('data-person-index', personIndex.toString())
    
    newItem.innerHTML = `
      <div class="flex items-center justify-between mb-3">
        <div class="flex items-center gap-2">
          <span class="text-sm font-medium text-gray-700">被保人 ${this.currentCount}</span>
        </div>
      </div>
      <div class="space-y-3">
        <div>
          <label class="text-xs text-gray-500 mb-1 block">姓名 *</label>
          <div class="relative">
            <input type="text" 
                   name="insurance_order[insured_persons][${personIndex}][name]" 
                   class="form-input w-full text-sm pr-10" 
                   placeholder="请输入姓名" 
                   required>
            <button type="button"
                    class="absolute right-2 top-1/2 -translate-y-1/2 p-1.5 text-gray-400 hover:text-primary transition"
                    data-person-index="${personIndex}"
                    data-action="click->insured-person-selector#openModal">
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" 
                      d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857
                      M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0z
                      M7 10a2 2 0 11-4 0 2 2 0 014 0z"/>
              </svg>
            </button>
          </div>
        </div>
        <div>
          <label class="text-xs text-gray-500 mb-1 block">身份证号 *</label>
          <input type="text" 
                 name="insurance_order[insured_persons][${personIndex}][id_number]" 
                 class="form-input w-full text-sm" 
                 placeholder="请输入身份证号" 
                 pattern="[0-9X]{18}" 
                 required>
        </div>
      </div>
    `

    container.appendChild(newItem)
  }

  private removeLastPersonForm(): void {
    const container = document.getElementById('insured-persons-list')
    if (!container) return

    const items = container.querySelectorAll('.insured-person-item')
    if (items.length > 1) {
      const lastItem = items[items.length - 1]
      lastItem.remove()
    }
  }

  private updateTotalPrice(): void {
    const totalPrice = this.unitPriceValue * this.currentCount
    this.totalPriceTarget.textContent = Math.round(totalPrice).toString()
    
    // Update hidden quantity field
    if (this.hasQuantityInputTarget) {
      this.quantityInputTarget.value = this.currentCount.toString()
    }
    
    console.log('Total price updated:', { 
      unitPrice: this.unitPriceValue, 
      count: this.currentCount, 
      totalPrice 
    })
  }
}
