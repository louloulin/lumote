# Blinko 本地开发指南

本指南涵盖了在本地设置、开发和贡献 Blinko 所需了解的一切内容，包括全面的插件开发文档。

## 目录

1. [先决条件](#先决条件)
2. [快速开始](#快速开始)
3. [项目架构](#项目架构)
4. [环境配置](#环境配置)
5. [插件开发](#插件开发)
6. [开发工作流程](#开发工作流程)
7. [调试](#调试)
8. [Docker 开发](#docker-开发)
9. [桌面和移动端开发](#桌面和移动端开发)
10. [常见问题](#常见问题)

## 先决条件

### 必需软件
- **Bun**: `>= 1.0.0` (主要运行时)
- **Node.js**: `>= 18.0.0` (兼容性需要)
- **PostgreSQL**: `>= 13.0` (数据库)
- **Docker**: `>= 20.0` (可选，用于容器化开发)
- **Git**: 最新版本

### 安装命令
```bash
# 安装 Bun
curl -fsSL https://bun.sh/install | bash

# 安装 Node.js (如果需要)
# 使用 nvm、fnm 或从 nodejs.org 下载

# 安装 PostgreSQL
# macOS: brew install postgresql
# Ubuntu: sudo apt install postgresql postgresql-contrib
# Windows: 从 postgresql.org 下载
```

## 快速开始

### 1. 克隆和设置
```bash
git clone https://github.com/blinko-space/blinko.git
cd blinko

# 为所有包安装依赖项
bun install
```

### 2. 数据库设置
```bash
# 启动 PostgreSQL 服务
# macOS: brew services start postgresql
# Ubuntu: sudo systemctl start postgresql
# Windows: 通过服务启动

# 创建数据库
createdb blinko_dev

# 或使用 Docker for PostgreSQL
docker run --name blinko-postgres -e POSTGRES_PASSWORD=password -e POSTGRES_DB=blinko_dev -p 5432:5432 -d postgres:13
```

### 3. 环境配置
在 `app/` 和 `server/` 目录中创建 `.env` 文件：

**app/.env.local:**
```env
NEXT_PUBLIC_API_URL=http://localhost:1111
NEXTAUTH_URL=http://localhost:3000
NEXTAUTH_SECRET=your-secret-key-here
```

**server/.env:**
```env
DATABASE_URL=postgresql://postgres:password@localhost:5432/blinko_dev
JWT_SECRET=your-jwt-secret
NODE_ENV=development
PORT=1111
```

### 4. 启动开发
```bash
# 启动后端服务器
cd server
bun run dev

# 在另一个终端中，启动前端
cd app
bun run dev
```

在 `http://localhost:3000` 访问应用程序

## 项目架构

Blinko 是一个 **monorepo** 项目，具有以下结构：

```
blinko/
├── app/                 # Next.js 前端应用程序
│   ├── src/
│   │   ├── components/  # React 组件
│   │   ├── pages/       # Next.js 页面
│   │   ├── store/       # Zustand 状态管理
│   │   │   └── plugin/  # 插件系统实现
│   │   └── lib/         # 工具和助手
│   └── package.json
├── server/              # Bun/Express 后端
│   ├── routerTrpc/      # tRPC API 路由
│   ├── plugins/         # 服务端插件系统
│   ├── database/        # 数据库模型和迁移
│   └── package.json
├── desktop/             # Tauri 桌面应用程序
├── docs/                # 文档
└── package.json         # 根工作区配置
```

### 技术栈
- **前端**: Next.js 14, React 18, TypeScript, TailwindCSS
- **后端**: Bun, Express, tRPC, Prisma ORM
- **数据库**: PostgreSQL with Prisma
- **状态管理**: Zustand
- **桌面端**: Tauri (Rust + WebView)
- **移动端**: React Native (计划中)

## 环境配置

### 开发环境变量

**前端 (.env.local):**
```env
# API 配置
NEXT_PUBLIC_API_URL=http://localhost:1111
NEXT_PUBLIC_WS_URL=ws://localhost:1111

# 身份验证
NEXTAUTH_URL=http://localhost:3000
NEXTAUTH_SECRET=your-nextauth-secret

# 插件开发
NEXT_PUBLIC_PLUGIN_DEV_MODE=true
NEXT_PUBLIC_PLUGIN_HMR=true
```

**后端 (.env):**
```env
# 数据库
DATABASE_URL=postgresql://username:password@localhost:5432/blinko_dev

# 服务器
NODE_ENV=development
PORT=1111
HOST=localhost

# 安全
JWT_SECRET=your-jwt-secret
ENCRYPTION_KEY=your-32-char-encryption-key

# 插件系统
PLUGIN_DEV_MODE=true
PLUGIN_STORE_URL=https://plugins.blinko.space

# 外部服务 (可选)
OPENAI_API_KEY=your-openai-key
GITHUB_TOKEN=your-github-token
```

## 插件开发

Blinko 具有强大的插件系统，允许通过自定义组件、API 路由和集成来扩展功能。

### 插件架构

插件系统包括：
- **BasePlugin**: 带有生命周期方法的核心插件类
- **Plugin API**: 用于 UI 扩展和数据访问的综合 API
- **热重载**: 通过 WebSocket 进行开发时实时重载
- **安全性**: 沙盒执行和权限系统
- **市场**: 插件分发和版本管理

### 创建新插件

#### 1. 基本插件结构
```typescript
// plugins/my-plugin/index.ts
import { BasePlugin, PluginAPI } from '@blinko/plugin-sdk';

export default class MyPlugin extends BasePlugin {
  name = 'my-plugin';
  version = '1.0.0';
  description = 'My awesome plugin';
  
  async onLoad(api: PluginAPI) {
    console.log('插件已加载!');
    
    // 注册 UI 组件
    api.ui.registerComponent('my-widget', MyWidget);
    
    // 添加菜单项
    api.ui.addMenuItem({
      label: '我的插件',
      icon: 'puzzle',
      onClick: () => api.ui.showModal('my-plugin-modal')
    });
    
    // 监听事件
    api.events.on('note:created', this.handleNoteCreated);
  }
  
  async onUnload() {
    console.log('插件已卸载!');
  }
  
  private handleNoteCreated = (note: any) => {
    console.log('创建了新笔记:', note);
  };
}
```

#### 2. 插件组件示例
```typescript
// plugins/my-plugin/components/MyWidget.tsx
import React from 'react';
import { usePluginAPI } from '@blinko/plugin-sdk';

export const MyWidget: React.FC = () => {
  const api = usePluginAPI();
  
  const handleClick = async () => {
    const notes = await api.data.getNotes({ limit: 10 });
    console.log('最近的笔记:', notes);
  };
  
  return (
    <div className="p-4 border rounded">
      <h3>我的插件小组件</h3>
      <button onClick={handleClick} className="btn btn-primary">
        加载笔记
      </button>
    </div>
  );
};
```

#### 3. 插件配置
```json
// plugins/my-plugin/plugin.json
{
  "name": "my-plugin",
  "version": "1.0.0",
  "description": "我为 Blinko 开发的超棒插件",
  "author": "Your Name",
  "homepage": "https://github.com/yourname/my-plugin",
  "main": "index.ts",
  "permissions": [
    "notes:read",
    "notes:write",
    "ui:register"
  ],
  "engines": {
    "blinko": ">=1.0.0"
  },
  "dependencies": {
    "@blinko/plugin-sdk": "^1.0.0"
  }
}
```

### 插件 API 参考

#### 数据 API
```typescript
// 访问笔记
const notes = await api.data.getNotes({ 
  limit: 10, 
  tags: ['重要'] 
});

// 创建新笔记
const note = await api.data.createNote({
  content: '来自插件的问候!',
  tags: ['插件创建']
});

// 搜索功能
const results = await api.data.search('查询字符串');
```

#### UI API
```typescript
// 注册组件
api.ui.registerComponent('widget-name', WidgetComponent);

// 添加菜单项
api.ui.addMenuItem({
  label: '插件操作',
  icon: 'star',
  position: 'tools',
  onClick: () => console.log('点击了!')
});

// 显示通知
api.ui.showNotification({
  type: 'success',
  message: '插件操作完成!'
});

// 打开模态框
api.ui.showModal('my-modal', { data: 'example' });
```

#### 事件 API
```typescript
// 监听系统事件
api.events.on('note:created', (note) => {
  console.log('新笔记:', note);
});

api.events.on('note:updated', (note) => {
  console.log('更新的笔记:', note);
});

api.events.on('user:login', (user) => {
  console.log('用户登录:', user);
});

// 发出自定义事件
api.events.emit('my-plugin:action', { data: 'value' });
```

### 插件开发工作流程

#### 1. 设置插件开发环境
```bash
# 启用插件开发模式
cd app
echo "NEXT_PUBLIC_PLUGIN_DEV_MODE=true" >> .env.local

# 启动开发并支持热重载
bun run dev:plugins
```

#### 2. 创建插件目录
```bash
mkdir -p app/src/plugins/my-plugin
cd app/src/plugins/my-plugin

# 创建基本文件
touch index.ts plugin.json
mkdir components
```

#### 3. 开发命令
```bash
# 监视插件更改
bun run plugin:watch my-plugin

# 构建插件用于生产
bun run plugin:build my-plugin

# 测试插件
bun run plugin:test my-plugin

# 打包插件用于分发
bun run plugin:package my-plugin
```

#### 4. 热重载开发
插件系统支持开发期间的热重载：

1. 对插件文件进行更改
2. WebSocket 连接自动检测更改
3. 插件在不刷新页面的情况下重新加载
4. 尽可能保留状态

### 插件测试

#### 单元测试
```typescript
// plugins/my-plugin/tests/index.test.ts
import { describe, it, expect } from 'bun:test';
import MyPlugin from '../index';
import { createMockAPI } from '@blinko/plugin-sdk/testing';

describe('MyPlugin', () => {
  it('应该正确加载', async () => {
    const plugin = new MyPlugin();
    const mockAPI = createMockAPI();
    
    await plugin.onLoad(mockAPI);
    
    expect(mockAPI.ui.registerComponent).toHaveBeenCalled();
  });
});
```

#### 集成测试
```bash
# 运行插件测试
bun test plugins/my-plugin

# 运行所有插件测试
bun test:plugins
```

## 开发工作流程

### 可用脚本

**根级别:**
```bash
bun install          # 安装所有依赖项
bun run dev          # 启动所有开发服务器
bun run build        # 构建所有包
bun run test         # 运行所有测试
bun run lint         # 检查所有包
bun run clean        # 清理构建工件
```

**前端 (app/):**
```bash
bun run dev          # 启动 Next.js 开发服务器
bun run build        # 构建生产版本
bun run start        # 启动生产服务器
bun run test         # 运行测试
bun run lint         # 检查代码
bun run type-check   # TypeScript 类型检查
```

**后端 (server/):**
```bash
bun run dev          # 启动开发服务器并支持热重载
bun run build        # 构建 TypeScript
bun run start        # 启动生产服务器
bun run test         # 运行测试
bun run db:migrate   # 运行数据库迁移
bun run db:studio    # 打开 Prisma Studio
```

### 代码风格和标准

项目使用：
- **ESLint**: 代码检查
- **Prettier**: 代码格式化
- **TypeScript**: 类型检查
- **Husky**: Git 钩子
- **lint-staged**: 预提交检查

```bash
# 格式化代码
bun run format

# 检查类型
bun run type-check

# 修复检查问题
bun run lint:fix
```

### Git 工作流程

1. 创建功能分支: `git checkout -b feature/my-feature`
2. 进行更改并提交: `git commit -m "feat: add new feature"`
3. 推送分支: `git push origin feature/my-feature`
4. 创建拉取请求

提交消息格式遵循 [Conventional Commits](https://www.conventionalcommits.org/)。

## 调试

### 前端调试
```bash
# 启用调试模式
NEXT_PUBLIC_DEBUG=true bun run dev

# 检查浏览器控制台日志
# 使用 React DevTools 进行组件调试
# 使用 Redux DevTools 进行状态管理
```

### 后端调试
```bash
# 启用调试日志
DEBUG=blinko:* bun run dev

# 使用调试器
bun run dev:debug

# 数据库调试
DATABASE_LOGGING=true bun run dev
```

### 插件调试
```bash
# 启用插件调试模式
NEXT_PUBLIC_PLUGIN_DEBUG=true bun run dev

# 在浏览器 DevTools 中检查插件控制台
# 插件错误会出现在主控制台中
# 使用 WebSocket 标签监控插件通信
```

### 常用调试工具
- **浏览器 DevTools**: 用于前端调试
- **Bun debugger**: 用于后端调试
- **Prisma Studio**: 用于数据库检查
- **Network 标签**: 用于 API 请求调试
- **WebSocket inspector**: 用于实时通信

## Docker 开发

### 快速 Docker 设置
```bash
# 使用 Docker Compose 启动
docker-compose up -d

# 本地构建和运行
docker build -t blinko .
docker run -p 3000:3000 -p 1111:1111 blinko
```

### Docker 开发环境
```bash
# 支持热重载的开发
docker-compose -f docker-compose.dev.yml up

# 生产构建
docker-compose -f docker-compose.prod.yml up -d
```

### Docker 命令参考

```bash
# 本地构建 Docker 镜像
docker build --build-arg USE_MIRROR=true -t blinko .

# 使用环境变量运行
docker run --name blinko-website -d -p 1111:1111 \
  -e "DATABASE_URL=postgresql://postgres:password@localhost:5432/blinko" \
  -v "$(pwd)/data:/app/.blinko" \
  blinko

# 为 ARM64 构建
docker buildx build --platform linux/arm64 -t blinko-arm .

# 使用 docker-compose 构建和运行
docker-compose -f docker-compose.yml up -d --build

# 查看日志
docker-compose logs -f

# 停止服务
docker-compose down
```

### 生产 Docker 设置
```bash
docker run -d \
  --name blinko-website \
  --network blinko-network \
  -p 1111:1111 \
  -e NODE_ENV=production \
  -v /path/to/data:/app/.blinko \
  -e NEXTAUTH_SECRET=your_secure_secret \
  -e DATABASE_URL=postgresql://user:pass@db:5432/blinko \
  --restart always \
  blinko:latest
```

## 桌面和移动端开发

### 桌面端 (Tauri)
```bash
cd desktop

# 安装 Rust 依赖项
cargo install tauri-cli

# 启动桌面开发
bun run tauri dev

# 构建桌面应用
bun run tauri build
```

### 移动端开发
```bash
# iOS 开发 (仅限 macOS)
bun run ios

# Android 开发
bun run android

# 构建生产版本
bun run build:mobile
```

## 常见问题

### 安装问题

**Bun 安装失败:**
```bash
# 尝试替代安装方式
npm install -g bun
# 或使用特定版本
curl -fsSL https://bun.sh/install | bash -s "bun-v1.0.0"
```

**PostgreSQL 连接错误:**
```bash
# 检查 PostgreSQL 状态
brew services list | grep postgresql
# 或
sudo systemctl status postgresql

# 重置 PostgreSQL
brew services restart postgresql
```

**端口冲突:**
```bash
# 检查正在使用端口的进程
lsof -i :3000
lsof -i :1111

# 如需要，终止进程
kill -9 <PID>
```

### 开发问题

**热重载不工作:**
1. 检查文件监视器: `echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf`
2. 重启开发服务器
3. 清除浏览器缓存

**数据库架构不同步:**
```bash
cd server
bun run db:reset
bun run db:migrate
bun run db:seed
```

**插件未加载:**
1. 检查 plugin.json 语法
2. 验证插件配置中的权限
3. 检查浏览器控制台错误
4. 确保启用了插件开发模式

**构建失败:**
```bash
# 清除所有缓存
bun run clean
rm -rf node_modules */node_modules
bun install

# 从头重新构建
bun run build:clean
```

### 插件开发问题

**插件 API 不可用:**
- 确保启用了插件开发模式
- 检查插件 SDK 是否正确导入
- 验证插件是否正确注册

**插件热重载不工作:**
- 检查浏览器 DevTools 中的 WebSocket 连接
- 确保插件观察器正在运行
- 验证插件文件结构

**权限错误:**
- 检查 plugin.json 权限数组
- 确保请求的权限可用
- 验证插件签名 (在生产中)

### 性能问题

**开发服务器缓慢:**
- 增加 Node.js 内存: `NODE_OPTIONS="--max-old-space-size=4096"`
- 使用 SSD 进行开发
- 关闭不必要的应用程序

**数据库性能:**
- 检查数据库索引
- 对慢查询使用 `EXPLAIN ANALYZE`
- 考虑连接池

### 获取帮助

1. **文档**: 检查 `/docs` 目录
2. **问题**: 创建 GitHub issue 并提供重现步骤
3. **讨论**: 使用 GitHub Discussions 提问
4. **贡献**: 参见 `CONTRIBUTE.md`

---

## 附加资源

- [架构文档](./arc.md)
- [贡献指南](./CONTRIBUTE.md)
- [API 文档](./docs/api.md)
- [插件 SDK 参考](./docs/plugin-sdk.md)
- [部署指南](./docs/deployment.md)

愉快编码! 🚀
