import { HttpUtil } from '../utils/HttpUtil';
import { Result } from '../models/Result';
import { ChatMessage } from '../models/ChatMessage';
import { ChatMessagePair } from '../models/ChatMessagePair';
import { AIService } from './AIService';
import { StorageUtil } from '../utils/StorageUtil';
import { ResultUtil } from '../models/Result';
import { AssistantResponse } from '../models/AssistantResponse';
import { MessageService } from './MessageService';
import { KnowledgeBaseService } from './KnowledgeBaseService';

/**
 * 聊天服务
 */
export class ChatService {
  /**
   * 发送消息并获取AI回复
   */
  static async sendMessageAndGetReply(
    sessionId: number,
    content: string,
    modelName: string,
    useKnowledgeBase: boolean = false
  ): Promise<ChatMessagePair> {
    console.info(`[ChatService] 发送消息，sessionId: ${sessionId}, content: ${content.substring(0, 50)}...`);

    // 获取userId
    const userId = await StorageUtil.getUserId();
    if (!userId) {
      throw new Error('用户未登录，请先登录');
    }

    // 先保存用户消息到后端（即便后续AI失败也要落表）
    let userMessage: ChatMessage;
    try {
      console.info(`[ChatService] 保存用户消息到后端...`);
      const userMessageResult = await MessageService.saveUserMessage(
        sessionId,
        content,
        modelName,
        false
      );
      if (ResultUtil.isSuccess(userMessageResult) && userMessageResult.data) {
        userMessage = userMessageResult.data;
        console.info(`[ChatService] 用户消息保存成功，ID: ${userMessage.id}`);
      } else {
        console.warn(`[ChatService] 用户消息保存失败，使用临时消息: ${ResultUtil.getErrorMessage(userMessageResult)}`);
        userMessage = {
          id: Date.now(),
          sessionId: sessionId,
          userId: parseInt(userId) || 0,
          role: 'user',
          content: content,
          modelName: modelName,
          tokens: null,
          hasThinking: false,
          thinkingContent: null,
          webSearch: false,
          status: true,
          createTime: new Date().toISOString(),
          updateTime: new Date().toISOString()
        };
      }
    } catch (err) {
      console.error(`[ChatService] 保存用户消息异常:`, err);
      userMessage = {
        id: Date.now(),
        sessionId: sessionId,
        userId: parseInt(userId) || 0,
        role: 'user',
        content: content,
        modelName: modelName,
        tokens: null,
        hasThinking: false,
        thinkingContent: null,
        webSearch: false,
        status: true,
        createTime: new Date().toISOString(),
        updateTime: new Date().toISOString()
      };
    }

    // 再调用AI/知识库；失败则把错误文本当作AI回复保存
    let aiReply = '';
    let aiResponse: AssistantResponse | null = null;
    try {
      if (useKnowledgeBase) {
        console.info(`[ChatService] 尝试调用知识库API，message: ${content.substring(0, 100)}`);
        const kbResult = await KnowledgeBaseService.queryKnowledgeBase(content);
        if (ResultUtil.isSuccess(kbResult) && kbResult.data) {
          aiReply = kbResult.data;
          aiResponse = {
            userId: userId,
            threadId: null,
            answer: aiReply,
            suggestion: '请根据你的需求，给出一个建议',
            type: 'general',
            needsFurtherHelp: false
          };
          console.info(`[ChatService] 知识库回复成功，长度: ${aiReply.length}`);
        } else {
          throw new Error(ResultUtil.getErrorMessage(kbResult) || '知识库调用失败');
        }
      } else {
        console.info(`[ChatService] 调用AI服务，userId: ${userId}, message: ${content.substring(0, 100)}`);
        const result = await AIService.advancedChat(userId, content);
        console.info(`[ChatService] AI服务响应:`, JSON.stringify(result).substring(0, 200));
        if (ResultUtil.isSuccess(result)) {
          aiResponse = result.data;
          if (aiResponse && aiResponse.answer) {
            aiReply = aiResponse.answer;
            console.info(`[ChatService] AI回复成功，长度: ${aiReply.length}`);
          } else {
            throw new Error('AI没有返回有效回复');
          }
        } else {
          throw new Error(ResultUtil.getErrorMessage(result) || 'AI服务调用失败');
        }
      }
    } catch (err) {
      console.error(`[ChatService] AI服务异常，使用错误提示作为回复:`, err);
      aiReply = err instanceof Error ? err.message : JSON.stringify(err);
      aiResponse = null;
    }

    // 保存AI回复消息到后端（即便AI失败也写入错误信息）
    let aiMessage: ChatMessage;
    try {
      console.info(`[ChatService] 保存AI回复消息到后端...`);
      const aiMessageResult = await MessageService.saveAssistantMessage(
        sessionId,
        aiReply,
        modelName,
        undefined,
        aiResponse?.needsFurtherHelp || false,
        undefined,
        false
      );
      if (ResultUtil.isSuccess(aiMessageResult) && aiMessageResult.data) {
        aiMessage = aiMessageResult.data;
        console.info(`[ChatService] AI消息保存成功，ID: ${aiMessage.id}`);
      } else {
        // 如果保存失败，创建临时消息对象
        console.warn(`[ChatService] AI消息保存失败，使用临时消息: ${ResultUtil.getErrorMessage(aiMessageResult)}`);
        aiMessage = {
          id: Date.now() + 1,
          sessionId: sessionId,
          userId: parseInt(userId) || 0,
          role: 'assistant',
          content: aiReply,
          modelName: modelName,
          tokens: null,
          hasThinking: aiResponse?.needsFurtherHelp || false,
          thinkingContent: null,
          webSearch: false,
          status: true,
          createTime: new Date().toISOString(),
          updateTime: new Date().toISOString()
        };
      }
    } catch (err) {
      console.error(`[ChatService] 保存AI消息异常:`, err);
      // 如果保存失败，创建临时消息对象
      aiMessage = {
        id: Date.now() + 1,
        sessionId: sessionId,
        userId: parseInt(userId) || 0,
        role: 'assistant',
        content: aiReply,
        modelName: modelName,
        tokens: null,
        hasThinking: aiResponse?.needsFurtherHelp || false,
        thinkingContent: null,
        webSearch: false,
        status: true,
        createTime: new Date().toISOString(),
        updateTime: new Date().toISOString()
      };
    }

    const result: ChatMessagePair = {
      userMessage: userMessage,
      aiMessage: aiMessage
    };
    
    console.info(`[ChatService] 消息处理完成，用户消息ID: ${userMessage.id}, AI消息ID: ${aiMessage.id}`);
    return result;
  }
}

