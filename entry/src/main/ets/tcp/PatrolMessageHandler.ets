import {
  AlertLevel,
  ChannelStatus,
  ControlMode,
  EnvSnapshot,
  LidarSnapshot,
  PatrolStatus,
  PatrolTaskState,
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
    if (type === 'patrol.accepted') {
      PatrolMessageHandler.handlePatrolAccepted(payload);
      return;
    }
    if (type === 'patrol.progress') {
      PatrolMessageHandler.handlePatrolProgress(payload);
      return;
    }
    if (type === 'patrol.result') {
      PatrolMessageHandler.handlePatrolResult(payload);
      return;
    }
    if (type === 'patrol.alarm') {
      PatrolMessageHandler.handlePatrolAlarm(payload);
      return;
    }
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
    if (type === 'status' || type === 'patrol.status') {
      PatrolMessageHandler.handleStatus(payload);
      return;
    }
    console.info(TAG, 'unknown message', JSON.stringify(payload));
  }

  private static handlePatrolAccepted(payload: Record<string, Object>): void {
    const store = PatrolStore.getInstance();
    const routeId = PatrolMessageHandler.readString(payload, 'routeId', store.vehicle.routeId);
    const taskState = PatrolMessageHandler.readTaskState(payload, 'state', PatrolTaskState.Starting);
    store.resetPatrolPoints();
    store.updateVehicle({
      taskState: taskState,
      patrolStatus: PatrolMessageHandler.toPatrolStatus(taskState),
      controlMode: ControlMode.Auto,
      manualControlLocked: true,
      requestId: PatrolMessageHandler.readString(payload, 'requestId', store.vehicle.requestId),
      routeId: routeId,
      route: routeId,
      currentIndex: 0,
      totalWaypoints: 0,
      progress: 0,
      failureCode: '',
      finishedAt: '',
      message: PatrolMessageHandler.readString(payload, 'message', '巡检任务已被 Jetson 接受')
    });
  }

  private static handlePatrolProgress(payload: Record<string, Object>): void {
    const store = PatrolStore.getInstance();
    const taskState = PatrolMessageHandler.readTaskState(payload, 'state', PatrolTaskState.Running);
    const currentIndex = PatrolMessageHandler.readNumber(payload, 'currentIndex', store.vehicle.currentIndex);
    const totalWaypoints = PatrolMessageHandler.readNumber(payload, 'total', store.vehicle.totalWaypoints);
    const progress = totalWaypoints > 0 ? Math.min(100, Math.max(0,
      Math.round(currentIndex * 100 / totalWaypoints))) : store.vehicle.progress;
    const currentWaypoint = PatrolMessageHandler.readString(payload, 'currentWaypoint', store.vehicle.currentPoint);
    store.updateVehicle({
      taskState: taskState,
      patrolStatus: PatrolMessageHandler.toPatrolStatus(taskState),
      controlMode: ControlMode.Auto,
      manualControlLocked: true,
      currentPoint: currentWaypoint,
      nextPoint: PatrolMessageHandler.readString(payload, 'nextWaypoint', store.vehicle.nextPoint),
      currentIndex: currentIndex,
      totalWaypoints: totalWaypoints,
      progress: progress,
      message: PatrolMessageHandler.readString(payload, 'message', '巡检进度已更新')
    });
  }

  private static handlePatrolResult(payload: Record<string, Object>): void {
    const store = PatrolStore.getInstance();
    const taskState = PatrolMessageHandler.readTaskState(payload, 'state', PatrolTaskState.Failed);
    const completed = taskState === PatrolTaskState.Succeeded;
    const routeId = PatrolMessageHandler.readString(payload, 'routeId', store.vehicle.routeId);
    store.updateVehicle({
      taskState: taskState,
      patrolStatus: PatrolMessageHandler.toPatrolStatus(taskState),
      controlMode: ControlMode.Manual,
      manualControlLocked: false,
      routeId: routeId,
      route: routeId,
      currentPoint: PatrolMessageHandler.readString(payload, 'waypoint', store.vehicle.currentPoint),
      currentIndex: completed ? store.vehicle.totalWaypoints : store.vehicle.currentIndex,
      progress: completed ? 100 : store.vehicle.progress,
      failureCode: PatrolMessageHandler.readString(payload, 'code', ''),
      finishedAt: PatrolMessageHandler.readString(payload, 'finishedAt', ''),
      message: PatrolMessageHandler.readString(payload, 'message', PatrolMessageHandler.taskResultMessage(taskState))
    });
  }

  private static handlePatrolAlarm(payload: Record<string, Object>): void {
    const store = PatrolStore.getInstance();
    store.createAlert(
      PatrolMessageHandler.readString(payload, 'time', PatrolMessageHandler.nowTime()),
      PatrolMessageHandler.readString(payload, 'waypoint', store.vehicle.currentPoint),
      PatrolMessageHandler.readString(payload, 'category', 'patrol_alarm'),
      PatrolMessageHandler.readString(payload, 'message', '巡检过程中检测到异常'),
      PatrolMessageHandler.readAlertLevel(payload, 'level', AlertLevel.Warning),
      PatrolMessageHandler.readString(payload, 'imageUrl', '')
    );
  }

  private static handleEnv(payload: Record<string, Object>): void {
    const store = PatrolStore.getInstance();
    const env: EnvSnapshot = {
      point: PatrolMessageHandler.readString(payload, 'waypoint',
        PatrolMessageHandler.readString(payload, 'point', store.env.point)),
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
      point: PatrolMessageHandler.readString(payload, 'waypoint',
        PatrolMessageHandler.readString(payload, 'point', store.lidar.point)),
      frontDistance: PatrolMessageHandler.readNumber(payload, 'frontDistance', store.lidar.frontDistance),
      leftDistance: PatrolMessageHandler.readNumber(payload, 'leftDistance', store.lidar.leftDistance),
      rightDistance: PatrolMessageHandler.readNumber(payload, 'rightDistance', store.lidar.rightDistance),
      channelStatus: PatrolMessageHandler.readChannelStatus(payload, 'channelStatus'),
      message: PatrolMessageHandler.readString(payload, 'message', '雷达状态更新'),
      updateTime: PatrolMessageHandler.readString(payload, 'time', PatrolMessageHandler.nowTime())
    };
    store.updateLidar(lidar);
  }

  private static handleVision(payload: Record<string, Object>): void {
    const store = PatrolStore.getInstance();
    const vision: VisionSnapshot = {
      point: PatrolMessageHandler.readString(payload, 'waypoint',
        PatrolMessageHandler.readString(payload, 'point', store.vision.point)),
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
    const taskState = PatrolMessageHandler.readTaskState(payload, 'taskState',
      PatrolMessageHandler.readTaskState(payload, 'state', store.vehicle.taskState));
    store.updateVehicle({
      taskState: taskState,
      patrolStatus: PatrolMessageHandler.toPatrolStatus(taskState),
      controlMode: PatrolMessageHandler.readControlMode(payload, 'controlMode', store.vehicle.controlMode),
      manualControlLocked: PatrolMessageHandler.readBoolean(payload, 'manualControlLocked',
        store.vehicle.manualControlLocked),
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

  private static readTaskState(payload: Record<string, Object>, key: string,
    fallback: PatrolTaskState): PatrolTaskState {
    const value = PatrolMessageHandler.readString(payload, key);
    if (value === PatrolTaskState.Ready) {
      return PatrolTaskState.Ready;
    }
    if (value === PatrolTaskState.Starting) {
      return PatrolTaskState.Starting;
    }
    if (value === PatrolTaskState.Running) {
      return PatrolTaskState.Running;
    }
    if (value === PatrolTaskState.Paused) {
      return PatrolTaskState.Paused;
    }
    if (value === PatrolTaskState.Stopping) {
      return PatrolTaskState.Stopping;
    }
    if (value === PatrolTaskState.Succeeded) {
      return PatrolTaskState.Succeeded;
    }
    if (value === PatrolTaskState.Failed) {
      return PatrolTaskState.Failed;
    }
    if (value === PatrolTaskState.Canceled || value === 'STOPPED') {
      return PatrolTaskState.Canceled;
    }
    if (value === PatrolTaskState.Disconnected) {
      return PatrolTaskState.Disconnected;
    }
    return fallback;
  }

  private static toPatrolStatus(taskState: PatrolTaskState): PatrolStatus {
    if (taskState === PatrolTaskState.Starting) {
      return PatrolStatus.Navigating;
    }
    if (taskState === PatrolTaskState.Running) {
      return PatrolStatus.Patrolling;
    }
    if (taskState === PatrolTaskState.Paused) {
      return PatrolStatus.Paused;
    }
    if (taskState === PatrolTaskState.Stopping) {
      return PatrolStatus.Returning;
    }
    return PatrolStatus.Idle;
  }

  private static taskResultMessage(taskState: PatrolTaskState): string {
    if (taskState === PatrolTaskState.Succeeded) {
      return '巡检任务已完成';
    }
    if (taskState === PatrolTaskState.Canceled) {
      return '巡检任务已停止';
    }
    return '巡检任务失败';
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
