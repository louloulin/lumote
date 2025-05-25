# API参考文档

## 概述

Blinko 提供完整的 RESTful API 和 tRPC API，支持所有核心功能的程序化访问。本文档包含详细的 API 使用示例、参数说明和最佳实践指南。

### API 架构总览

```typescript
interface APIArchitecture {
  tRPC: {
    endpoint: "/api/trpc",
    features: ["类型安全", "实时订阅", "自动代码生成"],
    authentication: "JWT Bearer Token"
  };
  REST: {
    endpoint: "/api",
    features: ["文件上传", "OAuth认证", "Webhook"],
    documentation: "/api-doc"
  };
  OpenAPI: {
    spec: "/api/openapi.json",
    ui: "/api-doc",
    version: "3.0.0"
  };
}
```

## 认证方式

### JWT Token 认证

```bash
# 获取 Token
curl -X POST https://your-domain.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "your-password"
  }'

# 使用 Token
curl -X GET https://your-domain.com/api/trpc/note.list \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### API Key 认证

```bash
# 使用 API Key (在用户设置中生成)
curl -X GET https://your-domain.com/api/trpc/note.list \
  -H "Authorization: Bearer YOUR_API_KEY"
```

## tRPC API 参考

### 1. 笔记管理 API

#### 获取笔记列表
```typescript
// TypeScript 客户端调用
const notes = await trpc.note.list.query({
  page: 1,
  size: 20,
  orderBy: 'desc',
  tagId: null,
  type: -1,
  searchText: 'TypeScript'
});

// HTTP 调用
POST /api/trpc/note.list
Content-Type: application/json
Authorization: Bearer YOUR_TOKEN

{
  "page": 1,
  "size": 20,
  "orderBy": "desc",
  "searchText": "TypeScript"
}
```

**响应示例：**
```json
{
  "notes": [
    {
      "id": 123,
      "content": "TypeScript 学习笔记",
      "type": 0,
      "isArchived": false,
      "isShare": false,
      "createdAt": "2024-01-01T00:00:00.000Z",
      "updatedAt": "2024-01-01T00:00:00.000Z",
      "attachments": [],
      "tags": [
        {
          "id": 1,
          "name": "TypeScript",
          "icon": "🔥"
        }
      ]
    }
  ],
  "total": 100,
  "hasMore": true
}
```

#### 创建笔记
```typescript
// TypeScript 客户端
const newNote = await trpc.note.upsert.mutate({
  content: "# 新笔记\n\n这是笔记内容",
  type: 0,
  isShare: false,
  attachments: []
});

// HTTP 调用
POST /api/trpc/note.upsert
Content-Type: application/json
Authorization: Bearer YOUR_TOKEN

{
  "content": "# 新笔记\n\n这是笔记内容",
  "type": 0,
  "isShare": false
}
```

#### 更新笔记
```typescript
// 更新现有笔记
const updatedNote = await trpc.note.upsert.mutate({
  id: 123,
  content: "# 更新的笔记内容",
  type: 0
});
```

#### 删除笔记
```typescript
// 删除笔记
await trpc.note.delete.mutate({
  id: 123
});

// 批量删除
await trpc.note.batchDelete.mutate({
  ids: [123, 124, 125]
});
```

### 2. AI 功能 API

#### AI 对话补全
```typescript
// 基本对话
const response = await trpc.ai.completions.mutate({
  question: "请帮我总结这篇文章的要点",
  conversations: [
    {
      role: "user",
      content: "请帮我总结这篇文章的要点"
    }
  ],
  withSearch: true,
  model: "gpt-4"
});

// HTTP 调用
POST /api/trpc/ai.completions
Content-Type: application/json
Authorization: Bearer YOUR_TOKEN

{
  "question": "请帮我总结这篇文章的要点",
  "withSearch": true,
  "model": "gpt-4"
}
```

#### 向量数据库操作
```typescript
// 添加向量嵌入
await trpc.ai.embeddingUpsert.mutate({
  id: 123,
  content: "需要向量化的内容",
  type: "insert"
});

// 重建向量数据库
await trpc.ai.rebuildEmbedding.mutate();

// 语义搜索
const searchResults = await trpc.ai.searchEmbedding.query({
  query: "机器学习相关内容",
  limit: 10
});
```

### 3. 用户管理 API

#### 用户信息
```typescript
// 获取当前用户信息
const userInfo = await trpc.user.detail.query();

// 获取用户列表 (管理员权限)
const users = await trpc.user.list.query();

// HTTP 调用
GET /api/trpc/user.detail
Authorization: Bearer YOUR_TOKEN
```

**响应示例：**
```json
{
  "id": 1,
  "name": "user@example.com",
  "nickName": "John Doe",
  "role": "user",
  "image": "https://avatar.url",
  "loginType": "email"
}
```

#### 用户注册
```typescript
// 注册新用户
const success = await trpc.user.register.mutate({
  name: "newuser@example.com",
  password: "securepassword123"
});

// HTTP 调用
POST /api/trpc/user.register
Content-Type: application/json

{
  "name": "newuser@example.com",
  "password": "securepassword123"
}
```

### 4. 标签管理 API

#### 标签操作
```typescript
// 获取所有标签
const tags = await trpc.tag.list.query();

// 创建标签
const newTag = await trpc.tag.upsert.mutate({
  name: "JavaScript",
  icon: "⚡",
  color: "#yellow"
});

// 删除标签
await trpc.tag.delete.mutate({
  id: 1
});
```

### 5. 文件管理 API

#### 文件列表和操作
```typescript
// 获取文件列表
const files = await trpc.attachments.list.query({
  page: 1,
  size: 20,
  searchText: "image"
});

// 删除文件
await trpc.attachments.delete.mutate({
  id: 123
});

// 设置文件分享
await trpc.attachments.share.mutate({
  id: 123,
  isShare: true,
  sharePassword: "optional-password"
});
```

## REST API 参考

### 1. 文件上传 API

#### 单文件上传
```bash
# cURL 示例
curl -X POST https://your-domain.com/api/file/upload \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "file=@/path/to/your/file.jpg" \
  -F "noteId=123"
```

```javascript
// JavaScript 示例
const formData = new FormData();
formData.append('file', fileInput.files[0]);
formData.append('noteId', '123');

const response = await fetch('/api/file/upload', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${token}`
  },
  body: formData
});

const result = await response.json();
```

**响应示例：**
```json
{
  "success": true,
  "files": [
    {
      "id": 456,
      "name": "image.jpg",
      "path": "/uploads/2024/01/image.jpg",
      "size": 102400,
      "mimeType": "image/jpeg"
    }
  ]
}
```

#### 批量文件上传
```javascript
// 多文件上传
const formData = new FormData();
for (let file of files) {
  formData.append('files', file);
}

const response = await fetch('/api/file/upload', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${token}`
  },
  body: formData
});
```

### 2. OAuth 认证 API

#### OAuth 登录流程
```bash
# 1. 重定向到 OAuth 提供商
GET /api/auth/github
# 用户将被重定向到 GitHub 授权页面

# 2. OAuth 回调处理
GET /api/auth/callback/github?code=AUTHORIZATION_CODE
# 系统将验证授权码并创建用户会话
```

#### 支持的 OAuth 提供商
```typescript
interface OAuthProviders {
  github: {
    endpoint: "/api/auth/github",
    scopes: ["user:email"]
  };
  google: {
    endpoint: "/api/auth/google", 
    scopes: ["profile", "email"]
  };
  discord: {
    endpoint: "/api/auth/discord",
    scopes: ["identify", "email"]
  };
}
```

### 3. RSS 订阅 API

#### RSS 源访问
```bash
# 获取用户的 RSS 源
GET /api/rss/{userId}/rss?row=20

# 获取 Atom 格式
GET /api/rss/{userId}/atom?row=20
```

**响应示例：**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
  <channel>
    <title>用户笔记 RSS</title>
    <description>用户的最新笔记</description>
    <link>https://your-domain.com</link>
    <item>
      <title>TypeScript 学习笔记</title>
      <description>学习 TypeScript 的一些心得...</description>
      <link>https://your-domain.com/note/123</link>
      <pubDate>Mon, 01 Jan 2024 00:00:00 GMT</pubDate>
    </item>
  </channel>
</rss>
```

### 4. OpenAI 兼容 API

#### 聊天补全接口
```bash
# cURL 示例
curl -X POST https://your-domain.com/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "model": "gpt-4",
    "messages": [
      {
        "role": "user",
        "content": "请帮我写一个 TypeScript 函数"
      }
    ],
    "stream": false
  }'
```

```javascript
// JavaScript 客户端
const response = await fetch('/v1/chat/completions', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${token}`
  },
  body: JSON.stringify({
    model: 'gpt-4',
    messages: [
      {
        role: 'user',
        content: '请帮我写一个 TypeScript 函数'
      }
    ],
    stream: false
  })
});
```

#### 流式响应
```javascript
// 流式聊天
const response = await fetch('/v1/chat/completions', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${token}`
  },
  body: JSON.stringify({
    model: 'gpt-4',
    messages: [
      {
        role: 'user',
        content: '请详细解释 React Hooks'
      }
    ],
    stream: true
  })
});

const reader = response.body?.getReader();
const decoder = new TextDecoder();

while (true) {
  const { done, value } = await reader.read();
  if (done) break;
  
  const chunk = decoder.decode(value);
  const lines = chunk.split('\n');
  
  for (const line of lines) {
    if (line.startsWith('data: ')) {
      const data = line.slice(6);
      if (data === '[DONE]') return;
      
      try {
        const parsed = JSON.parse(data);
        const content = parsed.choices[0]?.delta?.content;
        if (content) {
          console.log(content); // 实时输出内容
        }
      } catch (e) {
        // 跳过解析错误
      }
    }
  }
}
```

## SDK 和客户端库

### TypeScript/JavaScript SDK

```bash
# 安装 SDK
npm install @blinko/sdk
```

```typescript
// 初始化 SDK
import { BlinkoSDK } from '@blinko/sdk';

const sdk = new BlinkoSDK({
  baseURL: 'https://your-domain.com',
  apiKey: 'YOUR_API_KEY'
});

// 使用 SDK
const notes = await sdk.notes.list({
  page: 1,
  size: 20
});

const newNote = await sdk.notes.create({
  content: '# 新笔记内容',
  type: 0
});
```

### Python SDK

```python
# pip install blinko-sdk

from blinko_sdk import BlinkoClient

client = BlinkoClient(
    base_url='https://your-domain.com',
    api_key='YOUR_API_KEY'
)

# 获取笔记列表
notes = client.notes.list(page=1, size=20)

# 创建新笔记
new_note = client.notes.create(
    content='# Python 笔记',
    type=0
)
```

## 错误处理

### 错误响应格式

```json
{
  "error": {
    "code": "UNAUTHORIZED",
    "message": "Invalid or expired token",
    "details": {
      "field": "authorization",
      "received": "invalid_token"
    }
  }
}
```

### 常见错误码

| 错误码 | HTTP 状态码 | 描述 | 解决方案 |
|--------|-------------|------|----------|
| `UNAUTHORIZED` | 401 | 认证失败 | 检查 Token 是否有效 |
| `FORBIDDEN` | 403 | 权限不足 | 确认用户权限 |
| `NOT_FOUND` | 404 | 资源不存在 | 检查资源 ID 是否正确 |
| `BAD_REQUEST` | 400 | 请求参数错误 | 检查请求参数格式 |
| `INTERNAL_SERVER_ERROR` | 500 | 服务器内部错误 | 联系技术支持 |
| `TOO_MANY_REQUESTS` | 429 | 请求频率超限 | 降低请求频率 |

### 错误处理最佳实践

```typescript
// tRPC 客户端错误处理
try {
  const notes = await trpc.note.list.query({ page: 1 });
} catch (error) {
  if (error.data?.code === 'UNAUTHORIZED') {
    // 重新登录
    redirectToLogin();
  } else if (error.data?.code === 'TOO_MANY_REQUESTS') {
    // 延迟重试
    await delay(1000);
    return retry();
  } else {
    // 显示错误信息
    showError(error.message);
  }
}

// REST API 错误处理
const response = await fetch('/api/trpc/note.list', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({ page: 1 })
});

if (!response.ok) {
  const errorData = await response.json();
  
  switch (response.status) {
    case 401:
      // 处理认证错误
      break;
    case 403:
      // 处理权限错误
      break;
    case 429:
      // 处理频率限制
      break;
    default:
      // 处理其他错误
      break;
  }
}
```

## 速率限制

### 限制规则

```typescript
interface RateLimits {
  standard: {
    requests: 1000,
    window: "1小时",
    scope: "每用户"
  };
  file_upload: {
    requests: 100,
    window: "1小时", 
    scope: "每用户"
  };
  ai_requests: {
    requests: 50,
    window: "1小时",
    scope: "每用户"
  };
}
```

### 响应头

```bash
# 速率限制相关的响应头
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 999
X-RateLimit-Reset: 1640995200
X-RateLimit-Window: 3600
```

## 最佳实践

### 1. 认证最佳实践

```typescript
// Token 刷新机制
class APIClient {
  private token: string;
  private refreshToken: string;
  
  async request(url: string, options: RequestInit) {
    try {
      return await this.makeRequest(url, options);
    } catch (error) {
      if (error.status === 401) {
        await this.refreshAccessToken();
        return await this.makeRequest(url, options);
      }
      throw error;
    }
  }
  
  private async refreshAccessToken() {
    const response = await fetch('/api/auth/refresh', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${this.refreshToken}`
      }
    });
    
    const data = await response.json();
    this.token = data.accessToken;
  }
}
```

### 2. 批量操作优化

```typescript
// 批量获取笔记
const batchNotes = await Promise.all([
  trpc.note.detail.query({ id: 1 }),
  trpc.note.detail.query({ id: 2 }),
  trpc.note.detail.query({ id: 3 })
]);

// 批量创建笔记
const batchCreate = await trpc.note.batchCreate.mutate({
  notes: [
    { content: "笔记 1" },
    { content: "笔记 2" },
    { content: "笔记 3" }
  ]
});
```

### 3. 分页查询优化

```typescript
// 分页加载模式
class NotePaginator {
  private page = 1;
  private hasMore = true;
  private notes: Note[] = [];
  
  async loadMore() {
    if (!this.hasMore) return;
    
    const response = await trpc.note.list.query({
      page: this.page,
      size: 20
    });
    
    this.notes.push(...response.notes);
    this.hasMore = response.hasMore;
    this.page++;
    
    return response.notes;
  }
}
```

### 4. 文件上传优化

```typescript
// 大文件分片上传
class ChunkedUploader {
  async uploadLargeFile(file: File) {
    const chunkSize = 1024 * 1024; // 1MB chunks
    const chunks = Math.ceil(file.size / chunkSize);
    
    for (let i = 0; i < chunks; i++) {
      const start = i * chunkSize;
      const end = Math.min(start + chunkSize, file.size);
      const chunk = file.slice(start, end);
      
      await this.uploadChunk(chunk, i, chunks);
    }
  }
  
  private async uploadChunk(chunk: Blob, index: number, total: number) {
    const formData = new FormData();
    formData.append('chunk', chunk);
    formData.append('index', index.toString());
    formData.append('total', total.toString());
    
    return await fetch('/api/file/upload-chunk', {
      method: 'POST',
      body: formData
    });
  }
}
```

## 调试和测试

### API 调试工具

1. **Swagger UI**: `https://your-domain.com/api-doc`
2. **Postman Collection**: 可导入 OpenAPI 规范
3. **curl 示例**: 每个 API 都提供 curl 示例

### 测试环境

```bash
# 测试环境 API 端点
https://test.your-domain.com/api

# 沙盒环境 (不会影响生产数据)
https://sandbox.your-domain.com/api
```

### API 监控

```typescript
// API 调用监控
const monitor = new APIMonitor({
  onRequest: (url, options) => {
    console.log(`[API] ${options.method} ${url}`);
  },
  onResponse: (url, response, duration) => {
    console.log(`[API] ${url} - ${response.status} (${duration}ms)`);
  },
  onError: (url, error) => {
    console.error(`[API] ${url} - Error:`, error);
  }
});
```

## 更新日志

### v1.0.0 (2024-01-01)
- 🎉 初始 API 版本发布
- ✨ 完整的笔记 CRUD 操作
- ✨ AI 集成接口
- ✨ 用户认证系统

### v1.1.0 (2024-02-01)
- ✨ 新增批量操作接口
- ✨ 文件分片上传支持
- 🐛 修复分页查询问题
- 📚 完善 API 文档

### v1.2.0 (2024-03-01)
- ✨ OpenAI 兼容接口
- ✨ 流式响应支持
- ✨ Webhook 事件系统
- 🚀 性能优化

---

*更多 API 信息请访问 [Swagger 文档](https://your-domain.com/api-doc)*
