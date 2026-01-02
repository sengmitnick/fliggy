import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = [
    "searchModal",
    "searchInput",
    "hotSearchContent", "hotSearchIcon",
    "hotBrandContent", "hotBrandIcon",
    "hotLocationContent", "hotLocationIcon",
    "metroContent", "metroIcon",
    "airportContent", "airportIcon",
    "attractionContent", "attractionIcon",
    "themeContent", "themeIcon",
    "hospitalContent", "hospitalIcon",
    "universityContent", "universityIcon"
  ]

  declare readonly searchModalTarget: HTMLElement
  declare readonly searchInputTarget: HTMLInputElement
  declare readonly hotSearchContentTarget: HTMLElement
  declare readonly hotSearchIconTarget: HTMLElement
  declare readonly hotBrandContentTarget: HTMLElement
  declare readonly hotBrandIconTarget: HTMLElement
  declare readonly hotLocationContentTarget: HTMLElement
  declare readonly hotLocationIconTarget: HTMLElement
  declare readonly metroContentTarget: HTMLElement
  declare readonly metroIconTarget: HTMLElement
  declare readonly airportContentTarget: HTMLElement
  declare readonly airportIconTarget: HTMLElement
  declare readonly attractionContentTarget: HTMLElement
  declare readonly attractionIconTarget: HTMLElement
  declare readonly themeContentTarget: HTMLElement
  declare readonly themeIconTarget: HTMLElement
  declare readonly hospitalContentTarget: HTMLElement
  declare readonly hospitalIconTarget: HTMLElement
  declare readonly universityContentTarget: HTMLElement
  declare readonly universityIconTarget: HTMLElement

  connect(): void {
    console.log("HotelSearch connected")
  }

  disconnect(): void {
    console.log("HotelSearch disconnected")
  }

  openSearchModal(): void {
    this.searchModalTarget.classList.remove("hidden")
    setTimeout(() => {
      this.searchInputTarget.focus()
    }, 100)
  }

  closeSearchModal(): void {
    this.searchModalTarget.classList.add("hidden")
  }

  submitSearch(): void {
    const form = this.searchInputTarget.closest("form") as HTMLFormElement
    if (form) {
      // Always submit the form, even if input is empty
      form.requestSubmit()
    }
  }

  handleSearchInputKeypress(event: KeyboardEvent): void {
    if (event.key === "Enter") {
      event.preventDefault()
      this.submitSearch()
    }
  }

  toggleSection(event: Event): void {
    const button = event.currentTarget as HTMLElement
    const section = button.dataset.section
    
    if (!section) return

    const contentTarget = `${section}ContentTarget` as keyof this
    const iconTarget = `${section}IconTarget` as keyof this

    const content = this[contentTarget] as HTMLElement
    const icon = this[iconTarget] as HTMLElement

    if (content && icon) {
      content.classList.toggle("hidden")
      icon.classList.toggle("rotate-180")
    }
  }

  openCitySelector(): void {
    alert("城市选择功能：\n\n在完整版本中，这里会打开城市选择器。\n\n当前城市：深圳市")
  }

  openGuestSelector(): void {
    const rooms = prompt("请输入房间数量", "1")
    const adults = prompt("请输入成人数量", "1")
    const children = prompt("请输入儿童数量", "0")
    
    if (rooms && adults) {
      const url = new URL(window.location.href)
      url.searchParams.set('rooms', rooms)
      url.searchParams.set('adults', adults)
      url.searchParams.set('children', children || '0')
      window.location.href = url.toString()
    }
  }
}
