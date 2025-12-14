/**
 * 保存消息请求
 */
export interface SaveMessageRequest {
  sessionId: number;
  role: string;
  content: string;
  modelName?: string;
  tokens?: number;
  hasThinking?: boolean;
  thinkingContent?: string;
  webSearch?: boolean;
}

