import { TCPClientManager } from './TCPClientManager';

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

export interface RedBottleDemoStatus {
  type: string;
  status: string;
  distance_m: number | null;
  threshold_m: number;
  speed_mps: number;
  detection: boolean;
  alarm_active: boolean;
  message: string;
  updated_at: number;
}

type PatrolCmdPayload = StartPatrolPayload | SetModePayload | SimpleCmdPayload;

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
    const response = await TCPClientManager.getInstance().requestMessageFromPort(6600, message);
    if (response.length === 0) {
      console.error(TAG, 'sendDemo empty response');
      return false;
    }
    try {
      const line = response.split('\n')[0];
      const reply = JSON.parse(line) as DemoCommandReply;
      if (!reply.ok) {
        console.error(TAG, `sendDemo rejected: ${reply.message}`);
      }
      return reply.ok === true;
    } catch (e) {
      console.error(TAG, 'sendDemo parse failed', JSON.stringify(e));
      return false;
    }
  }

  private static defaultRedBottleStatus(message: string): RedBottleDemoStatus {
    return {
      type: 'red_bottle_status',
      status: '未启动',
      distance_m: null,
      threshold_m: 0.30,
      speed_mps: 0.05,
      detection: false,
      alarm_active: false,
      message: message,
      updated_at: 0
    };
  }
}
