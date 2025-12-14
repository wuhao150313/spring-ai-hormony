/**
 * 发送消息请求
 */
export interface SendMessageRequest {
  sessionId: number;
  modelName: string;
  content: string;
  webSearch?: boolean;
  deepThinking?: boolean;
  longThinking?: boolean;
  attachments?: string[];
}

