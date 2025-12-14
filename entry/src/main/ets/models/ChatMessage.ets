/**
 * 聊天消息模型
 */
export interface ChatMessage {
  id: number;
  sessionId: number;
  userId: number;
  role: 'system' | 'user' | 'assistant';
  content: string;
  modelName: string;
  tokens: number | null;
  hasThinking: boolean;
  thinkingContent: string | null;
  webSearch: boolean;
  status: boolean;  // 0-发送中，1-完成，2-失败
  createTime: string;
  updateTime: string;
}

