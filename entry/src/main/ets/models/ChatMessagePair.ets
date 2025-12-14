import { ChatMessage } from './ChatMessage';

/**
 * 聊天消息对（用户消息和AI回复）
 */
export interface ChatMessagePair {
  userMessage: ChatMessage;
  aiMessage: ChatMessage;
}

