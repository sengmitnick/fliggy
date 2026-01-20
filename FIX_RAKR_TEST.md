📋 测试错误问题清单和解决方案
问题 1: Stimulus 验证 - 缺失 Targets (217个错误)
原因: Stimulus 控制器声明了 targets，但在对应的 HTML 视图中缺少这些 target 元素

典型错误:

payment-confirmation:processingAmount 和 userEmail 在多个视图中缺失
abroad-ticket-search:form, regionInput, originInput 等缺失
bus-ticket-search:overlay, modal, 各种 tab 和 section 缺失
deep-travel:video, videoContainer 等缺失
解决方案:

方案A (推荐): 在对应的视图中添加缺失的 data-xxx-target 属性元素
方案B: 如果某些 target 是可选的或动态生成的，在控制器中使用 hasXXXTarget 检查，或添加 // stimulus-validator: disable-next-line 注释
问题 2: Stimulus 验证 - querySelector 找不到元素 (28个错误)
原因: Stimulus 控制器中使用了 querySelector/querySelectorAll 查找特定选择器，但这些元素在视图中不存在

典型错误:

city-selector 控制器在多个视图中查找 [data-city-name] 和 [data-hot-cities]，但元素缺失
解决方案:

方案A (推荐): 在对应视图中添加缺失的元素和属性
方案B: 如果选择器是动态生成的或确实不需要，在代码前添加 // stimulus-validator: disable-next-line 注释
问题 3: Turbo 架构验证 - 使用了禁止的模式 (56个错误)
原因: 多个控制器使用了违反 Turbo Stream 架构的模式

违规类型:

使用 respond_to 块 (多处) - 添加不必要的复杂性
使用 format.html/json/turbo_stream (多处) - 违反简化架构
使用 render json: (多处) - 需要手动处理前端数据和 DOM 更新
受影响的文件:

abroad_ticket_orders_controller.rb
bus_ticket_orders_controller.rb
flights_controller.rb
hotel_bookings_controller.rb
profiles_controller.rb
等多个控制器
解决方案:

删除 respond_to 块，直接渲染 HTML 或 Turbo Stream
删除 format.* 调用，使用直接渲染
将 render json: 改为 Turbo Stream 响应（创建 .turbo_stream.erb 视图）
问题 4: Playwright 浏览器未安装
原因: Playwright 的 Chromium 浏览器未安装

错误信息:

Executable doesn't exist at /home/runner/.cache/ms-playwright/chromium_headless_shell-1200/
解决方案: 运行命令安装浏览器：bundle exec playwright install chromium

问题 5: Playwright 测试 - 购买流程测试 (2个错误)
原因: 由于问题4，浏览器未安装导致测试无法运行

解决方案: 先解决问题4，安装浏览器后再运行这些测试

🎯 建议的修复顺序
我建议按以下顺序修复，从最简单到最复杂：

问题 4 (最简单) - 安装 Playwright 浏览器
问题 3 (中等) - 修复 Turbo 架构违规（重构控制器响应逻辑）
问题 2 (中等) - 修复 querySelector 缺失元素
问题 1 (复杂) - 修复 217 个缺失的 Stimulus targets
问题 5 (依赖) - 重新运行 Playwright 测试