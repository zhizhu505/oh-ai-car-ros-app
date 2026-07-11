import { carApi } from '../CarUtill/CarApi';
import { CarEncode } from '../CarUtill/CarEncode';
import { CarDirection } from '../CarUtill/CarEnum';
import { CarBtnComponents } from '../components/CarBtnComponents';
import { CarRockerComponents } from '../components/CarRockerComponents';
import { VideoComponents } from '../components/VideoComponents';
import { PageHeader, InfoCard } from '../components/PageHeader';
import { CardShadow, ButtonShadow } from '../styles/styles';

@Entry
@Component
struct RemoteControl {
  @State nowCtrlModel: CtrlModel = CtrlModel.Button;
  @State autoTracking: boolean = false;
  ctrlTextTextList: string[] = ['按钮', '遥杆'];
  ctrlModeList: CtrlModel[] = [CtrlModel.Button, CtrlModel.Rocker];

  build() {
    Column({ space: '0vp' }) {
      PageHeader({
        title: '单独遥控',
        subtitle: '按钮 / 摇杆控制 · 视频预览 · 自动循迹',
        accentColor: $r('app.color.module5_accent')
      })

      Scroll() {
        Column({ space: '16vp' }) {
          Row({ space: '16vp' }) {
            Column({ space: '16vp' }) {
              InfoCard({ title: '控制模式' }) {
                Row({ space: '8vp' }) {
                  ForEach(this.ctrlTextTextList, (item: string, index: number) => {
                    ModeTab({
                      state: this.nowCtrlModel === this.ctrlModeList[index],
                      text: item
                    }).onClick((): void => {
                      this.nowCtrlModel = this.ctrlModeList[index];
                    })
                  }, (item: string) => item)
                }
              }

              InfoCard({ title: '控制面板' }) {
                Stack() {
                  CarBtnComponents()
                    .visibility(this.nowCtrlModel === CtrlModel.Button ? Visibility.Visible : Visibility.None)
                  CarRockerComponents()
                    .visibility(this.nowCtrlModel === CtrlModel.Rocker ? Visibility.Visible : Visibility.None)
                }
                .width('220vp')
                .height('220vp')
              }
            }
            .layoutWeight(1)

            Column({ space: '16vp' }) {
              InfoCard({ title: '视频预览' }) {
                VideoComponents()
              }

              InfoCard({ title: '自动循迹' }) {
                Row({ space: '12vp' }) {
                  Text('启用自动循迹')
                    .fontSize('14fp')
                    .fontColor($r('app.color.text'))
                  Toggle({ type: ToggleType.Switch, isOn: this.autoTracking })
                    .selectedColor($r('app.color.button_primary'))
                    .switchPointColor(Color.White)
                    .onChange((value: boolean): void => {
                      this.autoTracking = value;
                      if (value) {
                        carApi.send(CarEncode.TrackingOpenEncode());
                      } else {
                        carApi.send(CarEncode.TrackingCloseEncode());
                      }
                    })
                }
                .justifyContent(FlexAlign.Center)
              }

              InfoCard({ title: '快捷指令' }) {
                Row({ space: '10vp' }) {
                  QuickBtn({ title: '前进', action: () => { carApi.send(CarEncode.ButtonCarEncode(CarDirection.Front)); } })
                  QuickBtn({ title: '后退', action: () => { carApi.send(CarEncode.ButtonCarEncode(CarDirection.After)); } })
                  QuickBtn({ title: '左转', action: () => { carApi.send(CarEncode.ButtonCarEncode(CarDirection.Left)); } })
                  QuickBtn({ title: '右转', action: () => { carApi.send(CarEncode.ButtonCarEncode(CarDirection.Right)); } })
                }
              }
            }
            .layoutWeight(1)
          }

          InfoCard({ title: '控制说明' }) {
            Column({ space: '8vp' }) {
              TipItem({ icon: '🎮', text: '按钮模式：点击方向按钮控制车辆移动' })
              TipItem({ icon: '🕹️', text: '遥杆模式：拖动遥杆控制方向和速度' })
              TipItem({ icon: '📹', text: '视频预览：实时查看车辆摄像头画面' })
              TipItem({ icon: '🧭', text: '自动循迹：开启后车辆沿预设路线行驶' })
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
}

enum CtrlModel {
  Button = 0,
  Rocker = 1,
}

@Component
struct ModeTab {
  @Prop state: boolean = false;
  @Prop text: string = 'hello';

  build() {
    Text(this.text)
      .fontSize('15fp')
      .fontColor(this.state ? $r('app.color.text_on_accent') : $r('app.color.text_secondary'))
      .fontWeight(this.state ? FontWeight.Medium : FontWeight.Normal)
      .padding({ left: '18vp', right: '18vp', top: '10vp', bottom: '10vp' })
      .backgroundColor(this.state ? $r('app.color.button_primary') : $r('app.color.card_elevated'))
      .borderRadius('22vp')
      .shadow(this.state ? ButtonShadow : CardShadow)
  }
}

@Component
struct QuickBtn {
  @Prop title: string = '';
  action: () => void = () => { };

  build() {
    Button(this.title)
      .width('100%')
      .height('44vp')
      .fontSize('14fp')
      .fontColor(Color.White)
      .backgroundColor($r('app.color.button_primary'))
      .borderRadius('22vp')
      .shadow(ButtonShadow)
      .onClick(this.action)
  }
}

@Component
struct TipItem {
  @Prop icon: string = '';
  @Prop text: string = '';

  build() {
    Row({ space: '10vp' }) {
      Text(this.icon)
        .fontSize('18fp')
      Text(this.text)
        .fontSize('14fp')
        .fontColor($r('app.color.text'))
    }
    .width('100%')
    .padding('6vp')
  }
}