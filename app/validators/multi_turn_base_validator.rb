# frozen_string_literal: true

# Multi-Turn Base Validator
# Extends BaseValidator to support AI-powered multi-turn dialogue testing
#
# Usage:
#   class HotelBookingMultiTurnValidator < MultiTurnBaseValidator
#     self.validator_id = 'v501'
#     self.task_id = 'uuid-here'
#     self.title = '酒店预订多轮对话'
#     self.max_turns = 10
#
#     def initial_task_goal
#       "帮我订一个上海的酒店，预算 500 元左右"
#     end
#
#     def user_context
#       { budget: 500, city: '上海', check_in_date: 3.days.from_now }
#     end
#
#     def verify
#       # Use standard assertions to check results
#       add_assertion "创建了酒店订单", weight: 50 do
#         orders = HotelOrder.where(data_version: @data_version)
#         expect(orders).not_to be_empty
#       end
#     end
#   end
class MultiTurnBaseValidator < BaseValidator
  class << self
    attr_accessor :max_turns
  end

  # Default max conversation turns
  self.max_turns = 10

  attr_reader :conversation_turns, :simul_user_service

  def initialize(execution_id = SecureRandom.uuid)
    super(execution_id)
    @conversation_turns = []
    @simul_user_service = nil
    @current_turn = 0
  end

  # Override simulate method to support multi-turn dialogue
  def simulate
    initialize_simul_user

    # First turn: simulated user sends initial request
    user_message = @simul_user_service.generate_message
    record_turn('simul_user', user_message)

    # Continue conversation until completion or max turns reached
    while @current_turn < self.class.max_turns
      @current_turn += 1

      # Agent processes user message and responds
      agent_response = process_user_message(user_message)
      record_turn('agent', agent_response)

      # Check if conversation should end
      break if @simul_user_service.should_end_conversation?

      # Simulated user generates next message based on agent's response
      user_message = @simul_user_service.generate_message(agent_response: agent_response)
      record_turn('simul_user', user_message)
    end

    Rails.logger.info("Multi-turn conversation completed in #{@current_turn} turns")
  rescue => e
    Rails.logger.error("Multi-turn simulation failed: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    raise
  end

  # Subclasses must implement: Define the initial task goal
  def initial_task_goal
    raise NotImplementedError, "Subclass must implement #initial_task_goal"
  end

  # Subclasses can override: Provide user context/background
  def user_context
    {}
  end

  # Subclasses can override: Process user message and return agent response
  # Default implementation calls the verify API endpoint
  def process_user_message(message)
    # This method should be overridden by subclasses to call their specific agent API
    # Default: return a placeholder response
    "我已收到您的消息：#{message}。正在处理中..."
  end

  # Subclasses can override: Evaluate agent behavior during conversation
  # This is called after each agent response for real-time validation
  def evaluate_agent_behavior(agent_response, turn_number)
    # Default: no evaluation
    # Subclasses can override to add real-time checks
    nil
  end

  private

  def initialize_simul_user
    @simul_user_service = AiSimulUserService.new(
      task_goal: initial_task_goal,
      user_context: user_context
    )
  end

  def record_turn(role, message)
    turn_data = {
      turn_number: @conversation_turns.size + 1,
      role: role,
      message: message,
      timestamp: Time.current
    }

    @conversation_turns << turn_data

    # Persist to database
    DialogTurn.create!(
      validator_execution_id: nil, # Will be set when ValidatorExecution is created
      turn_number: turn_data[:turn_number],
      role: role,
      message: message,
      metadata: { timestamp: turn_data[:timestamp] },
      data_version: @data_version
    )

    Rails.logger.info("Turn #{turn_data[:turn_number]} [#{role}]: #{message[0..100]}")
  end
end
