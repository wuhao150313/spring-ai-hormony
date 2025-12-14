/**
 * 统一响应模型
 */
export interface Result<T> {
  code: number;
  message: string;
  data: T;
}

/**
 * Result 工具类
 */
export class ResultUtil {
  /**
   * 判断响应是否成功
   */
  static isSuccess<T>(result: Result<T>): boolean {
    return result.code === 200;
  }

  /**
   * 获取错误信息
   */
  static getErrorMessage<T>(result: Result<T>): string {
    return result.message || '请求失败';
  }
}

