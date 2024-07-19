/**
 * 麦克纳姆轮单独控制界面
 */
@Entry
@Component
struct MecanumWheel {
  @State message: string = 'Hello World';

  build() {
    Row() {
      Column() {
        Text(this.message)
          .fontSize(50)
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')
    }
    .height('100%')
  }
}