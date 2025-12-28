import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = [
    "trigger",      // 触发加载的不可见元素
    "container",    // 内容容器
    "loading"       // 加载指示器
  ]

  static values = {
    page: Number,      // 当前页码
    hasMore: Boolean   // 是否还有更多数据
  }

  // Declare targets and values
  declare readonly triggerTarget: HTMLElement
  declare readonly containerTarget: HTMLElement
  declare readonly loadingTarget: HTMLElement
  declare pageValue: number
  declare hasMoreValue: boolean

  private observer: IntersectionObserver | null = null
  private isLoading: boolean = false

  connect(): void {
    console.log("InfiniteScroll connected, initial page:", this.pageValue, "hasMore:", this.hasMoreValue)
    
    // 只有在有更多数据时才设置observer
    if (this.hasMoreValue) {
      this.setupObserver()
    }
  }

  disconnect(): void {
    console.log("InfiniteScroll disconnected")
    if (this.observer) {
      this.observer.disconnect()
      this.observer = null
    }
  }

  private setupObserver(): void {
    // 创建IntersectionObserver监听trigger元素
    this.observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          // 当trigger元素进入视口时触发加载
          if (entry.isIntersecting && this.hasMoreValue && !this.isLoading) {
            this.loadMore()
          }
        })
      },
      {
        root: null,           // 使用viewport作为root
        rootMargin: "100px",  // 提前100px触发
        threshold: 0.1        // 10%可见时触发
      }
    )

    // 开始观察trigger元素
    this.observer.observe(this.triggerTarget)
  }

  private async loadMore(): Promise<void> {
    if (this.isLoading || !this.hasMoreValue) {
      return
    }

    this.isLoading = true
    this.showLoading()

    console.log("Loading more trips, page:", this.pageValue)

    try {
      // 使用Turbo发起请求，自动处理turbo_stream响应
      const url = `/trips/load_more?page=${this.pageValue}`
      const response = await fetch(url, {
        headers: {
          "Accept": "text/vnd.turbo-stream.html",
          "X-Requested-With": "XMLHttpRequest"
        }
      })

      if (response.ok) {
        const html = await response.text()
        
        // 手动处理Turbo Stream响应
        const streamElement = document.createElement('div')
        streamElement.innerHTML = html
        
        // 执行turbo-stream标签
        const turboStreams = streamElement.querySelectorAll('turbo-stream')
        turboStreams.forEach((stream) => {
          // Turbo会自动处理这些元素
          document.body.appendChild(stream)
        })
        
        // 增加页码
        this.pageValue++
        
        // 检查是否还有更多数据（通过检查响应中是否包含has_more信息）
        // 如果没有更多数据，停止observer
        if (html.includes('已显示全部行程')) {
          this.hasMoreValue = false
          if (this.observer) {
            this.observer.disconnect()
          }
        }
        
        console.log("Loaded more trips, new page:", this.pageValue, "hasMore:", this.hasMoreValue)
      }
    } catch (error) {
      console.error("Failed to load more trips:", error)
    } finally {
      this.isLoading = false
      this.hideLoading()
    }
  }

  private showLoading(): void {
    this.loadingTarget.classList.remove('hidden')
  }

  private hideLoading(): void {
    this.loadingTarget.classList.add('hidden')
  }
}
