import { TCPClientManager } from '../tcp/TCPClientManager';
import { TCPClientSendUtils } from '../tcp/TCPClientSendUtils';
import { PatrolMessageHandler } from '../tcp/PatrolMessageHandler';
import { PatrolStore } from '../store/PatrolStore';
import promptAction from '@ohos.promptAction';
import router from '@ohos.router';
import { PreferencesUtils } from '../utils/PreferencesUtils';
import { VideoComponents } from '../components/VideoComponents';
import { ButtonShadow, CardShadow, ElevatedShadow, CardPadding, ButtonRadius } from '../styles/styles';
import { MyUtils } from '../utils/MyUtils';
import preferences from '@ohos.data.preferences';

@Entry
@Component
struct NetworkSettings {
  @State online: boolean = false;

  aboutToAppear(): void {
    this.online = PatrolStore.getInstance().vehicle.online;
  }

  build(): void {
    Column({ space: '0vp' }) {
      Column({ space: '16vp' }) {
        Row() {
          Column({ space: '6vp' }) {
            Text('智慧仓储巡检系统')
              .fontSize('32fp')
              .fontColor($r('app.color.text'))
              .fontWeight(FontWeight.Bold)
            Text('Warehouse Intelligent Patrol System')
              .fontSize('14fp')
              .fontColor($r('app.color.text_secondary'))
          }
          .alignItems(HorizontalAlign.Start)
          Blank()
          if (this.online) {
            Row({ space: '6vp' }) {
              Column()
                .width('8vp')
                .height('8vp')
                .backgroundColor($r('app.color.status_success'))
                .borderRadius('4vp')
                .animation({
                  duration: 1000,
                  iterations: -1,
                  curve: Curve.EaseInOut
                })
              Text('已连接')
                .fontSize('13fp')
                .fontColor($r('app.color.status_success'))
            }
            .alignItems(VerticalAlign.Center)
          }
        }
        .width('100%')
        .padding({ left: '32vp', right: '32vp', top: '32vp' })

        Column({ space: '12vp' }) {
          FlowStep({ step: '01', text: '环境感知 · 温湿度/烟雾监测', icon: '🌡️' })
          FlowStep({ step: '02', text: 'SLAM导航 · 多点自动巡检', icon: '🗺️' })
          FlowStep({ step: '03', text: '激光雷达 · 通道占用检测', icon: '📡' })
          FlowStep({ step: '04', text: '视觉识别 · 人员/货物异常', icon: '👁️' })
          FlowStep({ step: '05', text: 'APP监控 · 告警与远程控制', icon: '🎮' })
        }
        .width('100%')
        .padding('20vp')
        .margin({ left: '32vp', right: '32vp' })
        .backgroundColor($r('app.color.card_background'))
        .borderRadius('16vp')
        .shadow(CardShadow)

        Blank()

        Column({ space: '16vp' }) {
          Text('功能特性')
            .fontSize('18fp')
            .fontColor($r('app.color.text'))
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .padding({ left: '32vp' })

          Row({ space: '12vp' }) {
            FeatureCard({ title: '实时监控', desc: '数据实时同步', icon: '⚡' })
            FeatureCard({ title: '智能告警', desc: '多级异常预警', icon: '🔔' })
            FeatureCard({ title: '远程控制', desc: '遥控与自动模式', icon: '🔧' })
          }
          .padding({ left: '32vp', right: '32vp' })
        }
      }
      .layoutWeight(1)
      .width('100%')
      .backgroundColor($r('app.color.window_background'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.window_background'))
    .overlay(this.LoginOverlay(), { align: Alignment.Center })
  }

  @Builder
  LoginOverlay() {
    Column({ space: '0vp' }) {
      LoginComponent({
        connectSuccessRun: (): void => {
          router.pushUrl({ url: 'pages/Index' });
        },
        connectfailRun: (): void => {
          if (MyUtils.isDebug) {
            router.pushUrl({ url: 'pages/Index' });
          }
        }
      })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor('rgba(0, 0, 0, 0.6)')
  }
}

@Component
struct FlowStep {
  @Prop step: string = '';
  @Prop text: string = '';
  @Prop icon: string = '';

  build() {
    Row({ space: '12vp' }) {
      Column({ space: '4vp' }) {
        Text(this.icon)
          .fontSize('18fp')
        Text(this.step)
          .fontSize('10fp')
          .fontColor($r('app.color.text_on_accent'))
          .backgroundColor($r('app.color.button_primary'))
          .width('24vp')
          .height('24vp')
          .textAlign(TextAlign.Center)
          .borderRadius('12vp')
      }
      .alignItems(HorizontalAlign.Center)
      Text(this.text)
        .fontSize('15fp')
        .fontColor($r('app.color.text'))
        .layoutWeight(1)
      Text('→')
        .fontSize('16fp')
        .fontColor($r('app.color.text_secondary'))
        .opacity(0.5)
    }
    .width('100%')
    .padding('8vp')
  }
}

@Component
struct FeatureCard {
  @Prop title: string = '';
  @Prop desc: string = '';
  @Prop icon: string = '';

  build() {
    Column({ space: '8vp' }) {
      Text(this.icon)
        .fontSize('24fp')
      Text(this.title)
        .fontSize('15fp')
        .fontColor($r('app.color.text'))
        .fontWeight(FontWeight.Medium)
      Text(this.desc)
        .fontSize('12fp')
        .fontColor($r('app.color.text_secondary'))
    }
    .layoutWeight(1)
    .padding('16vp')
    .backgroundColor($r('app.color.card_elevated'))
    .borderRadius('12vp')
    .alignItems(HorizontalAlign.Center)
  }
}

@Component
struct LoginComponent {
  TextWidth: Length = '72vp';
  FontSize: Length = '15fp';
  BlankWidth: Length = '10vp';
  @State ip: string = '192.168.1.11';
  @State tcpPort: string = '6000';
  @State videoPort: string = '6500';
  @State connecting: boolean = false;
  connectSuccessRun: () => void = (): void => {
  };
  connectfailRun: () => void = (): void => {
  };

  aboutToAppear(): void {
    this.readNetConfig();
  }

  build(): void {
    Column({ space: '20vp' }) {
      Column({ space: '6vp' }) {
        Text('连接小车')
          .fontSize('26fp')
          .fontColor($r('app.color.text'))
          .fontWeight(FontWeight.Bold)
        Text('配置网络参数后连接，或跳过直接进入预览')
          .fontSize('14fp')
          .fontColor($r('app.color.text_secondary'))
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)

      this.InputRow('IP地址', this.ip, (v: string): void => { this.ip = v; })
      this.InputRow('TCP端口', this.tcpPort, (v: string): void => { this.tcpPort = v; })
      this.InputRow('视频端口', this.videoPort, (v: string): void => { this.videoPort = v; })

      Button(this.connecting ? '连接中...' : '连接小车')
        .width('100%')
        .height('48vp')
        .fontSize('16fp')
        .fontColor($r('app.color.text_on_accent'))
        .backgroundColor($r('app.color.button_primary'))
        .borderRadius(ButtonRadius)
        .shadow(ButtonShadow)
        .enabled(!this.connecting)
        .onClick((): void => {
          this.connectCar();
        })

      Button('跳过连接，直接进入')
        .width('100%')
        .height('48vp')
        .fontSize('15fp')
        .fontColor($r('app.color.text'))
        .backgroundColor($r('app.color.card_elevated'))
        .border({ width: '1vp', color: $r('app.color.divider') })
        .borderRadius(ButtonRadius)
        .onClick((): void => {
          this.enterWithoutConnect();
        })

      Text('离线模式下可浏览全部页面，连接小车后数据将实时更新')
        .fontSize('12fp')
        .fontColor($r('app.color.text_secondary'))
        .width('100%')
        .textAlign(TextAlign.Center)
        .lineHeight('18fp')
    }
    .width('340vp')
    .padding('28vp')
    .backgroundColor($r('app.color.card_background'))
    .borderRadius('24vp')
    .shadow(ElevatedShadow)
  }

  @Builder
  InputRow(label: string, value: string, onChange: (v: string) => void) {
    Column({ space: '6vp' }) {
      Text(label)
        .fontSize('14fp')
        .fontColor($r('app.color.text_secondary'))
        .width('100%')
      TextInput({ text: value, placeholder: `请输入${label}` })
        .fontSize('16fp')
        .fontColor($r('app.color.text'))
        .placeholderColor($r('app.color.text_secondary'))
        .backgroundColor($r('app.color.edit_text_background'))
        .border({ width: '1vp', color: $r('app.color.edit_text_border') })
        .borderRadius('12vp')
        .height('44vp')
        .padding({ left: '14vp', right: '14vp' })
        .onChange(onChange)
    }
    .width('100%')
  }

  private enterWithoutConnect(): void {
    this.saveNetConfig();
    VideoComponents.ip = this.ip;
    VideoComponents.port = Number.parseInt(this.videoPort);
    PatrolStore.getInstance().setOnline(false);
    PatrolStore.getInstance().updateVehicle({ message: '离线预览模式，未连接小车' });
    promptAction.showToast({ message: '已进入离线预览模式' });
    router.pushUrl({ url: 'pages/Index' });
  }

  private async connectCar(): Promise<void> {
    this.connecting = true;
    this.saveNetConfig();
    VideoComponents.ip = this.ip;
    VideoComponents.port = Number.parseInt(this.videoPort);
    await this.initTcpConfig();
    this.connecting = false;
  }

  private async initTcpConfig(): Promise<void> {
    const address = this.ip;
    TCPClientManager.getInstance().initNetAddress({
      address: address,
      port: Number.parseInt(this.tcpPort)
    });
    const isConnect = await TCPClientManager.getInstance().connect();
    if (isConnect) {
      promptAction.showToast({ message: '连接成功' });
      PatrolMessageHandler.init();
      TCPClientManager.receiveMessage = (message: string): void => {
        PatrolMessageHandler.handleMessage(message);
      };
      PatrolStore.getInstance().setOnline(true);
      TCPClientSendUtils.getInstance().init();
      this.connectSuccessRun();
    } else {
      PatrolStore.getInstance().setOnline(false);
      promptAction.showToast({ message: '连接失败，请检查信息' });
      this.connectfailRun();
    }
  }

  private readNetConfig(): void {
    const netUtils = PreferencesUtils.getInstance().netUtils;
    if (!netUtils) {
      return;
    }
    netUtils.getIP().then((v: preferences.ValueType): string => this.ip = String(v));
    netUtils.getTcpPort().then((v: preferences.ValueType): string => this.tcpPort = String(v));
    netUtils.getVideoPort().then((v: preferences.ValueType): string => this.videoPort = String(v));
  }

  private saveNetConfig(): void {
    const netUtils = PreferencesUtils.getInstance().netUtils;
    if (!netUtils) {
      return;
    }
    netUtils.setIp(this.ip);
    netUtils.setTcpPort(this.tcpPort);
    netUtils.setVideoPort(this.videoPort);
  }
}