# FastEmbed 集成计划 (Mastra 方式)

## 背景

Blinko 当前使用 OpenAI、AzureOpenAI 等外部 API 或 Ollama 本地模型生成文本嵌入。这种方式对于自托管用户来说可能存在以下问题：
- 需要 API 密钥和额外成本
- 对网络连接的依赖
- 隐私问题
- 性能瓶颈

FastEmbed 是一个轻量级的、高性能的本地文本嵌入库，集成后可以提供无需外部 API 的嵌入功能，提升用户体验并降低使用门槛。Blinko 已经使用 Mastra 框架处理 AI 功能，因此我们将通过 Mastra 集成 FastEmbed。

## 目标

1. 将 FastEmbed 通过 Mastra 框架集成到 Blinko 作为默认的嵌入模型选项
2. 保持与现有嵌入 API 的兼容性，确保用户可以灵活选择
3. 优化向量存储和检索性能
4. 提供中英文双语支持的嵌入模型

## 实施计划

### 1. 依赖添加

```bash
# 安装 Mastra FastEmbed 及其依赖
cd server
bun add @mastra/fastembed
```

### 2. 创建 FastEmbed 提供者

**创建文件：`server/aiServer/providers/fastEmbed.ts`**

```typescript
import { AiBaseModelProvider } from '.';
import { ProviderV1, EmbeddingModelV1 } from '@ai-sdk/provider';
import { createFastEmbed } from '@mastra/fastembed';

export class FastEmbedModelProvider extends AiBaseModelProvider {
  private embeddingModel: EmbeddingModelV1<string> | null = null;
  private modelName: string;
  
  constructor({ globalConfig }) {
    super({ globalConfig });
    this.modelName = globalConfig.fastEmbedModel || 'BAAI/bge-small-en-v1.5';
  }

  protected createProvider(): ProviderV1 {
    // FastEmbed 通过 Mastra 集成，不使用标准 ProviderV1 接口
    // 返回一个空的提供者，实际嵌入功能通过 getEmbeddings 方法提供
    return {} as ProviderV1;
  }

  protected getLLM() {
    // FastEmbed 不提供 LLM 功能
    throw new Error('FastEmbed provider does not support LLM');
  }

  // 覆盖基类的 getEmbeddings 方法
  protected getEmbeddings(): EmbeddingModelV1<string> {
    if (!this.embeddingModel) {
      this.embeddingModel = createFastEmbed({
        modelName: this.modelName,
        useGPU: this.globalConfig.useGPU || false,
        quantize: this.globalConfig.quantize || true,
        dimensions: this.getDimensions(),
        cache: this.globalConfig.useCache || true
      });
    }
    return this.embeddingModel;
  }

  private getDimensions(): number {
    // 根据模型名称返回维度
    const modelName = this.modelName.toLowerCase();
    if (modelName.includes('bge-small')) {
      return 384;
    } else if (modelName.includes('bge-base')) {
      return 768;
    } else if (modelName.includes('bge-large')) {
      return 1024;
    } else if (modelName.includes('multilingual')) {
      return 768;
    } else {
      // 默认维度
      return 384;
    }
  }
}
```

### 3. 修改 AI 模型工厂

**修改文件：`server/aiServer/aiModelFactory.ts`**

```typescript
// 添加 FastEmbed 导入
import { FastEmbedModelProvider } from './providers/fastEmbed';

// 修改 GetProvider 方法
static async GetProvider() {
  const globalConfig = await AiModelFactory.ValidConfig();

  return cache.wrap(
    `GetProvider-
    ${globalConfig.aiModelProvider}-
    ${globalConfig.aiApiKey}-
    ${globalConfig.embeddingModel}-
    ${globalConfig.embeddingApiKey}-
    ${globalConfig.aiModel}-
    ${globalConfig.aiApiEndpoint}-
    ${globalConfig.embeddingTopK}-
    ${globalConfig.embeddingScore}-
    ${globalConfig.isUseHttpProxy}-
    ${globalConfig.httpProxyHost}-
    ${globalConfig.httpProxyPort}-
    ${globalConfig.httpProxyPassword}-
    ${globalConfig.httpProxyUsername}-
    ${globalConfig.fastEmbedModel || ''}
    `,
    async () => {
      const createProviderResult = async (provider: any) => ({
        LLM: (await provider.LLM()) as LanguageModelV1,
        VectorStore: (await provider.VectorStore()) as LibSQLVector,
        Embeddings: (await provider.Embeddings()) as EmbeddingModelV1<string>,
        MarkdownSplitter: provider.MarkdownSplitter() as MarkdownTextSplitter,
        TokenTextSplitter: provider.TokenTextSplitter() as TokenTextSplitter,
        provider,
      });

      // 添加 FastEmbed 条件
      switch (globalConfig.aiModelProvider) {
        case 'FastEmbed':
          return createProviderResult(new FastEmbedModelProvider({ globalConfig }));
        case 'OpenAI':
          return createProviderResult(new OpenAIModelProvider({ globalConfig }));
        case 'AzureOpenAI':
          return createProviderResult(new AzureOpenAIModelProvider({ globalConfig }));
        // 其他现有 case...
      }
    }
  );
}

// 修改 rebuildVectorIndex 方法，添加 FastEmbed 的维度处理
static async rebuildVectorIndex({ vectorStore, isDelete = false }: { vectorStore: LibSQLVector; isDelete?: boolean }) {
  try {
    if (isDelete) {
      await vectorStore.deleteIndex('blinko');
    }
  } catch (error) {
    console.error('delete vector index failed:', error);
  }

  const config = await AiModelFactory.globalConfig();
  const model = config.embeddingModel?.toLowerCase() || 'text-embedding-3-small';
  let userConfigDimensions = config.embeddingDimensions;
  let dimensions: number = 0;
  
  // 添加 FastEmbed 模型的维度处理
  if (config.aiModelProvider === 'FastEmbed') {
    const fastEmbedModel = config.fastEmbedModel?.toLowerCase() || 'bge-small-en-v1.5';
    if (fastEmbedModel.includes('bge-small')) {
      dimensions = 384;
    } else if (fastEmbedModel.includes('bge-base')) {
      dimensions = 768;
    } else if (fastEmbedModel.includes('bge-large')) {
      dimensions = 1024;
    } else if (fastEmbedModel.includes('multilingual')) {
      dimensions = 768;
    } else {
      dimensions = 384; // 默认维度
    }
  } else {
    // 原有的维度处理逻辑
    switch (true) {
      case model.includes('text-embedding-3-small'):
        dimensions = 1536;
        break;
      // ...其他现有 case
    }
  }
  
  // 用户配置的维度优先
  if (userConfigDimensions != 0 && userConfigDimensions != undefined) {
    dimensions = userConfigDimensions;
  }
  
  await vectorStore.createIndex('blinko', dimensions, 'cosine');
}
```

### 4. 更新配置模型和接口

**修改文件：`server/aiServer/aiModelFactory.d.ts`**

```typescript
// 在 GlobalConfig 接口中添加 FastEmbed 相关配置
interface GlobalConfig {
  // ...现有配置
  fastEmbedModel?: string;
  useGPU?: boolean;
  quantize?: boolean;
  useCache?: boolean;
}
```

### 5. 更新用户界面

**创建/修改文件：`app/src/components/BlinkoSettings/EmbeddingSettings.tsx`**

添加 FastEmbed 的配置界面，包括：
- 模型选择（支持 BAAI/bge-small-en-v1.5、BAAI/bge-base-en-v1.5、BAAI/bge-large-en-v1.5）
- 中文模型支持（BAAI/bge-small-zh-v1.5）
- GPU 加速选项
- 模型量化选项
- 模型缓存选项

### 6. 数据库更新

**创建迁移文件，更新配置表以支持 FastEmbed 设置**

```sql
-- 在 config 表中添加新的配置字段
ALTER TABLE config 
ADD COLUMN IF NOT EXISTS fastEmbedModel VARCHAR DEFAULT 'BAAI/bge-small-en-v1.5',
ADD COLUMN IF NOT EXISTS useGPU BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS quantize BOOLEAN DEFAULT TRUE,
ADD COLUMN IF NOT EXISTS useCache BOOLEAN DEFAULT TRUE;
```

### 7. 集成 Mastra RAG 功能

利用 Mastra 的 RAG 功能增强文本检索：

```typescript
// 在 server/aiServer/index.ts 中
import { createRAG } from '@mastra/rag';

// 创建 RAG 增强查询功能
async function enhancedSearch(query: string, accountId: number) {
  const { VectorStore, Embeddings, LLM } = await AiModelFactory.GetProvider();
  
  const rag = createRAG({
    llm: LLM,
    embeddings: Embeddings,
    vectorStore: VectorStore,
    indexName: 'blinko',
    options: {
      topK: 5,
      threshold: 0.6,
      reranker: true
    }
  });
  
  const results = await rag.query({
    query,
    filter: { accountId }
  });
  
  return results;
}
```

### 8. 默认配置与迁移策略

1. 为新安装用户设置 FastEmbed 为默认嵌入提供者
2. 为现有用户提供迁移指南
3. 添加重建嵌入索引的功能，以支持从其他模型切换到 FastEmbed

### 9. 文档更新

1. 更新开发文档，说明基于 Mastra 的 FastEmbed 集成
2. 更新用户指南，介绍 FastEmbed 的优势和使用方法
3. 提供故障排除指南

### 10. 测试计划

1. 单元测试
   - Mastra FastEmbed 提供者的嵌入功能
   - 嵌入维度处理逻辑
   - 配置切换和持久化

2. 集成测试
   - 与向量数据库的交互
   - 嵌入和检索的准确性
   - 与现有 AI 功能的兼容性
   - Mastra RAG 功能测试

3. 性能测试
   - 与 OpenAI 和 Ollama 的性能对比
   - 内存使用和 CPU/GPU 利用率
   - 响应时间和吞吐量
   - 缓存效果测试

### 11. 部署计划

1. 在开发环境测试
2. 在测试环境验证
3. 在生产环境部署
4. 监控性能和用户反馈

## 时间线

1. 依赖添加和基础集成：1天
2. FastEmbed 提供者实现：2天
3. AI 模型工厂修改：2天
4. Mastra RAG 集成：2天
5. 用户界面更新：2天
6. 测试和修复：3天
7. 文档编写：1天
8. 部署和监控：1天

**总计：约14天**

## 预期结果

1. 提供无需外部 API 的本地嵌入功能
2. 降低 Blinko 的使用门槛
3. 提高搜索响应速度
4. 保护用户数据隐私
5. 支持离线操作
6. 与 Mastra 框架的完美集成

## 风险与缓解措施

1. **性能问题**：在低端设备上可能性能不佳
   - 缓解：提供模型量化选项，允许用户选择较小的模型
   - 缓解：启用缓存机制减少重复计算

2. **兼容性问题**：与现有嵌入不兼容
   - 缓解：提供重建嵌入索引的功能，保留使用外部 API 的选项
   - 缓解：使用 Mastra 的兼容层确保 API 一致性

3. **准确性问题**：FastEmbed 模型的准确性可能不如商业 API
   - 缓解：提供不同模型选项，允许用户权衡速度和准确性
   - 缓解：利用 Mastra RAG 提高检索质量

4. **依赖问题**：TensorFlow.js 依赖可能较大
   - 缓解：实现懒加载策略，只在需要时加载模型
   - 缓解：使用 Mastra 的优化实现，减少依赖影响 