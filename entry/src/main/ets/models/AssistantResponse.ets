/**
 * Agent 响应模型
 */
export interface AssistantResponse {
  userId: string | null;
  threadId: string | null;
  answer: string;
  suggestion: string;
  type: 'weather' | 'course' | 'library' | 'general';
  needsFurtherHelp: boolean;
}

