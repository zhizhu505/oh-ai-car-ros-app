import { DEFAULT_PATROL_ROUTE_ID, RETURN_HOME_ROUTE_ID } from '../model/PatrolModels';
import { TCPClientManager } from './TCPClientManager';

const TAG = 'PatrolCommandUtils';

export interface PatrolCommandResult {
  sent: boolean;
  requestId: string;
}

interface PatrolCommandPayload {
  type: string;
  requestId: string;
  routeId?: string;
  reason?: string;
}

class PatrolCommandExtras {
  routeId?: string;
  reason?: string;
}

/**
 * Jetson 巡检桥接节点协议。
 * TCP 发送成功仅代表数据已写入 socket；任务是否生效必须以 patrol.accepted /
 * patrol.result 回包为准。
 */
export class PatrolCommandUtils {
  private static requestSequence: number = 0;

  static async startPatrol(routeId: string = DEFAULT_PATROL_ROUTE_ID): Promise<PatrolCommandResult> {
    const extras = new PatrolCommandExtras();
    extras.routeId = routeId;
    return PatrolCommandUtils.send('patrol.start', extras);
  }

  static async pausePatrol(): Promise<PatrolCommandResult> {
    return PatrolCommandUtils.send('patrol.pause', new PatrolCommandExtras());
  }

  static async resumePatrol(): Promise<PatrolCommandResult> {
    return PatrolCommandUtils.send('patrol.resume', new PatrolCommandExtras());
  }

  /** 返航也作为 Jetson 端预置路线执行，避免 App 下发任意坐标。 */
  static async returnHome(routeId: string = RETURN_HOME_ROUTE_ID): Promise<PatrolCommandResult> {
    return PatrolCommandUtils.startPatrol(routeId);
  }

  static async stopPatrol(reason: string = 'user_stop'): Promise<PatrolCommandResult> {
    const extras = new PatrolCommandExtras();
    extras.reason = reason;
    return PatrolCommandUtils.send('patrol.stop', extras);
  }

  static async queryPatrol(): Promise<PatrolCommandResult> {
    return PatrolCommandUtils.send('patrol.query', new PatrolCommandExtras());
  }

  private static async send(type: string, extra: PatrolCommandExtras):
    Promise<PatrolCommandResult> {
    const requestId = PatrolCommandUtils.createRequestId();
    const payload: PatrolCommandPayload = {
      type: type,
      requestId: requestId
    };
    if (extra.routeId !== undefined) {
      payload.routeId = extra.routeId;
    }
    if (extra.reason !== undefined) {
      payload.reason = extra.reason;
    }
    const message = `${JSON.stringify(payload)}\n`;
    console.info(TAG, 'send', message);
    const sent = await TCPClientManager.getInstance().sendMessage(message);
    return { sent: sent, requestId: requestId };
  }

  private static createRequestId(): string {
    PatrolCommandUtils.requestSequence += 1;
    return `app-${Date.now()}-${PatrolCommandUtils.requestSequence}`;
  }
}
