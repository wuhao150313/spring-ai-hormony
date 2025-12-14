import http from '@ohos.net.http';
import { Constants } from '../utils/Constants';
import { KnowledgeBaseRequest, KnowledgeBaseInput } from '../models/KnowledgeBaseRequest';
import { KnowledgeBaseResponse } from '../models/KnowledgeBaseResponse';
import { Result, ResultUtil } from '../models/Result';

/**
 * DashScope知识库服务
 */
export class KnowledgeBaseService {
  /**
   * 判断是否为特殊问题（模型相关、你是谁等）
   */
  static isSpecialQuestion(prompt: string): boolean {
    const lowerPrompt = prompt.toLowerCase();
    for (const keyword of Constants.SPECIAL_QUESTIONS) {
      if (lowerPrompt.includes(keyword.toLowerCase())) {
        return true;
      }
    }
    return false;
  }

  /**
   * 获取特殊问题的标准回答
   */
  static getSpecialAnswer(): string {
    return '您好，我是依托default模型的智能助手，在Cursor IDE中为您提供代码编写和问题解答服务，你可以直接告诉我你的需求。';
  }

  /**
   * 调用DashScope知识库API
   */
  static async queryKnowledgeBase(prompt: string, agentId?: number): Promise<Result<string>> {
    // 检查是否为特殊问题
    if (KnowledgeBaseService.isSpecialQuestion(prompt)) {
      return {
        code: 200,
        message: 'success',
        data: KnowledgeBaseService.getSpecialAnswer()
      };
    }

    return new Promise(async (resolve) => {
      try {
        const appId = Constants.getAppIdByAgentId(agentId);
        const url = `${Constants.DASHSCOPE_BASE_URL}/api/v1/apps/${appId}/completion`;
        
        const input: KnowledgeBaseInput = {
          prompt: prompt
        };
        
        const request: KnowledgeBaseRequest = {
          input: input,
          parameters: {},
          debug: {}
        };

        // 创建HTTP请求
        const httpRequest = http.createHttp();
        const headers: Record<string, string> = {
          'Authorization': `Bearer ${Constants.DASHSCOPE_API_KEY}`,
          'Content-Type': 'application/json'
        };

        const requestOptions: http.HttpRequestOptions = {
          method: http.RequestMethod.POST,
          header: headers,
          connectTimeout: 60000,
          readTimeout: 60000,
          extraData: JSON.stringify(request)
        };

        console.info(`[KnowledgeBaseService] 调用知识库API: ${url}`);
        console.info(`[KnowledgeBaseService] 请求内容: ${prompt.substring(0, 100)}...`);

        httpRequest.request(url, requestOptions)
          .then((data: http.HttpResponse) => {
            httpRequest.destroy();
            try {
              const responseText = data.result.toString();
              console.info(`[KnowledgeBaseService] 响应状态: ${data.responseCode}, 响应内容: ${responseText.substring(0, 200)}`);

              if (data.responseCode === 200) {
                try {
                  const jsonData: Record<string, Object> = JSON.parse(responseText);
                  const kbResponse = jsonData as KnowledgeBaseResponse;
                  
                  // 提取回答内容
                  let answer = '';
                  if (kbResponse.output?.text) {
                    answer = kbResponse.output.text;
                  } else if (kbResponse.output?.choices && kbResponse.output.choices.length > 0) {
                    const firstChoice = kbResponse.output.choices[0];
                    if (firstChoice.message?.content) {
                      answer = firstChoice.message.content;
                    }
                  }

                  if (answer) {
                    resolve({
                      code: 200,
                      message: 'success',
                      data: answer
                    });
                  } else {
                    resolve({
                      code: -1,
                      message: '知识库返回格式异常',
                      data: ''
                    });
                  }
                } catch (e) {
                  console.error(`[KnowledgeBaseService] JSON解析失败:`, e);
                  resolve({
                    code: -1,
                    message: `JSON解析失败: ${JSON.stringify(e)}`,
                    data: ''
                  });
                }
              } else {
                resolve({
                  code: data.responseCode,
                  message: responseText || `HTTP Error: ${data.responseCode}`,
                  data: ''
                });
              }
            } catch (err) {
              console.error(`[KnowledgeBaseService] 响应处理异常:`, err);
              resolve({
                code: -1,
                message: `响应处理异常: ${JSON.stringify(err)}`,
                data: ''
              });
            }
          })
          .catch((err: Error) => {
            httpRequest.destroy();
            console.error(`[KnowledgeBaseService] 网络请求失败:`, err);
            resolve({
              code: -1,
              message: err.message || '网络请求失败',
              data: ''
            });
          });
      } catch (err) {
        console.error(`[KnowledgeBaseService] 请求构建异常:`, err);
        resolve({
          code: -1,
          message: `请求构建异常: ${JSON.stringify(err)}`,
          data: ''
        });
      }
    });
  }
}

