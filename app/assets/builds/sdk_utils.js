// app/javascript/sdk_utils.ts
var SDKUtils = class {
  constructor() {
    this.isAvailable = this.checkSDKAvailability();
  }
  /**
   * Check if SDK is available in current context
   */
  checkSDKAvailability() {
    return typeof window.sdk !== "undefined" && window.sdk && typeof window.sdk.send === "function";
  }
  /**
   * Send message to chatbox if SDK is available
   * @param {string} message - Message to send
   * @returns {boolean} - Whether message was sent successfully
   */
  sendMessage(message) {
    if (this.isAvailable) {
      try {
        window.sdk.send(message);
        console.log("Message sent to chatbox:", message);
        return true;
      } catch (error) {
        console.error("Failed to send message to SDK:", error);
        return false;
      }
    } else {
      console.log("SDK not available. Would send message:", message);
      return false;
    }
  }
  /**
   * Send error details to chatbox for fixing
   * @param {Object} errorInfo - Error information object
   */
  sendErrorForFix(errorInfo = {}) {
    const {
      url = window.location.href,
      path = window.location.pathname.substring(1),
      errorMessage = "Unknown error",
      additionalContext = ""
    } = errorInfo;
    const message = `Fix this error:
URL: ${url}
Error: ${errorMessage}
Path: ${path}${additionalContext ? `

Additional Context:
${additionalContext}` : ""}

Please help me fix this issue.`;
    return this.sendMessage(message);
  }
  /**
   * Refresh SDK availability status
   */
  refresh() {
    this.isAvailable = this.checkSDKAvailability();
    return this.isAvailable;
  }
  /**
   * Get current SDK status
   */
  getStatus() {
    return {
      isAvailable: this.isAvailable,
      hasSDK: typeof window.sdk !== "undefined",
      hasSendMethod: typeof window.sdk?.send === "function"
    };
  }
};
var sdkUtils = new SDKUtils();
window.sendToSDK = (message) => sdkUtils.sendMessage(message);
window.sendErrorToSDK = (errorInfo) => sdkUtils.sendErrorForFix(errorInfo);
window.isSDKAvailable = () => sdkUtils.getStatus().isAvailable;
window.sdkUtils = sdkUtils;
var sdk_utils_default = sdkUtils;
export {
  sdk_utils_default as default
};
//# sourceMappingURL=data:application/json;base64,ewogICJ2ZXJzaW9uIjogMywKICAic291cmNlcyI6IFsiLi4vLi4vamF2YXNjcmlwdC9zZGtfdXRpbHMudHMiXSwKICAic291cmNlc0NvbnRlbnQiOiBbIi8vIFNESyBVdGlsaXR5IGZvciBjaGF0Ym94IGludGVncmF0aW9uXG4vLyBIYW5kbGVzIGNoYXRib3ggU0RLIGRldGVjdGlvbiBhbmQgbWVzc2FnZSBzZW5kaW5nXG5cbmNsYXNzIFNES1V0aWxzIHtcbiAgcHJpdmF0ZSBpc0F2YWlsYWJsZTogYm9vbGVhbjtcblxuICBjb25zdHJ1Y3RvcigpIHtcbiAgICB0aGlzLmlzQXZhaWxhYmxlID0gdGhpcy5jaGVja1NES0F2YWlsYWJpbGl0eSgpO1xuICB9XG5cbiAgLyoqXG4gICAqIENoZWNrIGlmIFNESyBpcyBhdmFpbGFibGUgaW4gY3VycmVudCBjb250ZXh0XG4gICAqL1xuICBjaGVja1NES0F2YWlsYWJpbGl0eSgpOiBib29sZWFuIHtcbiAgICByZXR1cm4gdHlwZW9mIHdpbmRvdy5zZGsgIT09ICd1bmRlZmluZWQnICYmIFxuICAgICAgICAgICB3aW5kb3cuc2RrICYmIFxuICAgICAgICAgICB0eXBlb2Ygd2luZG93LnNkay5zZW5kID09PSAnZnVuY3Rpb24nO1xuICB9XG5cbiAgLyoqXG4gICAqIFNlbmQgbWVzc2FnZSB0byBjaGF0Ym94IGlmIFNESyBpcyBhdmFpbGFibGVcbiAgICogQHBhcmFtIHtzdHJpbmd9IG1lc3NhZ2UgLSBNZXNzYWdlIHRvIHNlbmRcbiAgICogQHJldHVybnMge2Jvb2xlYW59IC0gV2hldGhlciBtZXNzYWdlIHdhcyBzZW50IHN1Y2Nlc3NmdWxseVxuICAgKi9cbiAgc2VuZE1lc3NhZ2UobWVzc2FnZTogc3RyaW5nKTogYm9vbGVhbiB7XG4gICAgaWYgKHRoaXMuaXNBdmFpbGFibGUpIHtcbiAgICAgIHRyeSB7XG4gICAgICAgIHdpbmRvdy5zZGshLnNlbmQobWVzc2FnZSk7XG4gICAgICAgIGNvbnNvbGUubG9nKCdNZXNzYWdlIHNlbnQgdG8gY2hhdGJveDonLCBtZXNzYWdlKTtcbiAgICAgICAgcmV0dXJuIHRydWU7XG4gICAgICB9IGNhdGNoIChlcnJvcikge1xuICAgICAgICBjb25zb2xlLmVycm9yKCdGYWlsZWQgdG8gc2VuZCBtZXNzYWdlIHRvIFNESzonLCBlcnJvcik7XG4gICAgICAgIHJldHVybiBmYWxzZTtcbiAgICAgIH1cbiAgICB9IGVsc2Uge1xuICAgICAgY29uc29sZS5sb2coJ1NESyBub3QgYXZhaWxhYmxlLiBXb3VsZCBzZW5kIG1lc3NhZ2U6JywgbWVzc2FnZSk7XG4gICAgICByZXR1cm4gZmFsc2U7XG4gICAgfVxuICB9XG5cbiAgLyoqXG4gICAqIFNlbmQgZXJyb3IgZGV0YWlscyB0byBjaGF0Ym94IGZvciBmaXhpbmdcbiAgICogQHBhcmFtIHtPYmplY3R9IGVycm9ySW5mbyAtIEVycm9yIGluZm9ybWF0aW9uIG9iamVjdFxuICAgKi9cbiAgc2VuZEVycm9yRm9yRml4KGVycm9ySW5mbzogYW55ID0ge30pOiBib29sZWFuIHtcbiAgICBjb25zdCB7XG4gICAgICB1cmwgPSB3aW5kb3cubG9jYXRpb24uaHJlZixcbiAgICAgIHBhdGggPSB3aW5kb3cubG9jYXRpb24ucGF0aG5hbWUuc3Vic3RyaW5nKDEpLFxuICAgICAgZXJyb3JNZXNzYWdlID0gJ1Vua25vd24gZXJyb3InLFxuICAgICAgYWRkaXRpb25hbENvbnRleHQgPSAnJ1xuICAgIH0gPSBlcnJvckluZm87XG5cbiAgICBjb25zdCBtZXNzYWdlID0gYEZpeCB0aGlzIGVycm9yOlxuVVJMOiAke3VybH1cbkVycm9yOiAke2Vycm9yTWVzc2FnZX1cblBhdGg6ICR7cGF0aH0ke2FkZGl0aW9uYWxDb250ZXh0ID8gYFxcblxcbkFkZGl0aW9uYWwgQ29udGV4dDpcXG4keyAgYWRkaXRpb25hbENvbnRleHR9YCA6ICcnfVxuXG5QbGVhc2UgaGVscCBtZSBmaXggdGhpcyBpc3N1ZS5gO1xuXG4gICAgcmV0dXJuIHRoaXMuc2VuZE1lc3NhZ2UobWVzc2FnZSk7XG4gIH1cblxuICAvKipcbiAgICogUmVmcmVzaCBTREsgYXZhaWxhYmlsaXR5IHN0YXR1c1xuICAgKi9cbiAgcmVmcmVzaCgpOiBib29sZWFuIHtcbiAgICB0aGlzLmlzQXZhaWxhYmxlID0gdGhpcy5jaGVja1NES0F2YWlsYWJpbGl0eSgpO1xuICAgIHJldHVybiB0aGlzLmlzQXZhaWxhYmxlO1xuICB9XG5cbiAgLyoqXG4gICAqIEdldCBjdXJyZW50IFNESyBzdGF0dXNcbiAgICovXG4gIGdldFN0YXR1cygpOiB7IGlzQXZhaWxhYmxlOiBib29sZWFuOyBoYXNTREs6IGJvb2xlYW47IGhhc1NlbmRNZXRob2Q6IGJvb2xlYW4gfSB7XG4gICAgcmV0dXJuIHtcbiAgICAgIGlzQXZhaWxhYmxlOiB0aGlzLmlzQXZhaWxhYmxlLFxuICAgICAgaGFzU0RLOiB0eXBlb2Ygd2luZG93LnNkayAhPT0gJ3VuZGVmaW5lZCcsXG4gICAgICBoYXNTZW5kTWV0aG9kOiB0eXBlb2Ygd2luZG93LnNkaz8uc2VuZCA9PT0gJ2Z1bmN0aW9uJ1xuICAgIH07XG4gIH1cbn1cblxuLy8gQ3JlYXRlIHNpbmdsZXRvbiBpbnN0YW5jZVxuY29uc3Qgc2RrVXRpbHMgPSBuZXcgU0RLVXRpbHMoKTtcblxuLy8gR2xvYmFsIGZ1bmN0aW9uIGZvciBiYWNrd2FyZCBjb21wYXRpYmlsaXR5XG53aW5kb3cuc2VuZFRvU0RLID0gKG1lc3NhZ2UpID0+IHNka1V0aWxzLnNlbmRNZXNzYWdlKG1lc3NhZ2UpO1xud2luZG93LnNlbmRFcnJvclRvU0RLID0gKGVycm9ySW5mbykgPT4gc2RrVXRpbHMuc2VuZEVycm9yRm9yRml4KGVycm9ySW5mbyk7XG53aW5kb3cuaXNTREtBdmFpbGFibGUgPSAoKSA9PiBzZGtVdGlscy5nZXRTdGF0dXMoKS5pc0F2YWlsYWJsZTtcblxuLy8gRXhwb3J0IGdsb2JhbGx5XG53aW5kb3cuc2RrVXRpbHMgPSBzZGtVdGlscztcblxuZXhwb3J0IGRlZmF1bHQgc2RrVXRpbHM7XG4iXSwKICAibWFwcGluZ3MiOiAiO0FBR0EsSUFBTSxXQUFOLE1BQWU7QUFBQSxFQUdiLGNBQWM7QUFDWixTQUFLLGNBQWMsS0FBSyxxQkFBcUI7QUFBQSxFQUMvQztBQUFBO0FBQUE7QUFBQTtBQUFBLEVBS0EsdUJBQWdDO0FBQzlCLFdBQU8sT0FBTyxPQUFPLFFBQVEsZUFDdEIsT0FBTyxPQUNQLE9BQU8sT0FBTyxJQUFJLFNBQVM7QUFBQSxFQUNwQztBQUFBO0FBQUE7QUFBQTtBQUFBO0FBQUE7QUFBQSxFQU9BLFlBQVksU0FBMEI7QUFDcEMsUUFBSSxLQUFLLGFBQWE7QUFDcEIsVUFBSTtBQUNGLGVBQU8sSUFBSyxLQUFLLE9BQU87QUFDeEIsZ0JBQVEsSUFBSSw0QkFBNEIsT0FBTztBQUMvQyxlQUFPO0FBQUEsTUFDVCxTQUFTLE9BQU87QUFDZCxnQkFBUSxNQUFNLGtDQUFrQyxLQUFLO0FBQ3JELGVBQU87QUFBQSxNQUNUO0FBQUEsSUFDRixPQUFPO0FBQ0wsY0FBUSxJQUFJLDBDQUEwQyxPQUFPO0FBQzdELGFBQU87QUFBQSxJQUNUO0FBQUEsRUFDRjtBQUFBO0FBQUE7QUFBQTtBQUFBO0FBQUEsRUFNQSxnQkFBZ0IsWUFBaUIsQ0FBQyxHQUFZO0FBQzVDLFVBQU07QUFBQSxNQUNKLE1BQU0sT0FBTyxTQUFTO0FBQUEsTUFDdEIsT0FBTyxPQUFPLFNBQVMsU0FBUyxVQUFVLENBQUM7QUFBQSxNQUMzQyxlQUFlO0FBQUEsTUFDZixvQkFBb0I7QUFBQSxJQUN0QixJQUFJO0FBRUosVUFBTSxVQUFVO0FBQUEsT0FDYixHQUFHO0FBQUEsU0FDRCxZQUFZO0FBQUEsUUFDYixJQUFJLEdBQUcsb0JBQW9CO0FBQUE7QUFBQTtBQUFBLEVBQThCLGlCQUFpQixLQUFLLEVBQUU7QUFBQTtBQUFBO0FBSXJGLFdBQU8sS0FBSyxZQUFZLE9BQU87QUFBQSxFQUNqQztBQUFBO0FBQUE7QUFBQTtBQUFBLEVBS0EsVUFBbUI7QUFDakIsU0FBSyxjQUFjLEtBQUsscUJBQXFCO0FBQzdDLFdBQU8sS0FBSztBQUFBLEVBQ2Q7QUFBQTtBQUFBO0FBQUE7QUFBQSxFQUtBLFlBQStFO0FBQzdFLFdBQU87QUFBQSxNQUNMLGFBQWEsS0FBSztBQUFBLE1BQ2xCLFFBQVEsT0FBTyxPQUFPLFFBQVE7QUFBQSxNQUM5QixlQUFlLE9BQU8sT0FBTyxLQUFLLFNBQVM7QUFBQSxJQUM3QztBQUFBLEVBQ0Y7QUFDRjtBQUdBLElBQU0sV0FBVyxJQUFJLFNBQVM7QUFHOUIsT0FBTyxZQUFZLENBQUMsWUFBWSxTQUFTLFlBQVksT0FBTztBQUM1RCxPQUFPLGlCQUFpQixDQUFDLGNBQWMsU0FBUyxnQkFBZ0IsU0FBUztBQUN6RSxPQUFPLGlCQUFpQixNQUFNLFNBQVMsVUFBVSxFQUFFO0FBR25ELE9BQU8sV0FBVztBQUVsQixJQUFPLG9CQUFROyIsCiAgIm5hbWVzIjogW10KfQo=
