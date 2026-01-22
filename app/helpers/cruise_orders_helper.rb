module CruiseOrdersHelper
  def status_text(status)
    case status
    when 'pending' then '待支付'
    when 'paid' then '已支付'
    when 'confirmed' then '已确认'
    when 'completed' then '已完成'
    when 'cancelled' then '已取消'
    else status
    end
  end

  def status_color(status)
    case status
    when 'pending' then 'text-yellow-600'
    when 'paid', 'confirmed' then 'text-green-600'
    when 'completed' then 'text-blue-600'
    when 'cancelled' then 'text-gray-400'
    else 'text-gray-900'
    end
  end
end
