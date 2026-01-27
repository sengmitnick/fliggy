import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static values = {
    roomName: String,
    following: Boolean
  }

  declare readonly roomNameValue: string
  declare readonly followingValue: boolean

  connect(): void {
    console.log("LiveRoomFollow connected", this.roomNameValue, this.followingValue)
  }

  async follow(event: Event): Promise<void> {
    event.preventDefault()
    
    const button = event.currentTarget as HTMLButtonElement
    button.disabled = true
    
    try {
      const response = await fetch(`/live_rooms/${encodeURIComponent(this.roomNameValue)}/follow`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.csrfToken(),
          'Accept': 'application/json'
        }
      })
      
      if (!response.ok) {
        throw new Error('Follow request failed')
      }
      
      const data = await response.json()
      
      if (data.success) {
        // Reload the page to refresh the button state
        window.location.reload()
      }
    } catch (error) {
      console.error('Error following live room:', error)
      alert('关注失败，请重试')
    } finally {
      button.disabled = false
    }
  }

  async unfollow(event: Event): Promise<void> {
    event.preventDefault()
    
    const button = event.currentTarget as HTMLButtonElement
    button.disabled = true
    
    try {
      const response = await fetch(`/live_rooms/${encodeURIComponent(this.roomNameValue)}/unfollow`, {
        method: 'DELETE',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.csrfToken(),
          'Accept': 'application/json'
        }
      })
      
      if (!response.ok) {
        throw new Error('Unfollow request failed')
      }
      
      const data = await response.json()
      
      if (data.success) {
        // Reload the page to refresh the button state
        window.location.reload()
      }
    } catch (error) {
      console.error('Error unfollowing live room:', error)
      alert('取消关注失败，请重试')
    } finally {
      button.disabled = false
    }
  }

  private csrfToken(): string {
    const token = document.querySelector('meta[name="csrf-token"]') as HTMLMetaElement
    return token ? token.content : ''
  }
}
