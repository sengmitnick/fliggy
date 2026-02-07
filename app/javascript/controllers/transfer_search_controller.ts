import { Controller } from "@hotwired/stimulus"

/**
 * 接送机/接送站搜索控制器
 * 
 * 功能：
 * - 处理"搜索接送机/接送站"按钮点击事件
 * - 验证用户输入（地点、时间）
 * - 根据服务类型（to_airport/from_airport）构建不同的字段映射
 * - 跳转到车辆列表页面
 * 
 * 字段映射逻辑：
 * - to_airport/to_station（送我到机场/车站）：
 *   - location_from = 上车点（用户选择的接送点）
 *   - location_to = 机场/车站（目的地）
 *   - pickup_time = 用车时间（必填）
 * 
 * - from_airport/from_station（到机场/车站接我）：
 *   - location_from = 机场/车站（从航班/火车数据获取）
 *   - location_to = 下车点（用户选择的接送点）
 *   - pickup_time = 不需要（因为航班/火车已有到达时间）
 */
export default class extends Controller<HTMLElement> {
  static values = {
    transferType: String,  // 'airport_pickup' 或 'train_pickup'
    serviceType: String,   // 'to_airport', 'from_airport', 'to_station', 'from_station'
    flightId: String,      // 航班ID（如果是接送机）
    trainId: String        // 火车ID（如果是接送站）
  }

  declare readonly transferTypeValue: string
  declare readonly serviceTypeValue: string
  declare readonly flightIdValue: string
  declare readonly trainIdValue: string

  connect(): void {
    console.log('🚀🚀🚀 [TransferSearch] Controller connected - VERSION 3.0 🚀🚀🚀')
    console.log('[TransferSearch] Button element:', this.element)
    console.log('[TransferSearch] Values:', {
      transferType: this.transferTypeValue,
      serviceType: this.serviceTypeValue,
      flightId: this.flightIdValue,
      trainId: this.trainIdValue
    })
  }

  /**
   * 处理搜索按钮点击
   * 
   * 验证流程：
   * 1. 根据 service_type 确定字段映射关系
   * 2. 验证必填字段：
   *    - to_airport/to_station: 上车点、目的地、用车时间
   *    - from_airport/from_station: 下车点
   * 3. 构建 URL 参数并跳转
   */
  handleSearch(event: Event): void {
    console.log('🔍🔍🔍 [TransferSearch] handleSearch CALLED 🔍🔍🔍')
    event.preventDefault()
    
    console.log('[TransferSearch] Service type:', this.serviceTypeValue)
    
    let locationFrom = ''
    let locationTo = ''
    let pickupTime = ''
    
    // 判断服务类型：送我到机场/车站 vs 到机场/车站接我
    if (this.serviceTypeValue === 'to_airport' || this.serviceTypeValue === 'to_station') {
      // ============ 送我到机场/车站模式 ============
      // location_from = 上车点（用户选择的接送点）
      // location_to = 机场/车站（目的地）
      // pickup_time = 用车时间（必填）
      
      const locationFromInput = document.getElementById('transfer-location-from') as HTMLInputElement
      locationFrom = locationFromInput?.value || ''
      
      if (this.serviceTypeValue === 'to_airport') {
        const airportDestInput = document.getElementById('transfer-airport-destination') as HTMLInputElement
        locationTo = airportDestInput?.value || ''
      } else {
        const stationDestInput = document.getElementById('transfer-station-destination') as HTMLInputElement
        locationTo = stationDestInput?.value || ''
      }
      
      console.log('[TransferSearch] TO mode - locationFrom (pickup):', locationFrom)
      console.log('[TransferSearch] TO mode - locationTo (destination):', locationTo)
      
      // 验证1: 上车点必须选择
      if (!locationFrom || locationFrom.trim() === '') {
        alert('请先选择上车点')
        return
      }
      
      // 验证2: 目的地（机场/车站）必须选择
      if (!locationTo || locationTo.trim() === '') {
        const destType = this.serviceTypeValue === 'to_airport' ? '机场' : '火车站'
        alert(`请先选择${destType}`)
        return
      }
      
      // 验证3: 用车时间必须选择（送我到机场/车站模式下必填）
      const timePickerDisplay = this.element.closest('.bg-surface')?.querySelector('[data-controller="transfer-time-picker"] h2') as HTMLElement
      pickupTime = timePickerDisplay?.textContent?.trim() || ''
      
      console.log('[TransferSearch] Pickup time:', pickupTime)
      
      if (!pickupTime || pickupTime === '请选择时间') {
        alert('请选择用车时间')
        return
      }
    } else {
      // ============ 到机场/车站接我模式 ============
      // location_from = 机场/车站（从航班/火车数据获取）
      // location_to = 下车点（用户选择的接送点）
      // pickup_time = 不需要（航班/火车已有到达时间）
      
      const locationFromElement = document.querySelector('[data-location-from]') as HTMLElement
      if (locationFromElement) {
        locationFrom = locationFromElement.dataset.locationFrom || ''
      }
      
      const locationToInput = document.getElementById('transfer-location-to') as HTMLInputElement
      locationTo = locationToInput?.value || ''
      
      console.log('[TransferSearch] FROM mode - locationFrom (airport/station):', locationFrom)
      console.log('[TransferSearch] FROM mode - locationTo (dropoff):', locationTo)
      
      // 验证: 下车点必须选择
      if (!locationTo || locationTo.trim() === '') {
        alert('请先选择下车点')
        
        // 自动触发地点选择弹窗
        const modalButton = document.querySelector('[data-action="click->location-selector#openModal"]') as HTMLButtonElement
        if (modalButton) {
          modalButton.click()
        }
        return
      }
    }
    
    console.log('[TransferSearch] Building URL with params:', {
      transfer_type: this.transferTypeValue,
      service_type: this.serviceTypeValue,
      location_from: locationFrom,
      location_to: locationTo,
      pickup_time: pickupTime,
      flight_id: this.flightIdValue,
      train_id: this.trainIdValue
    })
    
    // 构建 URL 参数
    const params = new URLSearchParams()
    params.append('transfer_type', this.transferTypeValue)
    params.append('service_type', this.serviceTypeValue)
    params.append('location_from', locationFrom)
    params.append('location_to', locationTo)
    
    // 只有在 to_airport/to_station 模式下才传递用车时间
    if (pickupTime && pickupTime !== '请选择时间') {
      params.append('pickup_time', pickupTime)
    }
    
    if (this.flightIdValue) {
      params.append('flight_id', this.flightIdValue)
    }
    
    if (this.trainIdValue) {
      params.append('train_id', this.trainIdValue)
    }
    
    const finalUrl = `/transfers/packages?${params.toString()}`
    console.log('[TransferSearch] Navigating to:', finalUrl)
    
    // 跳转到车辆列表页面
    window.location.href = finalUrl
  }
}
