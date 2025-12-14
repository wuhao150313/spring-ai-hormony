/**
 * DashScope知识库响应消息模型
 */
export interface KnowledgeBaseMessage {
  role?: string;
  content?: string;
}

/**
 * DashScope知识库响应选择模型
 */
export interface KnowledgeBaseChoice {
  message?: KnowledgeBaseMessage;
}

/**
 * DashScope知识库响应输出模型
 */
export interface KnowledgeBaseOutput {
  text?: string;
  choices?: Array<KnowledgeBaseChoice>;
}

/**
 * DashScope知识库响应使用情况模型
 */
export interface KnowledgeBaseUsage {
  input_tokens?: number;
  output_tokens?: number;
  total_tokens?: number;
}

/**
 * DashScope知识库响应模型
 */
export interface KnowledgeBaseResponse {
  output?: KnowledgeBaseOutput;
  usage?: KnowledgeBaseUsage;
  request_id?: string;
}

