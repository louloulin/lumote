# 后端API设计

## 概述

Blinko项目采用现代化的混合API架构，结合了tRPC和Express两种技术栈，为前端和第三方应用提供丰富的API服务。系统设计遵循RESTful原则，支持OpenAPI规范，并提供完整的Swagger文档。

## 技术架构

### API架构概览

```
┌─────────────────────────────────────────────────────┐
│                API Gateway                          │
├─────────────────────────────────────────────────────┤
│                tRPC Router                          │
│ ┌─────────────┬─────────────┬─────────────────────┐ │
│ │ Type-Safe   │ Real-time   │ Auto-generated      │ │
│ │ Procedures  │ Streaming   │ Types               │ │
│ └─────────────┴─────────────┴─────────────────────┘ │
├─────────────────────────────────────────────────────┤
│               Express Routes                        │
│ ┌─────────────┬─────────────┬─────────────────────┐ │
│ │ File Upload │ OAuth       │ Webhooks           │ │
│ │ RSS Feeds   │ OpenAI API  │ Static Files       │ │
│ └─────────────┴─────────────┴─────────────────────┘ │
├─────────────────────────────────────────────────────┤
│              Middleware Layer                       │
│ ┌─────────────┬─────────────┬─────────────────────┐ │
│ │ Auth & JWT  │ CORS        │ Error Handling      │ │
│ │ Rate Limit  │ Validation  │ Logging             │ │
│ └─────────────┴─────────────┴─────────────────────┘ │
├─────────────────────────────────────────────────────┤
│               Service Layer                         │
│ ┌─────────────┬─────────────┬─────────────────────┐ │
│ │ Business    │ AI Services │ File Management     │ │
│ │ Logic       │ Vector DB   │ Plugin System       │ │
│ └─────────────┴─────────────┴─────────────────────┘ │
├─────────────────────────────────────────────────────┤
│                Data Layer                           │
│ ┌─────────────┬─────────────┬─────────────────────┐ │
│ │ PostgreSQL  │ Prisma ORM  │ Redis Cache         │ │
│ │ Vector DB   │ File System │ External APIs       │ │
│ └─────────────┴─────────────┴─────────────────────┘ │
└─────────────────────────────────────────────────────┘
```

### 核心技术栈

| 技术 | 版本 | 用途 | 特性 |
|------|------|------|------|
| **tRPC** | ^11.0.0 | 类型安全API | • End-to-end类型安全<br>• 实时数据流<br>• 自动代码生成 |
| **Express** | ^4.18.0 | HTTP服务器 | • 文件上传下载<br>• OAuth认证<br>• 第三方集成 |
| **Prisma** | ^5.0.0 | ORM框架 | • 类型安全数据库操作<br>• 数据库迁移<br>• 查询优化 |
| **Zod** | ^3.22.0 | 数据验证 | • 运行时类型检查<br>• Schema验证<br>• 错误处理 |
| **Swagger** | ^6.2.0 | API文档 | • 自动文档生成<br>• 交互式测试<br>• OpenAPI标准 |

## tRPC路由系统

### 路由架构

tRPC路由系统采用模块化设计，每个业务领域都有独立的路由器：

```typescript
// server/routerTrpc/_app.ts
export const appRouter = router({
  ai: aiRouter,              // AI功能相关
  notes: noteRouter,         // 笔记管理
  tags: tagRouter,           // 标签系统
  users: userRouter,         // 用户管理
  attachments: attachmentsRouter,  // 附件管理
  config: configRouter,      // 配置管理
  public: publicRouter,      // 公开接口
  task: taskRouter,          // 任务管理
  analytics: analyticsRouter, // 数据分析
  comments: commentRouter,   // 评论系统
  follows: followsRouter,    // 关注系统
  notifications: notificationRouter, // 通知
  plugin: pluginRouter,      // 插件系统
  conversation: conversationRouter,  // 对话管理
  message: messageRouter,    // 消息系统
});
```

### 权限控制中间件

系统提供多层级的权限控制机制：

```typescript
// 公开访问接口
export const publicProcedure = t.procedure;

// 需要登录的接口
export const authProcedure = t.procedure.use(async ({ ctx, next, path }) => {
  if (!ctx?.name || ctx?.requiresTwoFactor) {
    throw new TRPCError({
      code: "UNAUTHORIZED",
      message: 'Unauthorized'
    });
  }
  
  // 检查特定权限
  if (ctx.permissions && Array.isArray(ctx.permissions)) {
    const hasPermission = ctx.permissions.some(perm => path?.includes(perm));
    if (!hasPermission) {
      throw new TRPCError({
        code: "FORBIDDEN",
        message: 'This token does not have permission to access this endpoint'
      });
    }
  }
  
  return next({ ctx, ...{ id: ctx.sub } });
});

// 演示环境限制
export const demoAuthMiddleware = t.middleware(async ({ ctx, next }) => {
  if (process.env.IS_DEMO) {
    throw new TRPCError({
      code: "FORBIDDEN",
      message: 'The operation is rejected because this is a demo environment'
    });
  }
  return next({ ctx });
});

// 超级管理员权限
export const superAdminAuthMiddleware = t.middleware(async ({ ctx, next }) => {
  if (ctx.role !== 'superadmin') {
    throw new TRPCError({
      code: "FORBIDDEN",
      message: 'You are not allowed to perform this operation'
    });
  }
  return next({ ctx });
});
```

### 核心API路由详解

#### 1. 笔记管理API (noteRouter)

提供完整的笔记CRUD操作和高级功能：

```typescript
export const noteRouter = router({
  // 查询笔记列表
  list: authProcedure
    .meta({ 
      openapi: { 
        method: 'POST', 
        path: '/v1/note/list', 
        summary: 'Query notes list', 
        protect: true, 
        tags: ['Note'] 
      } 
    })
    .input(z.object({
      tagId: z.union([z.number(), z.null()]).default(null),
      page: z.number().default(1),
      size: z.number().default(30),
      orderBy: z.enum(['asc', 'desc']).default('desc'),
      type: z.union([z.nativeEnum(NoteType), z.literal(-1)]).default(-1),
      isArchived: z.boolean().optional(),
      isShare: z.boolean().optional(),
      isRecycle: z.boolean().optional(),
      searchText: z.string().optional(),
      withoutTag: z.boolean().optional(),
      withFile: z.boolean().optional(),
      withLink: z.boolean().optional(),
      isUseAiQuery: z.boolean().optional(),
      startDate: z.date().optional(),
      endDate: z.date().optional(),
      hasTodo: z.boolean().optional(),
    }))
    .query(async ({ input, ctx }) => {
      // 复杂的查询逻辑实现
      // 支持多条件过滤、分页、排序
      // 包含附件、标签、引用关系
    }),

  // 创建笔记
  upsert: authProcedure.use(demoAuthMiddleware)
    .meta({ 
      openapi: { 
        method: 'POST', 
        path: '/v1/note/upsert', 
        summary: 'Create or update note', 
        protect: true, 
        tags: ['Note'] 
      } 
    })
    .input(z.object({
      id: z.number().optional(),
      content: z.string(),
      type: z.nativeEnum(NoteType).optional(),
      references: z.array(z.number()).optional(),
      isArchived: z.boolean().optional(),
      isShare: z.boolean().optional(),
      sharePassword: z.string().optional(),
    }))
    .mutation(async ({ input, ctx }) => {
      // 创建或更新笔记
      // 自动提取标签
      // 处理引用关系
      // 触发AI嵌入更新
      // 发送Webhook通知
    }),

  // 删除笔记
  delete: authProcedure.use(demoAuthMiddleware)
    .input(z.object({
      ids: z.array(z.number())
    }))
    .mutation(async ({ input, ctx }) => {
      // 软删除或硬删除
      // 清理相关数据
      // 删除AI嵌入
    }),

  // 导出笔记
  export: authProcedure
    .input(z.object({
      type: z.enum(['markdown', 'json', 'html'])
    }))
    .mutation(async ({ input, ctx }) => {
      // 按格式导出笔记
      // 包含附件和媒体文件
    }),
});
```

#### 2. AI集成API (aiRouter)

提供AI功能的完整接口：

```typescript
export const aiRouter = router({
  // 向量数据库嵌入
  embeddingUpsert: authProcedure
    .input(z.object({
      id: z.number(),
      content: z.string(),
      type: z.enum(['update', 'insert'])
    }))
    .mutation(async ({ input }) => {
      const { id, content, type } = input;
      const createTime = await prisma.notes.findUnique({ 
        where: { id } 
      }).then(i => i?.createdAt);
      
      const { ok, error } = await AiService.embeddingUpsert({ 
        id, 
        content, 
        type, 
        createTime: createTime! 
      });
      
      if (!ok) {
        throw new TRPCError({
          code: 'INTERNAL_SERVER_ERROR',
          message: error
        });
      }
      return { ok };
    }),

  // AI对话补全
  completions: authProcedure
    .input(z.object({
      question: z.string(),
      conversations: z.array(z.any()).optional(),
      withSearch: z.boolean().optional(),
      model: z.string().optional(),
    }))
    .mutation(async ({ input, ctx }) => {
      // 调用AI模型
      // 可选RAG检索
      // 流式响应
    }),

  // 重建向量数据库
  rebuildEmbedding: authProcedure
    .mutation(async () => {
      // 异步重建所有嵌入
      // 后台任务处理
    }),
});
```

#### 3. 用户管理API (userRouter)

提供用户认证和管理功能：

```typescript
export const userRouter = router({
  // 用户列表（超级管理员）
  list: authProcedure.use(superAdminAuthMiddleware)
    .meta({
      openapi: {
        method: 'GET', 
        path: '/v1/user/list', 
        summary: 'Find user list',
        description: 'Find user list, need super admin permission', 
        tags: ['User']
      }
    })
    .query(async () => {
      return await prisma.accounts.findMany();
    }),

  // 用户详情
  detail: authProcedure
    .meta({
      openapi: {
        method: 'GET', 
        path: '/v1/user/detail', 
        summary: 'Find user detail from user id',
        description: 'Find user detail from user id, need login', 
        tags: ['User']
      }
    })
    .input(z.object({ id: z.number().optional() }))
    .query(async ({ input, ctx }) => {
      const user = await prisma.accounts.findFirst({ 
        where: { id: input.id ?? Number(ctx.id) } 
      });
      
      // 权限检查
      if (Number(user?.id) !== Number(ctx.id) && user?.role !== 'superadmin') {
        throw new TRPCError({ 
          code: 'UNAUTHORIZED', 
          message: 'You are not allowed to access this user' 
        });
      }
      
      return {
        id: user?.id,
        name: user?.name,
        nickName: user?.nickname,
        token: user?.apiToken,
        loginType: user?.loginType,
        image: user?.image,
        role: user?.role
      };
    }),

  // 用户注册
  register: publicProcedure
    .meta({
      openapi: {
        method: 'POST', 
        path: '/v1/user/register', 
        summary: 'Register user account',
        tags: ['User']
      }
    })
    .input(z.object({
      name: z.string(),
      password: z.string(),
    }))
    .mutation(async ({ input }) => {
      const { name, password } = input;
      const count = await prisma.accounts.count();
      
      if (count === 0) {
        // 创建超级管理员
        const passwordHash = await hashPassword(password);
        const res = await prisma.accounts.create({
          data: {
            name,
            password: passwordHash,
            nickname: name,
            role: 'superadmin',
          }
        });
        
        // 生成API Token
        await prisma.accounts.update({
          where: { id: res.id },
          data: {
            apiToken: await genToken({ 
              id: res.id, 
              name, 
              role: 'superadmin' 
            })
          }
        });
        
        // 创建初始配置和示例数据
        await createSeed(res.id);
        return true;
      } else {
        // 检查是否允许注册
        const config = await prisma.config.findFirst({ 
          where: { key: 'isAllowRegister' } 
        });
        
        if (config?.config?.value === false || !config) {
          throw new TRPCError({
            code: 'INTERNAL_SERVER_ERROR',
            message: 'Registration not allowed',
          });
        }
        
        // 创建普通用户
        const passwordHash = await hashPassword(password);
        const res = await prisma.accounts.create({ 
          data: { 
            name, 
            password: passwordHash, 
            nickname: name, 
            role: 'user' 
          } 
        });
        
        await prisma.accounts.update({ 
          where: { id: res.id }, 
          data: { 
            apiToken: await genToken({ 
              id: res.id, 
              name, 
              role: 'user' 
            }) 
          } 
        });
        
        return true;
      }
    }),
});
```

#### 4. 文件管理API (attachmentsRouter)

提供文件上传、管理和分享功能：

```typescript
export const attachmentsRouter = router({
  // 文件列表
  list: authProcedure
    .input(z.object({
      page: z.number().default(1),
      size: z.number().default(10),
      searchText: z.string().optional(),
      folder: z.string().optional()
    }))
    .query(async ({ input, ctx }) => {
      const { page, size, searchText, folder } = input;
      const skip = (page - 1) * size;

      // 构建查询条件
      const whereCondition = {
        OR: [
          { note: { accountId: Number(ctx.id) } },
          { accountId: Number(ctx.id) }
        ]
      };

      if (searchText) {
        whereCondition.name = {
          contains: searchText,
          mode: 'insensitive'
        };
      }

      if (folder) {
        whereCondition.path = {
          startsWith: folder
        };
      }

      const attachments = await prisma.attachments.findMany({
        where: whereCondition,
        skip,
        take: size,
        orderBy: { createdAt: 'desc' },
        include: {
          note: {
            select: {
              id: true,
              content: true,
              createdAt: true
            }
          }
        }
      });

      return attachments;
    }),

  // 文件分享
  share: authProcedure
    .input(z.object({
      id: z.number(),
      isShare: z.boolean(),
      sharePassword: z.string().optional()
    }))
    .mutation(async ({ input, ctx }) => {
      const { id, isShare, sharePassword } = input;
      
      await prisma.attachments.update({
        where: { 
          id,
          OR: [
            { note: { accountId: Number(ctx.id) } },
            { accountId: Number(ctx.id) }
          ]
        },
        data: {
          isShare,
          sharePassword: sharePassword || null
        }
      });
      
      return { success: true };
    }),
});
```

## Express路由系统

### 文件上传API

处理多媒体文件上传，支持多种存储后端：

```typescript
// server/routerExpress/file/upload.ts
router.post('/api/file/upload', async (req, res) => {
  try {
    const token = await getTokenFromRequest(req);
    if (!token) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    const bb = busboy({ headers: req.headers });
    const uploadPromises: Promise<any>[] = [];

    bb.on('file', (name, file, info) => {
      const { filename, encoding, mimeType } = info;
      
      uploadPromises.push(
        FileService.uploadFile({
          file,
          filename,
          mimeType,
          accountId: Number(token.id)
        })
      );
    });

    bb.on('close', async () => {
      try {
        const results = await Promise.all(uploadPromises);
        res.json({
          success: true,
          files: results
        });
      } catch (error) {
        console.error('Upload error:', error);
        res.status(500).json({ error: 'Upload failed' });
      }
    });

    req.pipe(bb);
  } catch (error) {
    res.status(500).json({ error: 'Upload failed' });
  }
});
```

### OAuth认证API

支持多种OAuth提供商的认证：

```typescript
// server/routerExpress/auth/index.ts
router.get('/github', (req, res, next) => {
  passport.authenticate('github', { scope: ['user:email'] })(req, res, next);
});

router.get('/google', (req, res, next) => {
  passport.authenticate('google', { scope: ['profile', 'email'] })(req, res, next);
});

router.get('/callback/:providerId', (req, res, next) => {
  const providerId = req.params.providerId;
  passport.authenticate(providerId, (err, user, info) => {
    handleOAuthCallback(req, res, err, user, info);
  })(req, res, next);
});

function handleOAuthCallback(req, res, err, user, info) {
  if (err) {
    return res.redirect('/?error=oauth_error');
  }
  
  if (!user) {
    return res.redirect('/?error=oauth_denied');
  }
  
  // 生成JWT Token
  const token = generateToken({
    id: user.id,
    name: user.name,
    role: user.role
  });
  
  // 重定向到前端并传递token
  res.redirect(`/?token=${token}`);
}
```

### RSS订阅API

提供RSS和Atom格式的订阅源：

```typescript
// server/routerExpress/rss.ts
router.get('/:userId/rss', async (req, res) => {
  try {
    const userId = req.params.userId;
    const rows = req.query.row ? parseInt(req.query.row as string) : 20;
    const origin = req.headers.origin || req.headers.host || 'http://localhost:1111';
    const fullOrigin = origin.toString().startsWith('http') 
      ? origin.toString() 
      : `http://${origin}`;
    
    const feed = await generateFeed(Number(userId), fullOrigin, rows);
    
    res.set({
      'Content-Type': 'application/rss+xml; charset=UTF-8',
      'Cache-Control': 'public, max-age=10800',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET',
      'X-Content-Type-Options': 'nosniff'
    });
    
    return res.send(feed.rss2());
  } catch (error) {
    console.error('Error generating RSS feed:', error);
    return res.status(500).json({ error: 'Failed to generate RSS feed' });
  }
});
```

### OpenAI兼容API

提供OpenAI兼容的聊天接口：

```typescript
// server/routerExpress/openai.ts
router.post('/chat/completions', async (req, res) => {
  try {
    const token = await getTokenFromRequest(req);
    if (!token) {
      return res.status(401).json({
        error: { message: 'No valid authorization token provided' }
      });
    }

    const config = await getGlobalConfig({ ctx: token });
    const { messages = [], stream = false, model = '' } = req.body;

    if (stream) {
      res.setHeader('Content-Type', 'text/event-stream');
      res.setHeader('Cache-Control', 'no-cache');
      res.setHeader('Connection', 'keep-alive');
      res.setHeader('Access-Control-Allow-Origin', '*');

      const streamClient = createServerStreamClient(req);
      
      try {
        const streamResponse = streamClient.ai.completions.mutate({
          question: messages[messages.length - 1]?.content || '',
          conversations: messages,
          model
        });

        for await (const chunk of streamResponse) {
          const sseData = `data: ${JSON.stringify({
            id: 'chatcmpl-' + Date.now(),
            object: 'chat.completion.chunk',
            created: Math.floor(Date.now() / 1000),
            model: model,
            choices: [{
              index: 0,
              delta: { content: chunk.content },
              finish_reason: chunk.done ? 'stop' : null
            }]
          })}\n\n`;
          
          res.write(sseData);
        }
        
        res.write('data: [DONE]\n\n');
        res.end();
      } catch (error) {
        res.write(`data: ${JSON.stringify({
          error: { message: error.message }
        })}\n\n`);
        res.end();
      }
    } else {
      // 非流式响应
      const response = await api.ai.completions.mutate({
        question: messages[messages.length - 1]?.content || '',
        conversations: messages,
        model
      });

      res.json({
        id: 'chatcmpl-' + Date.now(),
        object: 'chat.completion',
        created: Math.floor(Date.now() / 1000),
        model: model,
        choices: [{
          index: 0,
          message: {
            role: 'assistant',
            content: response.content
          },
          finish_reason: 'stop'
        }]
      });
    }
  } catch (error) {
    res.status(500).json({
      error: { message: error.message || 'Internal server error' }
    });
  }
});
```

## 数据验证与错误处理

### Zod Schema验证

系统使用Zod进行严格的输入验证：

```typescript
// 笔记创建验证
const noteCreateSchema = z.object({
  content: z.string().min(1, "内容不能为空"),
  type: z.nativeEnum(NoteType).optional(),
  references: z.array(z.number()).optional(),
  isArchived: z.boolean().optional(),
  isShare: z.boolean().optional(),
  sharePassword: z.string().optional(),
});

// 用户注册验证
const userRegisterSchema = z.object({
  name: z.string()
    .min(3, "用户名至少3个字符")
    .max(20, "用户名最多20个字符")
    .regex(/^[a-zA-Z0-9_]+$/, "用户名只能包含字母、数字和下划线"),
  password: z.string()
    .min(6, "密码至少6个字符")
    .max(100, "密码最多100个字符"),
});

// 文件上传验证
const fileUploadSchema = z.object({
  file: z.any(),
  filename: z.string().min(1, "文件名不能为空"),
  mimeType: z.string().optional(),
  maxSize: z.number().default(50 * 1024 * 1024), // 50MB
});
```

### 错误处理机制

统一的错误处理和响应格式：

```typescript
// tRPC错误处理
export const errorFormatter = ({ shape, error }) => {
  return {
    ...shape,
    data: {
      ...shape.data,
      zodError: error.code === 'BAD_REQUEST' && error.cause instanceof ZodError 
        ? error.cause.flatten() 
        : null,
    },
  };
};

// Express错误处理中间件
app.use((error, req, res, next) => {
  console.error('API Error:', error);
  
  if (error.name === 'ValidationError') {
    return res.status(400).json({
      error: 'Validation failed',
      details: error.details
    });
  }
  
  if (error.name === 'UnauthorizedError') {
    return res.status(401).json({
      error: 'Unauthorized',
      message: error.message
    });
  }
  
  if (error.name === 'ForbiddenError') {
    return res.status(403).json({
      error: 'Forbidden',
      message: error.message
    });
  }
  
  // 默认服务器错误
  res.status(500).json({
    error: 'Internal server error',
    message: process.env.NODE_ENV === 'development' ? error.message : 'Something went wrong'
  });
});
```

## OpenAPI规范

### Swagger文档生成

系统自动生成完整的API文档：

```typescript
// server/swagger.ts
const trpcOpenApiDocument = generateOpenApiDocument(appRouter, {
  title: 'Blinko tRPC API',
  description: 'Blinko智能笔记系统API文档',
  version: '1.0.0',
  baseUrl: '/api',
  tags: ['Note', 'User', 'Task', 'Tag', 'Public', 'Config', 'File'],
  securitySchemes: {
    bearer: {
      type: 'http',
      scheme: 'bearer',
      bearerFormat: 'JWT'
    }
  }
});

// Swagger UI配置
app.use('/api-doc', swaggerUi.serve, swaggerUi.setup(openApiDocument, {
  customCss: '.swagger-ui .topbar { display: none }',
  customSiteTitle: 'Blinko API文档',
  customfavIcon: '/favicon.ico',
  swaggerOptions: {
    persistAuthorization: true,
    docExpansion: 'list',
    filter: true
  }
}));
```

### API元数据定义

为每个接口提供详细的元数据：

```typescript
// OpenAPI元数据示例
.meta({
  openapi: {
    method: 'POST',
    path: '/v1/note/upsert',
    summary: '创建或更新笔记',
    description: '支持创建新笔记或更新现有笔记，自动处理标签提取和引用关系',
    tags: ['Note'],
    protect: true, // 需要认证
    security: [{ bearer: [] }],
    responses: {
      200: {
        description: '操作成功',
        content: {
          'application/json': {
            schema: {
              type: 'object',
              properties: {
                id: { type: 'number' },
                content: { type: 'string' },
                createdAt: { type: 'string', format: 'date-time' }
              }
            }
          }
        }
      },
      401: {
        description: '未授权访问'
      },
      400: {
        description: '请求参数错误'
      }
    }
  }
})
```

## 性能优化

### 查询优化

使用Prisma的高级查询特性：

```typescript
// 分页查询优化
const notesList = await prisma.notes.findMany({
  where: queryCondition,
  skip: (page - 1) * size,
  take: size,
  orderBy: { [orderField]: orderDirection },
  include: {
    attachments: {
      select: {
        id: true,
        path: true,
        name: true,
        size: true,
        type: true
      }
    },
    tags: {
      include: {
        tag: {
          select: {
            id: true,
            name: true,
            color: true
          }
        }
      }
    }
  }
});

// 使用索引优化查询
await prisma.$executeRaw`
  CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_notes_account_created 
  ON notes(account_id, created_at DESC);
`;

// 批量操作优化
await prisma.$transaction([
  prisma.notes.createMany({ data: notesData }),
  prisma.tagsToNote.createMany({ data: tagsData }),
  prisma.attachments.createMany({ data: attachmentsData })
]);
```

### 缓存策略

多层级缓存提升性能：

```typescript
// Redis缓存
import { cache } from '@shared/lib/cache';

// 缓存热门标签
const popularTags = await cache.wrap(
  `popular-tags-${userId}`,
  async () => {
    return await prisma.tag.findMany({
      where: { accountId: userId },
      orderBy: { _count: { tagsToNote: 'desc' } },
      take: 20
    });
  },
  { ttl: 60 * 60 * 1000 } // 1小时缓存
);

// 缓存用户配置
const userConfig = await cache.wrap(
  `user-config-${userId}`,
  async () => {
    return await getGlobalConfig({ ctx: { id: userId } });
  },
  { ttl: 5 * 60 * 1000 } // 5分钟缓存
);

// 缓存链接预览
const linkPreview = await cache.wrap(
  `link-preview-${url}`,
  async () => {
    return await fetchLinkMetadata(url);
  },
  { ttl: 24 * 60 * 60 * 1000 } // 24小时缓存
);
```

### 流式处理

支持大数据量的流式处理：

```typescript
// 流式导出
router.get('/export/stream', async (req, res) => {
  res.setHeader('Content-Type', 'application/json');
  res.setHeader('Content-Disposition', 'attachment; filename="notes.json"');
  
  const stream = new PassThrough();
  stream.pipe(res);
  
  stream.write('{"notes":[');
  
  let isFirst = true;
  const pageSize = 100;
  let page = 1;
  
  while (true) {
    const notes = await prisma.notes.findMany({
      where: { accountId: Number(userId) },
      skip: (page - 1) * pageSize,
      take: pageSize,
      include: { attachments: true, tags: true }
    });
    
    if (notes.length === 0) break;
    
    for (const note of notes) {
      if (!isFirst) stream.write(',');
      stream.write(JSON.stringify(note));
      isFirst = false;
    }
    
    page++;
  }
  
  stream.write(']}');
  stream.end();
});
```

## 安全机制

### JWT认证

基于JWT的无状态认证：

```typescript
// JWT Token生成
const genToken = async ({ id, name, role, permissions }) => {
  const secret = await getNextAuthSecret();
  return jwt.sign(
    {
      role,
      name,
      sub: id.toString(),
      exp: Math.floor(Date.now() / 1000) + (60 * 60 * 24 * 365 * 100),
      iat: Math.floor(Date.now() / 1000),
      permissions
    },
    secret
  );
};

// JWT验证中间件
const verifyJWT = async (token: string) => {
  try {
    const secret = await getNextAuthSecret();
    const decoded = jwt.verify(token, secret) as JWTPayload;
    return decoded;
  } catch (error) {
    throw new TRPCError({
      code: 'UNAUTHORIZED',
      message: 'Invalid token'
    });
  }
};
```

### 输入验证

严格的输入验证防止注入攻击：

```typescript
// SQL注入防护
const safeQuery = await prisma.$queryRaw`
  SELECT * FROM notes 
  WHERE account_id = ${userId} 
  AND content ILIKE ${`%${searchText}%`}
`;

// XSS防护
import DOMPurify from 'isomorphic-dompurify';

const sanitizeContent = (content: string) => {
  return DOMPurify.sanitize(content, {
    ALLOWED_TAGS: ['p', 'br', 'strong', 'em', 'u', 'h1', 'h2', 'h3', 'ul', 'ol', 'li'],
    ALLOWED_ATTR: ['href', 'target']
  });
};
```

### 访问控制

细粒度的权限控制：

```typescript
// 资源访问权限检查
const checkNoteAccess = async (noteId: number, userId: number, action: string) => {
  const note = await prisma.notes.findUnique({
    where: { id: noteId },
    include: { account: true }
  });
  
  if (!note) {
    throw new TRPCError({
      code: 'NOT_FOUND',
      message: 'Note not found'
    });
  }
  
  // 检查所有权
  if (note.accountId !== userId) {
    // 检查是否为共享笔记
    if (action === 'read' && note.isShare) {
      return true;
    }
    
    throw new TRPCError({
      code: 'FORBIDDEN',
      message: 'Access denied'
    });
  }
  
  return true;
};
```

## 监控与日志

### API监控

完整的API监控和指标收集：

```typescript
// 请求日志中间件
app.use((req, res, next) => {
  const start = Date.now();
  const originalSend = res.send;
  
  res.send = function(data) {
    const duration = Date.now() - start;
    
    console.log({
      method: req.method,
      url: req.url,
      status: res.statusCode,
      duration: `${duration}ms`,
      userAgent: req.get('User-Agent'),
      ip: req.ip,
      timestamp: new Date().toISOString()
    });
    
    // 发送到监控系统
    if (process.env.ENABLE_METRICS) {
      sendMetrics({
        type: 'api_request',
        method: req.method,
        route: req.route?.path,
        status: res.statusCode,
        duration,
        timestamp: Date.now()
      });
    }
    
    return originalSend.call(this, data);
  };
  
  next();
});

// 错误监控
app.use((error, req, res, next) => {
  // 记录错误详情
  console.error('API Error:', {
    error: error.message,
    stack: error.stack,
    url: req.url,
    method: req.method,
    body: req.body,
    user: req.user?.id,
    timestamp: new Date().toISOString()
  });
  
  // 发送到错误追踪服务
  if (process.env.SENTRY_DSN) {
    Sentry.captureException(error, {
      tags: {
        component: 'api',
        method: req.method,
        url: req.url
      },
      user: {
        id: req.user?.id,
        username: req.user?.name
      }
    });
  }
  
  next(error);
});
```

### 性能指标

关键性能指标的收集和分析：

```typescript
// 数据库查询性能监控
const monitorQuery = async (operation: string, query: () => Promise<any>) => {
  const start = process.hrtime.bigint();
  let result;
  let error;
  
  try {
    result = await query();
  } catch (e) {
    error = e;
    throw e;
  } finally {
    const end = process.hrtime.bigint();
    const duration = Number(end - start) / 1000000; // 转换为毫秒
    
    // 记录慢查询
    if (duration > 1000) { // 超过1秒
      console.warn('Slow Query:', {
        operation,
        duration: `${duration.toFixed(2)}ms`,
        timestamp: new Date().toISOString()
      });
    }
    
    // 发送指标
    sendMetrics({
      type: 'db_query',
      operation,
      duration,
      success: !error,
      timestamp: Date.now()
    });
  }
  
  return result;
};
```

## 总结

Blinko的后端API系统通过tRPC和Express的混合架构，提供了类型安全、高性能、可扩展的API服务。系统特点包括：

1. **类型安全**: End-to-end类型安全，减少运行时错误
2. **高性能**: 多层缓存、查询优化、流式处理
3. **安全可靠**: JWT认证、权限控制、输入验证
4. **易于维护**: 模块化设计、完整文档、监控日志
5. **开发友好**: 自动代码生成、热重载、调试工具

这种架构设计不仅满足了当前的功能需求，也为未来的扩展提供了良好的基础。
