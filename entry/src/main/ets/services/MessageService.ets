import { HttpUtil } from '../utils/HttpUtil';
import { Result } from '../models/Result';
import { ChatMessage } from '../models/ChatMessage';
import { SendMessageRequest } from '../models/SendMessageRequest';
import { SaveMessageRequest } from '../models/SaveMessageRequest';

/**
 * 消息服务
 */
export class MessageService {
  /**
   * 保存用户消息
   */
  static async saveUserMessage(
    sessionId: number,
    content: string,
    modelName: string,
    webSearch: boolean = false
  ): Promise<Result<ChatMessage>> {
    const request: SendMessageRequest = {
      sessionId,
      modelName,
      content,
      webSearch
    };
    return await HttpUtil.post<ChatMessage>('/api/chat/message/user', request);
  }

  /**
   * 保存AI回复消息
   */
  static async saveAssistantMessage(
    sessionId: number,
    content: string,
    modelName: string,
    tokens?: number,
    hasThinking: boolean = false,
    thinkingContent?: string,
    webSearch: boolean = false
  ): Promise<Result<ChatMessage>> {
    const request: SaveMessageRequest = {
      sessionId,
      role: 'assistant',
      content,
      modelName,
      tokens,
      hasThinking,
      thinkingContent,
      webSearch
    };
    return await HttpUtil.post<ChatMessage>('/api/chat/message/assistant', request);
  }
}

