/**
 * 通知模型
 */
export interface NotificationVO {
  id: number;
  title: string;
  content: string;
  type: 'system' | 'message' | 'like' | 'comment';
  isRead: boolean;
  createTime: string;
}

