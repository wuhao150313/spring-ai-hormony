/**
 * 日期工具类
 */
export class DateUtil {
  /**
   * 格式化日期时间
   * @param dateStr ISO 8601 格式的日期字符串
   * @returns 格式化后的日期字符串，如 "12-02 10:00"
   */
  static formatDateTime(dateStr: string | null): string {
    if (!dateStr) {
      return '';
    }
    try {
      const date = new Date(dateStr);
      const month = (date.getMonth() + 1).toString().padStart(2, '0');
      const day = date.getDate().toString().padStart(2, '0');
      const hours = date.getHours().toString().padStart(2, '0');
      const minutes = date.getMinutes().toString().padStart(2, '0');
      return `${month}-${day} ${hours}:${minutes}`;
    } catch (err) {
      console.error('Failed to format date:', JSON.stringify(err));
      return '';
    }
  }

  /**
   * 格式化相对时间
   * @param dateStr ISO 8601 格式的日期字符串
   * @returns 相对时间字符串，如 "刚刚"、"5分钟前"、"今天 10:00"
   */
  static formatRelativeTime(dateStr: string | null): string {
    if (!dateStr) {
      return '';
    }
    try {
      const date = new Date(dateStr);
      const now = new Date();
      const diff = now.getTime() - date.getTime();
      const minutes = Math.floor(diff / 60000);
      const hours = Math.floor(diff / 3600000);
      const days = Math.floor(diff / 86400000);

      if (minutes < 1) {
        return '刚刚';
      } else if (minutes < 60) {
        return `${minutes}分钟前`;
      } else if (hours < 24) {
        return `${hours}小时前`;
      } else if (days < 7) {
        return `${days}天前`;
      } else {
        return DateUtil.formatDateTime(dateStr);
      }
    } catch (err) {
      console.error('Failed to format relative time:', JSON.stringify(err));
      return '';
    }
  }
}

