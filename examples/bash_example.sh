#!/bin/bash

# 验证任务 API - Bash 示例
# 演示如何使用 curl 调用验证任务 API

# 配置
API_BASE="https://3000-ec82d74f5a03-web.clackypaas.com/api"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================
# 函数定义
# ============================================

# 创建验证任务
create_task() {
    local departure_city="$1"
    local arrival_city="$2"
    local departure_date="$3"
    
    echo -e "${BLUE}📋 创建验证任务...${NC}"
    echo "   出发城市: $departure_city"
    echo "   到达城市: $arrival_city"
    echo "   出发日期: $departure_date"
    
    response=$(curl -s -X POST "$API_BASE/validation_tasks" \
        -H "Content-Type: application/json" \
        -d "{
            \"departure_city\": \"$departure_city\",
            \"arrival_city\": \"$arrival_city\",
            \"departure_date\": \"$departure_date\"
        }")
    
    # 检查是否成功
    success=$(echo "$response" | python3 -c "import sys, json; print(json.load(sys.stdin)['success'])")
    
    if [ "$success" = "True" ]; then
        task_id=$(echo "$response" | python3 -c "import sys, json; print(json.load(sys.stdin)['task_id'])")
        user_instruction=$(echo "$response" | python3 -c "import sys, json; print(json.load(sys.stdin)['task_info']['user_instruction'])")
        
        echo -e "${GREEN}✅ 任务创建成功！${NC}"
        echo "   任务ID: $task_id"
        echo "   用户指令: $user_instruction"
        
        # 返回任务ID（通过全局变量）
        TASK_ID="$task_id"
        return 0
    else
        echo -e "${RED}❌ 创建失败${NC}"
        echo "$response" | python3 -m json.tool
        return 1
    fi
}

# 验证任务
verify_task() {
    local task_id="$1"
    
    echo -e "\n${BLUE}🔍 验证任务结果...${NC}"
    echo "   任务ID: $task_id"
    
    response=$(curl -s -X POST "$API_BASE/validation_tasks/$task_id/verify")
    
    # 检查是否成功
    success=$(echo "$response" | python3 -c "import sys, json; print(json.load(sys.stdin)['success'])")
    
    if [ "$success" = "True" ]; then
        echo -e "${GREEN}✅ 验证通过！任务成功完成${NC}"
        
        # 显示预订详情
        echo -e "\n📦 预订详情:"
        echo "$response" | python3 -c "
import sys, json
data = json.load(sys.stdin)
booking = data['validation_result']['booking_details']
if booking:
    print(f\"   预订ID: {booking['booking_id']}\")
    print(f\"   航班号: {booking['flight']['flight_number']}\")
    print(f\"   路线: {booking['flight']['departure_city']} → {booking['flight']['destination_city']}\")
    print(f\"   日期: {booking['flight']['departure_date']}\")
    print(f\"   状态: {booking['status']}\")
"
        return 0
    else
        echo -e "${RED}❌ 验证失败！${NC}"
        
        # 显示错误详情
        echo -e "\n🔍 错误详情:"
        echo "$response" | python3 -c "
import sys, json
data = json.load(sys.stdin)
errors = data['validation_result']['errors']
for i, error in enumerate(errors, 1):
    print(f\"   {i}. {error}\")
"
        return 1
    fi
}

# 查询任务状态
get_task_status() {
    local task_id="$1"
    
    echo -e "\n${BLUE}📊 查询任务状态...${NC}"
    
    response=$(curl -s "$API_BASE/validation_tasks/$task_id")
    
    # 检查HTTP状态
    http_code=$(curl -s -o /dev/null -w "%{http_code}" "$API_BASE/validation_tasks/$task_id")
    
    if [ "$http_code" = "200" ]; then
        echo "$response" | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(f\"   状态: {data['status']}\")
print(f\"   用户指令: {data['task_info']['user_instruction']}\")
print(f\"   创建时间: {data['task_info']['created_at']}\")
"
    else
        echo -e "${RED}❌ 任务不存在或已过期${NC}"
    fi
}

# 取消任务
cancel_task() {
    local task_id="$1"
    
    echo -e "\n${YELLOW}🗑️  取消任务...${NC}"
    
    response=$(curl -s -X DELETE "$API_BASE/validation_tasks/$task_id")
    
    success=$(echo "$response" | python3 -c "import sys, json; print(json.load(sys.stdin)['success'])")
    
    if [ "$success" = "True" ]; then
        echo -e "${GREEN}✅ 任务已取消${NC}"
        return 0
    else
        echo -e "${RED}❌ 取消失败${NC}"
        return 1
    fi
}

# ============================================
# 示例 1: 基础流程
# ============================================
example_basic() {
    echo "============================================================"
    echo "示例 1: 基础预订验证"
    echo "============================================================"
    
    # 1. 创建任务
    create_task "深圳" "武汉" "2025-01-15"
    
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    local task_id="$TASK_ID"
    
    # 2. 等待执行
    echo -e "\n⏸️  等待执行任务..."
    echo "   按 Enter 键继续验证..."
    read
    
    # 3. 验证结果
    verify_task "$task_id"
}

# ============================================
# 示例 2: 批量测试
# ============================================
example_batch() {
    echo ""
    echo "============================================================"
    echo "示例 2: 批量测试"
    echo "============================================================"
    
    # 测试用例列表
    local test_cases=(
        "深圳:武汉:2025-01-15"
        "北京:上海:2025-01-20"
        "广州:深圳:2025-01-25"
    )
    
    local success_count=0
    local total_count=${#test_cases[@]}
    
    for test_case in "${test_cases[@]}"; do
        IFS=':' read -r departure arrival date <<< "$test_case"
        
        echo ""
        echo "------------------------------------------------------------"
        echo "测试: $departure → $arrival ($date)"
        echo "------------------------------------------------------------"
        
        # 创建任务
        create_task "$departure" "$arrival" "$date"
        
        if [ $? -ne 0 ]; then
            continue
        fi
        
        local task_id="$TASK_ID"
        
        # 模拟执行（实际应该调用大模型）
        echo "   执行中..."
        sleep 2
        
        # 验证结果
        verify_task "$task_id"
        
        if [ $? -eq 0 ]; then
            ((success_count++))
        fi
    done
    
    # 输出汇总
    echo ""
    echo "============================================================"
    echo "测试汇总"
    echo "============================================================"
    echo "总计: $total_count 个测试"
    echo "成功: $success_count 个"
    echo "失败: $((total_count - success_count)) 个"
    echo "成功率: $(awk "BEGIN {printf \"%.1f\", $success_count / $total_count * 100}")%"
}

# ============================================
# 示例 3: 完整流程演示
# ============================================
example_full() {
    echo ""
    echo "============================================================"
    echo "示例 3: 完整流程演示"
    echo "============================================================"
    
    # 1. 创建任务
    create_task "杭州" "成都" "2025-01-30"
    
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    local task_id="$TASK_ID"
    
    # 2. 查询状态
    get_task_status "$task_id"
    
    # 3. 模拟执行
    echo -e "\n⏸️  等待 5 秒模拟执行..."
    sleep 5
    
    # 4. 验证结果
    verify_task "$task_id"
    
    # 5. 再次查询状态（任务应该已被删除）
    echo -e "\n验证后查询任务（应该已被删除）:"
    get_task_status "$task_id"
}

# ============================================
# 主程序
# ============================================
main() {
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║          验证任务 API - Bash 示例                          ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    
    if [ $# -gt 0 ]; then
        case "$1" in
            basic)
                example_basic
                ;;
            batch)
                example_batch
                ;;
            full)
                example_full
                ;;
            *)
                echo "未知示例: $1"
                echo "可用示例: basic, batch, full"
                exit 1
                ;;
        esac
    else
        echo ""
        echo "请选择要运行的示例:"
        echo "  1. basic - 基础流程"
        echo "  2. batch - 批量测试"
        echo "  3. full  - 完整流程演示"
        echo ""
        echo "用法: bash bash_example.sh [basic|batch|full]"
        echo ""
        echo "运行默认示例..."
        
        example_basic
    fi
}

# 运行主程序
main "$@"
