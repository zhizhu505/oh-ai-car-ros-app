import { TCPClientManager } from '../tcp/TCPClientManager'
import { CarEncode } from './CarEncode';
import { CarDirection } from './CarEnum';
import { RosbridgeWebSocket } from '../tcp/RosbridgeWebSocket';

class CarApi {
  /**
   *
   * @param d
   */
  carBtnCtrl(d: CarDirection) {
    this.send(CarEncode.ButtonCarEncode(d))
  }

  send(message: string): Promise<boolean> {
    return TCPClientManager.getInstance().sendMessage(message)
  }

  async enterManualMode(): Promise<boolean> {
    const rosbridge = RosbridgeWebSocket.getInstance();
    if (!rosbridge.isConnected()) {
      return false;
    }
    return rosbridge.sendTopicMessage('/app_cmd_receive', 'manual_mode');
  }

  async sendWheelSpeeds(l1: number, l2: number, r1: number, r2: number): Promise<boolean> {
    const leftFront = this.clampWheelSpeed(l1);
    const leftRear = this.clampWheelSpeed(l2);
    const rightFront = this.clampWheelSpeed(r1);
    const rightRear = this.clampWheelSpeed(r2);
    const rosbridge = RosbridgeWebSocket.getInstance();
    if (rosbridge.isConnected()) {
      return rosbridge.sendTopicMessage('/app_manual_cmd',
        `wheels:${leftFront},${leftRear},${rightFront},${rightRear}`);
    }
    return this.send(CarEncode.UpSpeedCarEncode(leftFront, leftRear, rightFront, rightRear));
  }

  async stopManualControl(): Promise<boolean> {
    return this.sendWheelSpeeds(0, 0, 0, 0);
  }

  private clampWheelSpeed(value: number): number {
    return Math.max(-100, Math.min(100, Math.round(value)));
  }
}


let carApi = (new CarApi())

export { carApi, }
