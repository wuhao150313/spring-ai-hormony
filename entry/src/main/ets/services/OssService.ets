import http from '@ohos.net.http';
import fs from '@ohos.file.fs';
import { Constants } from '../utils/Constants';
import { Result } from '../models/Result';
import { StorageUtil } from '../utils/StorageUtil';

/**
 * OSS 文件上传服务
 */
export class OssService {
  /**
   * 上传文件到OSS
   * @param fileUri 文件URI（HarmonyOS格式，如：file://... 或 internal://...）
   * @returns OSS文件URL
   */
  static async uploadFile(fileUri: string): Promise<Result<string>> {
    return new Promise(async (resolve) => {
      try {
        // 处理文件URI：去掉file://前缀（如果存在），否则直接使用
        let actualPath: string = fileUri;
        if (fileUri.startsWith('file://')) {
          actualPath = fileUri.substring(7);
          // HarmonyOS 返回的 file://media/... 可能缺少前导斜杠，补齐以便 fs 识别
          if (!actualPath.startsWith('/')) {
            actualPath = '/' + actualPath;
          }
        }
        console.info(`[OssService] 使用文件路径: ${actualPath}`);

        // 尝试读取文件信息（先路径，失败再直接用原URI）
        let file: fs.File;
        let fileSize: number;
        let stat: fs.Stat;

        try {
          file = fs.openSync(actualPath, fs.OpenMode.READ_ONLY);
          stat = fs.statSync(actualPath);
          fileSize = stat.size;
        } catch (pathErr) {
          console.warn(`[OssService] 路径打开失败，尝试用原URI: ${fileUri}, err: ${JSON.stringify(pathErr)}`);
          try {
            file = fs.openSync(fileUri, fs.OpenMode.READ_ONLY);
            stat = fs.statSync(fileUri);
            fileSize = stat.size;
            actualPath = fileUri;
          } catch (uriErr) {
            console.error(`[OssService] URI与路径都无法读取文件: ${fileUri}, err: ${JSON.stringify(uriErr)}`);
            const result: Result<string> = {
              code: -1,
              message: 'File read error: cannot open selected file',
              data: ''
            };
            resolve(result);
            return;
          }
        }
        
        // 读取文件内容
        const buffer: ArrayBuffer = new ArrayBuffer(fileSize);
        fs.readSync(file.fd, buffer);
        fs.closeSync(file);
        
        // 获取文件名（从actualPath或原始URI中提取）
        let fileName: string = actualPath.substring(actualPath.lastIndexOf('/') + 1);
        // 如果文件名包含查询参数或其他URI组件，需要清理
        if (fileName.includes('?')) {
          fileName = fileName.substring(0, fileName.indexOf('?'));
        }
        if (fileName.includes('#')) {
          fileName = fileName.substring(0, fileName.indexOf('#'));
        }
        // 如果没有扩展名，尝试从URI中获取
        let mimeType = 'image/jpeg'; // 默认MIME类型
        if (fileName.includes('.')) {
          const ext = fileName.substring(fileName.lastIndexOf('.') + 1).toLowerCase();
          const mimeTypes: Record<string, string> = {
            'jpg': 'image/jpeg',
            'jpeg': 'image/jpeg',
            'png': 'image/png',
            'gif': 'image/gif',
            'bmp': 'image/bmp'
          };
          mimeType = mimeTypes[ext] || 'image/jpeg';
        }
        
        // 构建multipart/form-data
        const boundary = '----WebKitFormBoundary' + Date.now();
        const formData = OssService.buildMultipartFormData(
          buffer,
          fileName,
          mimeType,
          boundary
        );
        
        // 构建完整URL
        const fullUrl = `${Constants.BASE_URL}/api/oss/upload`;
        
        // 创建请求
        const httpRequest = http.createHttp();
        const headers: Record<string, string> = {
          'Content-Type': `multipart/form-data; boundary=${boundary}`
        };
        
        // 添加Token（如果需要）
        const token = await StorageUtil.getToken();
        if (token) {
          headers['Authorization'] = `Bearer ${token}`;
        }
        
        const requestOptions: http.HttpRequestOptions = {
          method: http.RequestMethod.POST,
          header: headers,
          extraData: formData,
          connectTimeout: 60000,
          readTimeout: 60000
        };
        
        // 发送请求
        httpRequest.request(fullUrl, requestOptions)
          .then((data: http.HttpResponse) => {
            httpRequest.destroy();
            try {
              const responseText = data.result.toString();
              console.info(`[OssService] Upload - Status: ${data.responseCode}, Response: ${responseText}`);
              
              // 解析JSON响应
              const jsonData: Record<string, Object> = JSON.parse(responseText);
              if (jsonData.code !== undefined) {
                const result: Result<string> = {
                  code: jsonData.code as number,
                  message: jsonData.message as string,
                  data: jsonData.data as string
                };
                resolve(result);
              } else {
                const result: Result<string> = {
                  code: data.responseCode === 200 ? 200 : data.responseCode,
                  message: data.responseCode === 200 ? 'success' : `HTTP ${data.responseCode}`,
                  data: responseText as string
                };
                resolve(result);
              }
            } catch (err) {
              const result: Result<string> = {
                code: -1,
                message: `Parse error: ${JSON.stringify(err)}`,
                data: ''
              };
              resolve(result);
            }
          })
          .catch((err: Error) => {
            httpRequest.destroy();
            console.error(`[OssService] Upload - Network error:`, err);
            const result: Result<string> = {
              code: -1,
              message: err.message || 'Network error',
              data: ''
            };
            resolve(result);
          });
      } catch (err) {
        console.error(`[OssService] Upload - File read error:`, err);
        const result: Result<string> = {
          code: -1,
          message: `File read error: ${JSON.stringify(err)}`,
          data: ''
        };
        resolve(result);
      }
    });
  }
  
  /**
   * 将字符串转换为Uint8Array（替代TextEncoder）
   */
  private static stringToUint8Array(str: string): Uint8Array {
    const arr: number[] = [];
    for (let i = 0; i < str.length; i++) {
      arr.push(str.charCodeAt(i));
    }
    return new Uint8Array(arr);
  }

  /**
   * 构建multipart/form-data格式的数据
   */
  private static buildMultipartFormData(
    fileBuffer: ArrayBuffer,
    fileName: string,
    mimeType: string,
    boundary: string
  ): ArrayBuffer {
    // 构建表单字段
    const parts: Uint8Array[] = [];
    
    // 开始边界
    parts.push(OssService.stringToUint8Array(`--${boundary}\r\n`));
    
    // Content-Disposition header
    parts.push(OssService.stringToUint8Array(`Content-Disposition: form-data; name="file"; filename="${fileName}"\r\n`));
    
    // Content-Type header
    parts.push(OssService.stringToUint8Array(`Content-Type: ${mimeType}\r\n\r\n`));
    
    // 文件内容
    parts.push(new Uint8Array(fileBuffer));
    
    // 结束边界
    parts.push(OssService.stringToUint8Array(`\r\n--${boundary}--\r\n`));
    
    // 合并所有部分
    let totalLength = 0;
    for (const part of parts) {
      totalLength += part.length;
    }
    
    const result = new Uint8Array(totalLength);
    let offset = 0;
    for (const part of parts) {
      result.set(part, offset);
      offset += part.length;
    }
    
    return result.buffer;
  }
}

