import { HttpUtil } from '../utils/HttpUtil';
import { Result } from '../models/Result';
import { ChatSession } from '../models/ChatSession';
import { CreateSessionRequest } from '../models/CreateSessionRequest';
import { UpdateSessionTitleRequest } from '../models/UpdateSessionTitleRequest';

/**
 * 会话服务
 */
export class SessionService {
  /**
   * 创建会话
   */
  static async createSession(title: string, modelName: string): Promise<Result<ChatSession>> {
    const request: CreateSessionRequest = {
      title,
      modelName
    };
    return await HttpUtil.post<ChatSession>('/api/chat/session/create', request);
  }

  /**
   * 获取会话列表
   */
  static async getSessionList(): Promise<Result<ChatSession[]>> {
    return await HttpUtil.get<ChatSession[]>('/api/chat/session/list');
  }

  /**
   * 获取会话详情
   */
  static async getSessionDetail(id: number): Promise<Result<ChatSession>> {
    return await HttpUtil.get<ChatSession>(`/api/chat/session/${id}`);
  }

  /**
   * 更新会话标题
   */
  static async updateSessionTitle(id: number, title: string): Promise<Result<ChatSession>> {
    const request: UpdateSessionTitleRequest = { title };
    return await HttpUtil.put<ChatSession>(`/api/chat/session/${id}/title`, request);
  }

  /**
   * 根据聊天内容自动更新会话标题
   */
  static async updateSessionTitleByContent(id: number): Promise<Result<ChatSession>> {
    return await HttpUtil.put<ChatSession>(`/api/chat/session/${id}/title/auto`, undefined);
  }

  /**
   * 更新会话收藏状态
   */
  static async updateSessionStar(id: number, star: boolean): Promise<Result<ChatSession>> {
    const params: Record<string, string> = {};
    params['star'] = star ? 'true' : 'false';
    return await HttpUtil.put<ChatSession>(`/api/chat/session/${id}/star`, undefined, params);
  }

  /**
   * 删除会话
   */
  static async deleteSession(id: number): Promise<Result<boolean>> {
    return await HttpUtil.delete<boolean>(`/api/chat/session/${id}`);
  }
}

