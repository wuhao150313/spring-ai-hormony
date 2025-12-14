/**
 * 常量定义
 */
export class Constants {
  // API 基础地址 - 请根据实际后端地址修改
  static readonly BASE_URL = 'http://192.168.80.1:8081/api-template';
  
  // 消息角色
  static readonly ROLE_USER = 'user';
  static readonly ROLE_ASSISTANT = 'assistant';
  static readonly ROLE_SYSTEM = 'system';
  
  // 消息状态
  static readonly STATUS_SENDING = 0;
  static readonly STATUS_COMPLETED = 1;
  static readonly STATUS_FAILED = 2;
  
  // 会话状态
  static readonly SESSION_ACTIVE = 0;
  static readonly SESSION_ARCHIVED = 1;
  
  // AI 模型
  static readonly MODEL_QWEN_MAX = 'qwen-max';
  static readonly MODEL_QWEN_PLUS = 'qwen-plus';
  static readonly MODEL_QWEN_TURBO = 'qwen-turbo';
  
  // 存储键名
  static readonly STORAGE_KEY_USER_ID = 'userId';
  static readonly STORAGE_KEY_TOKEN = 'token';
  static readonly STORAGE_KEY_THREAD_ID = 'threadId';
  static readonly STORAGE_KEY_USER_INFO = 'userInfo';
  
  // DashScope知识库配置
  static readonly DASHSCOPE_BASE_URL = 'https://dashscope.aliyuncs.com';
  static readonly DASHSCOPE_APP_ID = '051414faae644e1ba08cd20ddb03d9f6'; // 默认APP_ID
  static readonly DASHSCOPE_WEATHER_APP_ID = 'c3dfa7059a144b18a4d72419757d0332'; // 天气查询助手应用ID
  static readonly DASHSCOPE_SCHOLARSHIP_APP_ID = '051414faae644e1ba08cd20ddb03d9f6'; // 助学政策助手应用ID
  static readonly DASHSCOPE_API_KEY = 'sk-fb85a2f8787e4d8bb8a6168b3b7bf653'; // 请替换为实际的API_KEY，或从环境变量/配置中读取

  /**
   * 根据agentId获取对应的APP_ID
   * @param agentId 智能体ID（可选）
   * @returns 对应的APP_ID常量
   */
  static getAppIdByAgentId(agentId?: number): string {
    if (agentId === 6) {
      return Constants.DASHSCOPE_WEATHER_APP_ID; // 天气查询助手
    } else if (agentId === 9) {
      return Constants.DASHSCOPE_SCHOLARSHIP_APP_ID; // 助学政策助手
    }
    // 其他智能体使用默认APP_ID
    return Constants.DASHSCOPE_APP_ID;
  }

  // 特殊问题关键词（用于判断是否需要特殊回答）
  static readonly SPECIAL_QUESTIONS = ['你是谁', '你是什么', '什么模型', '模型', 'who are you', 'what are you'];
}

