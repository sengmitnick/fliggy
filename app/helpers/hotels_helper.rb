module HotelsHelper
  def date_label(date)
    date = Date.parse(date) if date.is_a?(String)
    today = Time.zone.today
    
    case (date - today).to_i
    when 0
      '今天'
    when 1
      '明天'
    when 2
      '后天'
    else
      # Return weekday name for dates beyond 后天
      weekdays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六']
      weekdays[date.wday]
    end
  end
end
