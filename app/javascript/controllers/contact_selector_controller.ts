import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = [
    // stimulus-validator: disable-next-line
    "modal",
    "nameDisplay",
    "emailDisplay",
    "phoneDisplay",
    "contactIdInput",
    "contactPhoneInput",
    // stimulus-validator: disable-next-line
    "contactItem"
  ]

  static values = {
    selectedContactId: Number
  }

  // stimulus-validator: disable-next-line
  declare readonly modalTarget: HTMLElement
  declare readonly hasNameDisplayTarget: boolean
  declare readonly nameDisplayTarget?: HTMLElement
  declare readonly hasEmailDisplayTarget: boolean
  declare readonly emailDisplayTarget?: HTMLElement
  declare readonly hasPhoneDisplayTarget: boolean
  declare readonly phoneDisplayTarget?: HTMLElement
  declare readonly hasContactIdInputTarget: boolean
  declare readonly contactIdInputTarget?: HTMLInputElement
  declare readonly hasContactPhoneInputTarget: boolean
  declare readonly contactPhoneInputTarget?: HTMLInputElement
  // stimulus-validator: disable-next-line
  declare readonly contactItemTargets: HTMLElement[]
  declare selectedContactIdValue: number

  connect(): void {
    console.log("ContactSelector connected", { selectedContactId: this.selectedContactIdValue })
  }

  openModal(): void {
    this.modalTarget.classList.remove('hidden')
    document.body.style.overflow = 'hidden'
    this.updateSelectedState()
  }

  closeModal(): void {
    this.modalTarget.classList.add('hidden')
    document.body.style.overflow = ''
  }

  stopPropagation(event: Event): void {
    event.stopPropagation()
  }

  selectContact(event: Event): void {
    const button = event.currentTarget as HTMLElement
    const contactId = parseInt(button.dataset.contactId || '0')
    const contactName = button.dataset.contactName || ''
    const contactEmail = button.dataset.contactEmail || ''
    const contactPhone = button.dataset.contactPhone || ''

    // Update selected contact ID
    this.selectedContactIdValue = contactId
    
    // Update contact ID input if exists
    if (this.hasContactIdInputTarget && this.contactIdInputTarget) {
      this.contactIdInputTarget.value = contactId.toString()
    }

    // Update name display if exists - support both input and display elements
    if (this.hasNameDisplayTarget && this.nameDisplayTarget) {
      if (this.nameDisplayTarget instanceof HTMLInputElement) {
        this.nameDisplayTarget.value = contactName
      } else {
        this.nameDisplayTarget.textContent = contactName
      }
    }
    
    // Update visible display element (for visa orders)
    const nameDisplayElement = document.getElementById('contact-name-display')
    if (nameDisplayElement) {
      nameDisplayElement.textContent = contactName
    }
    
    // Update email display if exists
    if (this.hasEmailDisplayTarget && this.emailDisplayTarget) {
      if (contactEmail) {
        if (this.emailDisplayTarget instanceof HTMLInputElement) {
          this.emailDisplayTarget.value = contactEmail
        } else {
          this.emailDisplayTarget.textContent = contactEmail
        }
        this.emailDisplayTarget.closest('div')?.classList.remove('hidden')
      } else {
        this.emailDisplayTarget.closest('div')?.classList.add('hidden')
      }
    }
    
    // Update visible display element (for visa orders)
    const emailDisplayElement = document.getElementById('contact-email-display')
    if (emailDisplayElement) {
      if (contactEmail) {
        emailDisplayElement.textContent = contactEmail
        emailDisplayElement.closest('div')?.classList.remove('hidden')
      } else {
        emailDisplayElement.closest('div')?.classList.add('hidden')
      }
    }
    
    // Update phone display if exists
    if (this.hasPhoneDisplayTarget && this.phoneDisplayTarget) {
      if (contactPhone) {
        if (this.phoneDisplayTarget instanceof HTMLInputElement) {
          this.phoneDisplayTarget.value = contactPhone
        } else {
          this.phoneDisplayTarget.textContent = contactPhone
        }
        this.phoneDisplayTarget.closest('div')?.classList.remove('hidden')
      } else {
        this.phoneDisplayTarget.closest('div')?.classList.add('hidden')
      }
    }
    
    // Update visible display element (for visa orders)
    const phoneDisplayElement = document.getElementById('contact-phone-display')
    if (phoneDisplayElement) {
      phoneDisplayElement.textContent = contactPhone
    }
    
    // Update phone input if exists (for ticket orders)
    if (this.hasContactPhoneInputTarget && this.contactPhoneInputTarget) {
      this.contactPhoneInputTarget.value = contactPhone
    }

    // Update selected state in modal
    this.updateSelectedState()

    // Close modal
    this.closeModal()
  }

  private updateSelectedState(): void {
    this.contactItemTargets.forEach(item => {
      const contactId = parseInt(item.dataset.contactId || '0')
      const checkIcon = item.querySelector('.check-icon')
      
      if (contactId === this.selectedContactIdValue) {
        item.classList.add('border-primary', 'bg-primary/5')
        item.classList.remove('border-gray-200')
        if (checkIcon) {
          checkIcon.classList.remove('hidden')
        }
      } else {
        item.classList.remove('border-primary', 'bg-primary/5')
        item.classList.add('border-gray-200')
        if (checkIcon) {
          checkIcon.classList.add('hidden')
        }
      }
    })
  }

  closeOnBackdrop(event: Event): void {
    if (event.target === event.currentTarget) {
      this.closeModal()
    }
  }
}
