import {
  AlertLevel,
  AlertRecord,
  AiAnalysisResult,
  AlarmData,
  ChannelStatus,
  ControlMode,
  DEFAULT_PATROL_POINTS,
  EnvSnapshot,
  LidarSnapshot,
  PatrolPoint,
  PatrolStatus,
  VehicleSnapshot,
  VisionSnapshot,
  createDefaultEnv,
  createDefaultLidar,
  createDefaultVehicle,
  createDefaultVision
} from '../model/PatrolModels';
import { analyzeAlarm } from '../utils/DeepSeekUtil';

type StoreListener = () => void;

/**
 * 仓储巡检全局状态
 */
export class PatrolStore {
  private static instance: PatrolStore;
  private listeners: StoreListener[] = [];
  private alertIdSeed: number = 1;

  env: EnvSnapshot = createDefaultEnv();
  vehicle: VehicleSnapshot = createDefaultVehicle();
  lidar: LidarSnapshot = createDefaultLidar();
  vision: VisionSnapshot = createDefaultVision();
  patrolPoints: PatrolPoint[] = DEFAULT_PATROL_POINTS.map((p: PatrolPoint): PatrolPoint => {
    return { id: p.id, name: p.name, visited: p.visited, abnormal: p.abnormal };
  });
  alerts: AlertRecord[] = [];

  static getInstance(): PatrolStore {
    if (!PatrolStore.instance) {
      PatrolStore.instance = new PatrolStore();
    }
    return PatrolStore.instance;
  }

  subscribe(listener: StoreListener): void {
    this.listeners.push(listener);
  }

  unsubscribe(listener: StoreListener): void {
    const index = this.listeners.indexOf(listener);
    if (index >= 0) {
      this.listeners.splice(index, 1);
    }
  }

  notify(): void {
    this.listeners.forEach((listener: StoreListener): void => listener());
  }

  setOnline(online: boolean): void {
    this.vehicle.online = online;
    this.vehicle.message = online ? '已连接' : '离线';
    this.notify();
  }

  updateEnv(data: EnvSnapshot): void {
    this.env = data;
    this.notify();
  }

  updateVehicle(data: Partial<VehicleSnapshot>): void {
    if (data.online !== undefined) {
      this.vehicle.online = data.online;
    }
    if (data.patrolStatus !== undefined) {
      this.vehicle.patrolStatus = data.patrolStatus;
    }
    if (data.controlMode !== undefined) {
      this.vehicle.controlMode = data.controlMode;
    }
    if (data.currentPoint !== undefined) {
      this.vehicle.currentPoint = data.currentPoint;
    }
    if (data.nextPoint !== undefined) {
      this.vehicle.nextPoint = data.nextPoint;
    }
    if (data.progress !== undefined) {
      this.vehicle.progress = data.progress;
    }
    if (data.route !== undefined) {
      this.vehicle.route = data.route;
    }
    if (data.lidarStatus !== undefined) {
      this.vehicle.lidarStatus = data.lidarStatus;
    }
    if (data.visionStatus !== undefined) {
      this.vehicle.visionStatus = data.visionStatus;
    }
    if (data.message !== undefined) {
      this.vehicle.message = data.message;
    }
    this.syncPatrolPoints();
    this.notify();
  }

  updateLidar(data: LidarSnapshot): void {
    this.lidar = data;
    this.vehicle.lidarStatus = data.channelStatus;
    this.notify();
  }

  updateVision(data: VisionSnapshot): void {
    this.vision = data;
    this.vehicle.visionStatus = data.personDetected || data.boxInChannel ? 'alert' : 'normal';
    this.notify();
  }

  addAlert(record: AlertRecord): void {
    this.alerts.unshift(record);
    if (this.alerts.length > 100) {
      this.alerts.pop();
    }
    this.markPointAbnormal(record.point);
    this.notify();
    this.triggerAiAnalysis(record);
  }

  private async triggerAiAnalysis(record: AlertRecord): Promise<void> {
    if (record.aiAnalyzing || record.aiAnalysis) {
      return;
    }
    record.aiAnalyzing = true;
    this.notify();
    let levelStr: string = '正常';
    if (record.level === AlertLevel.Critical) {
      levelStr = '严重';
    } else if (record.level === AlertLevel.Warning) {
      levelStr = '预警';
    }
    const alarmData: AlarmData = {
      alarm_id: record.id,
      time: record.time,
      point: record.point,
      alarm_type: record.category,
      message: record.message,
      level: levelStr
    };
    try {
      const result: AiAnalysisResult = await analyzeAlarm(JSON.stringify(alarmData));
      record.aiAnalysis = result;
    } catch (err) {
      console.error(`AI分析失败: ${err}`);
      const defaultAnalysis: AiAnalysisResult = {
        summary: 'AI分析失败',
        risk: '网络异常',
        solve: ['检查网络连接']
      };
      record.aiAnalysis = defaultAnalysis;
    } finally {
      record.aiAnalyzing = false;
      this.notify();
    }
  }

  updateAiAnalysis(alertId: string, analysis: AiAnalysisResult): void {
    const record = this.alerts.find((a: AlertRecord): boolean => a.id === alertId);
    if (record) {
      record.aiAnalysis = analysis;
      record.aiAnalyzing = false;
      this.notify();
    }
  }

  createAlert(time: string, point: string, category: string, message: string,
    level: AlertLevel, imageUrl: string = ''): AlertRecord {
    const record: AlertRecord = {
      id: `alert_${this.alertIdSeed++}`,
      time: time,
      point: point,
      category: category,
      message: message,
      level: level,
      imageUrl: imageUrl
    };
    this.addAlert(record);
    return record;
  }

  clearAlerts(): void {
    this.alerts = [];
    this.notify();
  }

  resetPatrolPoints(): void {
    this.patrolPoints = DEFAULT_PATROL_POINTS.map((p: PatrolPoint): PatrolPoint => {
      return { id: p.id, name: p.name, visited: false, abnormal: false };
    });
    this.notify();
  }

  getPointName(pointId: string): string {
    const point = this.patrolPoints.find((p: PatrolPoint): boolean => p.id === pointId);
    return point ? `${point.id} ${point.name}` : pointId;
  }

  getAlertsByCategory(category: string): AlertRecord[] {
    return this.alerts.filter((item: AlertRecord): boolean => item.category === category);
  }

  private syncPatrolPoints(): void {
    const currentIndex = this.patrolPoints.findIndex((p: PatrolPoint): boolean => {
      return p.id === this.vehicle.currentPoint;
    });
    this.patrolPoints.forEach((p: PatrolPoint, index: number): void => {
      p.visited = currentIndex >= 0 && index < currentIndex;
    });
    if (currentIndex >= 0 && this.vehicle.patrolStatus === PatrolStatus.Patrolling) {
      this.patrolPoints[currentIndex].visited = true;
    }
  }

  private markPointAbnormal(point: string): void {
    const target = this.patrolPoints.find((p: PatrolPoint): boolean => {
      return point.includes(p.id) || point.includes(p.name) || p.name.includes(point);
    });
    if (target) {
      target.abnormal = true;
    }
  }
}
