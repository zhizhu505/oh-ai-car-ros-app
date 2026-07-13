import { carApi } from '../CarUtill/CarApi'
import { CarEncode } from '../CarUtill/CarEncode';
import { RockerComponent, RockerOptions } from "rocker"

@Component
struct CarRockerComponents {
  tiltStyle: ImageBitmap = new ImageBitmap("img/remote.svg");
  backgroundStyle: ImageBitmap = new ImageBitmap("img/remote_background.svg");
  private rockerOptions: RockerOptions = new RockerOptions()
  private lastSendTime: number = 0;
  private lastL: number = 0;
  private lastR: number = 0;

  aboutToAppear(): void {
    this.rockerOptions.tiltWidth = 0.6
    this.rockerOptions.getTiltStyle = (): ImageBitmap => this.tiltStyle
    this.rockerOptions.getBackgroundStyle = (): ImageBitmap => this.backgroundStyle
    this.rockerOptions.tiltEvent = (tiltX: number, tiltY: number, event?: TouchEvent): void => {
      this.sendSteeringCommand(tiltX, tiltY, event);
    }
  }

  build(): void {
    RockerComponent({
      rockerOptions: this.rockerOptions
    })
  }

  private sendSteeringCommand(tiltX: number, tiltY: number, event?: TouchEvent): void {
    const deadZone = 8;
    let forward = Math.abs(tiltY) < deadZone ? 0 : tiltY;
    let turn = Math.abs(tiltX) < deadZone ? 0 : tiltX;

    if (event && event.type === TouchType.Up) {
      forward = 0;
      turn = 0;
    }

    const turnGain = Math.abs(forward) > 0 ? 0.72 : 0.88;
    let leftSpeed = forward + turn * turnGain;
    let rightSpeed = forward - turn * turnGain;
    const maxSpeed = Math.max(100, Math.abs(leftSpeed), Math.abs(rightSpeed));
    leftSpeed = leftSpeed / maxSpeed * 100;
    rightSpeed = rightSpeed / maxSpeed * 100;

    const left = Math.round(this.clamp(leftSpeed, -100, 100));
    const right = Math.round(this.clamp(rightSpeed, -100, 100));
    const now = Date.now();
    const isStop = left === 0 && right === 0;
    if (!isStop && now - this.lastSendTime < 70) {
      return;
    }
    if (left === this.lastL && right === this.lastR) {
      return;
    }

    this.lastSendTime = now;
    this.lastL = left;
    this.lastR = right;
    carApi.send(CarEncode.UpSpeedCarEncode(left, left, right, right));
  }

  private clamp(value: number, min: number, max: number): number {
    return Math.max(min, Math.min(max, value));
  }
}

export { CarRockerComponents }
