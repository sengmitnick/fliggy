import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = [
    "avatar",
    "guideInfo"
  ]

  declare readonly avatarTargets: HTMLElement[]
  declare readonly guideInfoTarget: HTMLElement

  switchGuide(event: Event): void {
    const clickedAvatar = event.currentTarget as HTMLElement
    const guideId = clickedAvatar.dataset.guideId || ''
    
    // Read guide data from individual data attributes
    const name = clickedAvatar.dataset.guideName || ''
    const followerCount = parseInt(clickedAvatar.dataset.guideFollowerCount || '0')
    const experienceYears = parseInt(clickedAvatar.dataset.guideExperienceYears || '0')
    const description = clickedAvatar.dataset.guideDescription || ''
    const price = parseFloat(clickedAvatar.dataset.guidePrice || '0')
    const servedCount = parseInt(clickedAvatar.dataset.guideServedCount || '0')
    const rating = parseFloat(clickedAvatar.dataset.guideRating || '0')

    // Update active state for avatars
    this.avatarTargets.forEach(avatar => {
      if (avatar.dataset.guideId === guideId) {
        avatar.classList.add('ring-2', 'ring-yellow-400')
        avatar.classList.remove('opacity-70')
      } else {
        avatar.classList.remove('ring-2', 'ring-yellow-400')
        avatar.classList.add('opacity-70')
      }
    })

    // Update guide info
    this.guideInfoTarget.innerHTML = `
      <span class="text-[10px] text-amber-700 bg-amber-50 px-1 py-0.5 rounded mb-1 inline-block">精选讲师</span>
      <h4 class="font-bold text-lg text-slate-800">${name}</h4>
      ${rating > 0 ? `
        <div class="flex items-center gap-1 mb-1">
          ${this.renderStars(rating)}
          <span class="text-xs text-gray-500 font-medium">${rating.toFixed(1)}</span>
        </div>
      ` : ''}
      <p class="text-xs text-gray-400 mb-2">
        ${followerCount > 0 ? `粉丝${followerCount}万+` : ''}
        ${experienceYears > 0 ? ` · 从业${experienceYears}年+` : ''}
      </p>
      <p class="text-xs text-slate-600 line-clamp-2 leading-tight mb-2">" ${description}</p>
      
      <div class="flex items-end justify-between mt-2">
        <div class="font-bold text-lg leading-none" style="color: #FF4D3F;">
          <span class="text-xs">¥</span>${Math.floor(price)}<span class="text-xs font-normal text-gray-400 ml-0.5">起</span>
        </div>
        <a href="/deep_travels/${guideId}" class="text-slate-900 text-xs font-bold px-3 py-1.5 rounded-full" style="background-color: #FFE855;">
          去预约
        </a>
      </div>
      <p class="text-[10px] text-gray-400 mt-1">已服务${servedCount}+人</p>
    `
  }

  private renderStars(rating: number): string {
    const fullStars = Math.round(rating)
    const emptyStars = 5 - fullStars
    const starPath = (
      'M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034' +
      'a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57' +
      '-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0' +
      '00.951-.69l1.07-3.292z'
    )
    
    let starsHtml = ''
    for (let i = 0; i < fullStars; i++) {
      starsHtml += `<svg class="w-3 h-3 text-yellow-400" fill="currentColor" viewBox="0 0 20 20"><path d="${starPath}"/></svg>`
    }
    for (let i = 0; i < emptyStars; i++) {
      starsHtml += `<svg class="w-3 h-3 text-gray-300" fill="currentColor" viewBox="0 0 20 20"><path d="${starPath}"/></svg>`
    }
    return starsHtml
  }
}
