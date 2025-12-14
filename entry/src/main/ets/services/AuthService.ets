import { HttpUtil } from '../utils/HttpUtil';
import { Result } from '../models/Result';
import { TokenVO } from '../models/TokenVO';
import { UserInfoVO } from '../models/UserInfoVO';
import { LoginRequest } from '../models/LoginRequest';
import { SmsLoginRequest } from '../models/SmsLoginRequest';
import { SendSmsCodeRequest } from '../models/SendSmsCodeRequest';
import { StorageUtil } from '../utils/StorageUtil';

/**
 * 认证服务
 */
export class AuthService {
  /**
   * 账号密码登录
   */
  static async login(username: string, password: string): Promise<Result<TokenVO>> {
    const request: LoginRequest = {
      username,
      password
    };
    const result = await HttpUtil.post<TokenVO>('/api/auth/login', request);
    // 登录成功后保存 Token 和 userId
    if (result.code === 200 && result.data && result.data.token) {
      await StorageUtil.saveToken(result.data.token);
      // 从 token 中解析 userId（临时方案，直到后端返回 userId）
      // 注意：这里使用 username 作为临时 userId，实际应该从 token 解析
      // 或者后端应该在 TokenVO 中包含 userId
      await StorageUtil.saveUserId(username); // 临时使用 username
    }
    return result;
  }

  /**
   * 短信登录
   */
  static async smsLogin(mobile: string, code: string): Promise<Result<TokenVO>> {
    const request: SmsLoginRequest = {
      mobile,
      code
    };
    const result = await HttpUtil.post<TokenVO>('/api/auth/sms-login', request);
    // 登录成功后保存 Token 和 userId
    if (result.code === 200 && result.data && result.data.token) {
      await StorageUtil.saveToken(result.data.token);
      // 从 token 中解析 userId（临时方案，直到后端返回 userId）
      // 注意：这里使用 mobile 作为临时 userId，实际应该从 token 解析
      await StorageUtil.saveUserId(mobile); // 临时使用 mobile
    }
    return result;
  }

  /**
   * 发送短信验证码
   */
  static async sendSmsCode(mobile: string): Promise<Result<string>> {
    const params: SendSmsCodeRequest = { mobile };
    return await HttpUtil.get<string>('/api/auth/send-sms-code', params);
  }

  /**
   * 登出
   */
  static async logout(): Promise<Result<string>> {
    const result = await HttpUtil.post<string>('/api/auth/logout');
    // 登出后清除 Token
    if (result.code === 200) {
      await StorageUtil.clearAll();
    }
    return result;
  }

  /**
   * 检查是否已登录
   */
  static async isLoggedIn(): Promise<boolean> {
    const token = await StorageUtil.getToken();
    return token !== null && token !== '';
  }

  /**
   * 获取当前用户信息
   */
  static async getCurrentUserInfo(): Promise<Result<UserInfoVO>> {
    return await HttpUtil.get<UserInfoVO>('/api/auth/user-info');
  }
}

