import http from '@ohos.net.http';
import { Constants } from './Constants';
import { Result } from '../models/Result';
import { StorageUtil } from './StorageUtil';

/**
 * HTTP 请求工具类
 */
export class HttpUtil {
  /**
   * GET 请求
   */
  static async get<T>(url: string, params?: Record<string, string> | object): Promise<Result<T>> {
    return HttpUtil.request<T>('GET', url, params);
  }

  /**
   * POST 请求
   */
  static async post<T>(url: string, body?: object, params?: Record<string, string> | object): Promise<Result<T>> {
    return HttpUtil.request<T>('POST', url, params, body);
  }

  /**
   * PUT 请求
   */
  static async put<T>(url: string, body?: object, params?: Record<string, string> | object): Promise<Result<T>> {
    return HttpUtil.request<T>('PUT', url, params, body);
  }

  /**
   * DELETE 请求
   */
  static async delete<T>(url: string, params?: Record<string, string> | object): Promise<Result<T>> {
    return HttpUtil.request<T>('DELETE', url, params);
  }

  /**
   * 将对象转换为查询参数字符串
   */
  private static objectToQueryString(params: Record<string, string> | object): string {
    const paramsRecord: Record<string, string> = {};
    const keys = Object.keys(params);
    for (const key of keys) {
      const value = (params as Record<string, Object>)[key];
      if (value !== null && value !== undefined) {
        paramsRecord[key] = String(value);
      }
    }
    return Object.keys(paramsRecord)
      .map(key => `${encodeURIComponent(key)}=${encodeURIComponent(paramsRecord[key])}`)
      .join('&');
  }

  /**
   * 通用请求方法
   */
  private static async request<T>(
    method: string,
    url: string,
    params?: Record<string, string> | object,
    body?: object
  ): Promise<Result<T>> {
    return new Promise(async (resolve, reject) => {
      try {
        // 构建完整URL
        let fullUrl = `${Constants.BASE_URL}${url}`;
        if (params && Object.keys(params).length > 0) {
          const queryString = HttpUtil.objectToQueryString(params);
          fullUrl += `?${queryString}`;
        }

        // 创建请求
        const httpRequest = http.createHttp();
        const headers: Record<string, string> = {
          'Content-Type': 'application/json'
        };

        // 添加Token（如果需要）
        const token = await StorageUtil.getToken();
        if (token) {
          headers['Authorization'] = `Bearer ${token}`;
        }

        const requestOptions: http.HttpRequestOptions = {
          method: method as http.RequestMethod,
          header: headers,
          connectTimeout: 60000,
          readTimeout: 60000
        };

        // 添加请求体
        if (body) {
          requestOptions.extraData = JSON.stringify(body);
        }

        // 发送请求
        httpRequest.request(fullUrl, requestOptions)
          .then((data: http.HttpResponse) => {
            httpRequest.destroy();
            try {
              const responseText = data.result.toString();
              console.info(`[HttpUtil] ${method} ${fullUrl} - Status: ${data.responseCode}, Response: ${responseText.substring(0, 200)}`);
              
              // 尝试解析JSON
              try {
                const jsonData: Record<string, Object> = JSON.parse(responseText);
                // 如果后端返回的是统一Result格式
                if (jsonData.code !== undefined) {
                  const result: Result<T> = {
                    code: jsonData.code as number,
                    message: jsonData.message as string,
                    data: jsonData.data as T
                  };
                  resolve(result);
                } else {
                  // 如果后端直接返回数据，包装成Result
                  const result: Result<T> = {
                    code: data.responseCode === 200 ? 200 : data.responseCode,
                    message: data.responseCode === 200 ? 'success' : `HTTP ${data.responseCode}`,
                    data: jsonData as T
                  };
                  resolve(result);
                }
              } catch (e) {
                // 如果不是JSON，根据状态码处理
                if (data.responseCode === 200) {
                  const result: Result<T> = {
                    code: 200,
                    message: 'success',
                    data: responseText as T
                  };
                  resolve(result);
                } else {
                  const result: Result<T> = {
                    code: data.responseCode,
                    message: responseText || `HTTP Error: ${data.responseCode}`,
                    data: null as T
                  };
                  resolve(result);
                }
              }
            } catch (err) {
              const result: Result<T> = {
                code: -1,
                message: `Parse error: ${JSON.stringify(err)}`,
                data: null as T
              };
              resolve(result);
            }
          })
          .catch((err: Error) => {
            httpRequest.destroy();
            console.error(`[HttpUtil] ${method} ${fullUrl} - Network error:`, err);
            const result: Result<T> = {
              code: -1,
              message: err.message || 'Network error',
              data: null as T
            };
            resolve(result);
          });
      } catch (err) {
        reject({
          code: -1,
          message: JSON.stringify(err),
          data: null
        });
      }
    });
  }

}

