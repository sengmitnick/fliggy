import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = [
    "avatar",
    "guideInfo",
    "bookButton"
  ]

  declare readonly avatarTargets: HTMLElement[]
  declare readonly guideInfoTarget: HTMLElement
  declare readonly bookButtonTarget: HTMLAnchorElement

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
}
