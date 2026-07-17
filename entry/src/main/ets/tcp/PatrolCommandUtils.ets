import { TCPClientManager } from './TCPClientManager';
import { CAR_CONTROL_TCP_PORT } from '../utils/PreferencesUtils';
import { RosbridgeWebSocket } from './RosbridgeWebSocket';

const TAG = 'PatrolCommandUtils';

export type PatrolRoute = 'warehouse_A' | 'warehouse_B';

interface StartPatrolPayload {
  cmd: string;
  route: string;
}

interface SetModePayload {
  cmd: string;
  mode: string;
}

interface SimpleCmdPayload {
  cmd: string;
}

interface DemoCommandReply {
  type: string;
  online: boolean;
  ok: boolean;
  message: string;
}

interface StartRedBottleGuardPayload {
  cmd: string;
  threshold_m: number;
  alarm_duration_s: number;
  hysteresis_m: number;
  fail_safe_stop: boolean;
}

interface StartAlertAreaGuardPayload {
  cmd: string;
  confidence: number;
  min_box_area: number;
  min_bottom_ratio: number;
  confirm_frames: number;
  forward_percent: number;
  turn_percent: number;
  turn_seconds: number;
  cooldown_seconds: number;
  control_enabled: boolean;
  publish_forward: boolean;
  fail_safe_stop: boolean;
}

export interface VoiceStatus {
  type: string;
  enabled: boolean;
  backend: string;
  message: string;
  alert_area_message: string;
  wav: string;
  updated_at: number;
}

interface SpeakVoicePayload {
  cmd: string;
  message: string;
}

interface LidarStrategyPayload {
  cmd: string;
  frontWarnM: number;
  frontStopM: number;
  channelHoldSec: number;
  shelfIdealM: number;
  shelfToleranceM: number;
  guardRegionEnabled: boolean;
}

interface LidarAvoidPayload {
  cmd: string;
  enabled: boolean;
}

interface LidarTrackPayload {
  cmd: string;
  enabled: boolean;
}

interface LidarScenePayload {
  cmd: string;
  scene: string;
  front_warn_m?: number;
  front_stop_m?: number;
  narrow_mode?: boolean;
}

export interface RedBottleDemoStatus {
  type: string;
  mode: string;
  status: string;
  distance_m: number | null;
  threshold_m: number;
  hysteresis_m: number;
  speed_mps: number;
  detection: boolean;
  alarm_active: boolean;
  guard_active: boolean;
  stop_latched: boolean;
  event: string;
  rgb_fresh?: boolean;
  depth_fresh?: boolean;
  inference_fresh?: boolean;
  vision_ready?: boolean;
  readiness_elapsed_s?: number;
  message: string;
  updated_at: number;
}

export interface AlertAreaStatus {
  type: string;
  mode: string;
  status: string;
  detection: boolean;
  confirmed: boolean;
  alarm_active: boolean;
  confidence: number;
  bbox_xyxy: number[];
  recommended_action: string;
  guard_active: boolean;
  event: string;
  rgb_fresh?: boolean;
  inference_fresh?: boolean;
  vision_ready?: boolean;
  message: string;
  updated_at: number;
}

export interface VisionGuardStatus {
  type: string;
  online: boolean;
  red_bottle: RedBottleDemoStatus;
  alert_area: AlertAreaStatus;
  event: string;
  level: string;
  recommended_action: string;
  should_stop: boolean;
  should_turn: boolean;
  message: string;
  updated_at: number;
}

type PatrolCmdPayload = StartPatrolPayload | SetModePayload | SimpleCmdPayload |
  StartRedBottleGuardPayload | StartAlertAreaGuardPayload |
  SpeakVoicePayload | LidarStrategyPayload | LidarAvoidPayload | LidarTrackPayload | LidarScenePayload;

/**
 * 向小车端发送 JSON 巡检控制命令
 */
export class PatrolCommandUtils {
  static async startPatrol(route: PatrolRoute = 'warehouse_A'): Promise<boolean> {
    const payload: StartPatrolPayload = {
      cmd: 'start_patrol',
      route: route
    };
    return PatrolCommandUtils.send(payload);
  }

  static async pausePatrol(): Promise<boolean> {
    const payload: SimpleCmdPayload = { cmd: 'pause_patrol' };
    return PatrolCommandUtils.send(payload);
  }

  static async resumePatrol(): Promise<boolean> {
    const payload: SimpleCmdPayload = { cmd: 'resume_patrol' };
    return PatrolCommandUtils.send(payload);
  }

  static async returnHome(): Promise<boolean> {
    const payload: SimpleCmdPayload = { cmd: 'return_home' };
    return PatrolCommandUtils.send(payload);
  }

  static async stopPatrol(): Promise<boolean> {
    const payload: SimpleCmdPayload = { cmd: 'stop_patrol' };
    return PatrolCommandUtils.send(payload);
  }

  static async startRedBottleDemo(): Promise<boolean> {
    const payload: SimpleCmdPayload = { cmd: 'start_red_bottle_demo' };
    return PatrolCommandUtils.sendDemo(payload);
  }

  static async stopRedBottleDemo(): Promise<boolean> {
    const payload: SimpleCmdPayload = { cmd: 'stop_red_bottle_demo' };
    return PatrolCommandUtils.sendDemo(payload);
  }

  static async stopBuzzer(): Promise<boolean> {
    const payload: SimpleCmdPayload = { cmd: 'stop_buzzer' };
    return PatrolCommandUtils.sendDemo(payload);
  }

  static async emergencyStopRedBottleDemo(): Promise<boolean> {
    const payload: SimpleCmdPayload = { cmd: 'emergency_stop_red_bottle_demo' };
    return PatrolCommandUtils.sendDemo(payload);
  }

  static async startRedBottleGuard(
    thresholdM: number = 0.30,
    alarmDurationS: number = 3.0,
    hysteresisM: number = 0.10,
    failSafeStop: boolean = true
  ): Promise<boolean> {
    const payload: StartRedBottleGuardPayload = {
      cmd: 'start_red_bottle_guard',
      threshold_m: thresholdM,
      alarm_duration_s: alarmDurationS,
      hysteresis_m: hysteresisM,
      fail_safe_stop: failSafeStop
    };
    return PatrolCommandUtils.sendDemo(payload);
  }

  static async stopRedBottleGuard(): Promise<boolean> {
    const payload: SimpleCmdPayload = { cmd: 'stop_red_bottle_guard' };
    return PatrolCommandUtils.sendDemo(payload);
  }

  static async resetRedBottleLatch(): Promise<boolean> {
    const payload: SimpleCmdPayload = { cmd: 'reset_red_bottle_latch' };
    return PatrolCommandUtils.sendDemo(payload);
  }

  static async startAlertAreaGuard(
    confidence: number = 0.45,
    minBoxArea: number = 12000.0,
    minBottomRatio: number = 0.48,
    confirmFrames: number = 2,
    forwardPercent: number = 5,
    turnPercent: number = 18,
    turnSeconds: number = 1.0,
    cooldownSeconds: number = 1.5,
    controlEnabled: boolean = true,
    publishForward: boolean = true,
    failSafeStop: boolean = true
  ): Promise<boolean> {
    const payload: StartAlertAreaGuardPayload = {
      cmd: 'start_alert_area_guard',
      confidence: confidence,
      min_box_area: minBoxArea,
      min_bottom_ratio: minBottomRatio,
      confirm_frames: confirmFrames,
      forward_percent: forwardPercent,
      turn_percent: turnPercent,
      turn_seconds: turnSeconds,
      cooldown_seconds: cooldownSeconds,
      control_enabled: controlEnabled,
      publish_forward: publishForward,
      fail_safe_stop: failSafeStop
    };
    return PatrolCommandUtils.sendDemo(payload);
  }

  static async testVisionVoice(message: string = '视觉语音播报测试'): Promise<boolean> {
    const payload: SpeakVoicePayload = {
      cmd: 'test_vision_voice',
      message: message
    };
    return PatrolCommandUtils.sendDemo(payload);
  }

  static async speakVoice(message: string): Promise<boolean> {
    const payload: SpeakVoicePayload = {
      cmd: 'speak_voice',
      message: message
    };
    return PatrolCommandUtils.sendDemo(payload);
  }

  static async getVoiceStatus(): Promise<VoiceStatus> {
    const payload: SimpleCmdPayload = { cmd: 'get_voice_status' };
    const message = `${JSON.stringify(payload)}\n`;
    const response = await TCPClientManager.getInstance().requestMessageFromPort(6600, message);
    if (response.length === 0) {
      return PatrolCommandUtils.defaultVoiceStatus('状态服务无响应');
    }
    try {
      const line = response.split('\n')[0];
      const status = JSON.parse(line) as VoiceStatus;
      if (!status.type) {
        return PatrolCommandUtils.defaultVoiceStatus('状态数据异常');
      }
      return status;
    } catch (e) {
      console.error(TAG, 'getVoiceStatus parse failed', JSON.stringify(e));
      return PatrolCommandUtils.defaultVoiceStatus('状态解析失败');
    }
  }

  static async stopAlertAreaGuard(): Promise<boolean> {
    const payload: SimpleCmdPayload = { cmd: 'stop_alert_area_guard' };
    return PatrolCommandUtils.sendDemo(payload);
  }

  static async pushLidarStrategy(strategy: LidarStrategyPayload): Promise<boolean> {
    strategy.cmd = 'set_lidar_strategy';
    console.info(TAG, `pushLidarStrategy called, strategy=${JSON.stringify(strategy)}`);
    const result = await PatrolCommandUtils.sendStrategy(strategy);
    console.info(TAG, `pushLidarStrategy result: ${result}`);
    return result;
  }

  static async enableLidarAvoidance(enabled: boolean): Promise<boolean> {
    console.info(TAG, `enableLidarAvoidance called, enabled=${enabled}`);
    const cmd = enabled ? 'start_auto' : 'stop_auto';
    const result = await RosbridgeWebSocket.getInstance().sendTopicMessage('/app_cmd_receive', cmd);
    console.info(TAG, `enableLidarAvoidance result: ${result}`);
    return result;
  }

  static async enableLidarTracking(enabled: boolean): Promise<boolean> {
    console.info(TAG, `enableLidarTracking called, enabled=${enabled}`);
    const cmd = enabled ? 'start_tracking' : 'stop_tracking';
    const result = await RosbridgeWebSocket.getInstance().sendTopicMessage('/app_cmd_receive', cmd);
    console.info(TAG, `enableLidarTracking result: ${result}`);
    return result;
  }

  static async startAutoAvoidance(): Promise<boolean> {
    return RosbridgeWebSocket.getInstance().sendTopicMessage('/app_cmd_receive', 'start_auto');
  }

  static async stopAutoAvoidance(): Promise<boolean> {
    return RosbridgeWebSocket.getInstance().sendTopicMessage('/app_cmd_receive', 'stop_auto');
  }

  static async setNarrowMode(enabled: boolean): Promise<boolean> {
    const cmd = enabled ? 'slow' : 'fast';
    return RosbridgeWebSocket.getInstance().sendTopicMessage('/app_cmd_receive', cmd);
  }

  static async setFrontWarnThreshold(frontWarnM: number): Promise<boolean> {
    return RosbridgeWebSocket.getInstance().sendTopicMessage('/app_cmd_receive',
      `set_front:${frontWarnM.toFixed(2)}`);
  }

  static async requestLidarSnapshot(): Promise<string> {
    const payload: SimpleCmdPayload = { cmd: 'get_lidar_snapshot' };
    const message = `${JSON.stringify(payload)}\n`;
    return TCPClientManager.getInstance().requestMessageFromPort(CAR_CONTROL_TCP_PORT, message);
  }

  static async getRedBottleStatus(): Promise<RedBottleDemoStatus> {
    const payload: SimpleCmdPayload = { cmd: 'get_red_bottle_status' };
    const message = `${JSON.stringify(payload)}\n`;
    const response = await TCPClientManager.getInstance().requestMessageFromPort(6600, message);
    if (response.length === 0) {
      return PatrolCommandUtils.defaultRedBottleStatus('状态服务无响应');
    }
    try {
      const line = response.split('\n')[0];
      const status = JSON.parse(line) as RedBottleDemoStatus;
      if (!status.status) {
        return PatrolCommandUtils.defaultRedBottleStatus('状态数据异常');
      }
      return status;
    } catch (e) {
      console.error(TAG, 'getRedBottleStatus parse failed', JSON.stringify(e));
      return PatrolCommandUtils.defaultRedBottleStatus('状态解析失败');
    }
  }

  static async getAlertAreaStatus(): Promise<AlertAreaStatus> {
    const payload: SimpleCmdPayload = { cmd: 'get_alert_area_status' };
    const message = `${JSON.stringify(payload)}\n`;
    const response = await TCPClientManager.getInstance().requestMessageFromPort(6600, message);
    if (response.length === 0) {
      return PatrolCommandUtils.defaultAlertAreaStatus('状态服务无响应');
    }
    try {
      const line = response.split('\n')[0];
      const status = JSON.parse(line) as AlertAreaStatus;
      if (!status.status) {
        return PatrolCommandUtils.defaultAlertAreaStatus('状态数据异常');
      }
      return status;
    } catch (e) {
      console.error(TAG, 'getAlertAreaStatus parse failed', JSON.stringify(e));
      return PatrolCommandUtils.defaultAlertAreaStatus('状态解析失败');
    }
  }

  static async getVisionGuardStatus(): Promise<VisionGuardStatus> {
    const payload: SimpleCmdPayload = { cmd: 'get_vision_guard_status' };
    const message = `${JSON.stringify(payload)}\n`;
    const response = await TCPClientManager.getInstance().requestMessageFromPort(6600, message);
    if (response.length === 0) {
      return PatrolCommandUtils.defaultVisionGuardStatus('状态服务无响应');
    }
    try {
      const line = response.split('\n')[0];
      const status = JSON.parse(line) as VisionGuardStatus;
      if (!status.type) {
        return PatrolCommandUtils.defaultVisionGuardStatus('状态数据异常');
      }
      return status;
    } catch (e) {
      console.error(TAG, 'getVisionGuardStatus parse failed', JSON.stringify(e));
      return PatrolCommandUtils.defaultVisionGuardStatus('状态解析失败');
    }
  }

  static async setControlMode(mode: 'manual' | 'auto'): Promise<boolean> {
    const payload: SetModePayload = {
      cmd: 'set_mode',
      mode: mode
    };
    return PatrolCommandUtils.send(payload);
  }

  private static async send(payload: PatrolCmdPayload): Promise<boolean> {
    const message = `${JSON.stringify(payload)}\n`;
    console.info(TAG, 'send', message);
    return TCPClientManager.getInstance().sendMessage(message);
  }

  private static async sendDemo(payload: PatrolCmdPayload): Promise<boolean> {
    const message = `${JSON.stringify(payload)}\n`;
    console.info(TAG, 'sendDemo', message);
    const ok = await TCPClientManager.getInstance().sendMessageToPort(6600, message);
    if (!ok) {
      console.error(TAG, 'sendDemo send failed');
      return false;
    }
    console.info(TAG, 'sendDemo success');
    return true;
  }

  private static async sendStrategy(payload: LidarStrategyPayload): Promise<boolean> {
    const message = `${JSON.stringify(payload)}\n`;
    console.info(TAG, 'sendStrategy', `message=${message}`);
    return TCPClientManager.getInstance().sendMessage(message);
  }

  private static async sendAvoid(payload: LidarAvoidPayload): Promise<boolean> {
    const message = `${JSON.stringify(payload)}\n`;
    console.info(TAG, 'sendAvoid', `message=${message}`);
    return TCPClientManager.getInstance().sendMessage(message);
  }

  private static async sendTrack(payload: LidarTrackPayload): Promise<boolean> {
    const message = `${JSON.stringify(payload)}\n`;
    console.info(TAG, 'sendTrack', `message=${message}`);
    return TCPClientManager.getInstance().sendMessage(message);
  }

  private static async sendScene(payload: LidarScenePayload): Promise<boolean> {
    const message = `${JSON.stringify(payload)}\n`;
    console.info(TAG, 'sendScene', `message=${message}`);
    return TCPClientManager.getInstance().sendMessage(message);
  }

  private static defaultRedBottleStatus(message: string): RedBottleDemoStatus {
    return {
      type: 'red_bottle_status',
      mode: 'idle',
      status: '未启动',
      distance_m: null,
      threshold_m: 0.60,
      hysteresis_m: 0.10,
      speed_mps: 0.05,
      detection: false,
      alarm_active: false,
      guard_active: false,
      stop_latched: false,
      event: '',
      rgb_fresh: false,
      depth_fresh: false,
      inference_fresh: false,
      vision_ready: false,
      readiness_elapsed_s: 0,
      message: message,
      updated_at: 0
    };
  }

  private static defaultAlertAreaStatus(message: string): AlertAreaStatus {
    return {
      type: 'alert_area_status',
      mode: 'idle',
      status: '未启动',
      detection: false,
      confirmed: false,
      alarm_active: false,
      confidence: 0.0,
      bbox_xyxy: [],
      recommended_action: 'forward',
      guard_active: false,
      event: '',
      rgb_fresh: false,
      inference_fresh: false,
      vision_ready: false,
      message: message,
      updated_at: 0
    };
  }

  private static defaultVisionGuardStatus(message: string): VisionGuardStatus {
    return {
      type: 'vision_guard_status',
      online: false,
      red_bottle: PatrolCommandUtils.defaultRedBottleStatus(message),
      alert_area: PatrolCommandUtils.defaultAlertAreaStatus(message),
      event: '',
      level: 'normal',
      recommended_action: 'forward',
      should_stop: false,
      should_turn: false,
      message: message,
      updated_at: 0
    };
  }

  private static defaultVoiceStatus(message: string): VoiceStatus {
    return {
      type: 'voice_status',
      enabled: false,
      backend: '',
      message: message,
      alert_area_message: '',
      wav: '',
      updated_at: 0
    };
  }
}
