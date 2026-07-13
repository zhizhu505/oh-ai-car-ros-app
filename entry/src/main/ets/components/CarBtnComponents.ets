import { carApi } from '../CarUtill/CarApi'
import { CarEncode } from '../CarUtill/CarEncode'
import { CarDirection } from '../CarUtill/CarEnum'
import { ButtonShadow } from '../styles/styles'

/**
 * 按键控制UI组件
 */
@Component
struct CarBtnComponents {
  @Prop speedValue: number = 45;
  private repeatTimer: number = -1;
  private activeDirection: CarDirection = CarDirection.Stop;

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
    this.sendDirectionSpeed(direction);
    this.repeatTimer = setInterval((): void => {
      this.sendDirectionSpeed(this.activeDirection);
    }, 180);
  }

  private stopContinuousControl(): void {
    this.stopRepeatTimer();
    this.activeDirection = CarDirection.Stop;
    this.sendStop();
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

  private clamp(value: number, min: number, max: number): number {
    return Math.max(min, Math.min(max, value));
  }
}

export { CarBtnComponents }
