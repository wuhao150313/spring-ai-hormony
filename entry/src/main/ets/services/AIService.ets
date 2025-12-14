import { HttpUtil } from '../utils/HttpUtil';
import { StreamHttpUtil } from '../utils/StreamHttpUtil';
import { Result } from '../models/Result';
import { AssistantResponse } from '../models/AssistantResponse';
import { ReviewResult } from '../models/ReviewResult';
import { ChatHistoryResponse } from '../models/ChatHistoryResponse';
import { QuestionRequest } from '../models/QuestionRequest';
import { AdvancedChatRequest } from '../models/AdvancedChatRequest';
import { ModelRequest } from '../models/ModelRequest';
import { ImageAnalyzeRequest } from '../models/ImageAnalyzeRequest';
import { CourseRecommendRequest } from '../models/CourseRecommendRequest';
import { HomeworkReviewRequest } from '../models/HomeworkReviewRequest';
import { SummaryRequest } from '../models/SummaryRequest';

/**
 * AI 服务
 */
export class AIService {
  /**
   * Agent 简单对话（无记忆）
   */
  static async simpleChat(question: string): Promise<string> {
    const params: QuestionRequest = { question };
    const response = await HttpUtil.get<string>('/api/v1/chat', params);
    if (typeof response.data === 'string') {
      return response.data;
    }
    return JSON.stringify(response.data);
  }

  /**
   * Agent 高级对话（有记忆）
   */
  static async advancedChat(userId: string, message: string): Promise<Result<AssistantResponse>> {
    const request: AdvancedChatRequest = {
      userId,
      message
    };
    return await HttpUtil.post<AssistantResponse>('/api/v2/chat', request);
  }

  /**
   * 获取对话历史
   */
  static async getChatHistory(userId: string): Promise<Result<ChatHistoryResponse>> {
    return await HttpUtil.get<ChatHistoryResponse>(`/api/v2/history/${userId}`);
  }

  /**
   * AI 问答
   */
  static async askQuestion(question: string): Promise<string> {
    const params: QuestionRequest = { question };
    const response = await HttpUtil.get<string>('/ai/qna/ask', params);
    if (typeof response.data === 'string') {
      return response.data;
    }
    return JSON.stringify(response.data);
  }

  /**
   * 流式问答
   * 
   * @param question 问题
   * @param onChunk 接收到数据块时的回调函数 (chunk: string) => void
   * @param onComplete 流式响应完成时的回调函数 (fullText: string) => void
   * @param onError 发生错误时的回调函数 (error: Error) => void
   */
  static async askQuestionStream(
    question: string,
    onChunk?: (chunk: string) => void,
    onComplete?: (fullText: string) => void,
    onError?: (error: Error) => void
  ): Promise<void> {
    const params: QuestionRequest = { question };
    return await StreamHttpUtil.createStreamRequest(
      '/ai/qna/ask/stream',
      params,
      onChunk,
      onComplete,
      onError
    );
  }

  /**
   * 联网搜索
   */
  static async webSearch(question: string): Promise<string> {
    const params: QuestionRequest = { question };
    const response = await HttpUtil.get<string>('/ai/qna/web-search', params);
    if (typeof response.data === 'string') {
      return response.data;
    }
    return JSON.stringify(response.data);
  }

  /**
   * 切换模型
   */
  static async switchModel(model: string): Promise<string> {
    const params: ModelRequest = { model };
    const response = await HttpUtil.get<string>('/ai/qna/switch-model', params);
    if (typeof response.data === 'string') {
      return response.data;
    }
    return JSON.stringify(response.data);
  }

  /**
   * 图片分析（URL）
   */
  static async analyzeImageByUrl(prompt: string, imageUrl: string): Promise<string> {
    const params: ImageAnalyzeRequest = { prompt, imageUrl };
    const response = await HttpUtil.get<string>('/ai/qna/image/analyze/url', params);
    if (typeof response.data === 'string') {
      return response.data;
    }
    return JSON.stringify(response.data);
  }

  /**
   * 课程推荐
   */
  static async recommendCourses(userLevel: string, completedCourses: string[]): Promise<Result<string[]>> {
    const request: CourseRecommendRequest = {
      userLevel,
      completedCourses
    };
    return await HttpUtil.post<string[]>('/ai/recommend/courses', request);
  }

  /**
   * 作业批改
   */
  static async reviewHomework(taskDescription: string, studentAnswer: string): Promise<Result<ReviewResult>> {
    const request: HomeworkReviewRequest = {
      taskDescription,
      studentAnswer
    };
    return await HttpUtil.post<ReviewResult>('/ai/homework/review', request);
  }

  /**
   * 课程总结
   */
  static async summarizeCourse(courseContent: string): Promise<Result<string>> {
    const request: SummaryRequest = {
      courseContent
    };
    return await HttpUtil.post<string>('/ai/summary/course', request);
  }

  /**
   * 生成思维导图
   */
  static async generateMindMap(courseContent: string): Promise<Result<string>> {
    const request: SummaryRequest = {
      courseContent
    };
    return await HttpUtil.post<string>('/ai/summary/mindmap', request);
  }
}

