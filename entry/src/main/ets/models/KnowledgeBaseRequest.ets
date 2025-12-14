/**
 * DashScope知识库请求输入模型
 */
export interface KnowledgeBaseInput {
  prompt: string;
}

/**
 * DashScope知识库请求模型
 */
export interface KnowledgeBaseRequest {
  input: KnowledgeBaseInput;
  parameters?: Record<string, Object>;
  debug?: Record<string, Object>;
}

