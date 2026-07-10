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
}
