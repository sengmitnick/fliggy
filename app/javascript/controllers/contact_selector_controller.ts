import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = [
    "modal",
    "nameDisplay",
    "emailDisplay",
    "phoneDisplay",
    "contactIdInput",
    "contactItem"
  ]

  static values = {
    selectedContactId: Number
  }

  declare readonly modalTarget: HTMLElement
  declare readonly nameDisplayTarget: HTMLElement
  declare readonly emailDisplayTarget: HTMLElement
  declare readonly phoneDisplayTarget: HTMLElement
  declare readonly contactIdInputTarget: HTMLInputElement
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

  selectContact(event: Event): void {
    const button = event.currentTarget as HTMLElement
    const contactId = parseInt(button.dataset.contactId || '0')
    const contactName = button.dataset.contactName || ''
    const contactEmail = button.dataset.contactEmail || ''
    const contactPhone = button.dataset.contactPhone || ''

    // Update selected contact ID
    this.selectedContactIdValue = contactId
    this.contactIdInputTarget.value = contactId.toString()

    // Update display
    this.nameDisplayTarget.textContent = contactName
    if (contactEmail) {
      this.emailDisplayTarget.textContent = contactEmail
      this.emailDisplayTarget.closest('div')?.classList.remove('hidden')
    } else {
      this.emailDisplayTarget.closest('div')?.classList.add('hidden')
    }
    if (contactPhone) {
      this.phoneDisplayTarget.textContent = contactPhone
      this.phoneDisplayTarget.closest('div')?.classList.remove('hidden')
    } else {
      this.phoneDisplayTarget.closest('div')?.classList.add('hidden')
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
