-- 生产环境数据库角色初始化脚本
-- 用于创建非超级用户角色以支持 RLS 策略

-- 检查 app_user 角色是否存在，不存在则创建
DO
$$
BEGIN
   IF NOT EXISTS (
      SELECT FROM pg_catalog.pg_roles
      WHERE rolname = 'app_user'
   ) THEN
      -- 创建非超级用户角色
      CREATE ROLE app_user WITH LOGIN NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION;
      RAISE NOTICE 'Created role: app_user';
   ELSE
      RAISE NOTICE 'Role app_user already exists';
   END IF;
END
$$;

-- 授予数据库连接权限
GRANT CONNECT ON DATABASE <%= ENV['DB_NAME'] || 'travel01_production' %> TO app_user;

-- 授予 public schema 使用权限
GRANT USAGE ON SCHEMA public TO app_user;

-- 授予所有现有表的权限
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_user;

-- 授予所有现有序列的权限
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO app_user;

-- 授予未来创建的表和序列权限（自动授权）
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO app_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE, SELECT ON SEQUENCES TO app_user;

-- 设置默认搜索路径
ALTER ROLE app_user SET search_path TO public;
