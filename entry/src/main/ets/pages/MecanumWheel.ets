import { carApi } from '../CarUtill/CarApi';
import { CarEncode } from '../CarUtill/CarEncode';
import { CarRockerComponents } from '../components/CarRockerComponents';
import { PageHeader, InfoCard } from '../components/PageHeader';
import { CardShadow, ButtonShadow } from '../styles/styles';
import promptAction from '@ohos.promptAction';

const TAG = 'SmartCarMecanumWheel'

@Entry
@Component
struct MecanumWheel {
  @State message: string = '麦克纳姆轮控制';
  @State L1Value: number = 0;
  @State L2Value: number = 0;
  @State R1Value: number = 0;
  @State R2Value: number = 0;

  build() {
    Column({ space: '0vp' }) {
      PageHeader({
        title: '麦克纳姆轮控制',
        subtitle: '四轮独立速度调节 · 全向移动',
        accentColor: $r('app.color.module5_accent')
      })

      Scroll() {
        Column({ space: '16vp' }) {
          Row({ space: '16vp' }) {
            Column({ space: '12vp' }) {
              InfoCard({ title: '左前轮 (L1)' }) {
                SliderComponent({ value: $L1Value, label: 'L1' })
              }
              InfoCard({ title: '左后轮 (L2)' }) {
                SliderComponent({ value: $L2Value, label: 'L2' })
              }
            }
            .layoutWeight(1)

            Column({ space: '12vp' }) {
              InfoCard({ title: '右前轮 (R1)' }) {
                SliderComponent({ value: $R1Value, label: 'R1' })
              }
              InfoCard({ title: '右后轮 (R2)' }) {
                SliderComponent({ value: $R2Value, label: 'R2' })
              }
            }
            .layoutWeight(1)
          }

          InfoCard({ title: '遥杆控制' }) {
            Column({ space: '8vp' }) {
              Row() {
                CarRockerComponents()
                  .width('160vp')
                  .height('160vp')
              }
              .justifyContent(FlexAlign.Center)
              Text('使用遥杆控制方向，上面滑块调节独立速度')
                .fontSize('13fp')
                .fontColor($r('app.color.text_secondary'))
                .textAlign(TextAlign.Center)
            }
          }

          InfoCard({ title: '快捷操作' }) {
            Row({ space: '12vp' }) {
              ActionButton({ title: '更新速度', icon: '➡️', action: () => { this.sendSpeed(); } })
              ActionButton({ title: '全部归零', icon: '🔄', action: () => { this.resetAll(); } })
              ActionButton({ title: '前进', icon: '⬆️', action: () => { this.setSpeed(50, 50, 50, 50); } })
              ActionButton({ title: '后退', icon: '⬇️', action: () => { this.setSpeed(-50, -50, -50, -50); } })
            }
          }

          InfoCard({ title: '速度状态' }) {
            Row({ space: '16vp' }) {
              SpeedDisplay({ label: 'L1', value: this.L1Value })
              SpeedDisplay({ label: 'L2', value: this.L2Value })
              SpeedDisplay({ label: 'R1', value: this.R1Value })
              SpeedDisplay({ label: 'R2', value: this.R2Value })
            }
          }
        }
        .padding({ top: '16vp', bottom: '32vp' })
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.window_background'))
  }

  sendSpeed() {
    console.log(TAG, 'speed', `l1`, this.L1Value, 'l2', this.L2Value)
    carApi.send(CarEncode.UpSpeedCarEncode(this.L1Value, this.L2Value, this.R1Value, this.R2Value));
    promptAction.showToast({ message: '速度已更新' });
  }

  resetAll() {
    this.L1Value = 0
    this.L2Value = 0
    this.R1Value = 0
    this.R2Value = 0
    this.sendSpeed();
  }

  setSpeed(l1: number, l2: number, r1: number, r2: number) {
    this.L1Value = l1;
    this.L2Value = l2;
    this.R1Value = r1;
    this.R2Value = r2;
    this.sendSpeed();
  }
}

@Component
struct SliderComponent {
  @Link value: number;
  @Prop label: string = '';

  build() {
    Column({ space: '8vp' }) {
      Row({ space: '12vp' }) {
        Text(this.label)
          .fontSize('14fp')
          .fontColor($r('app.color.text'))
          .fontWeight(FontWeight.Medium)
          .width('32vp')
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
            this.value = val;
          })
          .layoutWeight(1)
        Text(`${this.value.toFixed(0)}`)
          .width('40vp')
          .textAlign(TextAlign.Center)
          .fontColor($r('app.color.text'))
          .fontSize('14fp')
          .fontWeight(FontWeight.Medium)
      }
    }
  }
}

@Component
struct ActionButton {
  @Prop title: string = '';
  @Prop icon: string = '';
  action: () => void = () => { };

  build() {
    Button() {
      Column({ space: '4vp' }) {
        Text(this.icon)
          .fontSize('18fp')
        Text(this.title)
          .fontSize('13fp')
          .fontColor(Color.White)
      }
    }
    .width('100%')
    .height('64vp')
    .backgroundColor($r('app.color.button_primary'))
    .borderRadius('14vp')
    .shadow(ButtonShadow)
    .onClick(this.action)
  }
}

@Component
struct SpeedDisplay {
  @Prop label: string = '';
  @Prop value: number = 0;

  build() {
    Column({ space: '4vp' }) {
      Text(this.label)
        .fontSize('12fp')
        .fontColor($r('app.color.text_secondary'))
      Text(`${this.value}`)
        .fontSize('20fp')
        .fontColor(this.value > 0 ? $r('app.color.alert_normal') : (this.value < 0 ? $r('app.color.alert_critical') : $r('app.color.text')))
        .fontWeight(FontWeight.Bold)
    }
    .layoutWeight(1)
    .padding('8vp')
    .backgroundColor($r('app.color.card_elevated'))
    .borderRadius('10vp')
    .alignItems(HorizontalAlign.Center)
  }
}