import http from '@ohos.net.http';
import { AiAnalysisResult } from '../model/PatrolModels';

export interface AiMessage {
  role: string;
  content: string;
}

export interface ChatMessage {
  message: ChatContent;
}

export interface ChatContent {
  content: string;
}

export interface ChatRequestBody {
  model: string;
  temperature: number;
  stream: boolean;
  messages: AiMessage[];
}

export interface ChatResponse {
  choices: ChatMessage[];
}

const API_KEY = "sk-f34e6cdc48f4462fb6f1165b08a0096f";
const URL = "https://api.deepseek.com/v1/chat/completions";
let lastRequestTime: number = 0;
const requestThrottleMs: number = 1000;

async function waitThrottle(): Promise<void> {
  const now = Date.now();
  const diff = now - lastRequestTime;
  if (diff < requestThrottleMs) {
    await new Promise<void>((resolve: (value?: void) => void): void => {
      setTimeout(resolve, requestThrottleMs - diff);
    });
  }
  lastRequestTime = Date.now();
}

export async function chat(sysPrompt: string, userInput: string): Promise<string> {
  await waitThrottle();
  let httpClient = http.createHttp();
  const message1: AiMessage = { role: "system", content: sysPrompt };
  const message2: AiMessage = { role: "user", content: userInput };
  const body: ChatRequestBody = {
    model: "deepseek-chat",
    temperature: 0.1,
    stream: false,
    messages: [message1, message2]
  };
  const bodyStr = JSON.stringify(body);
  try {
    let res = await httpClient.request(URL, {
      method: http.RequestMethod.POST,
      header: {
        "Authorization": `Bearer ${API_KEY}`,
        "Content-Type": "application/json"
      },
      extraData: bodyStr,
      connectTimeout: 5000,
      readTimeout: 15000
    });
    let resObj: ChatResponse = JSON.parse(res.result as string);
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

export async function analyzeAlarm(alarmJsonStr: string): Promise<AiAnalysisResult> {
  const prompt = `你是仓储巡检告警专家，仅输出标准JSON，禁止多余文字。输出三个字段：summary：一句话概括异常；risk：仓储对应安全风险；solve：数组，3条分步处置操作。告警数据：${alarmJsonStr}`;
  const result = await chat(prompt, alarmJsonStr);
  try {
    return JSON.parse(result) as AiAnalysisResult;
  } catch {
    const defaultResult: AiAnalysisResult = {
      summary: "AI分析失败",
      risk: "模型返回格式异常",
      solve: ["请稍后重试"]
    };
    return defaultResult;
  }
}

export async function queryAlarmQuestion(alarmJsonStr: string, question: string): Promise<string> {
  const prompt = "结合下方仓储告警数据，简短专业回答用户巡检相关问题，适配手机展示";
  const input = `告警信息：${alarmJsonStr}\n用户问题：${question}`;
  return chat(prompt, input);
}