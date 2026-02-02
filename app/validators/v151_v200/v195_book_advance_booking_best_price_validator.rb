# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例511: 预订15天后出发的最优价格组合
#
# 任务描述:
#   预订15天后出发的最优价格组合
#
# 评分标准:
#   - TODO: 定义评分标准
#
# 使用方法:
#   # 准备阶段
#   POST /api/tasks/v511_book_advance_booking_best_price_validator/start
#   
#   # Agent 通过界面操作完成任务...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
module V151V200
  class V195BookAdvanceBookingBestPriceValidator < BaseValidator
    self.validator_id = 'v195_book_advance_booking_best_price_validator'
    self.task_id = '6f3a5eb6-ae1b-45cc-ae14-ecec290c6cba'
    self.title = '预订15天后出发的最优价格组合'
    self.description = '预订15天后出发的最优价格组合'
    self.timeout_seconds = 300
    
    # 准备阶段：设置任务参数
    #
    # 返回任务信息给 Agent（必须包含 task 字段）
    #
    # Example:
    #   def prepare
    #     @city = '深圳'
    #     @budget = 500
    #     
    #     {
    #       task: "请预订#{@city}的酒店，预算≤#{@budget}元",
    #       city: @city,
    #       budget: @budget,
    #       hint: "系统中有多家酒店可选，请选择性价比最高的"
    #     }
    #   end
    def prepare
      # TODO: 设置任务参数（使用实例变量存储，用于后续 verify）
      
      # 返回任务信息
      {
        task: '预订15天后出发的最优价格组合',
        # TODO: 添加更多任务参数和提示
      }
    end
    
    # 验证阶段：检查任务是否完成
    #
    # 使用 add_assertion 添加断言（必须指定 weight 权重，总和为 100）
    def verify
      # TODO: 添加断言验证任务完成情况
      
      # 第一个断言：验证核心操作是否完成
      add_assertion "TODO: 断言描述", weight: 20 do
        # Query with data_version filter
        # @record = Model.where(data_version: @data_version).order(created_at: :desc).first
        # expect(@record).not_to be_nil, "未找到记录"
      end
      
      # Guard clause: 如果核心操作未完成，后续断言无法继续
      # return unless @record
      
      # 后续断言：验证具体属性
      add_assertion "TODO: 属性验证2", weight: 20 do
      end
      
      add_assertion "TODO: 属性验证3", weight: 20 do
      end
      
      add_assertion "TODO: 属性验证4", weight: 20 do
      end
      
      add_assertion "TODO: 属性验证5", weight: 20 do
      end
    end
    
    # 模拟 AI Agent 操作
    #
    # 此方法模拟 AI Agent 如何完成任务（用于自动化测试）
    #
    # Example:
    #   def simulate
    #     user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    #     
    #     hotel = Hotel.where(city: @city, data_version: 0)
    #                  .where('price <= ?', @budget)
    #                  .order(rating: :desc)
    #                  .first
    #     
    #     HotelBooking.create!(
    #       user_id: user.id,
    #       hotel_id: hotel.id,
    #       check_in_date: @check_in_date,
    #       total_price: hotel.price
    #     )
    #   end
    def simulate
      # TODO: 实现 AI Agent 自动化逻辑
      
      # 1. 查找测试用户（数据包中已创建，data_version: 0）
      # user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 2. 根据任务要求查找数据（注意过滤 data_version: 0）
      # target = Model.where(data_version: 0).where(...).first
      
      # 3. 创建订单/记录（使用 data_version: @data_version）
      # Record.create!(
      #   user_id: user.id,
      #   # ... other fields
      #   data_version: @data_version  # 关键：使用当前 execution 的 data_version
      # )
      
      raise NotImplementedError, "TODO: 实现 simulate 方法"
    end
    
    private
    
    # 保存执行状态数据（用于跨请求恢复状态）
    #
    # 返回需要持久化的实例变量数据
    def execution_state_data
      {
        # TODO: 添加需要保存的状态数据
        # city: @city,
        # budget: @budget
      }
    end
    
    # 从状态恢复实例变量（用于跨请求恢复状态）
    #
    # 从持久化数据恢复实例变量
    def restore_from_state(data)
      # TODO: 从 data 恢复实例变量
      # @city = data['city']
      # @budget = data['budget']
    end
  end
end
