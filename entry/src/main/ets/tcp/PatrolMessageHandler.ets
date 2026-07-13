import {
  AlertLevel,
  ChannelStatus,
  ControlMode,
  EnvSnapshot,
  LidarSnapshot,
  PatrolStatus,
  VisionSnapshot
} from '../model/PatrolModels';
import { PatrolStore } from '../store/PatrolStore';

const TAG = 'PatrolMessageHandler';

/**
 * 解析小车端 JSON 巡检协议
 */
export class PatrolMessageHandler {
  private static buffer: string = '';

  static init(): void {
    PatrolMessageHandler.buffer = '';
  }

  static handleMessage(raw: string): void {
    PatrolMessageHandler.buffer += raw;
    const parts = PatrolMessageHandler.buffer.split('\n');
    PatrolMessageHandler.buffer = parts.pop() ?? '';

    parts.forEach((part: string): void => {
      PatrolMessageHandler.parseLine(part.trim());
    });

    const remain = PatrolMessageHandler.buffer.trim();
    if (remain.startsWith('{') && remain.endsWith('}')) {
      PatrolMessageHandler.parseLine(remain);
      PatrolMessageHandler.buffer = '';
    }
  }

  private static parseLine(line: string): void {
    if (!line.startsWith('{')) {
      return;
    }
    try {
      const payload = JSON.parse(line) as Record<string, Object>;
      PatrolMessageHandler.dispatch(payload);
    } catch (e) {
      console.error(TAG, 'JSON parse error', JSON.stringify(e));
    }
  }

  private static dispatch(payload: Record<string, Object>): void {
    const type = PatrolMessageHandler.readString(payload, 'type');
    if (type === 'env') {
      PatrolMessageHandler.handleEnv(payload);
      return;
    }
    if (type === 'patrol') {
      PatrolMessageHandler.handlePatrol(payload);
      return;
    }
    if (type === 'alert') {
      PatrolMessageHandler.handleAlert(payload);
      return;
    }
    if (type === 'lidar') {
      PatrolMessageHandler.handleLidar(payload);
      return;
    }
    if (type === 'vision') {
      PatrolMessageHandler.handleVision(payload);
      return;
    }
    if (type === 'status') {
      PatrolMessageHandler.handleStatus(payload);
      return;
    }
    if (payload['cmd'] !== undefined) {
      return;
    }
    console.info(TAG, 'unknown message', JSON.stringify(payload));
  }

  private static handleEnv(payload: Record<string, Object>): void {
    const store = PatrolStore.getInstance();
    const env: EnvSnapshot = {
      point: PatrolMessageHandler.readString(payload, 'point', store.env.point),
      temperature: PatrolMessageHandler.readNumber(payload, 'temperature', store.env.temperature),
      humidity: PatrolMessageHandler.readNumber(payload, 'humidity', store.env.humidity),
      smoke: PatrolMessageHandler.readNumber(payload, 'smoke', store.env.smoke),
      gas: PatrolMessageHandler.readNumber(payload, 'gas', store.env.gas),
      light: PatrolMessageHandler.readNumber(payload, 'light', store.env.light),
      pressure: PatrolMessageHandler.readNumber(payload, 'pressure', store.env.pressure),
      pm25: PatrolMessageHandler.readNumber(payload, 'pm25', store.env.pm25),
      level: PatrolMessageHandler.readAlertLevel(payload, 'level', store.env.level),
      updateTime: PatrolMessageHandler.readString(payload, 'time', PatrolMessageHandler.nowTime())
    };
    store.updateEnv(env);
  }

  private static handlePatrol(payload: Record<string, Object>): void {
    const store = PatrolStore.getInstance();
    store.updateVehicle({
      patrolStatus: PatrolMessageHandler.readPatrolStatus(payload, 'status'),
      currentPoint: PatrolMessageHandler.readString(payload, 'currentPoint', store.vehicle.currentPoint),
      nextPoint: PatrolMessageHandler.readString(payload, 'nextPoint', store.vehicle.nextPoint),
      progress: PatrolMessageHandler.readNumber(payload, 'progress', store.vehicle.progress),
      route: PatrolMessageHandler.readString(payload, 'route', store.vehicle.route),
      message: PatrolMessageHandler.readString(payload, 'message', '巡检状态更新')
    });
  }

  private static handleAlert(payload: Record<string, Object>): void {
    const store = PatrolStore.getInstance();
    store.createAlert(
      PatrolMessageHandler.readString(payload, 'time', PatrolMessageHandler.nowTime()),
      PatrolMessageHandler.readString(payload, 'point', '-'),
      PatrolMessageHandler.readString(payload, 'category', 'unknown'),
      PatrolMessageHandler.readString(payload, 'message', '检测到异常'),
      PatrolMessageHandler.readAlertLevel(payload, 'level', AlertLevel.Warning),
      PatrolMessageHandler.readString(payload, 'imageUrl', '')
    );
    if (PatrolMessageHandler.readString(payload, 'status') === 'alerting') {
      store.updateVehicle({ patrolStatus: PatrolStatus.Alerting });
    }
  }

  private static handleLidar(payload: Record<string, Object>): void {
    const store = PatrolStore.getInstance();
    const lidar: LidarSnapshot = {
      point: PatrolMessageHandler.readString(payload, 'point', store.lidar.point),
      frontDistance: PatrolMessageHandler.readNumber(payload, 'frontDistance', store.lidar.frontDistance),
      leftDistance: PatrolMessageHandler.readNumber(payload, 'leftDistance', store.lidar.leftDistance),
      rightDistance: PatrolMessageHandler.readNumber(payload, 'rightDistance', store.lidar.rightDistance),
      channelStatus: PatrolMessageHandler.readChannelStatus(payload, 'channelStatus'),
      message: PatrolMessageHandler.readString(payload, 'message', '雷达状态更新'),
      updateTime: PatrolMessageHandler.readString(payload, 'time', PatrolMessageHandler.nowTime()),
      avoidanceEnabled: store.lidar.avoidanceEnabled,
      trackingEnabled: store.lidar.trackingEnabled,
      avoidanceStatus: store.lidar.avoidanceStatus,
      targetDistance: store.lidar.targetDistance
    };
    store.updateLidar(lidar);
    if (lidar.channelStatus === ChannelStatus.Blocked || lidar.channelStatus === ChannelStatus.Occupied) {
      store.updateVehicle({ patrolStatus: PatrolStatus.Avoiding, message: lidar.message });
    }
  }

  private static handleVision(payload: Record<string, Object>): void {
    const store = PatrolStore.getInstance();
    const vision: VisionSnapshot = {
      point: PatrolMessageHandler.readString(payload, 'point', store.vision.point),
      personDetected: PatrolMessageHandler.readBoolean(payload, 'personDetected'),
      boxInChannel: PatrolMessageHandler.readBoolean(payload, 'boxInChannel'),
      message: PatrolMessageHandler.readString(payload, 'message', '视觉检测更新'),
      imageUrl: PatrolMessageHandler.readString(payload, 'imageUrl', ''),
      updateTime: PatrolMessageHandler.readString(payload, 'time', PatrolMessageHandler.nowTime())
    };
    store.updateVision(vision);
  }

  private static handleStatus(payload: Record<string, Object>): void {
    const store = PatrolStore.getInstance();
    store.setOnline(PatrolMessageHandler.readBoolean(payload, 'online', true));
    store.updateVehicle({
      patrolStatus: PatrolMessageHandler.readPatrolStatus(payload, 'patrolStatus', store.vehicle.patrolStatus),
      controlMode: PatrolMessageHandler.readControlMode(payload, 'controlMode', store.vehicle.controlMode),
      message: PatrolMessageHandler.readString(payload, 'message', store.vehicle.message)
    });
  }

  private static readString(payload: Record<string, Object>, key: string, fallback: string = ''): string {
    const value = payload[key];
    if (typeof value === 'string') {
      return value;
    }
    if (typeof value === 'number') {
      return `${value}`;
    }
    return fallback;
  }

  private static readNumber(payload: Record<string, Object>, key: string, fallback: number = 0): number {
    const value = payload[key];
    if (typeof value === 'number') {
      return value;
    }
    if (typeof value === 'string') {
      const parsed = Number.parseFloat(value);
      return Number.isNaN(parsed) ? fallback : parsed;
    }
    return fallback;
  }

  private static readBoolean(payload: Record<string, Object>, key: string, fallback: boolean = false): boolean {
    const value = payload[key];
    if (typeof value === 'boolean') {
      return value;
    }
    if (value === 1 || value === '1' || value === 'true') {
      return true;
    }
    if (value === 0 || value === '0' || value === 'false') {
      return false;
    }
    return fallback;
  }

  private static readAlertLevel(payload: Record<string, Object>, key: string,
    fallback: AlertLevel = AlertLevel.Normal): AlertLevel {
    const value = PatrolMessageHandler.readString(payload, key);
    if (value === AlertLevel.Warning) {
      return AlertLevel.Warning;
    }
    if (value === AlertLevel.Critical) {
      return AlertLevel.Critical;
    }
    if (value === AlertLevel.Normal) {
      return AlertLevel.Normal;
    }
    return fallback;
  }

  private static readPatrolStatus(payload: Record<string, Object>, key: string,
    fallback: PatrolStatus = PatrolStatus.Idle): PatrolStatus {
    const value = PatrolMessageHandler.readString(payload, key);
    const values: PatrolStatus[] = [
      PatrolStatus.Idle,
      PatrolStatus.Patrolling,
      PatrolStatus.Paused,
      PatrolStatus.Navigating,
      PatrolStatus.Avoiding,
      PatrolStatus.Alerting,
      PatrolStatus.Returning
    ];
    const matched = values.find((item: PatrolStatus): boolean => item === value);
    return matched ?? fallback;
  }

  private static readControlMode(payload: Record<string, Object>, key: string,
    fallback: ControlMode = ControlMode.Manual): ControlMode {
    const value = PatrolMessageHandler.readString(payload, key);
    if (value === ControlMode.Auto) {
      return ControlMode.Auto;
    }
    if (value === ControlMode.Manual) {
      return ControlMode.Manual;
    }
    return fallback;
  }

  private static readChannelStatus(payload: Record<string, Object>, key: string): ChannelStatus {
    const value = PatrolMessageHandler.readString(payload, key);
    if (value === ChannelStatus.SlowDown) {
      return ChannelStatus.SlowDown;
    }
    if (value === ChannelStatus.Blocked) {
      return ChannelStatus.Blocked;
    }
    if (value === ChannelStatus.Occupied) {
      return ChannelStatus.Occupied;
    }
    return ChannelStatus.Clear;
  }

  private static nowTime(): string {
    const now = new Date();
    const hour = now.getHours().toString().padStart(2, '0');
    const minute = now.getMinutes().toString().padStart(2, '0');
    const second = now.getSeconds().toString().padStart(2, '0');
    return `${hour}:${minute}:${second}`;
  }
}
