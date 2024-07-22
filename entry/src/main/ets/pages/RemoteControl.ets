/**
 * 遥控界面
 */
import { carApi } from '../CarUtill/CarApi';
import { CarDirection } from '../CarUtill/CarEnum';

@Entry
@Component
struct RemoteControl {
  @State message: string = 'Hello World';

  build() {
    Row() {
      Column() {
        // 操控按钮
        Grid() {
          // 第一行
          GridItem() {
            Button("左转")// .backgroundColor(0xF9CF93)
              .width('100%')
              .height('100%')
              .onTouch(this.makeTouchEvent(() => carApi.carBtnCtrl(CarDirection.LeftRotate)))
          }

          GridItem() {
            Button("前")// .backgroundColor(0xF9CF93)
              .width('100%')
              .height('100%')
              .onTouch(this.makeTouchEvent(() => carApi.carBtnCtrl(CarDirection.Front)))
          }

          GridItem() {
            Button("左转")// .backgroundColor(0xF9CF93)
              .width('100%')
              .height('100%')
              .onTouch(this.makeTouchEvent(() => carApi.carBtnCtrl(CarDirection.RightRotate)))
          }

          // 第二行
          GridItem() {
            Button("左")
              .width('100%')
              .height('100%')
              .onTouch(this.makeTouchEvent(() => carApi.carBtnCtrl(CarDirection.Left)))
          }

          GridItem() {
            Button("停")
              .width('100%')
              .height('100%')
              .onTouch(this.makeTouchEvent(() => carApi.carBtnCtrl(CarDirection.Brake)))

          }

          GridItem() {
            Button("右")
              .width('100%')
              .height('100%')
              .onTouch(this.makeTouchEvent(() => carApi.carBtnCtrl(CarDirection.Right)))

          }

          // 第三行
          GridItem()

          GridItem() {
            Button("后")
              .width('100%')
              .height('100%')
              .onTouch(this.makeTouchEvent(() => carApi.carBtnCtrl(CarDirection.After)))

          }

          GridItem()
        }
        .rowsTemplate('1fr 1fr 1fr')
        .columnsTemplate('1fr 1fr 1fr')
        //80
        // 10
        .width('320vp')
        .height('320vp')
      }

      .width(0)
      .layoutWeight(1)

      Column() {
      }
      .width(0)
      .layoutWeight(1)
    }
    .height('100%')
  }

  /**
   * 车辆拥有统一的触摸停止事件，所以通过本函数来构造响应函数
   * @param upEvent
   */
  makeTouchEvent(upEvent: (event?: TouchEvent) => void) {

    let fun = (event?: TouchEvent) => {
      // 防御性编程
      if (!event)
        return;

      if (event.type === TouchType.Up) {
        // 如果抬起触摸事件时，暂停车辆移动
        carApi.carBtnCtrl(CarDirection.Stop)
      } else if (event.type === TouchType.Down) {
        // 如果出发触摸事件时响应相应的点击事件
        upEvent(event);
      } else if (event.type === TouchType.Move) {
        // 手指触摸途中不会有相应的响应

      }

    }

    return fun;
  }
}