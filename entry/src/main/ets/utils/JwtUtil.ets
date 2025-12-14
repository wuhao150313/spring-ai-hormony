/**
 * JWT 工具类
 */
export class JwtUtil {
  /**
   * 从 JWT token 中解析 userId
   * JWT token 格式: header.payload.signature
   * payload 是 base64 编码的 JSON，包含用户信息
   */
  static getUserIdFromToken(token: string): string | null {
    try {
      // JWT token 由三部分组成，用 . 分隔
      const parts = token.split('.');
      if (parts.length !== 3) {
        console.error('[JwtUtil] Invalid JWT token format');
        return null;
      }

      // 解析 payload（第二部分）
      const payload = parts[1];
      
      // Base64 解码（HarmonyOS 可能需要使用 TextEncoder/TextDecoder 或类似方法）
      // 这里使用简单的 base64 解码
      try {
        // 注意：HarmonyOS 的 base64 解码可能需要使用特定的 API
        // 这里先尝试使用 atob（如果可用）或手动解码
        const decoded = this.base64Decode(payload);
        const jsonData = JSON.parse(decoded);
        
        // 尝试从不同的字段获取 userId
        // JWT 标准字段：sub (subject), user_id, id, userId
        const userId = jsonData.sub || jsonData.user_id || jsonData.id || jsonData.userId;
        
        if (userId) {
          return String(userId);
        }
        
        console.warn('[JwtUtil] No userId found in token payload:', JSON.stringify(jsonData));
        return null;
      } catch (e) {
        console.error('[JwtUtil] Failed to decode payload:', e);
        return null;
      }
    } catch (err) {
      console.error('[JwtUtil] Failed to parse token:', err);
      return null;
    }
  }

  /**
   * Base64 解码（简化实现）
   * 注意：这是一个简化的实现，实际项目中应该使用 HarmonyOS 提供的 base64 解码 API
   */
  private static base64Decode(str: string): string {
    // HarmonyOS 可能需要使用特定的 base64 解码 API
    // 这里使用一个简单的实现（注意：可能不适用于所有情况）
    try {
      // 尝试使用 TextDecoder（如果可用）
      // 或者使用 HarmonyOS 的 base64 解码 API
      // 这里先使用一个简单的实现
      const base64Chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=';
      let output = '';
      let i = 0;
      
      str = str.replace(/[^A-Za-z0-9\+\/\=]/g, '');
      
      while (i < str.length) {
        const enc1 = base64Chars.indexOf(str.charAt(i++));
        const enc2 = base64Chars.indexOf(str.charAt(i++));
        const enc3 = base64Chars.indexOf(str.charAt(i++));
        const enc4 = base64Chars.indexOf(str.charAt(i++));
        
        const chr1 = (enc1 << 2) | (enc2 >> 4);
        const chr2 = ((enc2 & 15) << 4) | (enc3 >> 2);
        const chr3 = ((enc3 & 3) << 6) | enc4;
        
        output += String.fromCharCode(chr1);
        
        if (enc3 !== 64) {
          output += String.fromCharCode(chr2);
        }
        if (enc4 !== 64) {
          output += String.fromCharCode(chr3);
        }
      }
      
      return output;
    } catch (e) {
      console.error('[JwtUtil] Base64 decode error:', e);
      return '';
    }
  }
}

