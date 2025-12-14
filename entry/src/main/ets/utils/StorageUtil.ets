import preferences from '@ohos.data.preferences';
import { common } from '@kit.AbilityKit';
import { Constants } from './Constants';
import { UserInfoVO } from '../models/UserInfoVO';

/**
 * 本地存储工具类
 */
export class StorageUtil {
  private static dataPreferences: preferences.Preferences | null = null;
  private static context: common.UIAbilityContext | null = null;

  /**
   * 初始化存储
   */
  static async init(context: common.UIAbilityContext): Promise<void> {
    StorageUtil.context = context;
    try {
      StorageUtil.dataPreferences = await preferences.getPreferences(context, 'app_storage');
    } catch (err) {
      console.error('Failed to initialize preferences:', JSON.stringify(err));
    }
  }

  /**
   * 保存用户ID
   */
  static async saveUserId(userId: string): Promise<void> {
    if (!StorageUtil.dataPreferences) {
      console.error('Preferences not initialized');
      return;
    }
    try {
      await StorageUtil.dataPreferences.put(Constants.STORAGE_KEY_USER_ID, userId);
      await StorageUtil.dataPreferences.flush();
    } catch (err) {
      console.error('Failed to save userId:', JSON.stringify(err));
    }
  }

  /**
   * 获取用户ID
   */
  static async getUserId(): Promise<string | null> {
    if (!StorageUtil.dataPreferences) {
      return null;
    }
    try {
      const userId = await StorageUtil.dataPreferences.get(Constants.STORAGE_KEY_USER_ID, '');
      return userId as string || null;
    } catch (err) {
      console.error('Failed to get userId:', JSON.stringify(err));
      return null;
    }
  }

  /**
   * 保存Token
   */
  static async saveToken(token: string): Promise<void> {
    if (!StorageUtil.dataPreferences) {
      return;
    }
    try {
      await StorageUtil.dataPreferences.put(Constants.STORAGE_KEY_TOKEN, token);
      await StorageUtil.dataPreferences.flush();
    } catch (err) {
      console.error('Failed to save token:', JSON.stringify(err));
    }
  }

  /**
   * 获取Token
   */
  static async getToken(): Promise<string | null> {
    if (!StorageUtil.dataPreferences) {
      return null;
    }
    try {
      const token = await StorageUtil.dataPreferences.get(Constants.STORAGE_KEY_TOKEN, '');
      return token as string || null;
    } catch (err) {
      console.error('Failed to get token:', JSON.stringify(err));
      return null;
    }
  }

  /**
   * 保存ThreadId
   */
  static async saveThreadId(threadId: string): Promise<void> {
    if (!StorageUtil.dataPreferences) {
      return;
    }
    try {
      await StorageUtil.dataPreferences.put(Constants.STORAGE_KEY_THREAD_ID, threadId);
      await StorageUtil.dataPreferences.flush();
    } catch (err) {
      console.error('Failed to save threadId:', JSON.stringify(err));
    }
  }

  /**
   * 获取ThreadId
   */
  static async getThreadId(): Promise<string | null> {
    if (!StorageUtil.dataPreferences) {
      return null;
    }
    try {
      const threadId = await StorageUtil.dataPreferences.get(Constants.STORAGE_KEY_THREAD_ID, '');
      return threadId as string || null;
    } catch (err) {
      console.error('Failed to get threadId:', JSON.stringify(err));
      return null;
    }
  }

  /**
   * 保存用户信息
   */
  static async saveUserInfo(userInfo: UserInfoVO): Promise<void> {
    if (!StorageUtil.dataPreferences) {
      return;
    }
    try {
      await StorageUtil.dataPreferences.put(Constants.STORAGE_KEY_USER_INFO, JSON.stringify(userInfo));
      await StorageUtil.dataPreferences.flush();
    } catch (err) {
      console.error('Failed to save userInfo:', JSON.stringify(err));
    }
  }

  /**
   * 获取用户信息
   */
  static async getUserInfo(): Promise<UserInfoVO | null> {
    if (!StorageUtil.dataPreferences) {
      return null;
    }
    try {
      const userInfoStr = await StorageUtil.dataPreferences.get(Constants.STORAGE_KEY_USER_INFO, '');
      if (userInfoStr && typeof userInfoStr === 'string' && userInfoStr !== '') {
        return JSON.parse(userInfoStr) as UserInfoVO;
      }
      return null;
    } catch (err) {
      console.error('Failed to get userInfo:', JSON.stringify(err));
      return null;
    }
  }

  /**
   * 清除所有数据
   */
  static async clearAll(): Promise<void> {
    if (!StorageUtil.dataPreferences) {
      return;
    }
    try {
      await StorageUtil.dataPreferences.clear();
      await StorageUtil.dataPreferences.flush();
    } catch (err) {
      console.error('Failed to clear preferences:', JSON.stringify(err));
    }
  }
}

