import { Controller } from "@hotwired/stimulus"

interface CityData {
  name: string
  pinyin: string
  slug: string | null
}

export default class extends Controller<HTMLElement> {
  static targets = ["regionButton", "cityList", "searchInput", "searchResults", "searchResultsList", "noResults", "normalView"]
  static values = {
    availableDestinations: Array,
    allCities: Array
  }

  declare readonly regionButtonTargets: HTMLButtonElement[]
  declare readonly cityListTargets: HTMLElement[]
  declare readonly searchInputTarget: HTMLInputElement
  declare readonly searchResultsTarget: HTMLElement
  declare readonly searchResultsListTarget: HTMLElement
  declare readonly noResultsTarget: HTMLElement
  declare readonly normalViewTarget: HTMLElement
  declare readonly hasSearchResultsTarget: boolean
  
  declare availableDestinationsValue: string[]
  declare allCitiesValue: CityData[]

  connect(): void {
    console.log("RegionSelector connected")
    // 默认显示热门目的地
    this.showRegion("热门目的地")
  }

  search(event: Event): void {
    const input = event.target as HTMLInputElement
    const query = input.value.trim().toLowerCase()
    
    if (query === '') {
      // 清空搜索，显示正常视图
      this.showNormalView()
      return
    }
    
    // 搜索城市（支持中文和拼音）
    const results = this.allCitiesValue.filter(city => 
      city.name.toLowerCase().includes(query) || 
      city.pinyin.toLowerCase().includes(query)
    )
    
    this.displaySearchResults(results)
  }
  
  clearSearch(): void {
    this.searchInputTarget.value = ''
    this.showNormalView()
  }
  
  private displaySearchResults(results: CityData[]): void {
    // 隐藏正常视图，显示搜索结果
    this.normalViewTarget.classList.add('hidden')
    
    if (this.hasSearchResultsTarget) {
      this.searchResultsTarget.classList.remove('hidden')
    }
    
    if (results.length === 0) {
      // 显示无结果
      this.searchResultsListTarget.innerHTML = ''
      this.noResultsTarget.classList.remove('hidden')
    } else {
      // 显示搜索结果
      this.noResultsTarget.classList.add('hidden')
      this.searchResultsListTarget.innerHTML = results.map(city => `
        <div class="text-center py-3 px-2 bg-surface rounded-lg border border-border hover:border-primary hover:shadow-sm transition-all cursor-pointer"
             data-action="click->region-selector#selectCity"
             data-city-name="${city.name}"
             data-city-slug="${city.slug || ''}">
          <div class="text-sm font-medium text-foreground">${city.name}</div>
        </div>
      `).join('')
    }
  }
  
  private showNormalView(): void {
    // 显示正常视图，隐藏搜索结果
    this.normalViewTarget.classList.remove('hidden')
    
    if (this.hasSearchResultsTarget) {
      this.searchResultsTarget.classList.add('hidden')
    }
  }

  selectRegion(event: Event): void {
    const button = event.currentTarget as HTMLButtonElement
    const regionName = button.dataset.region
    
    if (!regionName) return

    // 更新按钮样式
    this.regionButtonTargets.forEach(btn => {
      if (btn === button) {
        btn.classList.add("text-foreground", "bg-white", "border-l-2", "border-primary", "font-medium")
        btn.classList.remove("text-muted")
      } else {
        btn.classList.remove("text-foreground", "bg-white", "border-l-2", "border-primary", "font-medium")
        btn.classList.add("text-muted")
      }
    })

    // 显示对应的城市列表
    this.showRegion(regionName)
  }

  selectCity(event: Event): void {
    const cityCard = event.currentTarget as HTMLElement
    const cityName = cityCard.dataset.cityName
    
    if (!cityName) return
    
    // 检查该城市是否有对应的目的地页面
    if (this.availableDestinationsValue.includes(cityName)) {
      // 跳转到目的地详情页
      const slug = cityCard.dataset.citySlug
      if (slug) {
        window.location.href = `/destinations/${slug}`
      }
    } else {
      // 显示提示：该城市暂无详细信息
      alert(`${cityName}的详细信息即将上线，敬请期待！`)
    }
  }

  private showRegion(regionName: string): void {
    this.cityListTargets.forEach(list => {
      if (list.dataset.region === regionName) {
        list.classList.remove("hidden")
      } else {
        list.classList.add("hidden")
      }
    })
  }
}
