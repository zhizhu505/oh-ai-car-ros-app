import router from '@ohos.router';
import { PatrolStore } from '../store/PatrolStore';
import promptAction from '@ohos.promptAction';
import { TCPClientManager } from '../tcp/TCPClientManager';
import { TCPClientSendUtils } from '../tcp/TCPClientSendUtils';
import { PatrolMessageHandler } from '../tcp/PatrolMessageHandler';
import { VideoComponents } from '../components/VideoComponents';
import { AlertRecord, AlertLevel, PatrolStatus, patrolStatusText } from '../model/PatrolModels';
import { CardShadow, CardShadowHover, ElevatedShadow } from '../styles/styles';
import { onlineColor } from '../utils/PatrolUiUtils';
import { DEFAULT_CAR_IP, DEFAULT_TCP_PORT, DEFAULT_VIDEO_PORT, PreferencesUtils } from '../utils/PreferencesUtils';
import preferences from '@ohos.data.preferences';

@Entry
@Component
struct Index {
  @State online: boolean = false;
  @State showConnectDialog: boolean = true;
  @State currentPoint: string = 'P2 A区管线左侧';
  @State nextPoint: string = 'P3 窄通道';
  @State patrolStatus: PatrolStatus = PatrolStatus.Idle;
  @State progress: number = 0;
  @State alerts: AlertRecord[] = [];
  private refreshHandler: () => void = (): void => {
    this.refreshData();
  };

  aboutToAppear(): void {
    this.refreshData();
    PatrolStore.getInstance().subscribe(this.refreshHandler);
  }

  aboutToDisappear(): void {
    PatrolStore.getInstance().unsubscribe(this.refreshHandler);
  }

  refreshData(): void {
    const store = PatrolStore.getInstance();
    this.online = store.vehicle.online;
    this.currentPoint = store.getPointName(store.vehicle.currentPoint);
    this.nextPoint = store.getPointName(store.vehicle.nextPoint);
    this.patrolStatus = store.vehicle.patrolStatus;
    this.progress = store.vehicle.progress;
    const sortedAlerts = store.alerts.slice(0) as AlertRecord[];
    sortedAlerts.sort((left: AlertRecord, right: AlertRecord): number => {
      return this.alertRank(right.level) - this.alertRank(left.level);
    });
    this.alerts = sortedAlerts.slice(0, 3) as AlertRecord[];
  }

  private alertRank(level: AlertLevel): number {
    if (level === AlertLevel.Critical) {
      return 3;
    }
    if (level === AlertLevel.Warning) {
      return 2;
    }
    return 1;
  }

  build() {
    Stack() {
      Column({ space: '0vp' }) {
        this.Header()

        Scroll() {
          Column({ space: '12vp' }) {
            VehicleStatusPanel({
              online: this.online,
              currentPoint: this.currentPoint,
              nextPoint: this.nextPoint,
              statusText: patrolStatusText(this.patrolStatus),
              progress: this.progress
            })
              .width('100%')

            AlertPreviewCard({ alerts: this.alerts })
              .width('100%')

            Row({ space: '10vp' }) {
              ModuleEntry({
                title: '环境感知',
                desc: '环境数据',
                metric: '异常阈值',
                accent: $r('app.color.module1_accent'),
                url: 'pages/Module1Environment'
              })
                .layoutWeight(1)
              ModuleEntry({
                title: 'SLAM导航',
                desc: '路线巡检',
                metric: '巡检路线',
                accent: $r('app.color.module2_accent'),
                url: 'pages/Module2Navigation'
              })
                .layoutWeight(1)
            }

            Row({ space: '10vp' }) {
              ModuleEntry({
                title: '激光雷达',
                desc: '通道安全',
                metric: '通道占用',
                accent: $r('app.color.module3_accent'),
                url: 'pages/Module3Lidar'
              })
                .layoutWeight(1)
              ModuleEntry({
                title: '视觉识别',
                desc: '视觉告警',
                metric: '视觉告警',
                accent: $r('app.color.module4_accent'),
                url: 'pages/Module4Vision'
              })
                .layoutWeight(1)
            }

            ModuleEntry({
              title: '手动接管',
              desc: '遥控小车',
              metric: '远程控制',
              accent: $r('app.color.module5_accent'),
              url: 'pages/RemoteControl'
            })
              .width('100%')

          }
          .padding({ left: '16vp', right: '16vp', top: '14vp', bottom: '18vp' })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.window_background'))

      if (this.showConnectDialog) {
        ConnectCarOverlay({
          onClose: (): void => {
            this.showConnectDialog = false;
          },
          onConnected: (): void => {
            this.showConnectDialog = false;
            this.refreshData();
          }
        })
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  Header() {
    Row({ space: '10vp' }) {
      Row({ space: '8vp' }) {
        Text('狭域巡航')
          .fontSize('20fp')
          .fontColor($r('app.color.text'))
          .fontWeight(FontWeight.Bold)
          .maxLines(1)
        Text('AI PATROL')
          .fontSize('9fp')
          .fontColor($r('app.color.module1_accent'))
          .fontWeight(FontWeight.Bold)
          .padding({ left: '6vp', right: '6vp', top: '2vp', bottom: '2vp' })
          .backgroundColor($r('app.color.module1_accent') + '18')
          .borderRadius('6vp')
      }
      .alignItems(VerticalAlign.Center)
      .layoutWeight(1)

      Row({ space: '6vp' }) {
        Stack() {
          Column()
            .width('8vp')
            .height('8vp')
            .backgroundColor(onlineColor(this.online))
            .borderRadius('4vp')
        }
        .shadow({
          radius: 8,
          offsetX: 0,
          offsetY: 0,
          color: onlineColor(this.online) + '60'
        })
        Text(this.online ? '已连接' : '离线')
          .fontSize('12fp')
          .fontColor($r('app.color.text_secondary'))
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
      }
      .alignItems(VerticalAlign.Center)
      .padding({ left: '10vp', right: '12vp', top: '6vp', bottom: '6vp' })
      .backgroundColor($r('app.color.card_elevated'))
      .borderRadius('14vp')
      .border({ width: '1vp', color: $r('app.color.divider') })

      NetworkButton({
        onOpen: (): void => {
          this.showConnectDialog = true;
        }
      })
    }
    .width('100%')
    .height('82vp')
    .padding({ left: '14vp', right: '14vp', top: '30vp', bottom: '8vp' })
    .alignItems(VerticalAlign.Center)
    .backgroundColor($r('app.color.header_background'))
    .shadow({
      radius: 6,
      offsetX: 0,
      offsetY: 2,
      color: '#00000030'
    })
  }
}

@Component
struct SectionTitle {
  @Prop title: string = '';

  build() {
    Row({ space: '8vp' }) {
      Column()
        .width('4vp')
        .height('18vp')
        .backgroundColor($r('app.color.button_primary'))
        .borderRadius('2vp')
      Text(this.title)
        .fontSize('16fp')
        .fontColor($r('app.color.text'))
        .fontWeight(FontWeight.Bold)
        .maxLines(1)
    }
  }
}

@Component
struct NetworkButton {
  @State isHover: boolean = false;
  onOpen: () => void = (): void => {};

  build() {
    Button() {
      Stack() {
        Column()
          .width('40vp')
          .height('40vp')
          .backgroundColor(this.isHover ? $r('app.color.module1_accent') + '22' : $r('app.color.card_elevated'))
          .borderRadius('20vp')
        Image($r('app.media.patrol_logo'))
          .width('34vp')
          .height('34vp')
          .borderRadius('17vp')
          .objectFit(ImageFit.Cover)
      }
      .alignContent(Alignment.Center)
    }
    .width('44vp')
    .height('44vp')
    .backgroundColor(Color.Transparent)
    .borderRadius('22vp')
    .border({ width: '1vp', color: this.isHover ? $r('app.color.module1_accent') : $r('app.color.divider') })
    .shadow({
      radius: this.isHover ? 12 : 6,
      offsetX: 0,
      offsetY: this.isHover ? 0 : 3,
      color: this.isHover ? $r('app.color.module1_accent') + '45' : '#00000045'
    })
    .onHover((isHover: boolean): void => {
      this.isHover = isHover;
    })
    .onClick((): void => {
      this.onOpen();
    })
  }
}

@Component
struct ModuleEntry {
  @Prop title: string = '';
  @Prop desc: string = '';
  @Prop metric: string = '';
  @Prop accent: ResourceColor = $r('app.color.button_primary');
  @Prop url: string = '';
  @State isHover: boolean = false;

  build() {
    Column({ space: '9vp' }) {
      Row({ space: '7vp' }) {
        Column()
          .width('4vp')
          .height('30vp')
          .backgroundColor(this.accent)
          .borderRadius('2vp')
        Column({ space: '4vp' }) {
          Text(this.title)
            .fontSize('16fp')
            .fontColor($r('app.color.text'))
            .fontWeight(FontWeight.Bold)
            .maxLines(1)
          Text(this.desc)
            .fontSize('11fp')
            .fontColor($r('app.color.text_secondary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Text('›')
          .fontSize('20fp')
          .fontColor(this.accent)
          .fontWeight(FontWeight.Bold)
          .opacity(0.9)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Row() {
        Text(this.metric)
          .fontSize('11fp')
          .fontColor(this.accent)
          .fontWeight(FontWeight.Bold)
          .textAlign(TextAlign.Center)
          .padding({ left: '10vp', right: '10vp', top: '3vp', bottom: '3vp' })
          .backgroundColor(this.accent + '18')
          .borderRadius('10vp')
          .maxLines(1)
        Blank()
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .height('96vp')
    .padding({ left: '12vp', right: '12vp', top: '12vp', bottom: '12vp' })
    .backgroundColor($r('app.color.card_background'))
    .borderRadius('14vp')
    .border({ width: this.isHover ? '2vp' : '1vp', color: this.isHover ? this.accent : $r('app.color.divider') })
    .shadow(this.isHover ? {
      radius: 12,
      offsetX: 0,
      offsetY: 0,
      color: this.accent + '55'
    } : CardShadow)
    .scale({ x: this.isHover ? 1.02 : 1, y: this.isHover ? 1.02 : 1 })
    .animation({ duration: 180, curve: Curve.EaseOut })
    .onClick((): void => {
      router.pushUrl({ url: this.url });
    })
    .onHover((isHover: boolean): void => {
      this.isHover = isHover;
    })
  }
}

@Component
struct ControlCard {
  build() {
    Column({ space: '10vp' }) {
      Row() {
        SectionTitle({ title: '手动接管' })
          .layoutWeight(1)
      }
      .width('100%')

      Row({ space: '10vp' }) {
        Stack() {
          Column()
            .width('36vp')
            .height('36vp')
            .backgroundColor($r('app.color.module5_accent') + '18')
            .borderRadius('12vp')
          Image($r('app.media.vector'))
            .width('20vp')
            .height('20vp')
        }
        .alignContent(Alignment.Center)
        Column({ space: '3vp' }) {
          Text('摇杆遥控')
            .fontSize('14fp')
            .fontColor($r('app.color.text'))
            .fontWeight(FontWeight.Bold)
          Text('遥控 / 视频 / 接管')
            .fontSize('12fp')
            .fontColor($r('app.color.text_secondary'))
            .maxLines(1)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        Button('进入')
          .height('30vp')
          .fontSize('12fp')
          .fontColor($r('app.color.text_on_accent'))
          .backgroundColor($r('app.color.button_primary'))
          .borderRadius('15vp')
          .onClick((): void => {
            router.pushUrl({ url: 'pages/RemoteControl' });
          })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding('14vp')
    .backgroundColor($r('app.color.card_background'))
    .borderRadius('14vp')
    .border({ width: '1vp', color: $r('app.color.divider') })
    .shadow(CardShadow)
  }
}

@Component
struct AlertPreviewCard {
  @Prop alerts: AlertRecord[] = [];

  build() {
    Column({ space: '10vp' }) {
      Row() {
        SectionTitle({ title: '重点告警' })
          .layoutWeight(1)
      }
      .width('100%')

      if (this.alerts.length > 0) {
        Column({ space: '8vp' }) {
          ForEach(this.alerts, (item: AlertRecord) => {
            this.AlertContent(item)
          }, (item: AlertRecord) => item.id)
        }
        .width('100%')
      } else {
        Column({ space: '8vp' }) {
          Row({ space: '8vp' }) {
            Text('正常')
              .fontSize('11fp')
              .fontColor($r('app.color.text_on_accent'))
              .backgroundColor($r('app.color.status_success'))
              .padding({ left: '8vp', right: '8vp', top: '3vp', bottom: '3vp' })
              .borderRadius('8vp')
            Text('暂无告警')
              .fontSize('15fp')
              .fontColor($r('app.color.text'))
              .fontWeight(FontWeight.Bold)
              .layoutWeight(1)
          }
          Text('暂无异常，AI监测待命')
            .fontSize('12fp')
            .fontColor($r('app.color.text_secondary'))
            .maxLines(1)
        }
        .width('100%')
        .padding('12vp')
        .backgroundColor($r('app.color.card_background'))
        .borderRadius('12vp')
        .border({ width: '1vp', color: $r('app.color.status_success') + '55' })
      }
    }
    .width('100%')
    .padding('12vp')
    .backgroundColor($r('app.color.card_background'))
    .borderRadius('14vp')
    .border({ width: '1vp', color: this.alerts.length > 0 ? $r('app.color.alert_warning') + '70' : $r('app.color.divider') })
    .shadow(this.alerts.length > 0 ? ElevatedShadow : CardShadow)
    .onClick((): void => {
      router.pushUrl({ url: 'pages/AlertRecords' });
    })
  }

  @Builder
  AlertContent(alert: AlertRecord) {
    Row({ space: '10vp' }) {
      Text(alert.level === AlertLevel.Critical ? '严重' : alert.level === AlertLevel.Warning ? '预警' : '提示')
        .fontSize('12fp')
        .fontColor($r('app.color.text_on_accent'))
        .fontWeight(FontWeight.Bold)
        .backgroundColor(alert.level === AlertLevel.Critical ? $r('app.color.alert_critical') : alert.level === AlertLevel.Warning ? $r('app.color.alert_warning') : $r('app.color.status_success'))
        .padding({ left: '8vp', right: '8vp', top: '4vp', bottom: '4vp' })
        .borderRadius('8vp')

      Column({ space: '4vp' }) {
        Text(alert.message)
          .fontSize(alert.level === AlertLevel.Critical ? '15fp' : '14fp')
          .fontColor($r('app.color.text'))
          .fontWeight(FontWeight.Bold)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(`${alert.time}  ${alert.point}`)
          .fontSize('10fp')
          .fontColor($r('app.color.text_secondary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      if (alert.aiAnalyzing || alert.aiAnalysis) {
        Text(alert.aiAnalyzing ? 'AI' : '完成')
          .fontSize('10fp')
          .fontColor($r('app.color.button_primary'))
          .fontWeight(FontWeight.Bold)
          .maxLines(1)
      }
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .padding({ left: '12vp', right: '12vp', top: '10vp', bottom: '10vp' })
    .backgroundColor(alert.level === AlertLevel.Critical ? $r('app.color.alert_critical') + '12' : alert.level === AlertLevel.Warning ? $r('app.color.alert_warning') + '12' : $r('app.color.card_background'))
    .borderRadius('12vp')
    .border({ width: '1vp', color: alert.level === AlertLevel.Critical ? $r('app.color.alert_critical') + '70' : alert.level === AlertLevel.Warning ? $r('app.color.alert_warning') + '70' : $r('app.color.divider') })
  }
}

@Component
struct ConnectCarOverlay {
  @State ip: string = DEFAULT_CAR_IP;
  @State tcpPort: string = DEFAULT_TCP_PORT;
  @State videoPort: string = DEFAULT_VIDEO_PORT;
  @State connecting: boolean = false;
  onClose: () => void = (): void => {};
  onConnected: () => void = (): void => {};

  aboutToAppear(): void {
    this.readNetConfig();
  }

  build() {
    Column() {
      Column({ space: '16vp' }) {
        Column({ space: '5vp' }) {
          Text('连接小车')
            .fontSize('22fp')
            .fontColor($r('app.color.text'))
            .fontWeight(FontWeight.Bold)
            .maxLines(1)
          Text('连接后同步小车数据，也可以跳过进入预览')
            .fontSize('12fp')
            .fontColor($r('app.color.text_secondary'))
            .maxLines(1)
        }
        .alignItems(HorizontalAlign.Center)
        .width('100%')

        Column({ space: '10vp' }) {
          this.InputField('IP地址', this.ip, (value: string): void => {
            this.ip = value;
          })
          this.InputField('TCP端口', this.tcpPort, (value: string): void => {
            this.tcpPort = value;
          })
          this.InputField('视频端口', this.videoPort, (value: string): void => {
            this.videoPort = value;
          })
        }
        .width('100%')

        Row({ space: '10vp' }) {
          Button(this.connecting ? '连接中...' : '连接小车')
            .layoutWeight(1)
            .height('42vp')
            .fontSize('14fp')
            .fontColor($r('app.color.text_on_accent'))
            .fontWeight(FontWeight.Bold)
            .backgroundColor($r('app.color.button_primary'))
            .borderRadius('14vp')
            .shadow({
              radius: 12,
              offsetX: 0,
              offsetY: 4,
              color: '#6366F145'
            })
            .enabled(!this.connecting)
            .onClick((): void => {
              this.connectCar();
            })

          Button('跳过')
            .layoutWeight(1)
            .height('42vp')
            .fontSize('14fp')
            .fontColor($r('app.color.text'))
            .fontWeight(FontWeight.Bold)
            .backgroundColor($r('app.color.card_elevated'))
            .border({ width: '1vp', color: $r('app.color.divider') })
            .borderRadius('14vp')
            .onClick((): void => {
              this.enterPreview();
            })
        }
        .width('100%')

        Text('离线预览可浏览全部页面，连接后可控制小车')
          .fontSize('11fp')
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
          .textAlign(TextAlign.Center)
          .maxLines(1)
      }
      .width('88%')
      .padding({ left: '20vp', right: '20vp', top: '22vp', bottom: '18vp' })
      .backgroundColor($r('app.color.header_background'))
      .borderRadius('16vp')
      .border({ width: '1vp', color: $r('app.color.divider') })
      .shadow({
        radius: 24,
        offsetX: 0,
        offsetY: 12,
        color: '#00000055'
      })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('rgba(0, 0, 0, 0.55)')
  }

  @Builder
  InputField(label: string, value: string, onChange: (value: string) => void) {
    Column({ space: '6vp' }) {
      Text(label)
        .fontSize('12fp')
        .fontColor($r('app.color.text_secondary'))
        .width('100%')
      TextInput({ text: value, placeholder: `请输入${label}` })
        .height('42vp')
        .fontSize('15fp')
        .fontColor($r('app.color.text'))
        .placeholderColor($r('app.color.text_secondary'))
        .backgroundColor($r('app.color.edit_text_background'))
        .border({ width: '1vp', color: $r('app.color.edit_text_border') })
        .borderRadius('12vp')
        .padding({ left: '12vp', right: '12vp' })
        .onChange(onChange)
    }
    .width('100%')
  }

  private async enterPreview(): Promise<void> {
    await this.saveNetConfig();
    VideoComponents.ip = this.ip.trim();
    VideoComponents.port = Number.parseInt(this.videoPort.trim());
    PatrolStore.getInstance().setOnline(false);
    PatrolStore.getInstance().updateVehicle({ message: '离线预览模式，未连接小车' });
    promptAction.showToast({ message: '已进入离线预览模式' });
    this.onClose();
  }

  private async connectCar(): Promise<void> {
    this.connecting = true;
    await this.saveNetConfig();
    VideoComponents.ip = this.ip.trim();
    VideoComponents.port = Number.parseInt(this.videoPort.trim());
    TCPClientManager.getInstance().initNetAddress({
      address: this.ip.trim(),
      port: Number.parseInt(this.tcpPort.trim())
    });
    const connected = await TCPClientManager.getInstance().connect();
    this.connecting = false;
    if (connected) {
      PatrolMessageHandler.init();
      TCPClientManager.receiveMessage = (message: string): void => {
        PatrolMessageHandler.handleMessage(message);
      };
      PatrolStore.getInstance().setOnline(true);
      TCPClientSendUtils.getInstance().init();
      promptAction.showToast({ message: '连接成功' });
      this.onConnected();
    } else {
      PatrolStore.getInstance().setOnline(false);
      promptAction.showToast({ message: '连接失败，请检查信息' });
    }
  }

  private readNetConfig(): void {
    const netUtils = PreferencesUtils.getInstance().netUtils;
    if (!netUtils) {
      return;
    }
    netUtils.getIP().then((v: preferences.ValueType): void => {
      this.ip = String(v);
    })
    netUtils.getTcpPort().then((v: preferences.ValueType): void => {
      this.tcpPort = String(v);
    })
    netUtils.getVideoPort().then((v: preferences.ValueType): void => {
      this.videoPort = String(v);
    })
  }

  private async saveNetConfig(): Promise<void> {
    const netUtils = PreferencesUtils.getInstance().netUtils;
    if (!netUtils) {
      return;
    }
    this.ip = this.ip.trim();
    this.tcpPort = this.tcpPort.trim();
    this.videoPort = this.videoPort.trim();
    await Promise.all([
      netUtils.setIp(this.ip),
      netUtils.setTcpPort(this.tcpPort),
      netUtils.setVideoPort(this.videoPort)
    ]);
  }
}

@Component
struct VehicleStatusPanel {
  @Prop online: boolean = false;
  @Prop currentPoint: string = '';
  @Prop nextPoint: string = '';
  @Prop statusText: string = '';
  @Prop progress: number = 0;

  build() {
    Column({ space: '12vp' }) {
      Row() {
        Column({ space: '5vp' }) {
          Row({ space: '7vp' }) {
            Stack() {
              Column()
                .width('8vp')
                .height('8vp')
                .backgroundColor(this.online ? $r('app.color.status_success') : $r('app.color.alert_warning'))
                .borderRadius('4vp')
            }
            .shadow({
              radius: 10,
              offsetX: 0,
              offsetY: 0,
              color: (this.online ? $r('app.color.status_success') : $r('app.color.alert_warning')) + '70'
            })
            Text(this.online ? '在线同步' : '离线预览')
              .fontSize('11fp')
              .fontColor(this.online ? $r('app.color.status_success') : $r('app.color.alert_warning'))
              .fontWeight(FontWeight.Bold)
              .maxLines(1)
          }
          .alignItems(VerticalAlign.Center)

          Text('巡检小车状态')
            .fontSize('17fp')
            .fontColor($r('app.color.text'))
            .fontWeight(FontWeight.Bold)
            .maxLines(1)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Text(this.statusText)
          .fontSize('12fp')
          .fontColor($r('app.color.text'))
          .fontWeight(FontWeight.Bold)
          .padding({ left: '12vp', right: '12vp', top: '6vp', bottom: '6vp' })
          .backgroundColor($r('app.color.button_primary') + '20')
          .borderRadius('14vp')
          .maxLines(1)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Column({ space: '7vp' }) {
        Row({ space: '10vp' }) {
          Column({ space: '4vp' }) {
            Text('当前点位')
              .fontSize('10fp')
              .fontColor($r('app.color.text_secondary'))
              .maxLines(1)
            Text(this.currentPoint)
              .fontSize('20fp')
              .fontColor($r('app.color.text'))
              .fontWeight(FontWeight.Bold)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)

          Column({ space: '4vp' }) {
            Text('下一点位')
              .fontSize('10fp')
              .fontColor($r('app.color.text_secondary'))
              .maxLines(1)
            Text(this.nextPoint)
              .fontSize('15fp')
              .fontColor($r('app.color.text'))
              .fontWeight(FontWeight.Bold)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width('38%')
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .alignItems(VerticalAlign.Bottom)

        Stack() {
          Column()
            .width('100%')
            .height('7vp')
            .backgroundColor($r('app.color.card_elevated'))
            .borderRadius('4vp')
          Row()
            .width(`${this.progress}%`)
            .height('7vp')
            .backgroundColor($r('app.color.button_primary'))
            .borderRadius('4vp')
            .shadow({
              radius: 8,
              offsetX: 0,
              offsetY: 0,
              color: '#6366F166'
            })
        }
        .alignContent(Alignment.Start)
        .width('100%')
        .height('7vp')
        .animation({ duration: 260, curve: Curve.EaseOut })
      }
      .width('100%')
      .padding({ left: '13vp', right: '13vp', top: '12vp', bottom: '12vp' })
      .backgroundColor($r('app.color.card_elevated') + 'BD')
      .borderRadius('13vp')

      Row({ space: '8vp' }) {
        Row({ space: '5vp' }) {
          Text('定位')
            .fontSize('10fp')
            .fontColor($r('app.color.text_secondary'))
          Text('已锁定')
            .fontSize('11fp')
            .fontColor($r('app.color.text'))
            .fontWeight(FontWeight.Bold)
            .maxLines(1)
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .padding({ top: '7vp', bottom: '7vp' })
        .backgroundColor($r('app.color.card_elevated') + '99')
        .borderRadius('12vp')

        Row({ space: '5vp' }) {
          Text('进度')
            .fontSize('10fp')
            .fontColor($r('app.color.text_secondary'))
          Text(`${this.progress}%`)
            .fontSize('12fp')
            .fontColor($r('app.color.text'))
            .fontWeight(FontWeight.Bold)
            .maxLines(1)
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .padding({ top: '7vp', bottom: '7vp' })
        .backgroundColor($r('app.color.card_elevated') + '99')
        .borderRadius('12vp')
      }
      .width('100%')
    }
    .width('100%')
    .padding({ left: '14vp', right: '14vp', top: '14vp', bottom: '14vp' })
    .backgroundColor($r('app.color.card_background') + 'F2')
    .borderRadius('16vp')
    .border({ width: '1vp', color: this.online ? $r('app.color.status_success') + '45' : $r('app.color.alert_warning') + '45' })
    .shadow({
      radius: 14,
      offsetX: 0,
      offsetY: 6,
      color: '#00000038'
    })
    .animation({ duration: 220, curve: Curve.EaseOut })
  }
}

@Component
struct StatusPill {
  @Prop label: string = '';
  @Prop value: string = '';

  build() {
    Row() {
      Column({ space: '3vp' }) {
        Text(this.label)
          .fontSize('10fp')
          .fontColor($r('app.color.text_secondary'))
          .opacity(0.78)
          .maxLines(1)
        Text(this.value)
          .fontSize('15fp')
          .fontColor($r('app.color.text'))
          .fontWeight(FontWeight.Bold)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding({ left: '12vp', right: '12vp', top: '10vp', bottom: '10vp' })
    .backgroundColor($r('app.color.card_elevated'))
    .borderRadius('10vp')
  }
}
@Component
struct PatrolSummary {
  build() {
    Column({ space: '8vp' }) {
      Row({ space: '8vp' }) {
        SummaryItem({ label: '当前点位', value: 'P2 A区管线左侧' })
          .layoutWeight(1)
        SummaryItem({ label: '下一点位', value: 'P3 窄通道' })
          .layoutWeight(1)
      }
      .width('100%')
      Row({ space: '8vp' }) {
        SummaryItem({ label: '巡检状态', value: '待启动' })
          .layoutWeight(1)
        SummaryItem({ label: '闭环流程', value: '采集 → 识别 → 告警' })
          .layoutWeight(1)
      }
      .width('100%')
    }
    .width('100%')
  }
}

@Component
struct SummaryItem {
  @Prop label: string = '';
  @Prop value: string = '';

  build() {
    Column({ space: '4vp' }) {
      Text(this.label)
        .fontSize('10fp')
        .fontColor($r('app.color.text_secondary'))
        .maxLines(1)
      Text(this.value)
        .fontSize('13fp')
        .fontColor($r('app.color.text'))
        .fontWeight(FontWeight.Medium)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .padding({ left: '10vp', right: '10vp', top: '10vp', bottom: '10vp' })
    .backgroundColor($r('app.color.card_elevated'))
    .borderRadius('10vp')
  }
}
