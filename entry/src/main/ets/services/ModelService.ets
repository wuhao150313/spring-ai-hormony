import { HttpUtil } from '../utils/HttpUtil';
import { Result } from '../models/Result';
import { AIModel } from '../models/AIModel';
import { SwitchModelRequest } from '../models/SwitchModelRequest';

/**
 * 模型服务
 */
export class ModelService {
  /**
   * 获取模型列表
   */
  static async getModelList(): Promise<Result<AIModel[]>> {
    return await HttpUtil.get<AIModel[]>('/api/ai/model/list');
  }

  /**
   * 获取当前模型
   */
  static async getCurrentModel(): Promise<Result<AIModel>> {
    return await HttpUtil.get<AIModel>('/api/ai/model/current');
  }

  /**
   * 切换模型
   */
  static async switchModel(modelName: string): Promise<Result<AIModel>> {
    const request: SwitchModelRequest = { modelName };
    return await HttpUtil.post<AIModel>('/api/ai/model/switch', request);
  }
}

