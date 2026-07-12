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

const API_KEY = "sk-a587882215c044768b4cdb400778ed2b";
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

function cleanMarkdownCodeBlock(text: string): string {
  let result = text.trim();
  if (result.startsWith('```json')) {
    result = result.substring(7);
  } else if (result.startsWith('```')) {
    result = result.substring(3);
  }
  if (result.endsWith('```')) {
    result = result.substring(0, result.length - 3);
  }
  return result.trim();
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
      connectTimeout: 10000,
      readTimeout: 10000
    });
    let resultStr = res.result.toString();
    let resObj: ChatResponse = JSON.parse(resultStr);
    if (resObj.choices && resObj.choices.length > 0) {
      return resObj.choices[0].message.content.trim();
    }
    throw new Error("API返回格式错误");
  } catch (err) {
    const errMsg = typeof err === 'object' ? JSON.stringify(err) : String(err);
    console.error(`DeepSeek调用失败详情: ${errMsg}`);
    return JSON.stringify({
      "summary": "AI分析失败",
      "risk": `请求异常: ${errMsg}`,
      "solve": ["切换手机流量、检查密钥、延长请求超时时间"]
    });
  } finally {
    httpClient.destroy();
  }
}

export async function analyzeAlarm(alarmJsonStr: string): Promise<AiAnalysisResult> {
  const prompt = `你是仓储巡检告警专家，仅输出标准JSON，禁止多余文字。输出三个字段：summary：一句话概括异常；risk：仓储对应安全风险；solve：数组，3条分步处置操作。告警数据：${alarmJsonStr}`;
  const result = await chat(prompt, alarmJsonStr);
  try {
    const cleanResult = cleanMarkdownCodeBlock(result);
    return JSON.parse(cleanResult) as AiAnalysisResult;
  } catch (err) {
    console.error(`AI分析JSON解析失败: ${err}, 原始内容: ${result}`);
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
  const result = await chat(prompt, input);
  return cleanMarkdownCodeBlock(result);
}