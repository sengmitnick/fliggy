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
    mode: { type: String, default: "form" } // "form" for index page, "search" for search page
  }

  declare readonly modalTarget: HTMLElement
  declare readonly sceneItemTargets: HTMLElement[]
  declare readonly companyItemTargets: HTMLElement[]
  declare readonly scenesInputTarget: HTMLInputElement
  declare readonly companyInputTarget: HTMLInputElement
  declare readonly displayTextTarget: HTMLElement
  declare readonly modeValue: string
  
  // Regular properties for state management (NOT Stimulus Values)
  private selectedScenes: string[] = []
  private selectedCompanies: string[] = []

  initialize(): void {
    console.log("[INITIALIZE] InsuranceFilter controller is being initialized")
    // Make this controller accessible from console for debugging
    ;(window as any).insuranceFilterController = this
  }

  connect(): void {
    console.log("========== InsuranceFilter connected ==========")
    console.log("1. Controller initialized")
    
    // 从隐藏字段回填已有的值
    const scenesValue = this.scenesInputTarget.value
    const companyValue = this.companyInputTarget.value
    
    console.log("2. Reading values from hidden inputs:")
    console.log("   - scenesInput.value:", scenesValue)
    console.log("   - companyInput.value:", companyValue)
    
    this.selectedScenes = scenesValue ? scenesValue.split(',').filter(s => s.trim()) : []
    this.selectedCompanies = companyValue ? companyValue.split(',').filter(c => c.trim()) : []
    
    console.log("3. Parsed arrays:")
    console.log("   - selectedScenes:", this.selectedScenes)
    console.log("   - selectedCompanies:", this.selectedCompanies)
    console.log("   - Total selected:", this.selectedScenes.length + this.selectedCompanies.length)
    
    // 更新显示文本
    console.log("4. Calling updateDisplayText()")
    this.updateDisplayText()
    console.log("5. Display text after update:", this.displayTextTarget.textContent)
    console.log("=================================================")
  }

  open(): void {
    console.log("========== Modal opening ==========")
    console.log("Current selections:")
    console.log("   - Scenes:", this.selectedScenes)
    console.log("   - Companies:", this.selectedCompanies)
    
    this.modalTarget.classList.remove('hidden')
    document.body.style.overflow = 'hidden'
    
    // 恢复按钮的选中状态
    console.log("Restoring button states...")
    this.restoreButtonStates()
    console.log("====================================")
  }

  close(): void {
    this.modalTarget.classList.add('hidden')
    document.body.style.overflow = ''
  }

  toggleScene(event: Event): void {
    const target = event.currentTarget as HTMLElement
    const scene = target.dataset.scene || ''
    
    if (this.selectedScenes.includes(scene)) {
      this.selectedScenes = this.selectedScenes.filter(s => s !== scene)
      target.classList.remove('bg-primary', 'text-white')
      target.classList.add('bg-gray-100', 'text-gray-800')
    } else {
      this.selectedScenes.push(scene)
      target.classList.remove('bg-gray-100', 'text-gray-800')
      target.classList.add('bg-primary', 'text-white')
    }
  }

  toggleCompany(event: Event): void {
    const target = event.currentTarget as HTMLElement
    const company = target.dataset.company || ''
    
    if (this.selectedCompanies.includes(company)) {
      this.selectedCompanies = this.selectedCompanies.filter(c => c !== company)
      target.classList.remove('bg-primary', 'text-white')
      target.classList.add('bg-gray-100', 'text-gray-800')
    } else {
      this.selectedCompanies.push(company)
      target.classList.remove('bg-gray-100', 'text-gray-800')
      target.classList.add('bg-primary', 'text-white')
    }
  }

  reset(): void {
    this.selectedScenes = []
    this.selectedCompanies = []
    
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
    console.log("========== Confirm clicked ==========")
    console.log("Mode:", this.modeValue)
    console.log("Saving selections:")
    console.log("   - Scenes:", this.selectedScenes)
    console.log("   - Companies:", this.selectedCompanies)
    
    this.scenesInputTarget.value = this.selectedScenes.join(',')
    this.companyInputTarget.value = this.selectedCompanies.join(',')
    
    console.log("Hidden input values after save:")
    console.log("   - scenesInput.value:", this.scenesInputTarget.value)
    console.log("   - companyInput.value:", this.companyInputTarget.value)
    
    this.updateDisplayText()
    this.close()
    
    // If in search mode, navigate to search page with new params
    if (this.modeValue === "search") {
      const urlParams = new URLSearchParams(window.location.search)
      
      // Update filter params
      if (this.selectedScenes.length > 0) {
        urlParams.set('scenes', this.selectedScenes.join(','))
      } else {
        urlParams.delete('scenes')
      }
      
      if (this.selectedCompanies.length > 0) {
        urlParams.set('company', this.selectedCompanies.join(','))
      } else {
        urlParams.delete('company')
      }
      
      // Navigate to new URL
      const newUrl = `${window.location.pathname}?${urlParams.toString()}`
      console.log("Navigating to:", newUrl)
      window.location.href = newUrl
    }
    
    console.log("=====================================")
  }
  
  updateDisplayText(): void {
    const totalSelected = this.selectedScenes.length + this.selectedCompanies.length
    console.log("[updateDisplayText] Total selected:", totalSelected)
    
    if (totalSelected > 0) {
      this.displayTextTarget.textContent = `已选 ${totalSelected} 项`
      this.displayTextTarget.classList.remove('text-gray-400')
      this.displayTextTarget.classList.add('text-gray-900')
      console.log(`[updateDisplayText] Set text to '已选 ${totalSelected} 项', color: gray-900`)
    } else {
      // Different placeholder text based on mode
      const placeholderText = this.modeValue === "search" ? "筛选" : "选择适用场景/保险公司（选填）"
      this.displayTextTarget.textContent = placeholderText
      this.displayTextTarget.classList.remove('text-gray-900')
      this.displayTextTarget.classList.add('text-gray-400')
      console.log(`[updateDisplayText] Set text to '${placeholderText}', color: gray-400`)
    }
  }
  
  restoreButtonStates(): void {
    console.log("[restoreButtonStates] Starting...")
    console.log("   - Scene items count:", this.sceneItemTargets.length)
    console.log("   - Company items count:", this.companyItemTargets.length)
    
    // 恢复场景按钮状态
    let scenesRestored = 0
    this.sceneItemTargets.forEach(item => {
      const scene = item.dataset.scene || ''
      if (this.selectedScenes.includes(scene)) {
        item.classList.remove('bg-gray-100', 'text-gray-800')
        item.classList.add('bg-primary', 'text-white')
        console.log(`   - ✓ Scene '${scene}' set to SELECTED`)
        scenesRestored++
      } else {
        item.classList.remove('bg-primary', 'text-white')
        item.classList.add('bg-gray-100', 'text-gray-800')
      }
    })
    
    // 恢复保险公司按钮状态
    let companiesRestored = 0
    this.companyItemTargets.forEach(item => {
      const company = item.dataset.company || ''
      if (this.selectedCompanies.includes(company)) {
        item.classList.remove('bg-gray-100', 'text-gray-800')
        item.classList.add('bg-primary', 'text-white')
        console.log(`   - ✓ Company '${company}' set to SELECTED`)
        companiesRestored++
      } else {
        item.classList.remove('bg-primary', 'text-white')
        item.classList.add('bg-gray-100', 'text-gray-800')
      }
    })
    
    console.log(`[restoreButtonStates] Restored ${scenesRestored} scenes, ${companiesRestored} companies`)
  }

  closeOnBackdrop(event: Event): void {
    if (event.target === event.currentTarget) {
      this.close()
    }
  }
  
  stopPropagation(event: Event): void {
    event.stopPropagation()
  }
  
  // Debug method - can be called from console via: insuranceFilterController.debug()
  debug(): void {
    console.log("[DEBUG] Current State")
    console.log("selectedScenes:", this.selectedScenes)
    console.log("selectedCompanies:", this.selectedCompanies)
    console.log("scenesInput.value:", this.scenesInputTarget.value)
    console.log("companyInput.value:", this.companyInputTarget.value)
    console.log("displayText.textContent:", this.displayTextTarget.textContent)
  }
}
