import { Controller } from "@hotwired/stimulus"
import * as Turbo from "@hotwired/turbo"

// Handles date link clicks for multi-city flight date selection with comprehensive validation
export default class extends Controller {
  static values = {
    url: String,
    selectedDate: String,
    allSegmentDates: Array,
    selectedFlightDates: Array,
    currentSegmentIndex: Number
  }

  declare urlValue: string
  declare selectedDateValue: string
  declare allSegmentDatesValue: string[]
  declare selectedFlightDatesValue: string[]
  declare currentSegmentIndexValue: number

  async navigate(event: Event) {
    event.preventDefault()
    
    // Frontend validation: check date constraints
    if (this.selectedDateValue && this.allSegmentDatesValue && this.allSegmentDatesValue.length > 0) {
      const selectedDate = new Date(this.selectedDateValue)
      const currentIndex = this.currentSegmentIndexValue
      const segmentNumber = currentIndex + 1
      
      // 获取前一程的日期（如果有已选航班，用已选航班的日期；否则用原始segment日期）
      let previousDate: Date | null = null
      if (currentIndex > 0) {
        // 如果有已选航班，使用已选航班的日期
        if (this.selectedFlightDatesValue && this.selectedFlightDatesValue.length > 0) {
          const lastSelectedFlightDate = this.selectedFlightDatesValue[this.selectedFlightDatesValue.length - 1]
          if (lastSelectedFlightDate) {
            previousDate = new Date(lastSelectedFlightDate)
          }
        }
        // 如果没有已选航班，使用原始segment日期
        if (!previousDate && this.allSegmentDatesValue[currentIndex - 1]) {
          previousDate = new Date(this.allSegmentDatesValue[currentIndex - 1])
        }
      }
      
      // 获取下一程的日期（使用原始segment日期）
      let nextDate: Date | null = null
      if (currentIndex + 1 < this.allSegmentDatesValue.length) {
        nextDate = new Date(this.allSegmentDatesValue[currentIndex + 1])
      }
      
      // 校验：不能早于前一程
      if (previousDate && selectedDate < previousDate) {
        if (window.showToast) {
          window.showToast(`第${segmentNumber}程日期不能早于第${currentIndex}程，请返回航班首页修改`)
        }
        return // Prevent navigation
      }
      
      // 校验：不能晚于下一程
      if (nextDate && selectedDate > nextDate) {
        if (window.showToast) {
          window.showToast(`第${segmentNumber}程日期不能晚于第${currentIndex + 2}程，请返回航班首页修改`)
        }
        return // Prevent navigation
      }
    }
    
    // If validation passes, proceed with navigation
    try {
      const response = await fetch(this.urlValue, {
        headers: {
          'Accept': 'text/vnd.turbo-stream.html, text/html',
          'Turbo-Frame': '_top'
        }
      })

      const contentType = response.headers.get('Content-Type')
      
      if (contentType?.includes('turbo-stream')) {
        // It's a Turbo Stream response (validation error with Toast)
        const html = await response.text()
        Turbo.renderStreamMessage(html)
      } else {
        // It's a regular HTML response (success - navigate to new page)
        Turbo.visit(this.urlValue)
      }
    } catch (error) {
      console.error('Navigation error:', error)
      // Fallback to regular navigation
      Turbo.visit(this.urlValue)
    }
  }
}
