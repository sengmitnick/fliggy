# frozen_string_literal: true

# AI-Powered Simulated User Service
# Uses LLM to generate realistic user messages in multi-turn dialogues
class AiSimulUserService
  attr_reader :task_goal, :user_context, :conversation_history

  def initialize(task_goal:, user_context: {})
    @task_goal = task_goal
    @user_context = user_context
    @conversation_history = []
  end

  # Generate next user message based on agent's response
  # @param agent_response [String] The agent's last response
  # @param skip_add_agent_to_history [Boolean] Skip adding agent response to history (default: false)
  # @return [String] The simulated user's next message
  def generate_message(agent_response: nil, skip_add_agent_to_history: false)
    add_to_history('agent', agent_response) if agent_response && !skip_add_agent_to_history

    system_prompt = build_system_prompt

    # 构建对话历史信息（作为 prompt 的一部分）
    if conversation_history.empty?
      # 初始消息：直接使用 task_goal
      prompt = task_goal
    else
      # 后续消息：包含对话历史
      prompt = <<~PROMPT
        对话历史：
        #{format_conversation_history}

        根据以上对话历史，生成你的下一条消息。记住：
        1. 你是用户，不是助手
        2. 根据助手的提问，提供相应的信息
        3. 不要重复你已经说过的话
        4. 直接回答问题，不要客套
        5. 不要主动要求助手做任何事
      PROMPT
    end

    response = LlmService.call(
      prompt: prompt,
      system: system_prompt
    )

    user_message = extract_message_from_response(response)
    add_to_history('simul_user', user_message)

    user_message
  end

  # Determine if the conversation should end
  # @return [Boolean] true if task is completed or cannot proceed
  def should_end_conversation?
    return false if conversation_history.empty?

    system_prompt = "你是一个对话分析助手。判断用户的任务目标是否已经完成或无法继续。"
    
    prompt = <<~PROMPT
      任务目标：#{task_goal}

      对话历史：
      #{format_conversation_history}

      请分析：
      1. 任务是否已经完成（订单已创建/信息已确认）？
      2. 是否出现无法继续的情况（缺少必要信息/用户拒绝/任务失败）？

      只需回答：YES 或 NO
      - YES：任务完成或无法继续
      - NO：仍需继续对话
    PROMPT

    response = LlmService.call(
      prompt: prompt,
      system: system_prompt
    )

    response.strip.upcase == 'YES'
  end

  # Evaluate agent's response against expected behavior
  # @param agent_response [String] The agent's response to evaluate
  # @param expected_behavior [String] Description of expected behavior
  # @return [Hash] Evaluation result with score and feedback
  def evaluate_agent_response(agent_response, expected_behavior)
    system_prompt = "你是一个智能对话评估助手。评估 AI 助手的回复是否符合预期行为。"
    
    prompt = <<~PROMPT
      预期行为：#{expected_behavior}

      对话历史：
      #{format_conversation_history}

      当前助手回复：#{agent_response}

      请评估：
      1. 助手是否表现出预期的行为？
      2. 回复是否合理、专业、有帮助？
      3. 是否有需要改进的地方？

      请以 JSON 格式返回评估结果：
      {
        "meets_expectation": true/false,
        "score": 0-100,
        "feedback": "具体反馈"
      }
    PROMPT

    response = LlmService.call(
      prompt: prompt,
      system: system_prompt
    )

    parse_evaluation_response(response)
  rescue => e
    Rails.logger.error("Failed to evaluate agent response: #{e.message}")
    { meets_expectation: false, score: 0, feedback: "评估失败：#{e.message}" }
  end

  private

  def build_system_prompt
    <<~PROMPT
      你是一个真实用户模拟器。你的任务是：模拟一个普通用户与 AI 助手进行对话，完成以下任务目标。

      任务目标：#{task_goal}

      你的真实需求信息（这些是你真正想要的，当助手提问时你应该提供）：
      #{format_user_context}

      ⚠️ 重要的角色限制：
      1. 你是被动的用户，只回答助手的问题
      2. 不要主动要求助手做任何事（例如：不要说"你能推荐吗"、"帮我找找"、"给我看看"等）
      3. 不要一次性提供所有信息，只在被问到时才回答
      4. 每次回答要简短，只针对当前问题
      5. 当助手询问时，根据上面"你的真实需求信息"如实回答
      6. 对于确认类问题（如"是否预订"），简单回答"好的"或"是的"即可
      7. 不要添加额外的客套话或主动询问

      错误示例（不要这样说）：
      ❌ "你能推荐几个酒店吗？"
      ❌ "帮我找找符合条件的酒店"
      ❌ "我想看看有哪些选项"
      ❌ "等等，你还没回答我"
      
      正确示例（应该这样说）：
      ✅ "上海的"
      ✅ "3天后入住，住一晚"
      ✅ "500元左右"
      ✅ "好的"

      请根据助手的回复，生成你的下一条消息。只返回消息内容，不要添加任何解释。
    PROMPT
  end

  def build_messages_for_llm
    conversation_history.map do |turn|
      role = turn[:role] == 'simul_user' ? 'user' : 'assistant'
      { role: role, content: turn[:message] }
    end
  end

  def format_user_context
    return "无特定背景信息" if user_context.empty?

    user_context.map do |k, v|
      case k.to_s
      when 'city'
        "城市：#{v}"
      when 'budget'
        "预算：每晚#{v}元"
      when 'check_in_date'
        "入住日期：#{v}"
      when 'check_out_date'
        "离店日期：#{v}"
      when 'preferences'
        "偏好：#{v}"
      else
        "#{k}: #{v}"
      end
    end.join("\n")
  end

  def format_conversation_history
    return "无对话历史" if conversation_history.empty?

    conversation_history.map do |turn|
      role_name = turn[:role] == 'simul_user' ? '用户' : '助手'
      "#{role_name}：#{turn[:message]}"
    end.join("\n")
  end

  def extract_message_from_response(response)
    # LlmService returns the text response directly
    response.strip
  end

  def parse_evaluation_response(response)
    # Try to parse JSON response
    result = JSON.parse(response, symbolize_names: true)
    {
      meets_expectation: result[:meets_expectation] || false,
      score: result[:score] || 0,
      feedback: result[:feedback] || "无反馈"
    }
  rescue JSON::ParserError
    # Fallback if response is not valid JSON
    { meets_expectation: false, score: 0, feedback: "无法解析评估结果" }
  end

  def add_to_history(role, message)
    return if message.blank?

    @conversation_history << {
      role: role,
      message: message,
      timestamp: Time.current
    }
  end
end
