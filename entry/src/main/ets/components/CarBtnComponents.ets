import { carApi } from '../CarUtill/CarApi'
import { CarEncode } from '../CarUtill/CarEncode'
import { CarDirection } from '../CarUtill/CarEnum'
import { ButtonShadow } from '../styles/styles'
import { PatrolCommandUtils } from '../tcp/PatrolCommandUtils'

/**
 * 按键控制UI组件
 */
@Component
struct CarBtnComponents {
  @Prop speedValue: number = 45;
  private repeatTimer: number = -1;
  private activeDirection: CarDirection = CarDirection.Stop;
  private lastVoiceMessage: string = '';
  private lastVoiceAt: number = 0;

  build(): void {
    Grid() {
      // 第一行
      GridItem() {
        Button("左转")
          .backgroundColor($r('app.color.button_background'))
          .shadow(ButtonShadow)
          .width('100%')
          .height('100%')
          .onTouch(this.makeTouchEvent(CarDirection.LeftRotate))
      }

      GridItem() {
        Button("前")
          .backgroundColor($r('app.color.button_background'))
          .shadow(ButtonShadow)
          .width('100%')
          .height('100%')
          .onTouch(this.makeTouchEvent(CarDirection.Front))
      }

      GridItem() {
        Button("右转")
          .backgroundColor($r('app.color.button_background'))
          .shadow(ButtonShadow)
          .width('100%')
          .height('100%')
          .onTouch(this.makeTouchEvent(CarDirection.RightRotate))
      }

      // 第二行
      GridItem() {
        Button("左")
          .backgroundColor($r('app.color.button_background'))
          .shadow(ButtonShadow)
          .width('100%')
          .height('100%')
          .onTouch(this.makeTouchEvent(CarDirection.Left))
      }

      GridItem() {
        Button("停")
          .backgroundColor($r('app.color.button_background'))
          .shadow(ButtonShadow)
          .width('100%')
          .height('100%')
          .onTouch(this.makeTouchEvent(CarDirection.Brake))

      }

      GridItem() {
        Button("右")
          .backgroundColor($r('app.color.button_background'))
          .shadow(ButtonShadow)
          .width('100%')
          .height('100%')
          .onTouch(this.makeTouchEvent(CarDirection.Right))

      }

      // 第三行
      GridItem()

      GridItem() {
        Button("后")
          .backgroundColor($r('app.color.button_background'))
          .shadow(ButtonShadow)
          .width('100%')
          .height('100%')
          .onTouch(this.makeTouchEvent(CarDirection.After))

      }

      GridItem()
    }
    .rowsTemplate('1fr 1fr 1fr')
    .columnsTemplate('1fr 1fr 1fr')
    .rowsGap('8vp')
    .columnsGap('8vp')
    .width('100%')
    .height('100%')
  }

  aboutToDisappear(): void {
    this.stopContinuousControl();
  }

  /**
   * 车辆拥有统一的触摸停止事件，所以通过本函数来构造响应函数
   * @param upEvent
   */
  makeTouchEvent(direction: CarDirection): (event?: TouchEvent) => void {

    let fun = (event?: TouchEvent): void => {
      // 防御性编程
      if (!event)
        return;

      if (event.type === TouchType.Up) {
        // 如果抬起触摸事件时，暂停车辆移动
        this.stopContinuousControl()
      } else if (event.type === TouchType.Down) {
        // 如果出发触摸事件时响应相应的点击事件
        this.startContinuousControl(direction);
      } else if (event.type === TouchType.Move) {
        // 手指触摸途中不会有相应的响应

      }

    }

    return fun;
  }

  private startContinuousControl(direction: CarDirection): void {
    this.stopRepeatTimer();
    this.activeDirection = direction;
    this.announceDirection(direction);
    this.sendDirectionSpeed(direction);
    this.repeatTimer = setInterval((): void => {
      this.sendDirectionSpeed(this.activeDirection);
    }, 180);
  }

  private stopContinuousControl(): void {
    this.stopRepeatTimer();
    this.activeDirection = CarDirection.Stop;
    this.sendStop();
    this.announceVoice('停止');
  }

  private stopRepeatTimer(): void {
    if (this.repeatTimer !== -1) {
      clearInterval(this.repeatTimer);
      this.repeatTimer = -1;
    }
  }

  private sendDirectionSpeed(direction: CarDirection): void {
    const speed = this.clamp(Math.round(this.speedValue), 0, 100);

    switch (direction) {
      case CarDirection.Front:
        carApi.send(CarEncode.UpSpeedCarEncode(speed, speed, speed, speed));
        break;
      case CarDirection.After:
        carApi.send(CarEncode.UpSpeedCarEncode(-speed, -speed, -speed, -speed));
        break;
      case CarDirection.Left:
        carApi.send(CarEncode.UpSpeedCarEncode(-speed, speed, speed, -speed));
        break;
      case CarDirection.Right:
        carApi.send(CarEncode.UpSpeedCarEncode(speed, -speed, -speed, speed));
        break;
      case CarDirection.LeftRotate:
        carApi.send(CarEncode.UpSpeedCarEncode(-speed, -speed, speed, speed));
        break;
      case CarDirection.RightRotate:
        carApi.send(CarEncode.UpSpeedCarEncode(speed, speed, -speed, -speed));
        break;
      default:
        this.sendStop();
        break;
    }
  }

  private sendStop(): void {
    carApi.send(CarEncode.UpSpeedCarEncode(0, 0, 0, 0));
  }

  private announceDirection(direction: CarDirection): void {
    const message = this.directionVoiceMessage(direction);
    if (message.length === 0) {
      return;
    }
    this.announceVoice(message);
  }

  private directionVoiceMessage(direction: CarDirection): string {
    switch (direction) {
      case CarDirection.Front:
        return '前进';
      case CarDirection.After:
        return '后退';
      case CarDirection.Left:
        return '左移';
      case CarDirection.Right:
        return '右移';
      case CarDirection.LeftRotate:
        return '左转';
      case CarDirection.RightRotate:
        return '右转';
      case CarDirection.Brake:
        return '停止';
      default:
        return '';
    }
  }

  private announceVoice(message: string): void {
    const now = Date.now();
    if (message === this.lastVoiceMessage && now - this.lastVoiceAt < 1200) {
      return;
    }
    this.lastVoiceMessage = message;
    this.lastVoiceAt = now;
    PatrolCommandUtils.speakVoice(message);
  }

  private clamp(value: number, min: number, max: number): number {
    return Math.max(min, Math.min(max, value));
  }
}

export { CarBtnComponents }
