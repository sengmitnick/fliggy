import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = [
    "modal",
    "sceneItem",
    "companyItem",
    "scenesInput",
    "companyInput",
    "displayText"
  ]

  static values = {
    selectedScenes: Array,
    selectedCompanies: Array
  }

  declare readonly modalTarget: HTMLElement
  declare readonly sceneItemTargets: HTMLElement[]
  declare readonly companyItemTargets: HTMLElement[]
  declare readonly scenesInputTarget: HTMLInputElement
  declare readonly companyInputTarget: HTMLInputElement
  declare readonly displayTextTarget: HTMLElement
  declare selectedScenesValue: string[]
  declare selectedCompaniesValue: string[]

  connect(): void {
    console.log("InsuranceFilter connected")
    this.selectedScenesValue = []
    this.selectedCompaniesValue = []
  }

  open(): void {
    this.modalTarget.classList.remove('hidden')
    document.body.style.overflow = 'hidden'
  }

  close(): void {
    this.modalTarget.classList.add('hidden')
    document.body.style.overflow = ''
  }

  toggleScene(event: Event): void {
    const target = event.currentTarget as HTMLElement
    const scene = target.dataset.scene || ''
    
    if (this.selectedScenesValue.includes(scene)) {
      this.selectedScenesValue = this.selectedScenesValue.filter(s => s !== scene)
      target.classList.remove('bg-primary', 'text-white')
      target.classList.add('bg-gray-100', 'text-gray-800')
    } else {
      this.selectedScenesValue.push(scene)
      target.classList.remove('bg-gray-100', 'text-gray-800')
      target.classList.add('bg-primary', 'text-white')
    }
  }

  toggleCompany(event: Event): void {
    const target = event.currentTarget as HTMLElement
    const company = target.dataset.company || ''
    
    if (this.selectedCompaniesValue.includes(company)) {
      this.selectedCompaniesValue = this.selectedCompaniesValue.filter(c => c !== company)
      target.classList.remove('bg-primary', 'text-white')
      target.classList.add('bg-gray-100', 'text-gray-800')
    } else {
      this.selectedCompaniesValue.push(company)
      target.classList.remove('bg-gray-100', 'text-gray-800')
      target.classList.add('bg-primary', 'text-white')
    }
  }

  reset(): void {
    this.selectedScenesValue = []
    this.selectedCompaniesValue = []
    
    this.sceneItemTargets.forEach(item => {
      item.classList.remove('bg-primary', 'text-white')
      item.classList.add('bg-gray-100', 'text-gray-800')
    })
    
    this.companyItemTargets.forEach(item => {
      item.classList.remove('bg-primary', 'text-white')
      item.classList.add('bg-gray-100', 'text-gray-800')
    })
  }

  confirm(): void {
    this.scenesInputTarget.value = this.selectedScenesValue.join(',')
    this.companyInputTarget.value = this.selectedCompaniesValue.join(',')
    
    const totalSelected = this.selectedScenesValue.length + this.selectedCompaniesValue.length
    if (totalSelected > 0) {
      this.displayTextTarget.textContent = `已选 ${totalSelected} 项`
    } else {
      this.displayTextTarget.textContent = '选择适用场景/保险公司（选填）'
    }
    
    this.close()
  }

  closeOnBackdrop(event: Event): void {
    if (event.target === event.currentTarget) {
      this.close()
    }
  }
}
