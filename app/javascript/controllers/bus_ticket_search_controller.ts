import { Controller } from "@hotwired/stimulus"
import * as Turbo from "@hotwired/turbo"

export default class extends Controller {
  static values = {
    origin: String,
    destination: String,
    date: String
  }

  static targets = [
    "overlay",
    "modal",
    "departureTimeTab",
    "seatTypeTab",
    "departureStationTab",
    "arrivalStationTab",
    "departureTimeSection",
    "seatTypeSection",
    "departureStationSection",
    "arrivalStationSection",
    "departureTimeCard",
    "seatTypeCard",
    "departureStationCard",
    "arrivalStationCard",
    "applyButton",
    "filterBadge",
    "selectedTagsContainer",
    "selectedTagsList"
  ]

  declare readonly overlayTarget: HTMLElement
  declare readonly modalTarget: HTMLElement
  declare readonly departureTimeTabTarget: HTMLElement
  declare readonly seatTypeTabTarget: HTMLElement
  declare readonly departureStationTabTarget: HTMLElement
  declare readonly arrivalStationTabTarget: HTMLElement
  declare readonly departureTimeSectionTarget: HTMLElement
  declare readonly seatTypeSectionTarget: HTMLElement
  declare readonly departureStationSectionTarget: HTMLElement
  declare readonly arrivalStationSectionTarget: HTMLElement
  declare readonly departureTimeCardTargets: HTMLElement[]
  declare readonly seatTypeCardTargets: HTMLElement[]
  declare readonly departureStationCardTargets: HTMLElement[]
  declare readonly arrivalStationCardTargets: HTMLElement[]
  declare readonly applyButtonTarget: HTMLElement
  declare readonly filterBadgeTarget: HTMLElement
  declare readonly selectedTagsContainerTarget: HTMLElement
  declare readonly selectedTagsListTarget: HTMLElement

  declare readonly originValue: string
  declare readonly destinationValue: string
  declare readonly dateValue: string

  selectedDepartureTimes: Set<string> = new Set()
  selectedSeatTypes: Set<string> = new Set()
  selectedDepartureStations: Set<string> = new Set()
  selectedArrivalStations: Set<string> = new Set()

  // 映射关系：标识符 -> 显示文字
  timeSlotLabels: { [key: string]: string } = {
    morning: '凌晨 00:00-05:59',
    morning2: '上午 06:00-11:59',
    afternoon: '下午 12:00-17:59',
    evening: '晚上 18:00-23:59'
  }

  openFilter(): void {
    this.overlayTarget.classList.remove("hidden")
    this.modalTarget.classList.remove("hidden")
  }

  closeModal(): void {
    this.overlayTarget.classList.add("hidden")
    this.modalTarget.classList.add("hidden")
  }

  selectTab(event: Event): void {
    const button = event.currentTarget as HTMLElement
    const tab = button.dataset.tab

    if (!tab) return

    // 移除所有tab的选中样式
    const tabs = [
      this.departureTimeTabTarget,
      this.seatTypeTabTarget,
      this.departureStationTabTarget,
      this.arrivalStationTabTarget
    ]
    tabs.forEach((t) => {
      t.classList.remove("bg-white", "border-[#FFD900]", "text-gray-900", "font-medium")
      t.classList.add("text-gray-600")
      t.classList.remove("border-l-4")
      t.classList.add("border-l-2", "border-transparent")
    })

    // 添加当前tab的选中样式
    button.classList.add("bg-white", "border-l-4", "border-[#FFD900]", "text-gray-900", "font-medium")
    button.classList.remove("text-gray-600", "border-l-2", "border-transparent")

    // 隐藏所有section
    const sections = [
      this.departureTimeSectionTarget,
      this.seatTypeSectionTarget,
      this.departureStationSectionTarget,
      this.arrivalStationSectionTarget
    ]
    sections.forEach((s) => s.classList.add("hidden"))

    // 显示对应的section
    const sectionMap: { [key: string]: HTMLElement } = {
      departureTime: this.departureTimeSectionTarget,
      seatType: this.seatTypeSectionTarget,
      departureStation: this.departureStationSectionTarget,
      arrivalStation: this.arrivalStationSectionTarget
    }

    const targetSection = sectionMap[tab]
    if (targetSection) {
      targetSection.classList.remove("hidden")
    }
  }

  toggleDepartureTime(event: Event): void {
    const card = event.currentTarget as HTMLElement
    const time = card.dataset.time

    if (!time) return

    if (this.selectedDepartureTimes.has(time)) {
      this.selectedDepartureTimes.delete(time)
      this.removeSelectedStyle(card)
    } else {
      this.selectedDepartureTimes.add(time)
      this.addSelectedStyle(card)
    }

    this.updateFilterBadge()
    this.updateApplyButton()
    this.updateSelectedTags()
  }

  toggleSeatType(event: Event): void {
    const card = event.currentTarget as HTMLElement
    const seatType = card.dataset.seatType

    if (!seatType) return

    if (this.selectedSeatTypes.has(seatType)) {
      this.selectedSeatTypes.delete(seatType)
      this.removeSelectedStyle(card)
    } else {
      this.selectedSeatTypes.add(seatType)
      this.addSelectedStyle(card)
    }

    this.updateFilterBadge()
    this.updateApplyButton()
    this.updateSelectedTags()
  }

  toggleDepartureStation(event: Event): void {
    const card = event.currentTarget as HTMLElement
    const station = card.dataset.station

    if (!station) return

    if (this.selectedDepartureStations.has(station)) {
      this.selectedDepartureStations.delete(station)
      this.removeSelectedStyle(card)
    } else {
      this.selectedDepartureStations.add(station)
      this.addSelectedStyle(card)
    }

    this.updateFilterBadge()
    this.updateApplyButton()
    this.updateSelectedTags()
  }

  toggleArrivalStation(event: Event): void {
    const card = event.currentTarget as HTMLElement
    const station = card.dataset.station

    if (!station) return

    if (this.selectedArrivalStations.has(station)) {
      this.selectedArrivalStations.delete(station)
      this.removeSelectedStyle(card)
    } else {
      this.selectedArrivalStations.add(station)
      this.addSelectedStyle(card)
    }

    this.updateFilterBadge()
    this.updateApplyButton()
    this.updateSelectedTags()
  }

  addSelectedStyle(card: HTMLElement): void {
    // 添加黄色背景
    card.classList.remove("bg-[#F7F8FA]")
    card.classList.add("bg-[#FFD900]")
    
    // 添加对勾图标（如果不存在）
    if (!card.querySelector(".checkmark-icon")) {
      const checkmark = this.createCheckmark()
      card.appendChild(checkmark)
    }
  }

  removeSelectedStyle(card: HTMLElement): void {
    // 移除黄色背景
    card.classList.remove("bg-[#FFD900]")
    card.classList.add("bg-[#F7F8FA]")
    
    // 移除对勾图标
    const checkmark = card.querySelector(".checkmark-icon")
    if (checkmark) {
      checkmark.remove()
    }
  }

  createCheckmark(): HTMLElement {
    const checkmark = document.createElement("div")
    checkmark.className = "checkmark-icon absolute top-2 right-2"
    checkmark.innerHTML = `
      <svg class="w-5 h-5 text-gray-900" fill="currentColor" viewBox="0 0 20 20">
        <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"></path>
      </svg>
    `
    return checkmark
  }

  updateFilterBadge(): void {
    const totalFilters = 
      this.selectedDepartureTimes.size +
      this.selectedSeatTypes.size +
      this.selectedDepartureStations.size +
      this.selectedArrivalStations.size

    if (totalFilters > 0) {
      this.filterBadgeTarget.textContent = totalFilters.toString()
      this.filterBadgeTarget.classList.remove("hidden")
    } else {
      this.filterBadgeTarget.classList.add("hidden")
    }
  }

  updateApplyButton(): void {
    // 实时计算筛选结果数量
    this.fetchFilteredCount()
  }

  resetFilters(): void {
    // 清空所有选中
    this.selectedDepartureTimes.clear()
    this.selectedSeatTypes.clear()
    this.selectedDepartureStations.clear()
    this.selectedArrivalStations.clear()

    // 移除所有卡片的选中样式
    const allCards = [
      ...this.departureTimeCardTargets,
      ...this.seatTypeCardTargets,
      ...this.departureStationCardTargets,
      ...this.arrivalStationCardTargets
    ]

    allCards.forEach((card) => {
      this.removeSelectedStyle(card)
    })

    // 更新角标和按钮
    this.updateFilterBadge()
    this.updateApplyButton()
    this.updateSelectedTags()
  }

  applyFilters(): void {
    // 构建筛选参数
    const params = new URLSearchParams()
    params.set('origin', this.originValue)
    params.set('destination', this.destinationValue)
    params.set('date', this.dateValue)
    
    // 添加筛选条件
    if (this.selectedDepartureTimes.size > 0) {
      params.set('time_slots', Array.from(this.selectedDepartureTimes).join(','))
    }
    if (this.selectedSeatTypes.size > 0) {
      params.set('seat_types', Array.from(this.selectedSeatTypes).join(','))
    }
    if (this.selectedDepartureStations.size > 0) {
      params.set('departure_stations', Array.from(this.selectedDepartureStations).join(','))
    }
    if (this.selectedArrivalStations.size > 0) {
      params.set('arrival_stations', Array.from(this.selectedArrivalStations).join(','))
    }
    
    // 关闭弹窗
    this.closeModal()
    
    // 使用Turbo.visit刷新页面
    Turbo.visit(`/bus_tickets/search?${params.toString()}`)
  }

  // 更新已选筛选项标签显示
  updateSelectedTags(): void {
    const tags: Array<{type: string, value: string, label: string}> = []

    // 发车时段
    this.selectedDepartureTimes.forEach(time => {
      tags.push({
        type: 'departureTime',
        value: time,
        label: this.timeSlotLabels[time] || time
      })
    })

    // 车型
    this.selectedSeatTypes.forEach(seatType => {
      tags.push({
        type: 'seatType',
        value: seatType,
        label: seatType
      })
    })

    // 出发车站
    this.selectedDepartureStations.forEach(station => {
      tags.push({
        type: 'departureStation',
        value: station,
        label: station
      })
    })

    // 到达车站
    this.selectedArrivalStations.forEach(station => {
      tags.push({
        type: 'arrivalStation',
        value: station,
        label: station
      })
    })

    // 清空标签列表
    this.selectedTagsListTarget.innerHTML = ''

    if (tags.length === 0) {
      // 隐藏容器
      this.selectedTagsContainerTarget.classList.add('hidden')
    } else {
      // 显示容器
      this.selectedTagsContainerTarget.classList.remove('hidden')

      // 添加每个标签
      tags.forEach(tag => {
        const tagElement = document.createElement('div')
        tagElement.className = 'bg-[#FFD900] text-gray-900 text-[13px] px-3 py-1 rounded-full flex items-center gap-1'
        tagElement.innerHTML = `
          <span>${tag.label}</span>
          <button type="button" 
            data-action="click->bus-ticket-search#removeTag"
            data-tag-type="${tag.type}"
            data-tag-value="${tag.value}"
            class="text-gray-900 hover:text-gray-700 font-bold">
            ✕
          </button>
        `
        this.selectedTagsListTarget.appendChild(tagElement)
      })
    }
  }

  // 移除单个标签
  removeTag(event: Event): void {
    const button = event.currentTarget as HTMLElement
    const tagType = button.dataset.tagType
    const tagValue = button.dataset.tagValue

    if (!tagType || !tagValue) return

    // 根据类型移除对应的选中项
    switch (tagType) {
      case 'departureTime': {
        this.selectedDepartureTimes.delete(tagValue)
        // 移除对应卡片的选中样式
        const timeCard = this.departureTimeCardTargets.find(
          card => card.dataset.time === tagValue
        )
        if (timeCard) this.removeSelectedStyle(timeCard)
        break
      }

      case 'seatType': {
        this.selectedSeatTypes.delete(tagValue)
        const seatCard = this.seatTypeCardTargets.find(
          card => card.dataset.seatType === tagValue
        )
        if (seatCard) this.removeSelectedStyle(seatCard)
        break
      }

      case 'departureStation': {
        this.selectedDepartureStations.delete(tagValue)
        const depCard = this.departureStationCardTargets.find(
          card => card.dataset.station === tagValue
        )
        if (depCard) this.removeSelectedStyle(depCard)
        break
      }

      case 'arrivalStation': {
        this.selectedArrivalStations.delete(tagValue)
        const arrCard = this.arrivalStationCardTargets.find(
          card => card.dataset.station === tagValue
        )
        if (arrCard) this.removeSelectedStyle(arrCard)
        break
      }
    }

    // 更新界面
    this.updateFilterBadge()
    this.updateApplyButton()
    this.updateSelectedTags()
  }

  // 实时获取筛选结果数量
  async fetchFilteredCount(): Promise<void> {
    try {
      // 构建查询参数
      const params = new URLSearchParams()
      params.set('origin', this.originValue)
      params.set('destination', this.destinationValue)
      params.set('date', this.dateValue)
      
      // 添加筛选条件
      if (this.selectedDepartureTimes.size > 0) {
        params.set('time_slots', Array.from(this.selectedDepartureTimes).join(','))
      }
      if (this.selectedSeatTypes.size > 0) {
        params.set('seat_types', Array.from(this.selectedSeatTypes).join(','))
      }
      if (this.selectedDepartureStations.size > 0) {
        params.set('departure_stations', Array.from(this.selectedDepartureStations).join(','))
      }
      if (this.selectedArrivalStations.size > 0) {
        params.set('arrival_stations', Array.from(this.selectedArrivalStations).join(','))
      }
      
      // 发起AJAX请求
      const response = await fetch(`/bus_tickets/count_filtered_results?${params.toString()}`)
      const data = await response.json()
      
      // 更新按钮文字
      this.applyButtonTarget.textContent = `查看${data.count}条结果`
    } catch (error) {
      console.error('获取筛选结果数量失败:', error)
      // 错误时显示默认文字
      this.applyButtonTarget.textContent = '查看结果'
    }
  }
}
