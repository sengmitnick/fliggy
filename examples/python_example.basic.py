#!/usr/bin/env python3
"""
Validator 完整的 py 脚本示例

依赖安装：
    pip3 install requests
    
使用方法：
    python3 examples/python_example.basic.py
"""

import requests
import time
import json
import os

# 配置
API_BASE = os.environ.get("TRAVEL_API_BASE", "https://travel01.clackyai.app/api").rstrip("/")


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
        departure_date="2026-01-15"
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
# 主程序
# ============================================
if __name__ == "__main__":
    print("╔════════════════════════════════════════════════════════════╗")
    print("║          验证任务 API - Python 示例                        ║")
    print("╚════════════════════════════════════════════════════════════╝")

    example_basic()
