import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = [
    "termsModal", "insuranceModal", "memberModal", "confirmModal",
    "confirmModalPassengerList", "totalPriceAmount", "passengerCount",
    "passengerCountText", "checkIcon"
  ]

  declare readonly termsModalTarget: HTMLElement
  declare readonly insuranceModalTarget: HTMLElement
  declare readonly memberModalTarget: HTMLElement
  declare readonly confirmModalTarget: HTMLElement
  declare readonly confirmModalPassengerListTarget: HTMLElement
  declare readonly totalPriceAmountTarget: HTMLElement
  declare readonly passengerCountTarget: HTMLElement
  declare readonly passengerCountTextTarget: HTMLElement
  declare readonly checkIconTargets: HTMLElement[]

  // 追踪会员检查是否已完成
  private memberCheckCompleted: boolean = false
  // 追踪是否为会员确认后的第二次等待
  private isSecondWait: boolean = false
  // 存储需要注册的航空公司列表
  private missingAirlines: string[] = []
  // 多乘客选择
  private selectedPassengers: Map<string, { name: string, type: string, idNumber: string, phone: string }> = new Map()

  connect(): void {
    // Load selected passengers from localStorage (from search page)
    this.loadPassengersFromLocalStorage()
    
    // Set default insurance selection visual style ("无保障" is checked by default)
    this.initializeDefaultInsuranceStyle()
  }

  private initializeDefaultInsuranceStyle(): void {
    // Find the default checked radio button (无保障)
    const defaultRadio = document.querySelector('input[name="insurance_selection"][checked]') as HTMLInputElement
    if (defaultRadio) {
      const card = defaultRadio.closest('[data-insurance-card]') as HTMLElement
      if (card) {
        // Remove default gray border
        card.classList.remove('border-gray-300')
        // Add gray border for "无保障" selection
        card.classList.add('border-gray-400')
        // Show checkmark
        const checkmark = card.querySelector('.bg-yellow-400') as HTMLElement
        if (checkmark) {
          checkmark.style.display = 'flex'
        }
      }
    }
  }

  private updateConfirmModalPassengers(): void {
    if (!this.confirmModalPassengerListTarget) return
    
    // Get selected passengers from Map
    const passengers = Array.from(this.selectedPassengers.values())
    
    if (passengers.length === 0) {
      this.confirmModalPassengerListTarget.innerHTML = '<div class="text-gray-500 text-center">未选择乘客</div>'
      return
    }
    
    // Generate HTML for each passenger
    const passengersHtml = passengers.map(passenger => {
      // Mask ID number: show first 6 and last 4 digits
      const maskedIdNumber = passenger.idNumber.length >= 18 
        ? passenger.idNumber.replace(/(\d{6})\d{8}(\d{4})/, '$1********$2')
        : passenger.idNumber
      
      const childBadge = passenger.type === 'child'
        ? '<span class="ml-2 px-2 py-0.5 bg-orange-50 text-orange-600 text-xs border border-orange-300 rounded">儿童票</span>'
        : ''
      
      const svgPath = 'M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z'
      
      return `
        <div class="flex items-center justify-between mb-3">
          <div>
            <div class="font-bold">
              ${passenger.name} ${maskedIdNumber} 身份证
              ${childBadge}
            </div>
            <div class="text-green-600 flex items-center mt-1">
              <svg class="w-5 h-5 mr-1" fill="currentColor" viewBox="0 0 20 20">
                <path fill-rule="evenodd" d="${svgPath}" clip-rule="evenodd"/>
              </svg>
            </div>
          </div>
        </div>
      `
    }).join('')
    
    // Populate the container
    this.confirmModalPassengerListTarget.innerHTML = passengersHtml
  }

  private loadPassengersFromLocalStorage(): void {
    const savedState = localStorage.getItem('passenger_selection')
    if (!savedState) return
    
    try {
      const state = JSON.parse(savedState)
      const passengerIds = state.passengerIds || []
      
      // Only apply if passenger names mode was used (not count mode)
      if (passengerIds.length === 0) return
      
      let firstAdultPhone = ''
      
      // Find and select passengers by their IDs
      passengerIds.forEach((passengerId: number) => {
        const passengerElement = document.querySelector(`[data-passenger-id="${passengerId}"]`) as HTMLElement
        if (passengerElement) {
          const passengerName = passengerElement.dataset.passengerName || ''
          const passengerType = passengerElement.dataset.passengerType || 'adult'
          const passengerIdNumber = passengerElement.dataset.passengerIdNumber || ''
          const passengerPhone = passengerElement.dataset.passengerPhone || ''
          
          // Add to selected passengers
          this.selectedPassengers.set(passengerId.toString(), {
            name: passengerName,
            type: passengerType,
            idNumber: passengerIdNumber,
            phone: passengerPhone
          })
          
          // Update UI to show selected state
          this.updatePassengerUI(passengerElement, true)
          
          // Store first adult passenger's phone
          if (!firstAdultPhone && passengerType === 'adult' && passengerPhone) {
            firstAdultPhone = passengerPhone
          }
        }
      })
      
      // Auto-fill contact phone with first adult passenger's phone
      if (firstAdultPhone) {
        const contactPhoneField = document.getElementById('booking_contact_phone') as HTMLInputElement
        if (contactPhoneField && !contactPhoneField.value) {
          contactPhoneField.value = firstAdultPhone
        }
      }
      
      // Update displays after loading all passengers
      this.updatePassengerCountDisplay()
      this.updateTotalPrice()
      this.updateHiddenField()
    } catch (e) {
      console.error('Failed to load passengers from localStorage:', e)
    }
  }

  togglePassenger(event: Event): void {
    const target = event.currentTarget as HTMLElement
    const passengerId = target.dataset.passengerId
    const passengerName = target.dataset.passengerName
    const passengerType = target.dataset.passengerType || 'adult'
    const passengerIdNumber = target.dataset.passengerIdNumber || ''
    const passengerPhone = target.dataset.passengerPhone || ''
    
    if (!passengerId || !passengerName) return
    
    // Check if already selected
    if (this.selectedPassengers.has(passengerId)) {
      this.selectedPassengers.delete(passengerId)
      this.updatePassengerUI(target, false)
    } else {
      // Check max limit (3 passengers for flight)
      if (this.selectedPassengers.size >= 3) {
        alert('最多只能选择3位乘机人')
        return
      }
      
      this.selectedPassengers.set(passengerId, {
        name: passengerName,
        type: passengerType,
        idNumber: passengerIdNumber,
        phone: passengerPhone
      })
      this.updatePassengerUI(target, true)
    }
    
    this.updatePassengerCountDisplay()
    this.updateTotalPrice()
    this.updateHiddenField()
  }

  private updatePassengerUI(element: HTMLElement, selected: boolean): void {
    const checkIcon = element.querySelector('[data-booking-target="checkIcon"]') as HTMLElement
    if (checkIcon) {
      if (selected) {
        checkIcon.classList.remove('text-gray-300')
        checkIcon.classList.add('text-yellow-400')
      } else {
        checkIcon.classList.add('text-gray-300')
        checkIcon.classList.remove('text-yellow-400')
      }
    }
  }

  private updatePassengerCountDisplay(): void {
    const count = this.selectedPassengers.size
    if (this.passengerCountTarget) {
      this.passengerCountTarget.textContent = `已选${count}人`
    }
    if (this.passengerCountTextTarget) {
      this.passengerCountTextTarget.textContent = `共${count}人`
    }
  }

  private updateHiddenField(): void {
    const passengerIds = Array.from(this.selectedPassengers.keys()).join(',')
    const hiddenField = document.getElementById('booking_passenger_ids') as HTMLInputElement
    if (hiddenField) {
      hiddenField.value = passengerIds
    }
  }

  selectPassenger(event: Event): void {
    const radio = event.currentTarget as HTMLInputElement
    const idNumber = radio.dataset.idNumber || ''
    const phone = radio.dataset.phone || ''
    
    // 填充隐藏字段
    const idNumberField = document.getElementById('passenger_id_number') as HTMLInputElement
    
    if (idNumberField) {
      idNumberField.value = idNumber
    }

    // 自动填充联系电话
    const contactPhoneField = document.getElementById('booking_contact_phone') as HTMLInputElement
    
    if (contactPhoneField && phone) {
      contactPhoneField.value = phone
    }
  }

  selectInsurance(event: Event): void {
    const button = event.currentTarget as HTMLButtonElement
    const insuranceType = button.dataset.insuranceType || 'none'
    const insurancePrice = button.dataset.insurancePrice || '0'
    
    this.setInsuranceValues(insuranceType, insurancePrice)
    this.closeInsuranceModal()
  }

  setInsuranceValues(insuranceType: string, insurancePrice: string): void {
    const insuranceTypeField = document.getElementById('booking_insurance_type') as HTMLInputElement
    const insurancePriceField = document.getElementById('booking_insurance_price') as HTMLInputElement
    
    if (insuranceTypeField) {
      insuranceTypeField.value = insuranceType
    }
    
    if (insurancePriceField) {
      insurancePriceField.value = insurancePrice
    }
  }

  // 处理表单中的保险选项卡选择
  selectInsuranceOption(event: Event): void {
    const radio = event.currentTarget as HTMLInputElement
    const insuranceType = radio.dataset.insuranceType || 'none'
    const insurancePrice = radio.dataset.insurancePrice || '0'
    
    // 更新隐藏字段
    this.setInsuranceValues(insuranceType, insurancePrice)
    
    // 更新视觉指示器（边框和对号）
    const allCards = document.querySelectorAll('[data-insurance-card]')
    allCards.forEach(card => {
      card.classList.remove('border-yellow-400', 'border-blue-400', 'border-gray-400')
      card.classList.add('border-2', 'border-gray-300')
      const checkmark = card.querySelector('.bg-yellow-400') as HTMLElement
      if (checkmark) {
        checkmark.style.display = 'none'
      }
    })
    
    // 为选中的卡片添加样式
    const selectedCard = radio.closest('[data-insurance-card]') as HTMLElement
    if (selectedCard) {
      selectedCard.classList.remove('border-gray-300')
      if (insuranceType === 'standard') {
        selectedCard.classList.add('border-yellow-400')
      } else if (insuranceType === 'premium') {
        selectedCard.classList.add('border-blue-400')
      } else {
        selectedCard.classList.add('border-gray-400')
      }
      const checkmark = selectedCard.querySelector('.bg-yellow-400') as HTMLElement
      if (checkmark) {
        checkmark.style.display = 'flex'
      }
    }

    // 更新底部总价
    this.updateTotalPrice()
  }

  // 更新总价显示
  private updateTotalPrice(): void {
    if (!this.totalPriceAmountTarget) return
    
    const basePrice = parseInt(this.totalPriceAmountTarget.dataset.basePrice || '0')
    const insurancePriceField = document.getElementById('booking_insurance_price') as HTMLInputElement
    const insurancePrice = parseInt(insurancePriceField?.value || '0')
    
    // 计算总价：基础价格 × 乘客人数 + 保险价格 × 乘客人数
    const passengerCount = this.selectedPassengers.size || 0
    const totalPrice = (basePrice * passengerCount) + (insurancePrice * passengerCount)
    
    this.totalPriceAmountTarget.textContent = totalPrice.toString()
  }

  showTermsModal(event: Event): void {
    event.preventDefault()
    this.termsModalTarget.classList.remove('hidden')
  }

  closeTermsModal(): void {
    this.termsModalTarget.classList.add('hidden')
  }

  acceptTerms(): void {
    const termsCheckbox = document.getElementById('booking_accept_terms') as HTMLInputElement
    if (termsCheckbox) {
      termsCheckbox.checked = true
    }
    this.closeTermsModal()
    
    // 检查用户是否已选择保险
    const insuranceTypeField = document.getElementById('booking_insurance_type') as HTMLInputElement
    const insuranceType = insuranceTypeField?.value || 'none'
    
    if (insuranceType === 'none') {
      // 用户未选择保险，显示保险推荐弹窗
      this.showInsuranceModal()
    } else {
      // 用户已选择保险，跳过保险弹窗，直接进入确认流程
      this.showConfirmModal()
    }
  }

  showInsuranceModal(): void {
    this.insuranceModalTarget.classList.remove('hidden')
  }

  closeInsuranceModal(): void {
    this.insuranceModalTarget.classList.add('hidden')
    this.showConfirmModal()
  }

  skipInsurance(): void {
    this.setInsuranceValues('none', '0')
    this.closeInsuranceModal()
  }

  showMemberModal(): void {
    // 更新弹窗中的航空公司列表显示
    this.updateMemberModalContent()
    this.memberModalTarget.classList.remove('hidden')
  }

  updateMemberModalContent(): void {
    // 更新会员弹窗中显示的航空公司名称
    const airlineTextElement = this.memberModalTarget.querySelector('[data-airline-names]') as HTMLElement
    if (airlineTextElement && this.missingAirlines.length > 0) {
      const airlinesText = this.missingAirlines.join('、')
      airlineTextElement.textContent = airlinesText
    }
  }

  closeMemberModal(): void {
    this.memberModalTarget.classList.add('hidden')
    // 标记会员检查已完成（用户同意注册会员）
    this.memberCheckCompleted = true
    // 标记为第二次等待
    this.isSecondWait = true
    // 会员确认后，再次显示等待弹窗
    this.showConfirmModal()
  }

  showConfirmModal(): void {
    // Update passenger list in confirmation modal with actual selected passengers
    this.updateConfirmModalPassengers()
    
    this.confirmModalTarget.classList.remove('hidden')
    
    // 如果是第二次等待（会员确认后），等待5-10秒后提交
    if (this.isSecondWait) {
      const waitTime = Math.floor(Math.random() * (10000 - 5000 + 1)) + 5000
      setTimeout(() => {
        this.submitForm()
      }, waitTime)
      return
    }
    
    // 第一次显示等待弹窗时，立即检查会员状态（无需等待）
    this.checkMembershipStatusFromDB().then(needsMemberRegistration => {
      if (needsMemberRegistration) {
        // 如果需要注册会员，关闭确认弹窗并显示会员弹窗
        this.closeConfirmModal()
        this.showMemberModal()
      } else {
        // 如果已是会员，保持等待弹窗显示，等待5-10秒后提交
        this.memberCheckCompleted = true
        const waitTime = Math.floor(Math.random() * (10000 - 5000 + 1)) + 5000
        setTimeout(() => {
          this.submitForm()
        }, waitTime)
      }
    })
  }

  async checkMembershipStatusFromDB(): Promise<boolean> {
    // 从数据库检查当前用户是否为所有相关航空公司的会员
    try {
      const urlParams = new URLSearchParams(window.location.search)
      const flightId = urlParams.get('flight_id')
      const returnFlightId = urlParams.get('return_flight_id')
      
      // 构建请求 URL，包含去程和回程航班 ID
      let url = `/api/check_membership?flight_id=${flightId}`
      if (returnFlightId) {
        url += `&return_flight_id=${returnFlightId}`
      }
      
      const response = await fetch(url, {
        headers: {
          'Accept': 'application/json'
        }
      })
      
      if (!response.ok) {
        // 如果请求失败，默认假设需要注册会员
        this.missingAirlines = []
        return true
      }
      
      const data = await response.json()
      // 存储缺失的航空公司会员身份
      this.missingAirlines = data.missing_airlines || []
      
      return !data.is_member // 返回true表示需要注册会员
    } catch (error) {
      console.error('检查会员状态失败:', error)
      // 发生错误时，默认假设需要注册会员
      this.missingAirlines = []
      return true
    }
  }

  closeConfirmModal(): void {
    this.confirmModalTarget.classList.add('hidden')
  }

  submitForm(): void {
    // stimulus-validator: disable-next-line
    const form = this.element.querySelector('form') as HTMLFormElement
    if (form) {
      form.submit()
    }
  }

  handleSubmit(event: Event): void {
    event.preventDefault()
    
    // 验证是否已选择乘机人（检查 passenger_ids hidden field）
    const passengerIdsField = document.getElementById('booking_passenger_ids') as HTMLInputElement
    const selectedPassengerIds = passengerIdsField?.value || ''
    
    if (!selectedPassengerIds || selectedPassengerIds.trim() === '') {
      // 显示错误提示
      if (window.showToast) {
        window.showToast('请先选择乘机人')
      } else {
        alert('请先选择乘机人')
      }
      return
    }
    
    // 验证联系电话是否已填写
    const contactPhoneField = document.getElementById('booking_contact_phone') as HTMLInputElement
    const contactPhone = contactPhoneField?.value || ''
    
    if (!contactPhone || contactPhone.trim() === '') {
      // 显示错误提示
      if (window.showToast) {
        window.showToast('请填写联系电话')
      } else {
        alert('请填写联系电话')
      }
      // 聚焦到联系电话输入框
      contactPhoneField?.focus()
      return
    }
    
    // 重置会员检查标志
    this.memberCheckCompleted = false
    this.isSecondWait = false
    this.showTermsModal(event)
  }
}
