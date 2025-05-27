# RAG 系统实现

## 1. RAG 系统概述

检索增强生成 (Retrieval-Augmented Generation, RAG) 是 Blinko 智能功能的核心，它结合了检索系统和生成式 AI，为用户提供基于笔记内容的智能问答和相关推荐。本文详细介绍 Blinko 中 RAG 系统的设计和实现。

## 2. RAG 核心架构

### 2.1 系统组件

Blinko 的 RAG 系统由以下主要组件构成：

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│  查询处理    │────>│  检索系统    │────>│  生成系统    │
└──────────────┘     └──────────────┘     └──────────────┘
       │                    │                    │
       ▼                    ▼                    ▼
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│  查询向量化  │     │  向量数据库  │     │   LLM 模型   │
└──────────────┘     └──────────────┘     └──────────────┘
```

### 2.2 工作流程

```typescript
// RAG 系统的基本工作流程
interface RAGWorkflow {
  // 查询处理
  queryProcessing: {
    parseUserQuery: "解析用户查询",
    queryExpansion: "查询扩展",
    vectorization: "向量化查询"
  };
  
  // 检索系统
  retrieval: {
    semanticSearch: "语义搜索",
    keywordSearch: "关键词搜索",
    hybridRetrieval: "混合检索",
    resultFiltering: "结果过滤"
  };
  
  // 生成系统
  generation: {
    contextAssembly: "上下文组装",
    promptConstruction: "提示词构建",
    llmInference: "LLM 推理",
    responseFormatting: "响应格式化"
  };
}
```

## 3. 查询处理实现

### 3.1 查询解析与向量化

查询处理是 RAG 系统的第一步，负责解析用户查询并生成查询向量：

```typescript
// server/aiServer/aiModelFactory.ts
static async queryVector(query: string, accountId: number, _topK?: number) {
  const { VectorStore, Embeddings, provider } = await AiModelFactory.GetProvider();

  // 获取配置
  const config = await AiModelFactory.globalConfig();
  const topK = _topK ?? config.embeddingTopK ?? 3;
  const embeddingMinScore = config.embeddingScore ?? 0.4;
  
  // 查询向量化 - 核心步骤
  const { embedding } = await embed({
    value: query,  // 用户原始查询
    model: Embeddings,  // 嵌入模型
  });
  
  // 使用向量检索相关内容
  // ...后续代码
}
```

### 3.2 查询扩展

为了提高检索质量，Blinko 支持查询扩展技术：

```typescript
// 查询扩展的基本实现示例
async function expandQuery(query: string, llm: LanguageModelV1): Promise<string> {
  // 使用 LLM 扩展查询
  const prompt = `
  原始查询: "${query}"
  请生成一个扩展版本的查询，包含相关的术语和同义词，以提高检索质量。
  扩展查询:
  `;
  
  const result = await llm.generate({
    messages: [{ role: "user", content: prompt }],
  });
  
  return result.message.content;
}
```

## 4. 检索系统实现

### 4.1 语义搜索

Blinko 使用向量相似度搜索实现语义搜索：

```typescript
// server/aiServer/aiModelFactory.ts
// 向量相似度搜索
const result = await VectorStore.query({
  indexName: 'blinko',
  queryVector: embedding,
  topK: topK,
});

// 过滤低相似度结果
let filteredResults = result.filter(({ score }) => score >= embeddingMinScore);
```

### 4.2 混合搜索策略

为了提高检索质量，Blinko 实现了语义搜索和关键词搜索的混合策略：

```typescript
// 混合搜索策略实现示例
async function hybridSearch(query: string, accountId: number) {
  // 并行执行语义搜索和关键词搜索
  const [semanticResults, keywordResults] = await Promise.all([
    semanticSearch(query),
    keywordSearch(query)
  ]);
  
  // 融合搜索结果
  const fusedResults = fuseSearchResults(
    semanticResults,
    keywordResults,
    0.7,  // 语义搜索权重
    0.3   // 关键词搜索权重
  );
  
  return fusedResults;
}

// 结果融合函数
function fuseSearchResults(semanticResults, keywordResults, semanticWeight, keywordWeight) {
  // 创建映射以便快速查找
  const resultMap = new Map();
  
  // 处理语义搜索结果
  semanticResults.forEach((result, index) => {
    const id = result.id;
    const score = semanticWeight * result.similarity * (1 - index * 0.01);
    resultMap.set(id, { ...result, score });
  });
  
  // 合并关键词搜索结果
  keywordResults.forEach((result, index) => {
    const id = result.id;
    const keywordScore = keywordWeight * result.similarity * (1 - index * 0.01);
    
    if (resultMap.has(id)) {
      // 如果已存在，合并分数
      const existingResult = resultMap.get(id);
      resultMap.set(id, { 
        ...existingResult, 
        score: existingResult.score + keywordScore 
      });
    } else {
      // 否则添加新结果
      resultMap.set(id, { ...result, score: keywordScore });
    }
  });
  
  // 排序返回结果
  return Array.from(resultMap.values())
    .sort((a, b) => b.score - a.score);
}
```

### 4.3 重排序优化

Blinko 支持使用重排序模型进一步优化检索结果：

```typescript
// server/aiServer/aiModelFactory.ts
// 使用重排序模型优化结果
if (config.rerankModel) {
  const rerankmodel = (await provider.rerankModel())!;
  const rerankScore = config.rerankScore ?? 0.5;
  
  // 使用 Mastra 的 rerank 函数优化结果
  const rerankedResults = await rerank(
    result,
    query,
    rerankmodel,
    {
      topK: config.rerankTopK ?? 3
    }
  );
  
  filteredResults = rerankedResults
    .filter((i) => i.score >= rerankScore)
    .map((i) => i.result);
}
```

## 5. 生成系统实现

### 5.1 上下文组装

在获取检索结果后，Blinko 将相关内容组装成上下文：

```typescript
// 上下文组装示例
function assembleContext(query: string, searchResults: SearchResult[]): string {
  // 格式化检索结果为上下文
  const contextParts = searchResults.map((result, index) => {
    return `[${index + 1}] 标题: ${result.title}\n内容: ${result.content}\n`;
  });
  
  // 组装完整上下文
  const context = `
用户查询: ${query}

相关信息:
${contextParts.join('\n')}
`;
  
  return context;
}
```

### 5.2 提示词构建

基于上下文，构建有效的提示词是 RAG 系统关键：

```typescript
// server/aiServer/index.ts
// 构建 RAG 提示词
function buildRagPrompt(query: string, context: string): string {
  return `你是 Blinko 的 AI 助手，你将基于用户的笔记内容回答问题。
  
以下是从用户笔记库中检索到的相关内容:
${context}

请根据上述内容回答用户的问题。如果无法从提供的内容中找到答案，请直接说明你不知道，不要编造信息。

用户问题: ${query}

回答:`;
}
```

### 5.3 LLM 调用

使用组装好的提示词调用 LLM 获取回答：

```typescript
// 使用 LLM 生成回答
async function generateAnswer(prompt: string): Promise<string> {
  const { LLM } = await AiModelFactory.GetProvider();
  
  try {
    const result = await LLM.generate({
      messages: [{ role: "user", content: prompt }],
    });
    
    return result.message.content;
  } catch (error) {
    console.error("LLM 生成失败:", error);
    return "抱歉，生成回答时出现了问题。";
  }
}
```

## 6. AI Agent 实现

### 6.1 Agent 基础架构

Blinko 使用 Agent 模式构建智能助手，实现更复杂的交互：

```typescript
// server/aiServer/aiModelFactory.ts
static async BaseChatAgent({ withTools = true, withOnlineSearch = false }) {
  const { LLM } = await AiModelFactory.GetProvider();
  
  // 创建基础 Mastra Agent
  const agent = new Agent({
    llm: LLM,
    systemPrompt: `你是 Blinko 的 AI 助手，你将帮助用户管理笔记和回答问题。`,
  });
  
  // 添加工具能力
  if (withTools) {
    agent.addTool(upsertBlinkoTool);
    agent.addTool(searchBlinkoTool);
    agent.addTool(updateBlinkoTool);
    agent.addTool(deleteBlinkoTool);
  }
  
  // 添加网络搜索能力
  if (withOnlineSearch) {
    agent.addTool(webSearchTool);
    agent.addTool(webExtra);
  }
  
  return agent;
}
```

### 6.2 特定功能 Agent

Blinko 为不同功能定制了专门的 Agent：

```typescript
// server/aiServer/aiModelFactory.ts
// 标签生成 Agent
static TagAgent = AiModelFactory.#createAgentFactory(
  'Blinko Tag Agent',
  `你是标签生成专家，你的任务是为笔记生成标签。
  根据笔记内容，提取 3-5 个最相关的关键词作为标签。
  标签应该简洁、相关、有助于内容分类。
  返回格式为逗号分隔的标签列表，如: "编程,JavaScript,React"`,
  'BlinkoTags'
);

// 摘要生成 Agent
static SummarizeAgent = AiModelFactory.#createAgentFactory(
  'Blinko Summarize Agent',
  `你是内容摘要专家，你的任务是为长文本生成简洁的摘要。
  摘要应该捕捉文本的主要观点和核心信息，长度控制在 100 字以内。`,
  'BlinkoSummarize'
);
```

### 6.3 工具实现

Blinko 实现了多种工具供 Agent 使用：

```typescript
// server/aiServer/tools/searchBlinko.ts
// 搜索 Blinko 笔记的工具
export const searchBlinkoTool = {
  name: 'searchBlinko',
  description: '搜索用户的笔记内容',
  parameters: {
    type: 'object',
    properties: {
      query: {
        type: 'string',
        description: '搜索查询，用于查找用户笔记'
      }
    },
    required: ['query']
  },
  execute: async ({ query }, { params }) => {
    const { accountId } = params;
    
    // 使用 RAG 系统搜索笔记
    const { notes } = await AiModelFactory.queryVector(query, accountId);
    
    // 格式化搜索结果
    const formattedResults = notes.map(note => ({
      id: note.id,
      title: note.title || note.content.substring(0, 50),
      content: note.content,
      createdAt: note.createdAt,
      updatedAt: note.updatedAt
    }));
    
    return formattedResults;
  }
};
```

## 7. RAG 优化策略

### 7.1 检索优化

Blinko 实现了多种检索优化策略：

1. **混合检索**：结合语义搜索和关键词搜索
2. **重排序**：使用 LLM 进行结果重排序
3. **动态 Top-K**：根据查询复杂度动态调整检索数量
4. **相似度阈值**：过滤低相似度结果

### 7.2 上下文优化

上下文处理对 RAG 质量至关重要：

```typescript
// 上下文优化策略
function optimizeContext(searchResults: SearchResult[], query: string, maxTokens: number = 4000): string {
  // 1. 根据相关性排序
  const sortedResults = [...searchResults].sort((a, b) => b.similarity - a.similarity);
  
  // 2. 提取相关段落
  const extractedParagraphs = sortedResults.map(result => {
    const paragraphs = result.content.split('\n\n');
    return paragraphs.map(p => ({
      text: p,
      score: calculateRelevance(p, query)
    }));
  }).flat();
  
  // 3. 按相关性排序段落
  extractedParagraphs.sort((a, b) => b.score - a.score);
  
  // 4. 组装上下文，控制总长度
  let context = '';
  let tokenCount = 0;
  
  for (const para of extractedParagraphs) {
    const paraTokens = estimateTokens(para.text);
    if (tokenCount + paraTokens > maxTokens) break;
    
    context += para.text + '\n\n';
    tokenCount += paraTokens;
  }
  
  return context;
}
```

### 7.3 提示词优化

Blinko 针对不同类型的查询使用不同的提示词模板：

```typescript
// 提示词模板选择
function selectPromptTemplate(query: string, context: string): string {
  // 分析查询类型
  if (isFactualQuery(query)) {
    return factualTemplate(query, context);
  } else if (isSummaryRequest(query)) {
    return summaryTemplate(query, context);
  } else if (isComparisonQuery(query)) {
    return comparisonTemplate(query, context);
  } else {
    return defaultTemplate(query, context);
  }
}

// 不同类型的提示词模板
function factualTemplate(query: string, context: string): string {
  return `你是 Blinko 的 AI 助手。基于下面的信息回答用户的事实性问题。
如果信息中没有明确答案，请说明你不知道。

信息：
${context}

问题：${query}

回答：`;
}
```

## 8. RAG 实际应用

### 8.1 智能问答

Blinko 的智能问答功能使用 RAG 系统：

```typescript
// server/routerTrpc/ai.ts
// tRPC AI 问答端点
export const aiAsk = authProcedure
  .input(
    z.object({
      query: z.string(),
    })
  )
  .mutation(async ({ ctx, input }) => {
    try {
      const { query } = input;
      const { user } = ctx;
      
      // 使用 RAG 系统回答问题
      const answer = await AiService.askQuestion({
        query,
        accountId: user.id,
      });
      
      return { ok: true, answer };
    } catch (error) {
      return { ok: false, error };
    }
  });
```

### 8.2 相关笔记推荐

基于 RAG 系统实现的相关笔记推荐功能：

```typescript
// server/aiServer/index.ts
// 获取相关笔记
static async getRelatedNotes({ noteId, content }) {
  try {
    const { accountId } = await prisma.notes.findUnique({
      where: { id: noteId },
      select: { accountId: true }
    });
    
    // 使用 RAG 系统查找相关笔记
    const { notes } = await AiModelFactory.queryVector(content, accountId, 5);
    
    // 过滤掉当前笔记
    const relatedNotes = notes.filter(note => note.id !== noteId);
    
    return { ok: true, notes: relatedNotes };
  } catch (error) {
    return { ok: false, error };
  }
}
```

### 8.3 智能标签生成

使用专用 Agent 实现标签生成：

```typescript
// server/aiServer/index.ts
// 生成笔记标签
static async generateTags({ content, noteId }) {
  try {
    // 使用标签 Agent 生成标签
    const agent = await AiModelFactory.TagAgent();
    const result = await agent.run(content);
    
    // 解析标签结果
    const tags = result.output.split(',')
      .map(tag => tag.trim())
      .filter(tag => tag.length > 0);
    
    return { ok: true, tags };
  } catch (error) {
    return { ok: false, error };
  }
}
```

## 9. RAG 系统配置与扩展

### 9.1 配置项

Blinko 的 RAG 系统提供了多种配置选项：

```typescript
// RAG 系统配置项
interface RAGConfig {
  // 检索配置
  embeddingTopK: number;       // 检索数量
  embeddingScore: number;      // 相似度阈值
  
  // 重排序配置
  rerankModel: string;         // 重排序模型名称
  rerankTopK: number;          // 重排序数量
  rerankScore: number;         // 重排序阈值
  
  // 生成配置
  aiModel: string;             // 语言模型名称
  maxTokens: number;           // 最大生成 token 数
  temperature: number;         // 生成温度
}
```

### 9.2 扩展 RAG 系统

要扩展 Blinko 的 RAG 系统，可以：

1. **添加新的检索策略**：实现新的检索方法并集成到混合搜索中
2. **自定义提示词模板**：为特定查询类型创建专用提示词
3. **添加新的上下文处理**：实现更智能的上下文提取和优化方法
4. **集成外部知识源**：接入外部 API 或数据库扩充知识库

## 10. 相关代码参考

- `server/aiServer/aiModelFactory.ts`: AI 模型工厂和向量查询
- `server/aiServer/index.ts`: AI 服务核心功能
- `server/aiServer/tools/`: AI 工具实现
- `server/routerTrpc/ai.ts`: AI API 端点
- `server/jobs/rebuildEmbeddingJob.ts`: 向量索引管理 