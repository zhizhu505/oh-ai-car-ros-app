/** 异常等级 */
export enum AlertLevel {
  Normal = 'normal',
  Warning = 'warning',
  Critical = 'critical'
}

/** 巡检状态 */
export enum PatrolStatus {
  Idle = 'idle',
  Patrolling = 'patrolling',
  Paused = 'paused',
  Navigating = 'navigating',
  Avoiding = 'avoiding',
  Alerting = 'alerting',
  Returning = 'returning'
}

/** 控制模式 */
export enum ControlMode {
  Manual = 'manual',
  Auto = 'auto'
}

/** 通道占用状态 */
export enum ChannelStatus {
  Clear = 'clear',
  SlowDown = 'slow_down',
  Blocked = 'blocked',
  Occupied = 'occupied'
}

/** 巡检点 */
export interface PatrolPoint {
  id: string;
  name: string;
  visited: boolean;
  abnormal: boolean;
}

/** 环境数据快照 */
export interface EnvSnapshot {
  point: string;
  temperature: number;
  humidity: number;
  smoke: number;
  gas: number;
  light: number;
  pressure: number;
  pm25: number;
  level: AlertLevel;
  updateTime: string;
}

export interface EnvHistoryRecord {
  time: string;
  temperature: number;
  humidity: number;
  gas: number;
  light: number;
  pm25: number;
}

export interface EnvMetricMeta {
  key: string;
  name: string;
  unit: string;
}

export interface AiAnalysisResult {
  summary: string;
  risk: string;
  solve: string[];
}

export interface AlarmData {
  alarm_id: string;
  time: string;
  point: string;
  alarm_type: string;
  message: string;
  level: string;
}

/** 异常告警记录 */
export interface AlertRecord {
  id: string;
  time: string;
  point: string;
  category: string;
  message: string;
  level: AlertLevel;
  imageUrl: string;
  aiAnalysis?: AiAnalysisResult;
  aiAnalyzing?: boolean;
}

/** 雷达通道状态 */
export interface LidarSnapshot {
  point: string;
  frontDistance: number;
  leftDistance: number;
  rightDistance: number;
  channelStatus: ChannelStatus;
  message: string;
  updateTime: string;
  avoidanceEnabled: boolean;
  trackingEnabled: boolean;
  avoidanceStatus: 'idle' | 'scanning' | 'avoiding' | 'tracking';
  targetDistance: number;
}

/** 视觉检测状态 */
export interface VisionSnapshot {
  point: string;
  personDetected: boolean;
  boxInChannel: boolean;
  message: string;
  imageUrl: string;
  updateTime: string;
}

/** 视觉模块运行日志 */
export interface VisionLogRecord {
  time: string;
  point: string;
  message: string;
  personDetected: boolean;
  boxInChannel: boolean;
}

/** 小车整体状态 */
export interface VehicleSnapshot {
  online: boolean;
  patrolStatus: PatrolStatus;
  controlMode: ControlMode;
  currentPoint: string;
  nextPoint: string;
  progress: number;
  route: string;
  lidarStatus: ChannelStatus;
  visionStatus: string;
  message: string;
}

/** 地下管廊环境阈值 */
export interface EnvThreshold {
  name: string;
  unit: string;
  min: number;
  max: number;
  warningMax: number;
  criticalMax: number;
}

export const DEFAULT_PATROL_POINTS: PatrolPoint[] = [
  { id: 'P1', name: '管廊入口', visited: false, abnormal: false },
  { id: 'P2', name: 'A区管线左侧', visited: false, abnormal: false },
  { id: 'P3', name: 'A区管线右侧', visited: false, abnormal: false },
  { id: 'P4', name: 'B区设备段', visited: false, abnormal: false },
  { id: 'P5', name: '高风险设备区', visited: false, abnormal: false },
  { id: 'P6', name: '返回起点', visited: false, abnormal: false }
];

export const ENV_THRESHOLDS: EnvThreshold[] = [
  { name: '温度', unit: '℃', min: 16, max: 32, warningMax: 32, criticalMax: 38 },
  { name: '湿度', unit: '%', min: 35, max: 75, warningMax: 75, criticalMax: 85 },
  { name: '可燃气体', unit: 'ppm', min: 0, max: 25, warningMax: 25, criticalMax: 50 },
  { name: 'PM2.5', unit: 'μg/m³', min: 0, max: 75, warningMax: 75, criticalMax: 115 },
  { name: '光照', unit: 'lux', min: 100, max: 500, warningMax: 100, criticalMax: 50 }
];

export const ENV_METRICS: EnvMetricMeta[] = [
  { key: 'temperature', name: '温度', unit: '℃' },
  { key: 'humidity', name: '湿度', unit: '%' },
  { key: 'gas', name: '可燃气体', unit: 'ppm' },
  { key: 'pm25', name: 'PM2.5', unit: 'μg/m³' },
  { key: 'light', name: '光照', unit: 'lux' }
];

export function createDefaultEnv(): EnvSnapshot {
  return {
    point: '地下管廊',
    temperature: 24.8,
    humidity: 58,
    smoke: 0,
    gas: 14,
    light: 220,
    pressure: 1012,
    pm25: 36,
    level: AlertLevel.Normal,
    updateTime: '-'
  };
}

export function createDefaultVehicle(): VehicleSnapshot {
  return {
    online: false,
    patrolStatus: PatrolStatus.Idle,
    controlMode: ControlMode.Manual,
    currentPoint: 'P1',
    nextPoint: 'P2',
    progress: 0,
    route: 'warehouse_A',
    lidarStatus: ChannelStatus.Clear,
    visionStatus: 'normal',
    message: '等待连接'
  };
}

export function createDefaultLidar(): LidarSnapshot {
  return {
    point: '-',
    frontDistance: 0,
    leftDistance: 0,
    rightDistance: 0,
    channelStatus: ChannelStatus.Clear,
    message: '等待数据',
    updateTime: '-',
    avoidanceEnabled: false,
    trackingEnabled: false,
    avoidanceStatus: 'idle',
    targetDistance: 0
  };
}

export function createDefaultVision(): VisionSnapshot {
  return {
    point: '-',
    personDetected: false,
    boxInChannel: false,
    message: '等待数据',
    imageUrl: '',
    updateTime: '-'
  };
}

export function alertLevelText(level: AlertLevel): string {
  if (level === AlertLevel.Warning) {
    return '预警';
  }
  if (level === AlertLevel.Critical) {
    return '严重异常';
  }
  return '正常';
}

export function patrolStatusText(status: PatrolStatus): string {
  switch (status) {
    case PatrolStatus.Patrolling:
      return '巡检中';
    case PatrolStatus.Paused:
      return '已暂停';
    case PatrolStatus.Navigating:
      return '正在导航';
    case PatrolStatus.Avoiding:
      return '避障中';
    case PatrolStatus.Alerting:
      return '异常告警中';
    case PatrolStatus.Returning:
      return '返回起点';
    default:
      return '空闲';
  }
}

export function channelStatusText(status: ChannelStatus): string {
  switch (status) {
    case ChannelStatus.SlowDown:
      return '减速通行';
    case ChannelStatus.Blocked:
      return '通道堵塞';
    case ChannelStatus.Occupied:
      return '通道占用';
    default:
      return '通道畅通';
  }
}

export const ALERT_CATEGORY_ENV = 'env';
export const ALERT_CATEGORY_LIDAR = 'lidar';
export const ALERT_CATEGORY_VISION = 'vision';
export const ALERT_CATEGORY_PATROL = 'patrol';

export function categoryLabel(category: string): string {
  if (category === ALERT_CATEGORY_ENV) {
    return '环境异常';
  }
  if (category === ALERT_CATEGORY_LIDAR) {
    return '通道占用';
  }
  if (category === ALERT_CATEGORY_VISION) {
    return '视觉异常';
  }
  if (category === ALERT_CATEGORY_PATROL) {
    return '巡检异常';
  }
  return category;
}
