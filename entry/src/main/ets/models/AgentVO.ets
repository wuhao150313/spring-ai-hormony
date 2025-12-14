/**
 * AI智能体模型
 */
export interface AgentVO {
  id: number;
  name: string;
  description: string;
  icon: string;
  isOfficial: boolean;
  chatCount: number;
  author: string;
  category: string;
  isAdded: boolean;
}

