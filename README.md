# 旅游环境01 - 部署指南

## 🚀 快速部署

### 甲方生产环境

```bash
bash deploy.sh
```

**仅此一步！** 脚本会自动完成所有配置。

部署完成后访问：
- 用户端: http://localhost:5010
- 管理后台: http://localhost:5010/admin  
- 默认账号: `admin` / `admin`

---

### 本地测试环境

```bash
bash local-deploy.sh
```

本地测试使用独立端口（5011），不影响生产环境。

---

## ✅ 功能验证

### 测试多会话隔离

```bash
docker-compose -f docker-compose.production.2core.yml exec web bundle exec rake rls:test_isolation
```

预期输出：
```
✅ 多会话隔离测试通过！
```

---

## 📚 详细文档

- `FINAL_FIX_SUMMARY.md` - **完整修复说明**（必读）
- `SIMPLE_DEPLOYMENT_GUIDE.md` - 简化部署指南
- `README-LOCAL-TEST.md` - 本地测试指南

---

**开发团队**: Clacky AI  
**更新日期**: 2026-01-27
