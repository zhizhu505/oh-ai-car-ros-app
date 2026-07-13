import resourceManager from '@ohos.resourceManager';
import { util } from '@kit.ArkTS';

export class EnvUtil {
  private static instance: EnvUtil;
  private envMap: Map<string, string> = new Map();

  private constructor() {}

  static getInstance(): EnvUtil {
    if (!EnvUtil.instance) {
      EnvUtil.instance = new EnvUtil();
    }
    return EnvUtil.instance;
  }

  async init(manager: resourceManager.ResourceManager): Promise<void> {
    try {
      const content: Uint8Array = await manager.getRawFileContent('config.env');
      const decoder: util.TextDecoder = util.TextDecoder.create('utf-8');
      const textContent: string = decoder.decodeToString(content);
      this.parseEnv(textContent);
    } catch (err) {
      console.error(`EnvUtil init failed: ${err}`);
    }
  }

  private parseEnv(content: string): void {
    const lines = content.split('\n');
    for (const line of lines) {
      const trimmedLine = line.trim();
      if (!trimmedLine || trimmedLine.startsWith('#')) {
        continue;
      }
      const parts = trimmedLine.split('=', 2);
      const key = parts[0];
      const value = parts[1];
      if (key && value) {
        this.envMap.set(key.trim(), value.trim());
      }
    }
  }

  get(key: string, defaultValue: string = ''): string {
    return this.envMap.get(key) || defaultValue;
  }

  set(key: string, value: string): void {
    this.envMap.set(key, value);
  }
}
