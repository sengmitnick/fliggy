# 🚀 部署指南（简化版）

## 甲方生产环境部署

### 一键部署

```bash
bash deploy.sh
```

就这么简单！脚本会自动完成：
- ✅ 拉取云端镜像
- ✅ 创建 `app_user` 数据库角色
- ✅ 启动所有服务
- ✅ 运行数据库迁移（包括 RLS 修复）
- ✅ 加载测试数据
- ✅ 创建管理员账号
- ✅ 验证多会话隔离功能

### 访问应用

```
用户端: http://localhost:5010
管理后台: http://localhost:5010/admin
默认账号: admin / admin
```

---

## 本地测试环境部署

### 一键部署

```bash
bash local-deploy.sh
```

本地测试会使用本地构建的镜像（不依赖云端）。

### 访问应用

```
用户端: http://localhost:5011
管理后台: http://localhost:5011/admin
默认账号: admin / admin
```

---

## 常用命令

### 查看日志

```bash
# 生产环境
docker-compose -f docker-compose.production.2core.yml logs -f web

# 本地测试
docker-compose -f docker-compose.local.yml logs -f web
```

### 停止服务

```bash
# 生产环境
docker-compose -f docker-compose.production.2core.yml down

# 本地测试
docker-compose -f docker-compose.local.yml down
```

### 重启服务

```bash
# 生产环境
docker-compose -f docker-compose.production.2core.yml restart web worker

# 本地测试
docker-compose -f docker-compose.local.yml restart web worker
```

---

## 多会话隔离测试

### 自动测试

```bash
# 生产环境
docker-compose -f docker-compose.production.2core.yml exec web bundle exec rake rls:test_isolation

# 本地测试
docker-compose -f docker-compose.local.yml exec web bundle exec rake rls:test_isolation
```

### 浏览器测试

1. **标签页 1** - Chrome 正常模式:
   ```
   http://localhost:5010/?session_id=test-session-1
   ```

2. **标签页 2** - Chrome 无痕模式或 Firefox:
   ```
   http://localhost:5010/?session_id=test-session-2
   ```

3. 验证：两个标签页的数据应该完全隔离

---

## 故障排查

### 容器启动失败

```bash
# 查看日志
docker logs travel01_web --tail 100

# 常见问题：app_user 未创建
# 解决：重新运行 deploy.sh
```

### 多会话隔离不工作

```bash
# 运行修复
docker-compose -f docker-compose.production.2core.yml exec web bundle exec rake rls:force_enable

# 验证
docker-compose -f docker-compose.production.2core.yml exec web bundle exec rake rls:test_isolation
```

---

## 详细文档（可选）

如需深入了解技术细节，请查看：
- `RLS_FIX_DEPLOYMENT_GUIDE.md` - RLS 修复详细说明
- `README-LOCAL-TEST.md` - 本地测试详细指南
- `DEPLOYMENT-FIX-SUMMARY.md` - Docker 部署问题修复

---

**就这么简单！** 🎉
