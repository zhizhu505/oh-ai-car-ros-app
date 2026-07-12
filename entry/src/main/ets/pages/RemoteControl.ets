import router from '@ohos.router';
import { carApi } from '../CarUtill/CarApi';
import { CarEncode } from '../CarUtill/CarEncode';
import { CarDirection } from '../CarUtill/CarEnum';
import { CarRockerComponents } from '../components/CarRockerComponents';
import { VideoComponents } from '../components/VideoComponents';
import { ButtonShadow, CardShadow } from '../styles/styles';
import promptAction from '@ohos.promptAction';
import { ScreenUtils } from '../utils/ScreenUtils';

const TAG = 'RemoteControl'

@Entry
@Component
struct RemoteControl {
  @State autoTracking: boolean = false;
  @State L1Value: number = 0;
  @State L2Value: number = 0;
  @State R1Value: number = 0;
  @State R2Value: number = 0;
  @State scrollEnabled: boolean = true;
  @State advancedExpanded: boolean = false;

  aboutToAppear(): void {
    ScreenUtils.setLandscape(getContext());
  }

  aboutToDisappear(): void {
    ScreenUtils.setPortrait(getContext());
  }

  build() {
    Stack() {
      Column({ space: '0vp' }) {
        this.TopBar()

        Row({ space: '10vp' }) {
          Column() {
            ControlPanel({ title: '摇杆控制' }) {
              Column({ space: '8vp' }) {
                Row({ space: '10vp' }) {
                  Toggle({ type: ToggleType.Switch, isOn: this.autoTracking })
                    .selectedColor($r('app.color.button_primary'))
                    .switchPointColor(Color.White)
                    .onChange((value: boolean): void => {
                      this.autoTracking = value;
                      carApi.send(value ? CarEncode.TrackingOpenEncode() : CarEncode.TrackingCloseEncode());
                    })
                  Text('自动循迹')
                    .fontSize('12fp')
                    .fontColor($r('app.color.text_secondary'))
                  Blank()
                  Button('急停')
                    .height('36vp')
                    .fontSize('12fp')
                    .fontColor(Color.White)
                    .backgroundColor($r('app.color.alert_critical'))
                    .borderRadius('18vp')
                    .onClick((): void => {
                      carApi.send(CarEncode.ButtonCarEncode(CarDirection.Stop));
                      this.resetAll();
                    })
                }
                .width('100%')
                .height('30vp')
                .alignItems(VerticalAlign.Center)

                Stack() {
                  CarRockerComponents()
                    .width('190vp')
                    .height('190vp')
                }
                .width('100%')
                .layoutWeight(1)
                .alignContent(Alignment.Center)
                .backgroundColor($r('app.color.card_elevated'))
                .borderRadius('14vp')
                .gesture(PanGesture({ fingers: 1, direction: PanDirection.All })
                  .onActionStart((): void => {
                    this.scrollEnabled = false;
                  })
                  .onActionUpdate((): void => { })
                  .onActionEnd((): void => {
                    this.scrollEnabled = true;
                  }))
                .onTouch((event: TouchEvent): void => {
                  if (event.type === TouchType.Down || event.type === TouchType.Move) {
                    this.scrollEnabled = false;
                  } else {
                    this.scrollEnabled = true;
                  }
                })
              }
              .height('100%')
            }
          }
          .layoutWeight(2)

          Column() {
            ControlPanel({ title: '视频预览' }) {
              VideoComponents({
                previewWidth: '100%',
                previewHeight: '96%',
                showActions: false
              })
            }
          }
          .layoutWeight(3)
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: '15vp', right: '15vp', top: '6vp', bottom: '8vp' })
      }
      .width('100%')
      .height('100%')

      if (this.advancedExpanded) {
        this.AdvancedOverlay()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.window_background'))
  }

  @Builder
  TopBar() {
    Row({ space: '12vp' }) {
      Button('返回')
        .width('68vp')
        .height('36vp')
        .fontSize('13fp')
        .fontColor($r('app.color.text'))
        .backgroundColor($r('app.color.button_secondary'))
        .borderRadius('18vp')
        .shadow(CardShadow)
        .onClick((): void => {
          router.back();
        })

      Column({ space: '3vp' }) {
        Text('手动接管')
          .fontSize('19fp')
          .fontColor($r('app.color.text'))
          .fontWeight(FontWeight.Bold)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text('摇杆控制  |  视频预览  |  远程接管')
          .fontSize('10fp')
          .fontColor($r('app.color.text_secondary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Button(this.advancedExpanded ? '关闭调节' : '高级调节')
        .width('86vp')
        .height('36vp')
        .fontSize('13fp')
        .fontColor(Color.White)
        .backgroundColor($r('app.color.button_primary'))
        .borderRadius('18vp')
        .shadow(ButtonShadow)
        .onClick((): void => {
          this.advancedExpanded = !this.advancedExpanded;
        })
    }
    .width('100%')
    .height('48vp')
    .padding({ left: '15vp', right: '15vp' })
    .backgroundColor($r('app.color.header_background'))
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  AdvancedOverlay() {
    Column({ space: '10vp' }) {
      Row({ space: '10vp' }) {
        Column({ space: '2vp' }) {
          Text('高级调节')
            .fontSize('15fp')
            .fontColor($r('app.color.text'))
            .fontWeight(FontWeight.Bold)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text('四轮速度 / 状态 / 快捷动作')
            .fontSize('10fp')
            .fontColor($r('app.color.text_secondary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Button('关闭')
          .width('72vp')
          .height('36vp')
          .fontSize('12fp')
          .fontColor(Color.White)
          .backgroundColor($r('app.color.button_primary'))
          .borderRadius('18vp')
          .onClick((): void => {
            this.advancedExpanded = false;
          })
      }
      .height('38vp')
      .alignItems(VerticalAlign.Center)

      Row({ space: '10vp' }) {
        Column({ space: '6vp' }) {
          SliderComponent({ value: $L1Value, title: '左前轮', label: 'L1' })
          SliderComponent({ value: $R1Value, title: '右前轮', label: 'R1' })
          SliderComponent({ value: $L2Value, title: '左后轮', label: 'L2' })
          SliderComponent({ value: $R2Value, title: '右后轮', label: 'R2' })
        }
        .height('120vp')
        .layoutWeight(4)
        .padding({ left: '10vp', right: '10vp', top: '8vp', bottom: '8vp' })
        .backgroundColor($r('app.color.card_elevated'))
        .borderRadius('12vp')

        Column({ space: '6vp' }) {
          Row({ space: '8vp' }) {
            SpeedDisplay({ label: 'L1', value: this.L1Value })
            SpeedDisplay({ label: 'R1', value: this.R1Value })
          }
          Row({ space: '8vp' }) {
            SpeedDisplay({ label: 'L2', value: this.L2Value })
            SpeedDisplay({ label: 'R2', value: this.R2Value })
          }
        }
        .height('120vp')
        .layoutWeight(2)
        .padding({ left: '10vp', right: '10vp', top: '12vp', bottom: '12vp' })
        .backgroundColor($r('app.color.card_elevated'))
        .borderRadius('12vp')
      }
      .height('120vp')

      Row({ space: '10vp' }) {
        ActionButton({ title: '应用轮速', action: () => { this.sendSpeed(); } })
        ActionButton({ title: '全部归零', action: () => { this.resetAll(); } })
        ActionButton({ title: '前进预设', action: () => { this.setSpeed(50, 50, 50, 50); } })
        ActionButton({ title: '后退预设', action: () => { this.setSpeed(-50, -50, -50, -50); } })
      }
      .height('36vp')
    }
    .width('70%')
    .height('216vp')
    .padding({ left: '12vp', right: '12vp', top: '10vp', bottom: '12vp' })
    .backgroundColor($r('app.color.card_background'))
    .borderRadius('12vp')
    .border({ width: '1vp', color: $r('app.color.divider') })
    .shadow(CardShadow)
    .position({ x: '28%', y: '62vp' })
    .zIndex(10)
  }

  sendSpeed(): void {
    console.log(TAG, 'speed', `l1`, this.L1Value, 'l2', this.L2Value)
    carApi.send(CarEncode.UpSpeedCarEncode(this.L1Value, this.L2Value, this.R1Value, this.R2Value));
    promptAction.showToast({ message: '轮速已更新' });
  }

  resetAll(): void {
    this.L1Value = 0
    this.L2Value = 0
    this.R1Value = 0
    this.R2Value = 0
    carApi.send(CarEncode.UpSpeedCarEncode(0, 0, 0, 0));
  }

  setSpeed(l1: number, l2: number, r1: number, r2: number): void {
    this.L1Value = l1;
    this.L2Value = l2;
    this.R1Value = r1;
    this.R2Value = r2;
    this.sendSpeed();
  }
}

@Component
struct ControlPanel {
  @Prop title: string = '';
  @BuilderParam content: () => void = this.defaultContent;

  @Builder
  defaultContent() {
    Text('')
  }

  build() {
    Column({ space: '6vp' }) {
      Text(this.title)
        .fontSize('14fp')
        .fontColor($r('app.color.text'))
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Column() {
        this.content()
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .clip(true)
    }
    .width('100%')
    .height('100%')
    .padding({ left: '12vp', right: '12vp', top: '10vp', bottom: '10vp' })
    .backgroundColor($r('app.color.card_background'))
    .borderRadius('12vp')
    .border({ width: '1vp', color: $r('app.color.divider') })
    .shadow(CardShadow)
  }
}

@Component
struct SliderComponent {
  @Link value: number;
  @Prop title: string = '';
  @Prop label: string = '';

  build() {
    Row({ space: '8vp' }) {
      Text(this.label)
        .width('24vp')
        .fontSize('11fp')
        .fontColor($r('app.color.text_secondary'))
        .fontWeight(FontWeight.Medium)
        .textAlign(TextAlign.Start)

      Text(this.title)
        .width('46vp')
        .fontSize('11fp')
        .fontColor($r('app.color.text'))
        .fontWeight(FontWeight.Medium)
        .maxLines(1)

      Slider({
        value: this.value,
        min: -100,
        max: 100,
        style: SliderStyle.InSet
      })
        .blockColor($r('app.color.button_primary'))
        .trackColor($r('app.color.track_background'))
        .selectedColor($r('app.color.slider_selected'))
        .onChange((val: number, mode: SliderChangeMode) => {
          this.value = Math.round(val);
        })
        .layoutWeight(1)

      Text(`${this.value.toFixed(0)}`)
        .width('32vp')
        .textAlign(TextAlign.Center)
        .fontColor($r('app.color.text'))
        .fontSize('12fp')
        .fontWeight(FontWeight.Medium)
    }
    .width('100%')
    .height('24vp')
    .padding({ left: '8vp', right: '8vp' })
    .backgroundColor($r('app.color.card_elevated'))
    .borderRadius('12vp')
    .alignItems(VerticalAlign.Center)
  }
}

@Component
struct ActionButton {
  @Prop title: string = '';
  action: () => void = () => { };

  build() {
    Button(this.title)
      .layoutWeight(1)
      .height('36vp')
      .fontSize('12fp')
      .fontColor(Color.White)
      .backgroundColor($r('app.color.button_primary'))
      .borderRadius('18vp')
      .shadow(ButtonShadow)
      .onClick(this.action)
  }
}

@Component
struct SpeedDisplay {
  @Prop label: string = '';
  @Prop value: number = 0;

  build() {
    Row() {
      Text(this.label)
        .fontSize('11fp')
        .fontColor($r('app.color.text_secondary'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      Blank()
      Text(`${this.value}`)
        .fontSize('15fp')
        .fontColor(this.value > 0 ? $r('app.color.alert_normal') : (this.value < 0 ? $r('app.color.alert_critical') : $r('app.color.text')))
        .fontWeight(FontWeight.Bold)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .layoutWeight(1)
    .height('26vp')
    .padding({ left: '10vp', right: '10vp' })
    .backgroundColor($r('app.color.card_elevated'))
    .borderRadius('10vp')
    .alignItems(VerticalAlign.Center)
  }
}
