import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = [
    "sortDropdown",
    "quickSelectDropdown", 
    "priceServiceDropdown",
    "sortButton",
    "quickSelectButton",
    "priceServiceButton"
  ]

  declare readonly sortDropdownTarget: HTMLElement
  declare readonly quickSelectDropdownTarget: HTMLElement
  declare readonly priceServiceDropdownTarget: HTMLElement
  declare readonly sortButtonTarget: HTMLElement
  declare readonly quickSelectButtonTarget: HTMLElement
  declare readonly priceServiceButtonTarget: HTMLElement

  // Store current filter state
  private currentSort: string = 'recommend'
  private quickSelectFilters: Set<string> = new Set()
  private priceServiceFilters: Set<string> = new Set()

  connect(): void {
    console.log("CarFilter connected")
    // Close dropdowns when clicking outside
    document.addEventListener('click', this.handleOutsideClick.bind(this))
    
    // Load filters from URL params
    this.loadFiltersFromURL()
  }

  disconnect(): void {
    console.log("CarFilter disconnected")
    document.removeEventListener('click', this.handleOutsideClick.bind(this))
  }

  toggleSortDropdown(event: Event): void {
    event.stopPropagation()
    this.closeAllDropdowns()
    this.sortDropdownTarget.classList.toggle('hidden')
  }

  toggleQuickSelectDropdown(event: Event): void {
    event.stopPropagation()
    this.closeAllDropdowns()
    this.quickSelectDropdownTarget.classList.toggle('hidden')
  }

  togglePriceServiceDropdown(event: Event): void {
    event.stopPropagation()
    this.closeAllDropdowns()
    this.priceServiceDropdownTarget.classList.toggle('hidden')
  }

  selectSortOption(event: Event): void {
    const target = event.currentTarget as HTMLElement
    const value = target.dataset.value || ''
    const label = target.textContent || ''
    
    // Update button text
    const textSpan = this.sortButtonTarget.querySelector('span')
    if (textSpan) {
      textSpan.textContent = label
    }
    
    // Update button highlight style
    if (value === 'recommend') {
      // Default option - remove highlight
      this.sortButtonTarget.classList.remove('text-blue-600', 'font-bold')
      this.sortButtonTarget.classList.add('font-medium')
    } else {
      // Non-default option - add highlight
      this.sortButtonTarget.classList.add('text-blue-600', 'font-bold')
      this.sortButtonTarget.classList.remove('font-medium')
    }
    
    // Update all options' active state
    this.sortDropdownTarget.querySelectorAll('[data-value]').forEach(option => {
      option.classList.remove('text-blue-600', 'font-bold')
      option.classList.add('text-gray-700')
    })
    target.classList.remove('text-gray-700')
    target.classList.add('text-blue-600', 'font-bold')
    
    // Close dropdown
    this.sortDropdownTarget.classList.add('hidden')
    
    // Store current sort and apply filter
    this.currentSort = value
    this.applyFilters()
  }

  selectQuickOption(event: Event): void {
    const target = event.currentTarget as HTMLElement
    const value = target.dataset.value || ''
    
    // Toggle checkbox
    const checkbox = target.querySelector('input[type="checkbox"]') as HTMLInputElement
    if (checkbox) {
      checkbox.checked = !checkbox.checked
      
      // Update filter set
      if (checkbox.checked) {
        this.quickSelectFilters.add(value)
      } else {
        this.quickSelectFilters.delete(value)
      }
    }
    
    // Update button highlight based on checked count
    this.updateQuickSelectHighlight()
    
    // Close dropdown after selection
    this.quickSelectDropdownTarget.classList.add('hidden')
    
    // Apply filters
    this.applyFilters()
  }

  selectPriceOption(event: Event): void {
    const target = event.currentTarget as HTMLElement
    const value = target.dataset.value || ''
    
    // Toggle checkbox
    const checkbox = target.querySelector('input[type="checkbox"]') as HTMLInputElement
    if (checkbox) {
      checkbox.checked = !checkbox.checked
      
      // Update filter set
      if (checkbox.checked) {
        this.priceServiceFilters.add(value)
      } else {
        this.priceServiceFilters.delete(value)
      }
    }
    
    // Update button highlight based on checked count
    this.updatePriceServiceHighlight()
    
    // Close dropdown after selection
    this.priceServiceDropdownTarget.classList.add('hidden')
    
    // Apply filters
    this.applyFilters()
  }

  private updateQuickSelectHighlight(): void {
    const checkedCount = this.quickSelectDropdownTarget.querySelectorAll('input[type="checkbox"]:checked').length
    const textSpan = this.quickSelectButtonTarget.querySelector('span')
    
    if (checkedCount > 0) {
      // Has selections - add highlight
      this.quickSelectButtonTarget.classList.add('text-blue-600', 'font-bold')
      if (textSpan) {
        textSpan.textContent = `快速选车(${checkedCount})`
      }
    } else {
      // No selections - remove highlight
      this.quickSelectButtonTarget.classList.remove('text-blue-600', 'font-bold')
      if (textSpan) {
        textSpan.textContent = '快速选车'
      }
    }
  }

  private updatePriceServiceHighlight(): void {
    const checkedCount = this.priceServiceDropdownTarget.querySelectorAll('input[type="checkbox"]:checked').length
    const textSpan = this.priceServiceButtonTarget.querySelector('span')
    
    if (checkedCount > 0) {
      // Has selections - add highlight
      this.priceServiceButtonTarget.classList.add('text-blue-600', 'font-bold')
      if (textSpan) {
        textSpan.textContent = `价格服务(${checkedCount})`
      }
    } else {
      // No selections - remove highlight
      this.priceServiceButtonTarget.classList.remove('text-blue-600', 'font-bold')
      if (textSpan) {
        textSpan.textContent = '价格服务'
      }
    }
  }

  private closeAllDropdowns(): void {
    // Close dropdowns if they exist
    try {
      this.sortDropdownTarget.classList.add('hidden')
    } catch {
      // Target not found, ignore
    }
    try {
      this.quickSelectDropdownTarget.classList.add('hidden')
    } catch {
      // Target not found, ignore
    }
    try {
      this.priceServiceDropdownTarget.classList.add('hidden')
    } catch {
      // Target not found, ignore
    }
  }

  private handleOutsideClick(event: Event): void {
    const target = event.target as HTMLElement
    if (!this.element.contains(target)) {
      this.closeAllDropdowns()
    }
  }

  private loadFiltersFromURL(): void {
    const urlParams = new URLSearchParams(window.location.search)
    
    // Load sort
    const sort = urlParams.get('sort')
    if (sort) {
      this.currentSort = sort
      
      // Update sort button UI
      this.updateSortButtonUI(sort)
      
      // Update dropdown options active state
      this.sortDropdownTarget.querySelectorAll('[data-value]').forEach(option => {
        const value = (option as HTMLElement).dataset.value
        if (value === sort) {
          option.classList.add('text-blue-600', 'font-bold')
          option.classList.remove('text-gray-700')
        } else {
          option.classList.remove('text-blue-600', 'font-bold')
          option.classList.add('text-gray-700')
        }
      })
    }
    
    // Load quick select filters
    const quickSelect = urlParams.get('quick_select')
    if (quickSelect) {
      quickSelect.split(',').forEach(f => this.quickSelectFilters.add(f))
      
      // Update UI
      this.quickSelectFilters.forEach(value => {
        const option = this.quickSelectDropdownTarget.querySelector(`[data-value="${value}"]`)
        if (option) {
          const checkbox = option.querySelector('input[type="checkbox"]') as HTMLInputElement
          if (checkbox) checkbox.checked = true
        }
      })
      this.updateQuickSelectHighlight()
    }
    
    // Load price service filters
    const priceService = urlParams.get('price_service')
    if (priceService) {
      priceService.split(',').forEach(f => this.priceServiceFilters.add(f))
      
      // Update UI
      this.priceServiceFilters.forEach(value => {
        const option = this.priceServiceDropdownTarget.querySelector(`[data-value="${value}"]`)
        if (option) {
          const checkbox = option.querySelector('input[type="checkbox"]') as HTMLInputElement
          if (checkbox) checkbox.checked = true
        }
      })
      this.updatePriceServiceHighlight()
    }
  }

  private updateSortButtonUI(sort: string): void {
    const textSpan = this.sortButtonTarget.querySelector('span')
    if (!textSpan) return
    
    // Update button text and highlight
    switch (sort) {
      case 'recommend':
        textSpan.textContent = '推荐排序'
        this.sortButtonTarget.classList.remove('text-blue-600', 'font-bold')
        this.sortButtonTarget.classList.add('font-medium')
        break
      case 'price-low':
        textSpan.textContent = '价格从低到高'
        this.sortButtonTarget.classList.add('text-blue-600', 'font-bold')
        this.sortButtonTarget.classList.remove('font-medium')
        break
      case 'price-high':
        textSpan.textContent = '价格从高到低'
        this.sortButtonTarget.classList.add('text-blue-600', 'font-bold')
        this.sortButtonTarget.classList.remove('font-medium')
        break
      case 'sales':
        textSpan.textContent = '销量优先'
        this.sortButtonTarget.classList.add('text-blue-600', 'font-bold')
        this.sortButtonTarget.classList.remove('font-medium')
        break
      default:
        textSpan.textContent = '推荐排序'
        this.sortButtonTarget.classList.remove('text-blue-600', 'font-bold')
        this.sortButtonTarget.classList.add('font-medium')
    }
  }

  private applyFilters(): void {
    // Build URL with current filters
    const url = new URL(window.location.href)
    const params = url.searchParams
    
    // Add sort parameter
    if (this.currentSort && this.currentSort !== 'recommend') {
      params.set('sort', this.currentSort)
    } else {
      params.delete('sort')
    }
    
    // Add quick select filters
    if (this.quickSelectFilters.size > 0) {
      params.set('quick_select', Array.from(this.quickSelectFilters).join(','))
    } else {
      params.delete('quick_select')
    }
    
    // Add price service filters
    if (this.priceServiceFilters.size > 0) {
      params.set('price_service', Array.from(this.priceServiceFilters).join(','))
    } else {
      params.delete('price_service')
    }
    
    // Navigate to new URL
    window.location.href = url.toString()
  }
}
