#!/usr/bin/env python3
"""
验证任务 API - Python 示例

演示如何使用 Python 调用验证任务 API

依赖安装：
    pip3 install requests
    
    或者使用系统包管理器（Ubuntu/Debian）：
    sudo apt-get install python3-requests
    
使用方法：
    python3 examples/python_example.py basic
    python3 examples/python_example.py params
    python3 examples/python_example.py batch
    python3 examples/python_example.py cancel
    
注意：此示例需要 Rails 应用正在运行（bin/dev）
"""

import requests
import time
import json
import os

# 配置
API_BASE = os.environ.get("FLIGGY_API_BASE", "https://3000-ec82d74f5a03-web.clackypaas.com/api").rstrip("/")


def _safe_json(response):
    """尽量解析 JSON；如果不是 JSON，返回 None。"""
    try:
        return response.json()
    except Exception:
        return None


def _print_http_error(prefix, response):
    data = _safe_json(response)
    print(f"❌ {prefix}")
    print(f"   HTTP {response.status_code}")
    if data is not None:
        print(f"   响应: {json.dumps(data, ensure_ascii=False, indent=2)}")
    else:
        text = (response.text or "").strip()
        print(f"   响应(非JSON): {text[:1000]}")


def create_validation_task(departure_city, arrival_city, departure_date, **kwargs):
    """
    创建验证任务
    
    Args:
        departure_city: 出发城市
        arrival_city: 到达城市
        departure_date: 出发日期 (YYYY-MM-DD)
        **kwargs: 其他可选参数
    
    Returns:
        dict: 任务信息
    """
    url = f"{API_BASE}/validation_tasks"
    
    payload = {
        "departure_city": departure_city,
        "arrival_city": arrival_city,
        "departure_date": departure_date,
        **kwargs
    }
    
    print(f"📋 创建验证任务...")
    print(f"   出发城市: {departure_city}")
    print(f"   到达城市: {arrival_city}")
    print(f"   出发日期: {departure_date}")
    
    response = requests.post(url, json=payload, timeout=15)
    data = _safe_json(response)
    
    if response.status_code == 201 and data and data.get("success"):
        print(f"✅ 任务创建成功！")
        print(f"   任务ID: {data['task_id']}")
        print(f"   用户指令: {data['task_info']['user_instruction']}")
        print(f"   初始预订数: {data['task_info']['initial_booking_count']}")
        return data
    else:
        _print_http_error("创建失败", response)
        return None


def verify_task(task_id):
    """
    验证任务结果
    
    Args:
        task_id: 任务ID
    
    Returns:
        dict: 验证结果
    """
    url = f"{API_BASE}/validation_tasks/{task_id}/verify"
    
    print(f"\n🔍 验证任务结果...")
    print(f"   任务ID: {task_id}")
    
    response = requests.post(url, timeout=30)
    data = _safe_json(response)

    if data is None:
        _print_http_error("验证失败（返回非JSON）", response)
        return None
    
    if data.get('success'):
        print(f"✅ 验证通过！任务成功完成")
        
        booking = (data.get('validation_result') or {}).get('booking_details')
        if booking:
            print(f"\n📦 预订详情:")
            print(f"   预订ID: {booking['booking_id']}")
            print(f"   航班号: {booking['flight']['flight_number']}")
            print(f"   路线: {booking['flight']['departure_city']} → {booking['flight']['destination_city']}")
            print(f"   日期: {booking['flight']['departure_date']}")
            print(f"   乘客: {booking['passenger']['name']}")
            print(f"   保险: {booking['insurance']['type']} ¥{booking['insurance']['price']}")
            print(f"   状态: {booking['status']}")
    else:
        print(f"❌ 验证失败！")

        # 兼容：404/400 等错误时可能只有 error 字段，没有 validation_result
        if data.get("error"):
            print(f"\n🔍 错误详情:")
            print(f"   - {data.get('error')}")
            if response.status_code == 404:
                print("   提示: 任务可能已过期/不存在；如果你刚创建就 404，检查服务是否重启或后端缓存未启用。")
        else:
            errors = (data.get('validation_result') or {}).get('errors') or []
            if errors:
                print(f"\n🔍 错误详情:")
                for i, error in enumerate(errors, 1):
                    print(f"   {i}. {error}")
            else:
                # 兜底：打印原始响应，方便排查
                _print_http_error("验证失败（缺少 errors/validation_result）", response)
    
    return data


def get_task_status(task_id):
    """
    查询任务状态
    
    Args:
        task_id: 任务ID
    
    Returns:
        dict: 任务状态
    """
    url = f"{API_BASE}/validation_tasks/{task_id}"
    
    response = requests.get(url, timeout=15)
    
    if response.status_code == 200:
        data = _safe_json(response) or {}
        print(f"📊 任务状态:")
        print(f"   状态: {data['status']}")
        print(f"   用户指令: {data['task_info']['user_instruction']}")
        return data
    else:
        _print_http_error("任务不存在", response)
        return None


def cancel_task(task_id):
    """
    取消任务
    
    Args:
        task_id: 任务ID
    
    Returns:
        bool: 是否成功
    """
    url = f"{API_BASE}/validation_tasks/{task_id}"
    
    response = requests.delete(url, timeout=15)
    
    if response.status_code == 200:
        print(f"✅ 任务已取消: {task_id}")
        return True
    else:
        _print_http_error("取消失败", response)
        return False


# ============================================
# 示例 1: 基础流程
# ============================================
def example_basic():
    """基础预订验证流程"""
    print("=" * 60)
    print("示例 1: 基础预订验证")
    print("=" * 60)
    
    # 1. 创建任务
    task = create_validation_task(
        departure_city="深圳",
        arrival_city="武汉",
        departure_date="2025-01-15"
    )
    
    if not task:
        return
    
    task_id = task['task_id']
    
    # 2. 模拟执行任务（这里应该调用大模型或手动操作）
    print(f"\n⏸️  等待执行任务...")
    print(f"   提示: 现在应该执行预订流程")
    print(f"   按 Enter 键继续验证...")
    input()
    
    # 3. 验证结果
    verify_task(task_id)


# ============================================
# 示例 2: 带参数的预订
# ============================================
def example_with_params():
    """带乘客信息和保险的预订"""
    print("\n" + "=" * 60)
    print("示例 2: 带参数的预订验证")
    print("=" * 60)
    
    # 1. 创建任务
    task = create_validation_task(
        departure_city="北京",
        arrival_city="上海",
        departure_date="2025-01-20",
        passenger_name="张三",
        contact_phone="13800138000",
        insurance_required=True
    )
    
    if not task:
        return
    
    task_id = task['task_id']
    
    # 2. 查询任务状态
    print(f"\n")
    get_task_status(task_id)
    
    # 3. 模拟执行
    print(f"\n⏸️  等待执行任务...")
    time.sleep(2)  # 实际场景中应该调用大模型
    
    # 4. 验证结果
    verify_task(task_id)


# ============================================
# 示例 3: 批量测试
# ============================================
def example_batch():
    """批量测试多个路线"""
    print("\n" + "=" * 60)
    print("示例 3: 批量测试")
    print("=" * 60)
    
    test_cases = [
        {"departure_city": "深圳", "arrival_city": "武汉", "departure_date": "2025-01-15"},
        {"departure_city": "北京", "arrival_city": "上海", "departure_date": "2025-01-20"},
        {"departure_city": "广州", "arrival_city": "深圳", "departure_date": "2025-01-25"},
    ]
    
    results = []
    
    for i, test_case in enumerate(test_cases, 1):
        print(f"\n测试用例 {i}/{len(test_cases)}")
        print("-" * 60)
        
        # 创建任务
        task = create_validation_task(**test_case)
        if not task:
            results.append({"case": test_case, "success": False})
            continue
        
        # 模拟执行（实际应该调用大模型）
        print(f"   执行中...")
        time.sleep(1)
        
        # 验证结果
        result = verify_task(task['task_id'])
        results.append({
            "case": test_case,
            "success": result['success']
        })
    
    # 输出汇总
    print("\n" + "=" * 60)
    print("测试汇总")
    print("=" * 60)
    
    success_count = sum(1 for r in results if r['success'])
    total_count = len(results)
    
    print(f"总计: {total_count} 个测试")
    print(f"成功: {success_count} 个")
    print(f"失败: {total_count - success_count} 个")
    print(f"成功率: {success_count / total_count * 100:.1f}%")


# ============================================
# 示例 4: 取消任务
# ============================================
def example_cancel():
    """创建并取消任务"""
    print("\n" + "=" * 60)
    print("示例 4: 取消任务")
    print("=" * 60)
    
    # 1. 创建任务
    task = create_validation_task(
        departure_city="杭州",
        arrival_city="成都",
        departure_date="2025-01-30"
    )
    
    if not task:
        return
    
    task_id = task['task_id']
    
    # 2. 查询状态
    print(f"\n")
    get_task_status(task_id)
    
    # 3. 取消任务
    print(f"\n")
    cancel_task(task_id)
    
    # 4. 再次查询（应该失败）
    print(f"\n")
    get_task_status(task_id)


# ============================================
# 主程序
# ============================================
if __name__ == "__main__":
    import sys
    
    print("╔════════════════════════════════════════════════════════════╗")
    print("║          验证任务 API - Python 示例                        ║")
    print("╚════════════════════════════════════════════════════════════╝")
    
    if len(sys.argv) > 1:
        example_name = sys.argv[1]
        
        if example_name == "basic":
            example_basic()
        elif example_name == "params":
            example_with_params()
        elif example_name == "batch":
            example_batch()
        elif example_name == "cancel":
            example_cancel()
        else:
            print(f"未知示例: {example_name}")
            print("可用示例: basic, params, batch, cancel")
    else:
        print("\n请选择要运行的示例:")
        print("  1. basic  - 基础流程")
        print("  2. params - 带参数的预订")
        print("  3. batch  - 批量测试")
        print("  4. cancel - 取消任务")
        print("\n用法: python3 python_example.py [basic|params|batch|cancel]")
        print("\n运行所有示例...")
        
        example_basic()
        # example_with_params()
        # example_batch()
        # example_cancel()
