import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = [
    // stimulus-validator: disable-next-line
    "nameInput",
    // stimulus-validator: disable-next-line
    "idInput"
  ]

  // stimulus-validator: disable-next-line
  declare readonly nameInputTargets: HTMLInputElement[]
  // stimulus-validator: disable-next-line
  declare readonly idInputTargets: HTMLInputElement[]

  connect(): void {
    console.log("TravelerDuplicateValidator connected")
  }

  // 验证姓名重复
  validateName(event: Event): void {
    const input = event.target as HTMLInputElement
    const currentValue = input.value.trim()
    
    if (!currentValue) {
      this.clearError(input)
      return
    }

    // 检查是否有重复
    const allNames = this.nameInputTargets
      .filter(inp => inp !== input)
      .map(inp => inp.value.trim())
      .filter(name => name !== '')

    if (allNames.includes(currentValue)) {
      this.showError(input, '该出行人姓名已存在，请勿重复添加')
    } else {
      this.clearError(input)
    }
  }

  // 验证身份证号重复
  validateIdNumber(event: Event): void {
    const input = event.target as HTMLInputElement
    const currentValue = input.value.trim()
    
    if (!currentValue) {
      this.clearError(input)
      return
    }

    // 检查是否有重复
    const allIdNumbers = this.idInputTargets
      .filter(inp => inp !== input)
      .map(inp => inp.value.trim())
      .filter(id => id !== '')

    if (allIdNumbers.includes(currentValue)) {
      this.showError(input, '该身份证号已存在，请勿重复添加')
    } else {
      this.clearError(input)
    }
  }

  private showError(input: HTMLInputElement, message: string): void {
    // 移除旧的错误提示
    this.clearError(input)

    // 添加红色边框
    const container = input.closest('.flex.items-center')
    if (container) {
      container.classList.add('border-red-500')
      
      // 创建错误提示
      const errorDiv = document.createElement('div')
      errorDiv.className = 'traveler-error-message text-xs text-red-500 mt-1 px-2'
      errorDiv.textContent = message
      
      // 插入错误提示
      container.insertAdjacentElement('afterend', errorDiv)
      
      // 禁用提交按钮
      this.disableSubmitButton()
    }
  }

  private clearError(input: HTMLInputElement): void {
    const container = input.closest('.flex.items-center')
    if (container) {
      container.classList.remove('border-red-500')
      
      // 移除错误提示
      const errorMessage = container.parentElement?.querySelector('.traveler-error-message')
      if (errorMessage) {
        errorMessage.remove()
      }
    }
    
    // 检查是否还有其他错误，没有则启用提交按钮
    const hasErrors = this.element.querySelectorAll('.traveler-error-message').length > 0
    if (!hasErrors) {
      this.enableSubmitButton()
    }
  }

  private disableSubmitButton(): void {
    const submitButton = document.querySelector('.fixed.bottom-0 button[type="submit"]') as HTMLButtonElement
    if (submitButton) {
      submitButton.disabled = true
      submitButton.classList.add('opacity-50', 'cursor-not-allowed')
    }
  }

  private enableSubmitButton(): void {
    const submitButton = document.querySelector('.fixed.bottom-0 button[type="submit"]') as HTMLButtonElement
    if (submitButton) {
      submitButton.disabled = false
      submitButton.classList.remove('opacity-50', 'cursor-not-allowed')
    }
  }
}
