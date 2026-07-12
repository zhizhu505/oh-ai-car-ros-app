import router from '@ohos.router';
import { carApi } from '../CarUtill/CarApi';
import { CarEncode } from '../CarUtill/CarEncode';
import { CarDirection } from '../CarUtill/CarEnum';
import { CarRockerComponents } from '../components/CarRockerComponents';
import { VideoComponents } from '../components/VideoComponents';
import { ButtonShadow, CardShadow } from '../styles/styles';
import promptAction from '@ohos.promptAction';

const TAG = 'RemoteControl'

@Entry
@Component
struct RemoteControl {
  @State autoTracking: boolean = false;
  @State L1Value: number = 0;
  @State L2Value: number = 0;
  @State R1Value: number = 0;
  @State R2Value: number = 0;

  build() {
    Column() {
      this.CompactHeader()

      Column({ space: '10vp' }) {
        Row({ space: '12vp' }) {
          Column() {
            ControlPanel({ title: '视频预览' }) {
              VideoComponents({
                previewWidth: '100%',
                previewHeight: '150vp',
                showActions: false
              })
            }
          }
          .layoutWeight(3)

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
                    .height('30vp')
                    .fontSize('12fp')
                    .fontColor(Color.White)
                    .backgroundColor($r('app.color.alert_critical'))
                    .borderRadius('15vp')
                    .onClick((): void => {
                      carApi.send(CarEncode.ButtonCarEncode(CarDirection.Stop));
                      this.resetAll();
                    })
                }
                .width('100%')
                .alignItems(VerticalAlign.Center)

                Stack() {
                  CarRockerComponents()
                    .width('134vp')
                    .height('134vp')
                }
                .width('100%')
                .height('138vp')
                .alignContent(Alignment.Center)
                .backgroundColor($r('app.color.card_elevated'))
                .borderRadius('14vp')
                .gesture(PanGesture({ fingers: 1, direction: PanDirection.All })
                  .onActionStart((): void => { })
                  .onActionUpdate((): void => { })
                  .onActionEnd((): void => { }))
              }
            }
          }
          .layoutWeight(2)
        }
        .height('202vp')

        Row({ space: '12vp' }) {
          Column() {
            ControlPanel({ title: '四轮速度调节' }) {
              Column({ space: '8vp' }) {
                Row({ space: '10vp' }) {
                  SliderComponent({ value: $L1Value, title: '左前轮', label: 'L1' })
                  SliderComponent({ value: $R1Value, title: '右前轮', label: 'R1' })
                }
                .height('42vp')

                Row({ space: '10vp' }) {
                  SliderComponent({ value: $L2Value, title: '左后轮', label: 'L2' })
                  SliderComponent({ value: $R2Value, title: '右后轮', label: 'R2' })
                }
                .height('42vp')
              }
            }
          }
          .layoutWeight(3)

          Column() {
            ControlPanel({ title: '速度状态' }) {
              Column({ space: '8vp' }) {
                Row({ space: '8vp' }) {
                  SpeedDisplay({ label: 'L1', value: this.L1Value })
                  SpeedDisplay({ label: 'R1', value: this.R1Value })
                }
                Row({ space: '8vp' }) {
                  SpeedDisplay({ label: 'L2', value: this.L2Value })
                  SpeedDisplay({ label: 'R2', value: this.R2Value })
                }
              }
            }
          }
          .layoutWeight(2)
        }
        .height('128vp')

        Row({ space: '10vp' }) {
          ActionButton({ title: '应用轮速', action: () => { this.sendSpeed(); } })
          ActionButton({ title: '全部归零', action: () => { this.resetAll(); } })
          ActionButton({ title: '前进预设', action: () => { this.setSpeed(50, 50, 50, 50); } })
          ActionButton({ title: '后退预设', action: () => { this.setSpeed(-50, -50, -50, -50); } })
        }
        .height('38vp')
      }
      .layoutWeight(1)
      .padding({ left: '18vp', right: '18vp', top: '10vp', bottom: '12vp' })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.window_background'))
  }

  @Builder
  CompactHeader() {
    Row({ space: '12vp' }) {
      Column()
        .width('6vp')
        .height('42vp')
        .backgroundColor($r('app.color.module5_accent'))
        .borderRadius('3vp')

      Column({ space: '5vp' }) {
        Text('手动接管')
          .fontSize('26fp')
          .fontColor($r('app.color.text'))
          .fontWeight(FontWeight.Bold)
        Text('视频预览 / 摇杆控制 / 四轮速度调节')
          .fontSize('13fp')
          .fontColor($r('app.color.text_secondary'))
          .maxLines(1)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Button('返回')
        .width('76vp')
        .height('38vp')
        .fontSize('14fp')
        .fontColor($r('app.color.text'))
        .backgroundColor($r('app.color.button_secondary'))
        .borderRadius('19vp')
        .onClick((): void => {
          router.back();
        })
    }
    .width('100%')
    .height('88vp')
    .padding({ left: '22vp', right: '22vp' })
    .backgroundColor($r('app.color.header_background'))
    .shadow(CardShadow)
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
    Column({ space: '8vp' }) {
      Text(this.title)
        .fontSize('16fp')
        .fontColor($r('app.color.text'))
        .fontWeight(FontWeight.Bold)
        .width('100%')
      this.content()
    }
    .width('100%')
    .height('100%')
    .padding({ left: '14vp', right: '14vp', top: '12vp', bottom: '12vp' })
    .backgroundColor($r('app.color.card_background'))
    .borderRadius('16vp')
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
      Column({ space: '1vp' }) {
        Text(this.title)
          .fontSize('12fp')
          .fontColor($r('app.color.text'))
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
        Text(this.label)
          .fontSize('10fp')
          .fontColor($r('app.color.text_secondary'))
      }
      .width('54vp')
      .alignItems(HorizontalAlign.Start)

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
        .width('28vp')
        .textAlign(TextAlign.Center)
        .fontColor($r('app.color.text'))
        .fontSize('13fp')
        .fontWeight(FontWeight.Medium)
    }
    .layoutWeight(1)
    .height('100%')
    .padding({ left: '10vp', right: '10vp' })
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
      .height('38vp')
      .fontSize('13fp')
      .fontColor(Color.White)
      .backgroundColor($r('app.color.button_primary'))
      .borderRadius('19vp')
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
      Blank()
      Text(`${this.value}`)
        .fontSize('16fp')
        .fontColor(this.value > 0 ? $r('app.color.alert_normal') : (this.value < 0 ? $r('app.color.alert_critical') : $r('app.color.text')))
        .fontWeight(FontWeight.Bold)
    }
    .layoutWeight(1)
    .height('32vp')
    .padding({ left: '10vp', right: '10vp' })
    .backgroundColor($r('app.color.card_elevated'))
    .borderRadius('10vp')
    .alignItems(VerticalAlign.Center)
  }
}
