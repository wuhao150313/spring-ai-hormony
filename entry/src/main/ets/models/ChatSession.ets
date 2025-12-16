import { ChatMessage } from './ChatMessage';

/**
 * 聊天会话模型
 */
export interface ChatSession {
  id: number;
  title: string;
  userId: number;
  modelName: string;
  status: boolean;  // 0-活跃，1-归档
  lastMessage: string | null;
  lastMessageTime: string | null;  // ISO 8601 格式
  createTime: string;
  updateTime: string;
  star?: boolean;  // 收藏状态（可选，后端返回0/1）
  messages?: ChatMessage[];
}

