import http from '@ohos.net.http';

export interface AiAnalysisResult {
  summary: string;
  risk: string;
  solve: string[];
}

export class DeepSeekUtil {
  private static readonly API_KEY = "sk-f34e6cdc48f4462fb6f1165b08a0096f";
  private static readonly URL = "https://api.deepseek.com/v1/chat/completions";
  private static lastRequestTime: number = 0;
  private static requestThrottleMs: number = 1000;

  private static async waitThrottle(): Promise<void> {
    const now = Date.now();
    const diff = now - this.lastRequestTime;
    if (diff < this.requestThrottleMs) {
      await new Promise((resolve): void => {
        setTimeout(resolve, this.requestThrottleMs - diff);
      });
    }
    this.lastRequestTime = Date.now();
  }

  static async chat(sysPrompt: string, userInput: string): Promise<string> {
    await this.waitThrottle();
    let httpClient = http.createHttp();
    const body = JSON.stringify({
      model: "deepseek-chat",
      temperature: 0.1,
      stream: false,
      messages: [
        { role: "system", content: sysPrompt },
        { role: "user", content: userInput }
      ]
    });
    try {
      let res = await httpClient.request(this.URL, {
        method: http.RequestMethod.POST,
        header: {
          "Authorization": `Bearer ${this.API_KEY}`,
          "Content-Type": "application/json"
        },
        extraData: body,
        connectTimeout: 5000,
        readTimeout: 15000
      });
      let resObj = JSON.parse(res.result as string);
      if (resObj.choices && resObj.choices.length > 0) {
        return resObj.choices[0].message.content.trim();
      }
      throw new Error("API返回格式错误");
    } catch (err) {
      console.error(`DeepSeek调用失败: ${err}`);
      return JSON.stringify({
        "summary": "AI分析失败",
        "risk": "网络异常，无法调用大模型",
        "solve": ["检查手机网络、确认可访问外网"]
      });
    } finally {
      httpClient.destroy();
    }
  }

  static async analyzeAlarm(alarmJsonStr: string): Promise<AiAnalysisResult> {
    const prompt = `你是仓储巡检告警专家，仅输出标准JSON，禁止多余文字。输出三个字段：summary：一句话概括异常；risk：仓储对应安全风险；solve：数组，3条分步处置操作。告警数据：${alarmJsonStr}`;
    const result = await this.chat(prompt, alarmJsonStr);
    try {
      return JSON.parse(result) as AiAnalysisResult;
    } catch {
      return {
        summary: "AI分析失败",
        risk: "模型返回格式异常",
        solve: ["请稍后重试"]
      };
    }
  }

  static async queryAlarmQuestion(alarmJsonStr: string, question: string): Promise<string> {
    const prompt = "结合下方仓储告警数据，简短专业回答用户巡检相关问题，适配手机展示";
    const input = `告警信息：${alarmJsonStr}\n用户问题：${question}`;
    return this.chat(prompt, input);
  }
}