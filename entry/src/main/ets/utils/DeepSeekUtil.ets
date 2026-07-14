import http from '@ohos.net.http';
import { AiAnalysisResult } from '../model/PatrolModels';
import { EnvUtil } from './EnvUtil';

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

const URL = 'https://api.deepseek.com/v1/chat/completions';
const MODEL = 'deepseek-chat';
const REQUEST_THROTTLE_MS = 150;
const REQUEST_TIMEOUT_MS = 30000;
let lastRequestTime: number = 0;

function getApiKey(): string {
  return EnvUtil.getInstance().get('DEEPSEEK_API_KEY', '').trim();
}

async function waitThrottle(): Promise<void> {
  const now = Date.now();
  const diff = now - lastRequestTime;
  if (diff < REQUEST_THROTTLE_MS) {
    await new Promise<void>((resolve: (value?: void) => void): void => {
      setTimeout(resolve, REQUEST_THROTTLE_MS - diff);
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
  const apiKey = getApiKey();
  if (!apiKey) {
    throw new Error('DEEPSEEK_API_KEY 未配置，请检查 entry/src/main/resources/rawfile/config.env。');
  }

  const httpClient = http.createHttp();
  const body: ChatRequestBody = {
    model: MODEL,
    temperature: 0.1,
    stream: false,
    messages: [
      { role: 'system', content: sysPrompt },
      { role: 'user', content: userInput }
    ]
  };

  try {
    const res = await httpClient.request(URL, {
      method: http.RequestMethod.POST,
      header: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json'
      },
      extraData: JSON.stringify(body),
      connectTimeout: REQUEST_TIMEOUT_MS,
      readTimeout: REQUEST_TIMEOUT_MS
    });
    const resultStr = res.result.toString();
    if (res.responseCode < 200 || res.responseCode >= 300) {
      throw new Error(`HTTP ${res.responseCode}: ${resultStr}`);
    }
    const resObj = JSON.parse(resultStr) as ChatResponse;
    if (resObj.choices && resObj.choices.length > 0 && resObj.choices[0].message &&
      resObj.choices[0].message.content) {
      return resObj.choices[0].message.content.trim();
    }
    throw new Error(`API 返回格式错误: ${resultStr}`);
  } catch (err) {
    const message = JSON.stringify(err);
    console.error(`DeepSeek 调用失败: ${message}`);
    throw new Error(message);
  } finally {
    httpClient.destroy();
  }
}

export async function analyzeAlarm(alarmJsonStr: string): Promise<AiAnalysisResult> {
  const prompt = `你是仓储巡检告警分析专家。只输出标准 JSON，不要输出 Markdown 和多余说明。
输出字段：
summary：一句话概括异常；
risk：说明对仓储通道、安全巡检或设备运行的风险；
solve：字符串数组，给出 3 条现场处置步骤。`;
  const result = await chat(prompt, `告警数据：${alarmJsonStr}`);
  const cleanResult = cleanMarkdownCodeBlock(result);
  try {
    return JSON.parse(cleanResult) as AiAnalysisResult;
  } catch (err) {
    throw new Error(`模型返回不是合法 JSON: ${cleanResult}`);
  }
}

export async function queryAlarmQuestion(alarmJsonStr: string, question: string): Promise<string> {
  const prompt = '结合仓储巡检告警数据，用中文简短、专业地回答用户问题。不要编造不存在的告警，适配手机展示。';
  const input = `告警信息：${alarmJsonStr}\n用户问题：${question}`;
  const result = await chat(prompt, input);
  return cleanMarkdownCodeBlock(result);
}
