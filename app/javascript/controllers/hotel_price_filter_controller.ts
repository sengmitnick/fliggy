import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = [
    "modal",
    "minSlider",
    "maxSlider",
    "sliderTrack",
    "minPriceDisplay",
    "maxPriceDisplay",
    "starRating",
    "pricePreset",
    "displayText"
  ]

  static values = {
    minPrice: Number,
    maxPrice: Number,
    stars: Number
  }

  declare readonly modalTarget: HTMLElement
  declare readonly minSliderTarget: HTMLInputElement
  declare readonly maxSliderTarget: HTMLInputElement
  declare readonly sliderTrackTarget: HTMLElement
  declare readonly minPriceDisplayTarget: HTMLElement
  declare readonly maxPriceDisplayTarget: HTMLElement
  declare readonly starRatingTargets: HTMLElement[]
  declare readonly pricePresetTargets: HTMLElement[]
  declare readonly displayTextTarget: HTMLElement

  declare minPriceValue: number
  declare maxPriceValue: number
  declare starsValue: number

  connect(): void {
    console.log("HotelPriceFilter connected")
    
    // Try to read initial values from URL parameters or hidden form fields
    const urlParams = new URLSearchParams(window.location.search)
    const minPriceParam = urlParams.get('price_min')
    const maxPriceParam = urlParams.get('price_max')
    const starLevelParam = urlParams.get('star_level')
    
    // Initialize from URL params if available, otherwise use defaults
    this.minPriceValue = minPriceParam && minPriceParam !== '' ? parseInt(minPriceParam) : 0
    this.maxPriceValue = maxPriceParam && maxPriceParam !== '' ? parseInt(maxPriceParam) : 3000
    this.starsValue = starLevelParam && starLevelParam !== '' ? parseInt(starLevelParam) : 0
    
    // Update UI to reflect loaded values
    this.minSliderTarget.value = this.minPriceValue.toString()
    this.maxSliderTarget.value = this.maxPriceValue.toString()
    this.minPriceDisplayTarget.textContent = this.minPriceValue.toString()
    this.maxPriceDisplayTarget.textContent = this.maxPriceValue.toString()
    
    // Update slider track visual
    this.updateSliderTrack()
    
    // Update price preset button selection if values match a preset
    this.updatePresetSelection()
    
    // Update star rating button selection
    this.updateStarSelection()
    
    // Update display text
    this.updateDisplayText()
  }

  openModal(): void {
    this.modalTarget.classList.remove('hidden')
    document.body.style.overflow = 'hidden'
  }

  closeModal(): void {
    this.modalTarget.classList.add('hidden')
    document.body.style.overflow = ''
  }

  updateMinPrice(): void {
    const minValue = parseInt(this.minSliderTarget.value)
    const maxValue = parseInt(this.maxSliderTarget.value)

    // Auto-adjust: min cannot exceed max
    if (minValue > maxValue) {
      this.minSliderTarget.value = maxValue.toString()
      this.minPriceValue = maxValue
    } else {
      this.minPriceValue = minValue
    }

    this.minPriceDisplayTarget.textContent = this.minPriceValue.toString()
    this.updateSliderTrack()
  }

  updateMaxPrice(): void {
    const minValue = parseInt(this.minSliderTarget.value)
    const maxValue = parseInt(this.maxSliderTarget.value)

    // Auto-adjust: max cannot be less than min
    if (maxValue < minValue) {
      this.maxSliderTarget.value = minValue.toString()
      this.maxPriceValue = minValue
    } else {
      this.maxPriceValue = maxValue
    }

    this.maxPriceDisplayTarget.textContent = this.maxPriceValue.toString()
    this.updateSliderTrack()
  }

  setQuickPrice(event: Event): void {
    const button = event.currentTarget as HTMLElement
    const min = parseInt(button.dataset.min || '0')
    const max = parseInt(button.dataset.max || '3000')

    // Clear all price preset selections first
    this.pricePresetTargets.forEach(el => {
      el.classList.remove('selected', 'border-yellow-500', 'bg-yellow-50')
      el.classList.add('border-gray-300')
    })

    // Select the clicked preset
    button.classList.remove('border-gray-300')
    button.classList.add('selected', 'border-yellow-500', 'bg-yellow-50')

    this.minSliderTarget.value = min.toString()
    this.maxSliderTarget.value = max.toString()
    this.minPriceValue = min
    this.maxPriceValue = max
    this.minPriceDisplayTarget.textContent = min.toString()
    this.maxPriceDisplayTarget.textContent = max.toString()
    this.updateSliderTrack()
  }

  private updateSliderTrack(): void {
    const sliderMax = 3000
    const minPercent = (this.minPriceValue / sliderMax) * 100
    const maxPercent = (this.maxPriceValue / sliderMax) * 100

    this.sliderTrackTarget.style.left = `${minPercent}%`
    this.sliderTrackTarget.style.right = `${100 - maxPercent}%`
  }

  selectStarRating(event: Event): void {
    const target = event.currentTarget as HTMLElement
    const stars = parseInt(target.dataset.stars || '0')

    // Toggle selection: if already selected, deselect
    if (this.starsValue === stars) {
      this.starsValue = 0
      target.classList.remove('selected', 'border-yellow-500', 'bg-yellow-50')
      target.classList.add('border-gray-300')
    } else {
      // Clear all selections first
      this.starRatingTargets.forEach(el => {
        el.classList.remove('selected', 'border-yellow-500', 'bg-yellow-50')
        el.classList.add('border-gray-300')
      })

      // Select the clicked one
      target.classList.remove('border-gray-300')
      target.classList.add('selected', 'border-yellow-500', 'bg-yellow-50')
      this.starsValue = stars
    }
  }

  reset(): void {
    // Reset price sliders
    this.minPriceValue = 0
    this.maxPriceValue = 3000
    this.minSliderTarget.value = '0'
    this.maxSliderTarget.value = '3000'
    this.minPriceDisplayTarget.textContent = '0'
    this.maxPriceDisplayTarget.textContent = '3000'
    this.updateSliderTrack()

    // Reset price presets
    this.pricePresetTargets.forEach(el => {
      el.classList.remove('selected', 'border-yellow-500', 'bg-yellow-50')
      el.classList.add('border-gray-300')
    })

    // Reset star ratings
    this.starsValue = 0
    this.starRatingTargets.forEach(el => {
      el.classList.remove('selected', 'border-yellow-500', 'bg-yellow-50')
      el.classList.add('border-gray-300')
    })

    // Update display text
    this.updateDisplayText()
  }

  confirm(): void {
    this.updateDisplayText()
    this.dispatchFilterUpdateEvent()
    this.closeModal()
  }

  private updateDisplayText(): void {
    const parts: string[] = []
    
    // Add price range if not default (0-3000)
    if (this.minPriceValue > 0 || this.maxPriceValue < 3000) {
      if (this.maxPriceValue >= 3000) {
        parts.push(`¥${this.minPriceValue}+`)
      } else {
        parts.push(`¥${this.minPriceValue}-${this.maxPriceValue}`)
      }
    }
    
    // Add star rating if selected
    if (this.starsValue > 0) {
      const starLabels: Record<number, string> = {
        2: '二星',
        3: '三星',
        4: '四星',
        5: '五星'
      }
      parts.push(starLabels[this.starsValue] || `${this.starsValue}星`)
    }
    
    // Update display text
    if (parts.length > 0) {
      this.displayTextTarget.textContent = parts.join(' · ')
    } else {
      this.displayTextTarget.textContent = '价格/星级'
    }
  }

  private dispatchFilterUpdateEvent(): void {
    const filterUpdateEvent = new CustomEvent('hotel-price-filter:filter-updated', {
      detail: {
        minPrice: this.minPriceValue,
        maxPrice: this.maxPriceValue,
        stars: this.starsValue
      },
      bubbles: true
    })
    document.dispatchEvent(filterUpdateEvent)
    console.log('Hotel price filter: Dispatched filter update event', {
      minPrice: this.minPriceValue,
      maxPrice: this.maxPriceValue,
      stars: this.starsValue
    })
  }

  private updatePresetSelection(): void {
    // Find matching preset button and mark it as selected
    this.pricePresetTargets.forEach(el => {
      const min = parseInt(el.dataset.min || '0')
      const max = parseInt(el.dataset.max || '3000')
      
      if (min === this.minPriceValue && max === this.maxPriceValue) {
        el.classList.remove('border-gray-300')
        el.classList.add('selected', 'border-yellow-500', 'bg-yellow-50')
      } else {
        el.classList.remove('selected', 'border-yellow-500', 'bg-yellow-50')
        el.classList.add('border-gray-300')
      }
    })
  }

  private updateStarSelection(): void {
    // Update star rating button selection
    this.starRatingTargets.forEach(el => {
      const stars = parseInt(el.dataset.stars || '0')
      
      if (stars === this.starsValue && this.starsValue > 0) {
        el.classList.remove('border-gray-300')
        el.classList.add('selected', 'border-yellow-500', 'bg-yellow-50')
      } else {
        el.classList.remove('selected', 'border-yellow-500', 'bg-yellow-50')
        el.classList.add('border-gray-300')
      }
    })
  }


}
