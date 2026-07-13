import { AlertLevel, EnvHistoryRecord, EnvSnapshot } from '../model/PatrolModels';
import { PatrolStore } from '../store/PatrolStore';

export class EnvMockService {
  private static instance: EnvMockService;
  private timerId: number = -1;
  private tick: number = 0;
  private temperature: number = 24.6;
  private humidity: number = 57.8;
  private gas: number = 13.6;
  private pm25: number = 34.5;
  private light: number = 226;

  static getInstance(): EnvMockService {
    if (!EnvMockService.instance) {
      EnvMockService.instance = new EnvMockService();
    }
    return EnvMockService.instance;
  }

  start(): void {
    if (this.timerId >= 0) {
      return;
    }
    this.seedHistory();
    this.timerId = setInterval((): void => {
      PatrolStore.getInstance().updateEnv(this.nextSnapshot());
    }, 3000);
  }

  stop(): void {
    if (this.timerId >= 0) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
  }

  private seedHistory(): void {
    const history: EnvHistoryRecord[] = [];
    for (let index = 23; index >= 0; index--) {
      history.push(this.nextHistoryRecord(index * 3));
    }
    PatrolStore.getInstance().setEnvHistory(history);
  }

  private nextSnapshot(): EnvSnapshot {
    const record = this.nextHistoryRecord(0);
    return {
      point: '地下管廊',
      temperature: record.temperature,
      humidity: record.humidity,
      smoke: 0,
      gas: record.gas,
      light: record.light,
      pressure: 1012,
      pm25: record.pm25,
      level: AlertLevel.Normal,
      updateTime: record.time
    };
  }

  private nextHistoryRecord(offsetSeconds: number): EnvHistoryRecord {
    this.tick++;
    this.temperature = this.clamp(24.5 + Math.sin(this.tick / 3.8) * 1.8 + this.randomStep(0.22), 22.1, 28.6);
    this.humidity = this.clamp(57 + Math.cos(this.tick / 4.5) * 5.4 + this.randomStep(0.9), 48, 66);
    this.gas = this.clamp(14 + Math.sin(this.tick / 5.2) * 4.2 + this.randomStep(0.65), 8, 22);
    this.pm25 = this.clamp(35 + Math.cos(this.tick / 4.1) * 10.5 + this.randomStep(1.4), 20, 52);
    this.light = this.clamp(230 + Math.sin(this.tick / 3.2) * 62 + this.randomStep(10), 145, 340);
    return {
      time: this.formatTime(offsetSeconds),
      temperature: Number(this.temperature.toFixed(1)),
      humidity: Number(this.humidity.toFixed(1)),
      gas: Number(this.gas.toFixed(1)),
      pm25: Number(this.pm25.toFixed(1)),
      light: Math.round(this.light)
    };
  }

  private randomStep(range: number): number {
    return (Math.random() - 0.5) * range * 2;
  }

  private clamp(value: number, min: number, max: number): number {
    return Math.max(min, Math.min(max, value));
  }

  private formatTime(offsetSeconds: number): string {
    const date = new Date(Date.now() - offsetSeconds * 1000);
    const hour = date.getHours().toString().padStart(2, '0');
    const minute = date.getMinutes().toString().padStart(2, '0');
    const second = date.getSeconds().toString().padStart(2, '0');
    return `${hour}:${minute}:${second}`;
  }
}
