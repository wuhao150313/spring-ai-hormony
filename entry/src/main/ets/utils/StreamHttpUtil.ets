import http from '@ohos.net.http';
import { Constants } from './Constants';
import { StorageUtil } from './StorageUtil';

/** SSE 解析结果 */
interface ParseResult {
  chunks: string[];
  fullText: string;
}

/** HTTP Header 结构 */
interface HttpHeaders {
  Accept: string;
  'Cache-Control': string;
  Authorization?: string;
}

export class StreamHttpUtil {

  /**
   * SDK20: 将对象转换为查询参数字符串
   * 使用JSON序列化和正则表达式解析，完全避免索引访问和受限的标准库
   */
  private static objectToQueryString(params: Record<string, string> | object): string {
    let result: string[] = [];
    // SDK20: 使用JSON方式转换，通过正则表达式解析避免索引访问
    try {
      // 将对象转换为JSON字符串
      let jsonStr: string = JSON.stringify(params);
      // 使用正则表达式匹配键值对，正确处理包含逗号的字符串值
      // 匹配模式: "key": "value" 或 "key": value
      let regex: RegExp = /"([^"]+)":\s*("([^"]*)"|([^,}]+))/g;
      let match: RegExpExecArray | null;
      
      while ((match = regex.exec(jsonStr)) !== null) {
        let key: string = match[1];
        // 值可能是带引号的字符串或非字符串值
        let value: string = match[3] !== undefined ? match[3] : match[4];
        if (value !== undefined) {
          result.push(encodeURIComponent(key) + '=' + encodeURIComponent(value.trim()));
        }
      }
    } catch (e) {
      console.error('[StreamHttpUtil] objectToQueryString error:', e);
    }

    return result.join('&');
  }

  private static extractSseContent(line: string): string {
    let t: string = line.trim();
    if (t.startsWith('data: ')) {
      return t.substring(6).trim();
    }
    if (t.startsWith('data:')) {
      return t.substring(5).trim();
    }
    return t;
  }

  private static parseToChunks(text: string): ParseResult {
    let lines: string[] = text.split('\n');
    let chunks: string[] = [];
    let fullText: string = '';
    let hasSse: boolean = false;

    for (let i = 0; i < lines.length; i++) {
      let line: string = lines[i].trim();
      if (!line) continue;

      if (line.startsWith('data:')) {
        hasSse = true;
        let content: string = StreamHttpUtil.extractSseContent(line);
        if (!content || content === '[DONE]') continue;

        chunks.push(content);
        fullText += content;
      }
    }

    if (!hasSse && text.trim()) {
      chunks.push(text.trim());
      fullText = text.trim();
    }

    return {
      chunks: chunks,
      fullText: fullText
    };
  }

  /**
   * SDK20: 创建流式请求
   * @param url 请求URL
   * @param params 查询参数对象（可以是任何对象类型）
   * @param onChunk 接收到数据块时的回调
   * @param onComplete 流式响应完成时的回调
   * @param onError 发生错误时的回调
   */
  static async createStreamRequest(
    url: string,
    params: Record<string, string> | object,
    onChunk?: (chunk: string) => void,
    onComplete?: (fullText: string) => void,
    onError?: (error: Error) => void
  ): Promise<void> {

    let request: http.HttpRequest | null = null;

    try {
      let fullUrl: string = Constants.BASE_URL + url;
      if (params && Object.keys(params).length > 0) {
        fullUrl += '?' + StreamHttpUtil.objectToQueryString(params);
      }

      request = http.createHttp();

      let headers: HttpHeaders = {
        Accept: 'text/event-stream',
        'Cache-Control': 'no-cache'
      };

      let token: string | null = await StorageUtil.getToken();
      if (token) {
        headers.Authorization = 'Bearer ' + token;
      }

      let response: http.HttpResponse = await request.request(fullUrl, {
        method: http.RequestMethod.GET,
        header: headers,
        connectTimeout: 60000,
        readTimeout: 120000
      });

      if (!response.result) {
        if (onError) onError(new Error('Empty response'));
        return;
      }

      let responseText: string = response.result.toString();
      let parsed: ParseResult = StreamHttpUtil.parseToChunks(responseText);

      // 🔥 关键：逐条触发 onChunk，UI 才会动
      if (onChunk) {
        for (let i = 0; i < parsed.chunks.length; i++) {
          onChunk(parsed.chunks[i]);
        }
      }

      if (onComplete) {
        onComplete(parsed.fullText);
      }

    } catch (e) {
      let err: Error = e instanceof Error ? e : new Error(JSON.stringify(e));
      if (onError) onError(err);
    } finally {
      if (request) {
        try {
          request.destroy();
        } catch (_) {}
      }
    }
  }
}
