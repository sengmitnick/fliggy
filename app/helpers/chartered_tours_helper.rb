module CharteredToursHelper
  def tab_button_class(tab_name, active_tab)
    base_classes = 'flex-1 py-3 text-center text-sm font-medium transition-colors'
    if tab_name == active_tab
      "#{base_classes} text-primary border-b-2 border-primary"
    else
      "#{base_classes} text-text-secondary"
    end
  end

  def tab_content_class(tab_name, active_tab)
    tab_name == active_tab ? '' : 'hidden'
  end
end
