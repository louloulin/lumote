# 贡献指南

中文版本 | [English](./CONTRIBUTE.md)

欢迎来到 Blinko 项目！我们很高兴您能为这个创新的笔记和知识管理平台做出贡献。本指南将帮助您开始开发并了解我们的贡献工作流程。

## 目录

- [概述](#概述)
- [快速开始](#快速开始)
- [开发环境设置](#开发环境设置)
- [项目结构](#项目结构)
- [开发工作流程](#开发工作流程)
- [编码规范](#编码规范)
- [测试](#测试)
- [插件开发](#插件开发)
- [贡献流程](#贡献流程)
- [发布流程](#发布流程)
- [社区与支持](#社区与支持)

## 概述

Blinko 是一个现代化的自托管笔记和知识管理平台，使用前沿技术构建：

- **前端**: React + Vite + Tauri (Web + 桌面端)
- **后端**: Express + tRPC + Prisma
- **数据库**: PostgreSQL
- **包管理器**: Bun
- **部署**: Docker + Docker Compose

项目采用 monorepo 结构，前端（`app/`）和后端（`server/`）分离。

## 快速开始

### 环境要求

开始之前，请确保安装了以下软件：

- **Bun** >= 1.0.0 ([安装指南](https://bun.sh/docs/installation))
- **Node.js** >= 20.0.0
- **PostgreSQL** >= 14
- **Git**
- **Docker** 和 **Docker Compose** (可选，用于容器化开发)

### 快速设置

1. **克隆仓库**
   ```bash
   git clone https://github.com/blinko-space/blinko.git
   cd blinko
   ```

2. **安装依赖**
   ```bash
   bun install
   ```

3. **设置数据库**
   ```bash
   # 启动 PostgreSQL (如果未运行)
   # 创建数据库
   createdb blinko
   
   # 运行迁移
   cd server
   bun run db:migrate
   ```

4. **配置环境变量**
   ```bash
   # 复制环境变量文件
   cp server/.env.example server/.env
   cp app/.env.example app/.env
   
   # 编辑 .env 文件配置您的设置
   ```

5. **启动开发服务器**
   ```bash
   # 在根目录下
   bun run dev
   ```

这将启动前端（http://localhost:3000）和后端（http://localhost:3001）开发服务器。

## 开发环境设置

### 环境变量

创建以下环境变量文件：

**server/.env**
```env
DATABASE_URL="postgresql://username:password@localhost:5432/blinko"
JWT_SECRET="your-jwt-secret"
PORT=3001
NODE_ENV=development
```

**app/.env**
```env
VITE_SERVER_URL=http://localhost:3001
VITE_APP_NAME=Blinko
```

### 数据库设置

1. **创建 PostgreSQL 数据库**
   ```bash
   createdb blinko
   ```

2. **运行 Prisma 迁移**
   ```bash
   cd server
   bun run db:migrate
   ```

3. **数据库种子数据（可选）**
   ```bash
   bun run db:seed
   ```

### Docker 开发

容器化开发环境：

```bash
# 启动所有服务
docker-compose up -d

# 查看日志
docker-compose logs -f

# 停止服务
docker-compose down
```

## 项目结构

```
blinko/
├── app/                    # 前端应用
│   ├── src/
│   │   ├── components/     # React 组件
│   │   ├── pages/         # 页面组件
│   │   ├── hooks/         # 自定义 React hooks
│   │   ├── utils/         # 工具函数
│   │   ├── stores/        # 状态管理
│   │   └── styles/        # CSS 和样式
│   ├── public/            # 静态资源
│   └── package.json
├── server/                # 后端应用
│   ├── src/
│   │   ├── routes/        # API 路由
│   │   ├── middleware/    # Express 中间件
│   │   ├── services/      # 业务逻辑
│   │   ├── models/        # 数据库模型
│   │   └── utils/         # 服务器工具
│   ├── prisma/           # 数据库架构和迁移
│   └── package.json
├── plugins/              # 插件系统
├── docs/                 # 文档
├── docker-compose.yml    # Docker 配置
└── package.json         # 根 package.json
```

## 开发工作流程

### 分支策略

- `main` - 生产就绪代码
- `develop` - 开发集成分支
- `feature/*` - 功能开发分支
- `bugfix/*` - 错误修复分支
- `hotfix/*` - 生产环境紧急修复

### 开发流程

1. **创建功能分支**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **进行更改**
   - 遵循我们的编码规范
   - 为新功能添加测试
   - 根据需要更新文档

3. **测试您的更改**
   ```bash
   # 运行测试
   bun test
   
   # 运行代码检查
   bun run lint
   
   # 类型检查
   bun run type-check
   ```

4. **提交更改**
   ```bash
   git add .
   git commit -m "feat: 添加新功能描述"
   ```

5. **推送并创建 Pull Request**
   ```bash
   git push origin feature/your-feature-name
   ```

### 常用命令

```bash
# 开发
bun run dev              # 同时启动前端和后端
bun run dev:app          # 仅启动前端
bun run dev:server       # 仅启动后端

# 构建
bun run build            # 构建两个应用
bun run build:app        # 构建前端
bun run build:server     # 构建后端

# 测试
bun test                 # 运行所有测试
bun run test:app         # 运行前端测试
bun run test:server      # 运行后端测试

# 数据库
bun run db:migrate       # 运行数据库迁移
bun run db:reset         # 重置数据库
bun run db:seed          # 种子数据库

# 代码检查和格式化
bun run lint             # 运行 ESLint
bun run lint:fix         # 修复代码检查问题
bun run format           # 使用 Prettier 格式化代码

# 桌面应用 (Tauri)
bun run tauri:dev        # 启动 Tauri 开发
bun run tauri:build      # 构建桌面应用
```

## 编码规范

### TypeScript

- 所有新代码使用 TypeScript
- 定义适当的类型和接口
- 避免使用 `any` 类型；使用适当的类型
- 使用有意义的变量和函数名

```typescript
// 好的
interface User {
  id: string;
  email: string;
  createdAt: Date;
}

const createUser = async (userData: Omit<User, 'id' | 'createdAt'>): Promise<User> => {
  // 实现
};

// 避免
const createUser = (data: any): any => {
  // 实现
};
```

### React 组件

- 使用带 hooks 的函数组件
- 遵循组件命名约定（PascalCase）
- 为 props 使用 TypeScript 接口
- 保持组件小而专注

```tsx
// 好的
interface NoteCardProps {
  note: Note;
  onEdit: (id: string) => void;
  onDelete: (id: string) => void;
}

export const NoteCard: React.FC<NoteCardProps> = ({ note, onEdit, onDelete }) => {
  return (
    <div className="note-card">
      <h3>{note.title}</h3>
      <p>{note.content}</p>
      <div className="note-actions">
        <button onClick={() => onEdit(note.id)}>编辑</button>
        <button onClick={() => onDelete(note.id)}>删除</button>
      </div>
    </div>
  );
};
```

### CSS 和样式

- 使用 Tailwind CSS 进行样式设计
- 对自定义 CSS 遵循 BEM 方法论
- 需要时使用 CSS 模块
- 保持样式模块化和可重用

```css
/* 好的 - BEM 方法论 */
.note-card {
  @apply bg-white rounded-lg shadow-md p-4;
}

.note-card__title {
  @apply text-lg font-semibold mb-2;
}

.note-card__content {
  @apply text-gray-700 mb-4;
}

.note-card__actions {
  @apply flex gap-2;
}
```

### API 开发

- 使用 tRPC 进行类型安全的 API
- 遵循 RESTful 原则
- 实现适当的错误处理
- 添加请求验证

```typescript
// 好的
export const noteRouter = t.router({
  getAll: t.procedure
    .input(z.object({
      page: z.number().min(1).default(1),
      limit: z.number().min(1).max(100).default(10),
    }))
    .query(async ({ input }) => {
      const { page, limit } = input;
      const offset = (page - 1) * limit;
      
      const notes = await prisma.note.findMany({
        skip: offset,
        take: limit,
        orderBy: { createdAt: 'desc' },
      });
      
      return {
        notes,
        pagination: {
          page,
          limit,
          total: await prisma.note.count(),
        },
      };
    }),
});
```

## 测试

### 前端测试

我们使用 Vitest 和 React Testing Library 进行前端测试。

```typescript
// 组件测试示例
import { render, screen, fireEvent } from '@testing-library/react';
import { describe, it, expect, vi } from 'vitest';
import { NoteCard } from './NoteCard';

describe('NoteCard', () => {
  const mockNote = {
    id: '1',
    title: '测试笔记',
    content: '测试内容',
    createdAt: new Date(),
  };

  it('正确渲染笔记信息', () => {
    render(
      <NoteCard 
        note={mockNote} 
        onEdit={vi.fn()} 
        onDelete={vi.fn()} 
      />
    );
    
    expect(screen.getByText('测试笔记')).toBeInTheDocument();
    expect(screen.getByText('测试内容')).toBeInTheDocument();
  });

  it('点击编辑按钮时调用 onEdit', () => {
    const onEdit = vi.fn();
    render(
      <NoteCard 
        note={mockNote} 
        onEdit={onEdit} 
        onDelete={vi.fn()} 
      />
    );
    
    fireEvent.click(screen.getByText('编辑'));
    expect(onEdit).toHaveBeenCalledWith('1');
  });
});
```

### 后端测试

我们使用 Vitest 进行后端测试，集成数据库。

```typescript
// API 测试示例
import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { createTestContext } from '../utils/test-context';
import { noteRouter } from './note.router';

describe('Note Router', () => {
  let ctx: TestContext;

  beforeEach(async () => {
    ctx = await createTestContext();
  });

  afterEach(async () => {
    await ctx.cleanup();
  });

  it('应该创建新笔记', async () => {
    const input = {
      title: '测试笔记',
      content: '测试内容',
    };

    const result = await noteRouter.create({
      input,
      ctx: ctx.context,
    });

    expect(result.title).toBe('测试笔记');
    expect(result.content).toBe('测试内容');
    expect(result.id).toBeDefined();
  });
});
```

### 运行测试

```bash
# 运行所有测试
bun test

# 监视模式运行测试
bun test --watch

# 带覆盖率运行测试
bun test --coverage

# 运行特定测试文件
bun test src/components/NoteCard.test.tsx
```

## 插件开发

Blinko 支持插件系统来扩展功能。插件位于 `plugins/` 目录中。

### 插件结构

```
plugins/
├── example-plugin/
│   ├── src/
│   │   ├── index.ts       # 插件入口
│   │   ├── components/    # React 组件
│   │   └── api/          # API 端点
│   ├── package.json      # 插件元数据
│   └── README.md         # 插件文档
```

### 创建插件

1. **创建插件目录**
   ```bash
   mkdir plugins/my-plugin
   cd plugins/my-plugin
   ```

2. **初始化插件**
   ```bash
   bun init
   ```

3. **定义插件结构**
   ```typescript
   // src/index.ts
   import { Plugin } from '@blinko/plugin-api';

   export default class MyPlugin extends Plugin {
     name = 'my-plugin';
     version = '1.0.0';

     async activate() {
       // 插件激活逻辑
       this.registerComponent('MyComponent', () => import('./components/MyComponent'));
       this.registerRoute('/api/my-plugin', () => import('./api/routes'));
     }

     async deactivate() {
       // 插件清理逻辑
     }
   }
   ```

### 插件 API

```typescript
// 可用的插件 API
interface PluginAPI {
  // 组件注册
  registerComponent(name: string, component: ComponentLoader): void;
  
  // 路由注册
  registerRoute(path: string, handler: RouteHandler): void;
  
  // 事件系统
  on(event: string, handler: EventHandler): void;
  emit(event: string, data: any): void;
  
  // 存储
  getStorage(): PluginStorage;
  
  // 配置
  getConfig(): PluginConfig;
}
```

## 贡献流程

### 贡献前准备

1. 检查现有问题和拉取请求
2. 阅读项目文档
3. 设置开发环境
4. 熟悉我们的编码规范

### 进行贡献

1. **Fork 仓库**
2. **从 `develop` 创建功能分支**
3. **遵循我们的指导原则进行更改**
4. **为您的更改添加/更新测试**
5. **如需要则更新文档**
6. **运行测试套件确保一切正常**
7. **提交包含清晰描述的拉取请求**

### 拉取请求指导原则

- 使用清晰描述性的标题
- 包含详细的更改描述
- 使用 `#issue-number` 引用相关问题
- 确保所有测试通过
- 必要时更新文档
- 遵循提交消息约定

### 提交消息约定

我们遵循 [Conventional Commits](https://www.conventionalcommits.org/) 规范：

```
<type>[可选 scope]: <description>

[可选 body]

[可选 footer(s)]
```

类型：
- `feat`: 新功能
- `fix`: 错误修复
- `docs`: 文档更改
- `style`: 代码样式更改（格式化等）
- `refactor`: 代码重构
- `test`: 添加或更新测试
- `chore`: 维护任务

示例：
```
feat(notes): 添加搜索功能
fix(auth): 解决登录令牌过期问题
docs: 更新 API 文档
test(components): 为 NoteCard 组件添加测试
```

### 代码审查流程

1. 所有提交都需要维护者审查
2. 我们可能要求更改或改进
3. 一旦批准，您的 PR 将被合并
4. 贡献将在发布说明中被致谢

## 发布流程

### 版本控制

我们遵循 [Semantic Versioning](https://semver.org/)：
- `MAJOR.MINOR.PATCH`
- Major: 破坏性更改
- Minor: 新功能（向后兼容）
- Patch: 错误修复（向后兼容）

### 发布工作流程

1. **功能冻结**: 停止添加新功能
2. **测试**: 发布候选版本的全面测试
3. **文档**: 更新变更日志和文档
4. **发布**: 创建发布标签并发布
5. **部署**: 部署到生产环境

### 部署

#### Docker 部署

```bash
# 使用 Docker Compose 构建和部署
docker-compose -f docker-compose.prod.yml up -d
```

#### 手动部署

```bash
# 构建应用
bun run build

# 启动生产服务器
bun run start:prod
```

## 社区与支持

### 获取帮助

- **文档**: 查看 `docs/` 目录
- **问题**: 搜索现有的 GitHub 问题
- **讨论**: 使用 GitHub Discussions 提问
- **Discord**: 加入我们的 Discord 社区（如果可用）

### 报告问题

报告错误时，请包括：
- 重现问题的步骤
- 预期与实际行为
- 环境信息（操作系统、浏览器、版本）
- 错误消息和日志
- 截图（如适用）

### 功能请求

- 检查功能是否已存在或已计划
- 清楚描述用例和好处
- 如可能提供示例或模型
- 对讨论和反馈保持开放

### 行为准则

我们致力于提供欢迎和包容的环境。请：
- 保持尊重和体贴
- 使用包容性语言
- 优雅地接受建设性批评
- 专注于对社区最好的结果
- 对其他社区成员表现出同理心

---

感谢您为 Blinko 做出贡献！您的努力让这个项目对每个人都变得更好。如果您有任何问题，请随时联系维护者或社区。
