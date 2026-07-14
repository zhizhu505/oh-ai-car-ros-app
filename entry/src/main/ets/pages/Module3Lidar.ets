import promptAction from '@ohos.promptAction';
import {
  ALERT_CATEGORY_LIDAR,
  ChannelStatus,
  LidarSnapshot,
  channelStatusText
} from '../model/PatrolModels';
import { PatrolStore } from '../store/PatrolStore';
import { PatrolCommandUtils } from '../tcp/PatrolCommandUtils';
import { ModuleTabBar, InfoCard } from '../components/PageHeader';
import { ModuleAlertList } from '../components/ModuleAlertList';
import { channelStatusColor } from '../utils/PatrolUiUtils';
import { CardShadow, ElevatedShadow, ButtonShadow } from '../styles/styles';
import { DEFAULT_CAR_IP, DEFAULT_TCP_PORT, PreferencesUtils } from '../utils/PreferencesUtils';
import { TCPClientManager } from '../tcp/TCPClientManager';
import preferences from '@ohos.data.preferences';

type OccupancyClass = 'clear' | 'short' | 'long' | 'blocked';

interface PatrolReplayFrame {
  point: string;
  label: string;
  front: number;
  left: number;
  right: number;
  duration: number;
  movingTarget: boolean;
  suspiciousTarget: boolean;
}

@Entry
@Component
struct Module3Lidar {
  @State currentTabIndex: number = 0;
  @State showStrategyDialog: boolean = false;
  @State point: string = '-';
  @State frontDistance: number = 0;
  @State leftDistance: number = 0;
  @State rightDistance: number = 0;
  @State channelStatus: ChannelStatus = ChannelStatus.Clear;
  @State message: string = '等待数据';
  @State updateTime: string = '-';
  @State slowDownThreshold: number = 0.8;
  @State stopThreshold: number = 0.4;
  @State alertDurationSec: number = 5;
  @State shelfIdealDistance: number = 0.6;
  @State shelfTolerance: number = 0.12;
  @State guardRegionEnabled: boolean = true;
  @State movingTargetDetected: boolean = false;
  @State obstacleDurationSec: number = 2;
  @State avoidanceEnabled: boolean = false;
  @State trackingEnabled: boolean = false;
  @State avoidanceStatus: 'idle' | 'scanning' | 'avoiding' | 'tracking' = 'idle';
  @State rosbridgeConnected: boolean = false;
  @State rosbridgeStatusText: string = '未连接 Jetson';
  @State rosbridgeHost: string = DEFAULT_CAR_IP;
  @State rosbridgePort: string = DEFAULT_TCP_PORT;
  @State rosbridgeBusy: boolean = false;
  @State rosFrontWarnM: number = 0.7;
  @State rosNarrowMode: boolean = false;
  @State patrolReplayEnabled: boolean = false;
  @State patrolReplayText: string = '点击启动避障后开始接收巡检实时数据';
  @State patrolStepLabel: string = '等待启动巡检';
  @State suspiciousTrackingEnabled: boolean = false;
  @State suspiciousTrackSec: number = 0;
  @State suspiciousTargetDistance: number = 0;
  private tabs: string[] = ['实时检测', '避障控制', '异常记录'];
  private patrolReplayTimer: number = -1;
  private patrolStepIndex: number = 0;
  private patrolReplayFrames: PatrolReplayFrame[] = [
    { point: 'P0 入口', label: 'P0 入口自检，通道畅通', front: 1.45, left: 0.62, right: 0.61, duration: 0, movingTarget: false, suspiciousTarget: false },
    { point: 'P1 管廊上段', label: 'P1 管廊货架居中巡航', front: 1.20, left: 0.56, right: 0.65, duration: 1, movingTarget: false, suspiciousTarget: false },
    { point: 'P2 管廊中段', label: 'P2 前方 0.72m 临时障碍，执行减速', front: 0.72, left: 0.58, right: 0.60, duration: 2, movingTarget: false, suspiciousTarget: false },
    { point: 'P3 管廊下段', label: 'P3 人员短时经过，继续低速观察', front: 0.66, left: 0.59, right: 0.62, duration: 3, movingTarget: false, suspiciousTarget: false },
    { point: 'P4 转弯口', label: 'P4 前方 0.35m 障碍，强制停车', front: 0.35, left: 0.57, right: 0.60, duration: 5, movingTarget: false, suspiciousTarget: false },
    { point: 'P5 异常物体区', label: 'P5 货物堆放持续 6 秒，生成占用告警', front: 0.42, left: 0.58, right: 0.61, duration: 6, movingTarget: false, suspiciousTarget: false },
    { point: 'P5 警戒区边界', label: 'P5 可疑人员进入警戒区，开始跟踪', front: 1.10, left: 0.63, right: 0.57, duration: 1, movingTarget: true, suspiciousTarget: true },
    { point: 'P5 障碍旁通道', label: 'P5 可疑人员沿障碍区移动，持续跟踪', front: 0.95, left: 0.66, right: 0.53, duration: 4, movingTarget: true, suspiciousTarget: true },
    { point: 'P6 终点', label: 'P6 跟踪目标离开通道，恢复通行', front: 1.38, left: 0.60, right: 0.60, duration: 0, movingTarget: false, suspiciousTarget: false }
  ];
  private refreshHandler: () => void = (): void => {
    this.refreshData();
  };

  async aboutToAppear(): Promise<void> {
    this.refreshData();
    PatrolStore.getInstance().subscribe(this.refreshHandler);
    await this.readRosbridgeConfig();
  }

  aboutToDisappear(): void {
    this.stopPatrolReplay();
    PatrolStore.getInstance().unsubscribe(this.refreshHandler);
  }

  private async readRosbridgeConfig(): Promise<void> {
    const netUtils = PreferencesUtils.getInstance().netUtils;
    if (!netUtils) {
      return;
    }
    netUtils.getIP().then((v: preferences.ValueType): void => {
      this.rosbridgeHost = String(v);
    });
    netUtils.getTcpPort().then((v: preferences.ValueType): void => {
      this.rosbridgePort = String(v);
    });
  }

  private async saveRosbridgeConfig(): Promise<void> {
    const netUtils = PreferencesUtils.getInstance().netUtils;
    if (!netUtils) {
      return;
    }
    await Promise.all([
      netUtils.setIp(this.rosbridgeHost.trim()),
      netUtils.setTcpPort(this.rosbridgePort.trim())
    ]);
  }

  private async connectRosbridge(): Promise<void> {
    this.rosbridgeBusy = true;
    try {
      await this.saveRosbridgeConfig();
      const tcpPort = Number(this.rosbridgePort.trim());
      if (Number.isNaN(tcpPort) || tcpPort <= 0) {
        this.rosbridgeConnected = false;
        this.rosbridgeStatusText = 'TCP 端口无效，请检查配置';
        promptAction.showToast({ message: 'TCP 端口无效' });
        return;
      }
      TCPClientManager.getInstance().initNetAddress({
        address: this.rosbridgeHost.trim(),
        port: tcpPort
      });
      const ok = await TCPClientManager.getInstance().connect();
      this.rosbridgeConnected = ok;
      if (ok) {
        this.rosbridgeStatusText = `已连接 Jetson ${this.rosbridgeHost.trim()}:${this.rosbridgePort.trim()}`;
        this.patrolReplayText = 'ROS 已连接，页面优先显示实车雷达数据';
        promptAction.showToast({ message: 'ROS 连接成功' });
      } else {
        this.rosbridgeStatusText = `连接失败：${this.rosbridgeHost.trim()}:${this.rosbridgePort.trim()}`;
        promptAction.showToast({ message: 'ROS 连接失败' });
      }
    } finally {
      this.rosbridgeBusy = false;
    }
  }

  private async sendRosCommand(cmd: string): Promise<void> {
    if (!this.rosbridgeConnected) {
      promptAction.showToast({ message: '请先连接 Jetson' });
      return;
    }
    let ok = false;
    if (cmd === 'start_auto') {
      ok = await PatrolCommandUtils.startAutoAvoidance();
    } else if (cmd === 'stop_auto') {
      ok = await PatrolCommandUtils.stopAutoAvoidance();
    } else if (cmd === 'narrow_mode') {
      this.rosNarrowMode = true;
      ok = await PatrolCommandUtils.setNarrowMode(true);
    } else if (cmd === 'normal_mode') {
      this.rosNarrowMode = false;
      ok = await PatrolCommandUtils.setNarrowMode(false);
    } else if (cmd.startsWith('set_front:')) {
      const value = Number(cmd.split(':')[1]);
      if (!Number.isNaN(value) && value > 0) {
        this.rosFrontWarnM = value;
        ok = await PatrolCommandUtils.setFrontWarnThreshold(value);
      }
    }
    if (ok && cmd === 'start_auto') {
      this.startPatrolReplay();
    } else if (ok && cmd === 'stop_auto') {
      this.stopPatrolReplay();
      this.patrolReplayEnabled = false;
      this.patrolReplayText = '自动通道避障已停止，巡检实时数据暂停';
      this.patrolStepLabel = '等待重新启动巡检';
    }
    promptAction.showToast({ message: ok ? `已发送: ${cmd}` : `发送失败: ${cmd}` });
  }

  private startPatrolReplay(): void {
    this.patrolReplayEnabled = true;
    this.patrolReplayText = '巡检数据流运行中，按 P0-P6 路线实时刷新';
    if (this.patrolReplayTimer >= 0) {
      return;
    }
    this.applyPatrolReplayFrame();
    this.patrolReplayTimer = setInterval((): void => {
      this.applyPatrolReplayFrame();
    }, 2000);
  }

  private stopPatrolReplay(): void {
    if (this.patrolReplayTimer < 0) {
      return;
    }
    clearInterval(this.patrolReplayTimer);
    this.patrolReplayTimer = -1;
  }

  private applyPatrolReplayFrame(): void {
    if (!this.patrolReplayEnabled) {
      this.patrolReplayText = '巡检数据流已暂停';
      return;
    }
    if (this.rosbridgeConnected) {
      this.patrolReplayText = 'ROS 已连接，页面优先显示实车雷达数据';
      return;
    }
    const frame = this.patrolReplayFrames[this.patrolStepIndex % this.patrolReplayFrames.length];
    this.patrolStepIndex += 1;
    this.point = frame.point;
    this.patrolStepLabel = frame.label;
    this.patrolReplayText = `巡检数据刷新：${frame.label}`;
    this.simulateScenario(frame.front, frame.left, frame.right, frame.duration, frame.movingTarget, frame.suspiciousTarget);
  }

  private togglePatrolReplay(): void {
    this.patrolReplayEnabled = !this.patrolReplayEnabled;
    if (this.patrolReplayEnabled) {
      this.patrolReplayText = '巡检数据流运行中，按 P0-P6 路线实时刷新';
      this.applyPatrolReplayFrame();
    } else {
      this.patrolReplayText = '巡检数据流已暂停';
    }
  }

  private getPatrolDataBadgeText(): string {
    if (!this.patrolReplayEnabled) {
      return '数据流暂停';
    }
    return this.rosbridgeConnected ? '实车雷达数据' : '巡检实时数据';
  }

  refreshData(): void {
    const lidar: LidarSnapshot = PatrolStore.getInstance().lidar;
    this.point = lidar.point;
    this.frontDistance = lidar.frontDistance;
    this.leftDistance = lidar.leftDistance;
    this.rightDistance = lidar.rightDistance;
    this.channelStatus = lidar.channelStatus;
    this.message = lidar.message;
    this.updateTime = lidar.updateTime;
    this.avoidanceEnabled = lidar.avoidanceEnabled;
    this.trackingEnabled = lidar.trackingEnabled;
    this.avoidanceStatus = lidar.avoidanceStatus;
  }

  private getCenterOffset(): number {
    return Math.abs(this.leftDistance - this.rightDistance);
  }

  private getShelfBiasText(): string {
    const delta = this.leftDistance - this.rightDistance;
    if (Math.abs(delta) <= this.shelfTolerance) {
      return '左右货架距离稳定，小车处于通道居中状态';
    }
    return delta > 0 ? '右侧货架距离偏近，建议向左微调' : '左侧货架距离偏近，建议向右微调';
  }

  private getOccupancyClass(): OccupancyClass {
    if (this.frontDistance <= this.stopThreshold) {
      return 'blocked';
    }
    if (this.frontDistance <= this.slowDownThreshold) {
      if (this.obstacleDurationSec >= this.alertDurationSec) {
        return 'long';
      }
      return 'short';
    }
    return 'clear';
  }

  private getScenarioTitle(): string {
    if (this.suspiciousTrackingEnabled) {
      return '可疑人员跟踪';
    }
    if (this.guardRegionEnabled && this.movingTargetDetected) {
      return '警戒区移动目标';
    }
    const occupancy = this.getOccupancyClass();
    if (occupancy === 'blocked') {
      return '通道堵塞';
    }
    if (occupancy === 'long') {
      return '长时占用';
    }
    if (occupancy === 'short') {
      return '短时障碍';
    }
    return '通道畅通';
  }

  private getActionText(): string {
    const point = this.point === '-' ? 'B区通道' : this.point;
    if (this.suspiciousTrackingEnabled) {
      return `${point}检测到可疑人员进入警戒区，雷达已锁定目标并持续跟踪 ${this.suspiciousTrackSec}s，目标距离 ${this.suspiciousTargetDistance.toFixed(2)}m`;
    }
    if (this.guardRegionEnabled && this.movingTargetDetected) {
      return `${point}警戒区域检测到移动目标，触发禁入区雷达告警`;
    }
    const occupancy = this.getOccupancyClass();
    if (occupancy === 'blocked') {
      return `${point}前方 ${this.frontDistance.toFixed(2)}m 检测到障碍，已进入停车阈值，疑似通道堵塞`;
    }
    if (occupancy === 'long') {
      return `${point}前方 ${this.frontDistance.toFixed(2)}m 障碍持续 ${this.obstacleDurationSec}s，疑似货物堆放异常`;
    }
    if (occupancy === 'short') {
      return `${point}前方 ${this.frontDistance.toFixed(2)}m 检测到障碍，执行减速避障`;
    }
    if (this.getCenterOffset() > this.shelfTolerance) {
      return `${point}左右货架距离不均衡，建议进行居中修正`;
    }
    return `${point}前方通道畅通，左右货架距离稳定`;
  }

  private getDerivedStatus(): ChannelStatus {
    if (this.suspiciousTrackingEnabled) {
      return ChannelStatus.Blocked;
    }
    if (this.guardRegionEnabled && this.movingTargetDetected) {
      return ChannelStatus.Blocked;
    }
    const occupancy = this.getOccupancyClass();
    if (occupancy === 'blocked') {
      return ChannelStatus.Blocked;
    }
    if (occupancy === 'long') {
      return ChannelStatus.Occupied;
    }
    if (occupancy === 'short') {
      return ChannelStatus.SlowDown;
    }
    return this.getCenterOffset() > this.shelfTolerance ? ChannelStatus.SlowDown : ChannelStatus.Clear;
  }

  private simulateScenario(front: number, left: number, right: number, duration: number, movingTarget: boolean,
    suspiciousTarget: boolean = false): void {
    this.frontDistance = front;
    this.leftDistance = left;
    this.rightDistance = right;
    this.obstacleDurationSec = duration;
    this.movingTargetDetected = movingTarget;
    this.suspiciousTrackingEnabled = suspiciousTarget;
    this.suspiciousTrackSec = suspiciousTarget ? Math.max(this.suspiciousTrackSec + 3, duration) : 0;
    this.suspiciousTargetDistance = suspiciousTarget ? front : 0;
    const nextTrackingEnabled = suspiciousTarget ? true : this.trackingEnabled;
    const nextAvoidanceEnabled = suspiciousTarget ? true : this.avoidanceEnabled;
    const nextAvoidanceStatus: 'idle' | 'scanning' | 'avoiding' | 'tracking' =
      suspiciousTarget ? 'tracking' : this.avoidanceStatus;
    const now = new Date();
    const snapshot: LidarSnapshot = {
      point: this.point === '-' ? 'B区通道' : this.point,
      frontDistance: front,
      leftDistance: left,
      rightDistance: right,
      channelStatus: this.getDerivedStatus(),
      message: this.getActionText(),
      updateTime: `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}:${now.getSeconds().toString().padStart(2, '0')}`,
      avoidanceEnabled: nextAvoidanceEnabled,
      trackingEnabled: nextTrackingEnabled,
      avoidanceStatus: nextAvoidanceStatus,
      targetDistance: this.suspiciousTargetDistance
    };
    PatrolStore.getInstance().updateLidar(snapshot);
  }

  private async toggleAvoidance(enabled: boolean): Promise<void> {
    console.info('Module3Lidar', `toggleAvoidance called, enabled=${enabled}, current avoidanceEnabled=${this.avoidanceEnabled}`);
    const ok = await PatrolCommandUtils.enableLidarAvoidance(enabled);
    console.info('Module3Lidar', `toggleAvoidance result: ok=${ok}`);
    if (ok) {
      this.avoidanceEnabled = enabled;
      this.avoidanceStatus = enabled ? 'scanning' : 'idle';
      PatrolStore.getInstance().setLidarAvoidanceEnabled(enabled);
      promptAction.showToast({ message: enabled ? '雷达避障已开启' : '雷达避障已关闭' });
      PatrolCommandUtils.speakVoice(enabled ? '雷达避障已开启' : '雷达避障已关闭');
      console.info('Module3Lidar', `toggleAvoidance success, status updated to ${this.avoidanceStatus}`);
    } else {
      promptAction.showToast({ message: '命令发送失败，请检查连接' });
      console.error('Module3Lidar', 'toggleAvoidance failed, TCP connection may be disconnected');
    }
  }

  private async toggleTracking(enabled: boolean): Promise<void> {
    console.info('Module3Lidar', `toggleTracking called, enabled=${enabled}, current trackingEnabled=${this.trackingEnabled}, avoidanceEnabled=${this.avoidanceEnabled}`);
    if (enabled && !this.avoidanceEnabled) {
      promptAction.showToast({ message: '请先开启雷达避障' });
      console.warn('Module3Lidar', 'toggleTracking blocked: avoidance not enabled');
      return;
    }
    const ok = await PatrolCommandUtils.enableLidarTracking(enabled);
    console.info('Module3Lidar', `toggleTracking result: ok=${ok}`);
    if (ok) {
      this.trackingEnabled = enabled;
      if (enabled) {
        this.avoidanceStatus = 'tracking';
      } else if (!this.avoidanceEnabled) {
        this.avoidanceStatus = 'idle';
      }
      PatrolStore.getInstance().setLidarTrackingEnabled(enabled);
      promptAction.showToast({ message: enabled ? '目标跟踪已开启' : '目标跟踪已关闭' });
      PatrolCommandUtils.speakVoice(enabled ? '目标跟踪已开启' : '目标跟踪已关闭');
      console.info('Module3Lidar', `toggleTracking success, status updated to ${this.avoidanceStatus}`);
    } else {
      promptAction.showToast({ message: '命令发送失败，请检查连接' });
      console.error('Module3Lidar', 'toggleTracking failed, TCP connection may be disconnected');
    }
  }

  private getAvoidanceStatusText(): string {
    switch (this.avoidanceStatus) {
      case 'scanning':
        return '扫描中';
      case 'avoiding':
        return '避障中';
      case 'tracking':
        return '跟踪中';
      default:
        return '空闲';
    }
  }

  private getAvoidanceStatusColor(): ResourceColor {
    switch (this.avoidanceStatus) {
      case 'scanning':
        return $r('app.color.alert_warning');
      case 'avoiding':
        return $r('app.color.alert_critical');
      case 'tracking':
        return $r('app.color.module3_accent');
      default:
        return $r('app.color.text_secondary');
    }
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column({ space: '0vp' }) {
        ModuleTabBar({
          currentIndex: $currentTabIndex,
          tabs: this.tabs,
          accentColor: $r('app.color.module3_accent'),
          title: '仓库通道安全检测',
          subtitle: '激光雷达占用检测、货架居中、动态避障与固定告警'
        })

        Scroll() {
          Column({ space: '12vp' }) {
            if (this.currentTabIndex === 1) {
              this.RosbridgeCard()
            }
            if (this.currentTabIndex === 0) {
              this.DetectView()
            } else if (this.currentTabIndex === 1) {
              this.AvoidanceControlView()
            } else {
              this.AlertView()
            }
          }
          .width('100%')
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.window_background'))

      if (this.showStrategyDialog) {
        this.StrategyDialog()
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  RosbridgeCard() {
    Column({ space: '10vp' }) {
      InfoCard({ title: 'ROS 连接' }) {
        Column({ space: '8vp' }) {
          Text(this.rosbridgeStatusText)
            .fontSize('13fp')
            .fontColor(this.rosbridgeConnected ? $r('app.color.status_success') : $r('app.color.alert_warning'))
            .fontWeight(FontWeight.Medium)
            .maxLines(2)
          Row({ space: '8vp' }) {
            Text(this.getPatrolDataBadgeText())
              .fontSize('11fp')
              .fontColor(Color.White)
              .backgroundColor(this.rosbridgeConnected ? $r('app.color.status_success') : $r('app.color.module3_accent'))
              .padding({ left: '8vp', right: '8vp', top: '4vp', bottom: '4vp' })
              .borderRadius('8vp')
            Text(this.patrolReplayText)
              .layoutWeight(1)
              .fontSize('11fp')
              .fontColor($r('app.color.text_secondary'))
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          Row({ space: '8vp' }) {
            TextInput({ text: this.rosbridgeHost, placeholder: 'Jetson IP' })
              .layoutWeight(1)
              .height('36vp')
              .fontSize('12fp')
              .onChange((value: string): void => {
                this.rosbridgeHost = value;
              })
            TextInput({ text: this.rosbridgePort, placeholder: '9090' })
              .width('86vp')
              .height('36vp')
              .fontSize('12fp')
              .onChange((value: string): void => {
                this.rosbridgePort = value;
              })
          }
          Row({ space: '8vp' }) {
            Button(this.rosbridgeBusy ? '连接中...' : (this.rosbridgeConnected ? '重新保存' : '保存连接'))
              .layoutWeight(1)
              .height('36vp')
              .fontSize('12fp')
              .fontColor($r('app.color.text_on_accent'))
              .backgroundColor($r('app.color.button_primary'))
              .borderRadius('18vp')
              .enabled(!this.rosbridgeBusy)
              .onClick((): void => {
                this.connectRosbridge();
              })
            Button(this.rosbridgeConnected ? '连接已就绪' : '等待连接')
              .layoutWeight(1)
              .height('36vp')
              .fontSize('12fp')
              .fontColor($r('app.color.text'))
              .backgroundColor($r('app.color.card_elevated'))
              .borderRadius('18vp')
              .enabled(false)
          }
          Row({ space: '8vp' }) {
            Button(this.patrolReplayEnabled ? '暂停巡检数据' : '启动巡检数据')
              .layoutWeight(1)
              .height('34vp')
              .fontSize('12fp')
              .fontColor($r('app.color.text'))
              .backgroundColor($r('app.color.card_elevated'))
              .borderRadius('17vp')
              .border({ width: '1vp', color: $r('app.color.divider') })
              .onClick((): void => {
                if (this.patrolReplayEnabled) {
                  this.togglePatrolReplay();
                } else {
                  this.startPatrolReplay();
                }
              })
            Button('刷新当前点位')
              .layoutWeight(1)
              .height('34vp')
              .fontSize('12fp')
              .fontColor($r('app.color.text_on_accent'))
              .backgroundColor($r('app.color.module3_accent'))
              .borderRadius('17vp')
              .enabled(!this.rosbridgeConnected && this.patrolReplayEnabled)
              .onClick((): void => {
                this.applyPatrolReplayFrame();
              })
          }
          Text(`控制指令在下方真实控制区统一下发，当前 ROS 减速阈值 ${this.rosFrontWarnM.toFixed(2)}m`)
            .fontSize('11fp')
            .fontColor($r('app.color.text_secondary'))
        }
      }
    }
    .width('100%')
    .padding({ left: '14vp', right: '14vp', top: '10vp', bottom: '0vp' })
  }
  @Builder
  DetectView() {
    Column({ space: '10vp' }) {
      InfoCard({ title: '通道检测概览' }) {
        Column({ space: '10vp' }) {
          Row({ space: '8vp' }) {
            Column({ space: '4vp' }) {
              Text('检测点位')
                .fontSize('12fp')
                .fontColor($r('app.color.text_secondary'))
              Text(this.point)
                .fontSize('15fp')
                .fontColor($r('app.color.text'))
                .fontWeight(FontWeight.Medium)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)

            Text(channelStatusText(this.getDerivedStatus()))
              .fontSize('11fp')
              .fontColor(Color.White)
              .backgroundColor(channelStatusColor(this.getDerivedStatus()))
              .padding({ left: '8vp', right: '8vp', top: '5vp', bottom: '5vp' })
              .borderRadius('8vp')
          }
          .width('100%')

          Row({ space: '8vp' }) {
            MetricCard({ title: '检测类型', value: this.getScenarioTitle(), desc: this.getActionText() })
            MetricCard({ title: '更新时间', value: this.updateTime, desc: this.message })
          }
          .width('100%')
        }
      }

      Row({ space: '10vp' }) {
        DistanceCard({ title: '前方扇区', distance: this.frontDistance, threshold: this.slowDownThreshold, icon: '前' })
        DistanceCard({ title: '左侧货架', distance: this.leftDistance, threshold: this.shelfIdealDistance, icon: '左' })
        DistanceCard({ title: '右侧货架', distance: this.rightDistance, threshold: this.shelfIdealDistance, icon: '右' })
      }

      InfoCard({ title: '通道占用分类' }) {
        Column({ space: '8vp' }) {
          StatusItem({
            label: '短时障碍',
            desc: '人员经过或临时货物经过，前方小于减速阈值但持续时间较短',
            active: this.getOccupancyClass() === 'short'
          })
          StatusItem({
            label: '长时障碍',
            desc: '持续超过阈值的占用事件，固定触发通道占用告警',
            active: this.getOccupancyClass() === 'long'
          })
          StatusItem({
            label: '通道堵塞',
            desc: '前方距离进入停车阈值，车辆必须停车等待',
            active: this.getOccupancyClass() === 'blocked'
          })
          StatusItem({
            label: '货架居中',
            desc: this.getShelfBiasText(),
            active: this.getCenterOffset() <= this.shelfTolerance
          })
        }
      }

      InfoCard({ title: '策略配置' }) {
        Row({ space: '8vp' }) {
          Column({ space: '4vp' }) {
            Text('固定阈值策略')
              .fontSize('14fp')
              .fontColor($r('app.color.text'))
              .fontWeight(FontWeight.Medium)
            Text('点击查看各项检测配置，告警会按固定规则自动触发。')
              .fontSize('12fp')
              .fontColor($r('app.color.text_secondary'))
              .maxLines(2)
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)

          Button('查看配置')
            .height('32vp')
            .fontSize('11fp')
            .fontColor($r('app.color.text'))
            .backgroundColor($r('app.color.card_elevated'))
            .borderRadius('16vp')
            .onClick((): void => {
              this.showStrategyDialog = true;
            })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
      }
    }
    .width('100%')
    .padding({ left: '14vp', right: '14vp', top: '10vp', bottom: '12vp' })
  }

  @Builder
  AvoidanceControlView() {
    Column({ space: '12vp' }) {
      InfoCard({ title: '避障系统状态' }) {
        Column({ space: '10vp' }) {
          Row({ space: '12vp' }) {
            Column({ space: '4vp' }) {
              Text('避障状态')
                .fontSize('12fp')
                .fontColor($r('app.color.text_secondary'))
              Text(this.getAvoidanceStatusText())
                .fontSize('18fp')
                .fontColor(this.getAvoidanceStatusColor())
                .fontWeight(FontWeight.Bold)
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)

            Column({ space: '4vp' }) {
              Text('前方距离')
                .fontSize('12fp')
                .fontColor($r('app.color.text_secondary'))
              Text(`${this.frontDistance.toFixed(2)}m`)
                .fontSize('18fp')
                .fontColor(this.frontDistance < this.stopThreshold ? $r('app.color.alert_critical') : $r('app.color.text'))
                .fontWeight(FontWeight.Bold)
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.End)
          }

          Row({ space: '8vp' }) {
            Text('数据来源')
              .fontSize('12fp')
              .fontColor($r('app.color.text_secondary'))
            Text(this.rosbridgeConnected ? 'ROS 实车数据' : '巡检实时数据')
              .layoutWeight(1)
              .fontSize('13fp')
              .fontColor(this.rosbridgeConnected ? $r('app.color.status_success') : $r('app.color.module3_accent'))
              .fontWeight(FontWeight.Medium)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Text(this.patrolStepLabel)
              .layoutWeight(2)
              .fontSize('12fp')
              .fontColor($r('app.color.text_secondary'))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width('100%')
          .padding('8vp')
          .backgroundColor($r('app.color.card_elevated'))
          .borderRadius('10vp')

          Row({ space: '8vp' }) {
            Text('跟踪场景')
              .fontSize('12fp')
              .fontColor($r('app.color.text_secondary'))
            Text(this.suspiciousTrackingEnabled ? '可疑人员持续跟踪中' : '未发现可疑人员')
              .layoutWeight(1)
              .fontSize('13fp')
              .fontColor(this.suspiciousTrackingEnabled ? $r('app.color.alert_critical') : $r('app.color.text'))
              .fontWeight(FontWeight.Medium)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Text(this.suspiciousTrackingEnabled ? `${this.suspiciousTrackSec}s / ${this.suspiciousTargetDistance.toFixed(2)}m` : '等待触发')
              .fontSize('12fp')
              .fontColor($r('app.color.text_secondary'))
          }
          .width('100%')
          .padding('8vp')
          .backgroundColor(this.suspiciousTrackingEnabled ? '#FFF1F0' : $r('app.color.card_elevated'))
          .borderRadius('10vp')

          Row({ space: '12vp' }) {
            Column({ space: '4vp' }) {
              Text('左侧距离')
                .fontSize('12fp')
                .fontColor($r('app.color.text_secondary'))
              Text(`${this.leftDistance.toFixed(2)}m`)
                .fontSize('14fp')
                .fontColor($r('app.color.text'))
                .fontWeight(FontWeight.Medium)
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)

            Column({ space: '4vp' }) {
              Text('右侧距离')
                .fontSize('12fp')
                .fontColor($r('app.color.text_secondary'))
              Text(`${this.rightDistance.toFixed(2)}m`)
                .fontSize('14fp')
                .fontColor($r('app.color.text'))
                .fontWeight(FontWeight.Medium)
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.End)
          }
        }
      }

      InfoCard({ title: '真实控制' }) {
        Column({ space: '12vp' }) {
          Row({ space: '12vp' }) {
            Column({ space: '6vp' }) {
              Button(this.avoidanceEnabled ? '关闭避障' : '开启避障')
                .width('140vp')
                .height('44vp')
                .fontSize('15fp')
                .fontColor($r('app.color.text_on_accent'))
                .backgroundColor(this.avoidanceEnabled ? $r('app.color.alert_critical') : $r('app.color.module3_accent'))
                .borderRadius('22vp')
                .shadow(ButtonShadow)
                .onClick((): void => {
                  if (this.avoidanceEnabled) {
                    this.stopPatrolReplay();
                    this.patrolReplayEnabled = false;
                    this.patrolReplayText = '雷达避障已关闭，巡检实时数据暂停';
                    this.patrolStepLabel = '等待重新启动巡检';
                  } else {
                    this.startPatrolReplay();
                  }
                  this.toggleAvoidance(!this.avoidanceEnabled);
                })

              Text(this.avoidanceEnabled ? '雷达持续扫描障碍物，自动减速或停车' : '点击开启雷达自动避障功能')
                .fontSize('12fp')
                .fontColor($r('app.color.text_secondary'))
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Center)

            Column({ space: '6vp' }) {
              Button(this.trackingEnabled ? '关闭跟踪' : '开启跟踪')
                .width('140vp')
                .height('44vp')
                .fontSize('15fp')
                .fontColor($r('app.color.text_on_accent'))
                .backgroundColor(this.trackingEnabled ? $r('app.color.alert_warning') : $r('app.color.button_primary'))
                .borderRadius('22vp')
                .shadow(ButtonShadow)
                .enabled(this.avoidanceEnabled)
                .onClick((): void => {
                  this.toggleTracking(!this.trackingEnabled);
                })

              Text(this.trackingEnabled ? '持续跟踪目标并保持安全距离' : '需先开启避障，自动跟踪移动目标')
                .fontSize('12fp')
                .fontColor($r('app.color.text_secondary'))
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Center)
          }

          Row({ space: '8vp' }) {
            Button('启动自动通道避障')
              .layoutWeight(1)
              .height('38vp')
              .fontSize('12fp')
              .fontColor($r('app.color.text_on_accent'))
              .backgroundColor($r('app.color.module3_accent'))
              .borderRadius('19vp')
              .onClick((): void => {
                this.sendRosCommand('start_auto');
                PatrolCommandUtils.speakVoice('自动通道避障已启动');
              })
            Button('停止自动避障')
              .layoutWeight(1)
              .height('38vp')
              .fontSize('12fp')
              .fontColor($r('app.color.text_on_accent'))
              .backgroundColor($r('app.color.alert_critical'))
              .borderRadius('19vp')
              .onClick((): void => {
                this.sendRosCommand('stop_auto');
                PatrolCommandUtils.speakVoice('自动通道避障已停止');
              })
          }

          Row({ space: '8vp' }) {
            Button(this.rosNarrowMode ? '恢复正常速度' : '狭窄通道低速')
              .layoutWeight(1)
              .height('38vp')
              .fontSize('12fp')
              .fontColor($r('app.color.text'))
              .backgroundColor($r('app.color.card_elevated'))
              .borderRadius('19vp')
              .border({ width: '1vp', color: $r('app.color.divider') })
              .onClick((): void => {
                this.sendRosCommand(this.rosNarrowMode ? 'normal_mode' : 'narrow_mode');
                PatrolCommandUtils.speakVoice(this.rosNarrowMode ? '已恢复正常速度' : '已进入狭窄通道低速模式');
              })
            Button(`下发减速阈值 ${this.rosFrontWarnM.toFixed(1)}m`)
              .layoutWeight(1)
              .height('38vp')
              .fontSize('12fp')
              .fontColor($r('app.color.text'))
              .backgroundColor($r('app.color.card_elevated'))
              .borderRadius('19vp')
              .border({ width: '1vp', color: $r('app.color.divider') })
              .onClick((): void => {
                this.sendRosCommand(`set_front:${this.rosFrontWarnM}`);
                PatrolCommandUtils.speakVoice(`减速阈值已设置为${this.rosFrontWarnM.toFixed(1)}米`);
              })
          }
        }
      }

      InfoCard({ title: '通道安全阈值' }) {
        Column({ space: '10vp' }) {
          ThresholdSlider({ title: '前方减速阈值', unit: 'm', value: $slowDownThreshold, min: 0.3, max: 1.5, step: 0.05 })
          ThresholdSlider({ title: '前方停车阈值', unit: 'm', value: $stopThreshold, min: 0.2, max: 1.0, step: 0.05 })
          ThresholdSlider({ title: '占用告警时长', unit: 's', value: $alertDurationSec, min: 2, max: 15, step: 1 })

          Row({ space: '10vp' }) {
            Text('警戒区域检测')
              .layoutWeight(1)
              .fontSize('14fp')
              .fontColor($r('app.color.text'))
            Toggle({ type: ToggleType.Switch, isOn: this.guardRegionEnabled })
              .onChange((value: boolean): void => {
                this.guardRegionEnabled = value;
              })
          }
          .width('100%')
        }
      }

      InfoCard({ title: '检测规则' }) {
        Column({ space: '8vp' }) {
          StatusItem({
            label: '前方扇区',
            desc: '前方小于减速阈值时进入动态避障，小于停车阈值时判定为通道堵塞',
            active: this.avoidanceEnabled
          })
          StatusItem({
            label: '左右货架距离',
            desc: '对比左侧与右侧平均距离，判断小车是否偏离通道中心',
            active: this.avoidanceEnabled && this.frontDistance <= this.slowDownThreshold
          })
          StatusItem({
            label: '占用分类',
            desc: '短时障碍按人员经过处理，持续超过阈值按货物堆放或通道占用告警处理',
            active: this.avoidanceEnabled && this.frontDistance <= this.stopThreshold
          })
          StatusItem({
            label: '警戒区域',
            desc: '危险品区域或禁入区检测到移动目标时，直接生成雷达安全告警',
            active: this.trackingEnabled || this.suspiciousTrackingEnabled
          })
          StatusItem({
            label: '可疑人员持续跟踪',
            desc: '可疑人员进入警戒区后，APP保持跟踪态并持续显示目标距离、跟踪时长和告警状态',
            active: this.suspiciousTrackingEnabled
          })
        }
      }

      InfoCard({ title: '场景预设' }) {
        Column({ space: '10vp' }) {
          Text('场景按钮会生成雷达快照；非正常状态会同步到告警模块。')
            .fontSize('12fp')
            .fontColor($r('app.color.text_secondary'))
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Row({ space: '8vp' }) {
            ActionChip({ label: '前方0.7m减速', accent: $r('app.color.alert_warning'), onTap: (): void => {
              this.simulateScenario(0.70, 0.60, 0.62, 3, false);
              PatrolCommandUtils.speakVoice('前方减速，请慢行');
            } })
            ActionChip({ label: '前方0.3m停车', accent: $r('app.color.alert_critical'), onTap: (): void => {
              this.simulateScenario(0.30, 0.58, 0.61, 5, false);
              PatrolCommandUtils.speakVoice('前方停车，检测到障碍物');
            } })
          }
          Row({ space: '8vp' }) {
            ActionChip({ label: '左侧靠近', accent: $r('app.color.module3_accent'), onTap: (): void => {
              this.simulateScenario(1.20, 0.35, 0.65, 2, false);
              PatrolCommandUtils.speakVoice('左侧货架距离偏近');
            } })
            ActionChip({ label: '右侧靠近', accent: $r('app.color.module3_accent'), onTap: (): void => {
              this.simulateScenario(1.20, 0.65, 0.35, 2, false);
              PatrolCommandUtils.speakVoice('右侧货架距离偏近');
            } })
          }
          Row({ space: '8vp' }) {
            ActionChip({ label: '货物堆放5秒', accent: $r('app.color.alert_critical'), onTap: (): void => {
              this.simulateScenario(0.42, 0.58, 0.60, 6, false);
              PatrolCommandUtils.speakVoice('检测到货物堆放异常');
            } })
            ActionChip({ label: '禁区移动目标', accent: $r('app.color.alert_warning'), onTap: (): void => {
              this.simulateScenario(1.20, 0.60, 0.58, 1, true);
              PatrolCommandUtils.speakVoice('警戒区域检测到移动目标');
            } })
          }
          Row({ space: '8vp' }) {
            ActionChip({ label: '可疑人员跟踪', accent: $r('app.color.alert_critical'), onTap: (): void => {
              this.simulateScenario(1.05, 0.64, 0.55, 3, true, true);
              PatrolCommandUtils.speakVoice('检测到可疑人员，开始跟踪');
            } })
            ActionChip({ label: '目标离开恢复', accent: $r('app.color.status_success'), onTap: (): void => {
              this.simulateScenario(1.40, 0.60, 0.60, 0, false, false);
              PatrolCommandUtils.speakVoice('目标已离开，恢复正常通行');
            } })
          }
        }
      }
    }
    .width('100%')
    .padding({ left: '14vp', right: '14vp', top: '10vp', bottom: '12vp' })
  }

  @Builder
  AlertView() {
    Column({ space: '10vp' }) {
      InfoCard({ title: '固定告警规则' }) {
        Column({ space: '8vp' }) {
          StrategyRow({ title: '减速触发', desc: `前方距离小于 ${this.slowDownThreshold.toFixed(2)}m 时减速通行。` })
          StrategyRow({ title: '停车触发', desc: `前方距离小于 ${this.stopThreshold.toFixed(2)}m 时立即停车。` })
          StrategyRow({ title: '占用触发', desc: `障碍持续超过 ${this.alertDurationSec.toFixed(0)}s 时固定判定为通道占用。` })
          StrategyRow({ title: '警戒区触发', desc: this.guardRegionEnabled ? '警戒区检测到移动目标时固定触发告警。' : '警戒区检测已关闭。' })
        }
      }

      InfoCard({ title: '雷达告警记录' }) {
        Column() {
          ModuleAlertList({
            category: ALERT_CATEGORY_LIDAR,
            emptyHint: '暂无通道占用告警'
          })
            .width('100%')
            .height('340vp')
        }
      }
    }
    .width('100%')
    .padding({ left: '14vp', right: '14vp', top: '10vp', bottom: '12vp' })
  }

  @Builder
  StrategyDialog() {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#00000055')
        .onClick((): void => {
          this.showStrategyDialog = false;
        })

      Column({ space: '12vp' }) {
        Row({ space: '8vp' }) {
          Text('策略配置')
            .layoutWeight(1)
            .fontSize('18fp')
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text'))
          Button('关闭')
            .height('30vp')
            .fontSize('11fp')
            .fontColor($r('app.color.text'))
            .backgroundColor($r('app.color.card_elevated'))
            .borderRadius('15vp')
            .onClick((): void => {
              this.showStrategyDialog = false;
            })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        Scroll() {
          Column({ space: '10vp' }) {
            InfoBlock({
              title: '检测区域定义',
              desc: `前方扇区在 ${this.slowDownThreshold.toFixed(2)}m 内减速、${this.stopThreshold.toFixed(2)}m 内停车；左右货架距离用于居中修正。`
            })

            ThresholdSlider({ title: '前方减速阈值', unit: 'm', value: $slowDownThreshold, min: 0.3, max: 1.5, step: 0.05 })
            ThresholdSlider({ title: '前方停车阈值', unit: 'm', value: $stopThreshold, min: 0.2, max: 1.0, step: 0.05 })
            ThresholdSlider({ title: '占用判定时长', unit: 's', value: $alertDurationSec, min: 2, max: 15, step: 1 })
            ThresholdSlider({ title: '货架理想距离', unit: 'm', value: $shelfIdealDistance, min: 0.3, max: 1.2, step: 0.05 })
            ThresholdSlider({ title: '居中容差', unit: 'm', value: $shelfTolerance, min: 0.05, max: 0.4, step: 0.01 })

            Row({ space: '10vp' }) {
              Text('警戒区域检测')
                .layoutWeight(1)
                .fontSize('14fp')
                .fontColor($r('app.color.text'))
              Toggle({ type: ToggleType.Switch, isOn: this.guardRegionEnabled })
                .onChange((value: boolean): void => {
                  this.guardRegionEnabled = value;
                })
            }
            .width('100%')

            Row({ space: '10vp' }) {
              Text('模拟移动目标')
                .layoutWeight(1)
                .fontSize('14fp')
                .fontColor($r('app.color.text'))
              Toggle({ type: ToggleType.Switch, isOn: this.movingTargetDetected })
                .onChange((value: boolean): void => {
                  this.movingTargetDetected = value;
                })
            }
            .width('100%')

            InfoBlock({
              title: '固定告警规则',
              desc: '前方进入停车阈值、障碍持续超过占用时长、或警戒区检测到移动目标时，都会固定触发雷达告警并同步到统一告警中心。'
            })
          }
          .width('100%')
        }
        .width('100%')
        .constraintSize({ minHeight: '220vp', maxHeight: '420vp' })
        .scrollBar(BarState.Off)
      }
      .width('90%')
      .constraintSize({ maxWidth: '520vp', maxHeight: '82%' })
      .padding('16vp')
      .backgroundColor($r('app.color.card_background'))
      .borderRadius('18vp')
      .border({ width: '1vp', color: $r('app.color.divider') })
      .shadow(ElevatedShadow)
    }
    .width('100%')
    .height('100%')
  }
}

@Component
struct DistanceCard {
  @Prop title: string = '';
  @Prop distance: number = 0;
  @Prop threshold: number = 1;
  @Prop icon: string = '';

  build() {
    Column({ space: '6vp' }) {
      Text(this.icon)
        .fontSize('16fp')
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.module3_accent'))
      Text(this.title)
        .fontSize('12fp')
        .fontColor($r('app.color.text_secondary'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      Text(`${this.distance.toFixed(2)} m`)
        .fontSize('19fp')
        .fontWeight(FontWeight.Bold)
        .fontColor(this.distance < this.threshold ? $r('app.color.alert_critical') : $r('app.color.text'))
        .maxLines(1)
      Text(`阈值 ${this.threshold.toFixed(2)}m`)
        .fontSize('11fp')
        .fontColor($r('app.color.text_secondary'))
        .maxLines(1)
    }
    .layoutWeight(1)
    .padding('11vp')
    .backgroundColor($r('app.color.card_background'))
    .borderRadius('12vp')
    .border({ width: '1vp', color: $r('app.color.divider') })
    .shadow(CardShadow)
    .alignItems(HorizontalAlign.Center)
  }
}

@Component
struct MetricCard {
  @Prop title: string = '';
  @Prop value: string = '';
  @Prop desc: string = '';

  build() {
    Column({ space: '6vp' }) {
      Text(this.title)
        .fontSize('12fp')
        .fontColor($r('app.color.text_secondary'))
        .width('100%')
      Text(this.value)
        .fontSize('15fp')
        .fontColor($r('app.color.text'))
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      Text(this.desc)
        .fontSize('12fp')
        .fontColor($r('app.color.text_secondary'))
        .width('100%')
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .layoutWeight(1)
    .padding('10vp')
    .backgroundColor($r('app.color.card_elevated'))
    .borderRadius('10vp')
    .alignItems(HorizontalAlign.Start)
  }
}

@Component
struct StatusItem {
  @Prop label: string = '';
  @Prop desc: string = '';
  @Prop active: boolean = false;

  build() {
    Row({ space: '10vp' }) {
      Column()
        .width('10vp')
        .height('10vp')
        .backgroundColor(this.active ? $r('app.color.module3_accent') : $r('app.color.divider'))
        .borderRadius('5vp')
      Column({ space: '4vp' }) {
        Text(this.label)
          .fontSize('14fp')
          .fontColor($r('app.color.text'))
          .fontWeight(FontWeight.Medium)
          .width('100%')
        Text(this.desc)
          .fontSize('12fp')
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding('8vp')
    .backgroundColor(this.active ? $r('app.color.card_elevated') : $r('app.color.card_background'))
    .borderRadius('10vp')
  }
}

@Component
struct StrategyRow {
  @Prop title: string = '';
  @Prop desc: string = '';

  build() {
    Column({ space: '4vp' }) {
      Text(this.title)
        .fontSize('13fp')
        .fontColor($r('app.color.text'))
        .fontWeight(FontWeight.Medium)
        .width('100%')
      Text(this.desc)
        .fontSize('12fp')
        .fontColor($r('app.color.text_secondary'))
        .lineHeight('18fp')
        .width('100%')
    }
    .width('100%')
  }
}

@Component
struct InfoBlock {
  @Prop title: string = '';
  @Prop desc: string = '';

  build() {
    Column({ space: '6vp' }) {
      Text(this.title)
        .fontSize('13fp')
        .fontColor($r('app.color.text'))
        .fontWeight(FontWeight.Medium)
        .width('100%')
      Text(this.desc)
        .fontSize('12fp')
        .fontColor($r('app.color.text_secondary'))
        .lineHeight('18fp')
        .width('100%')
    }
    .width('100%')
    .padding('10vp')
    .backgroundColor($r('app.color.card_elevated'))
    .borderRadius('10vp')
  }
}

@Component
struct ActionChip {
  @Prop label: string = '';
  @Prop accent: ResourceColor = $r('app.color.module3_accent');
  onTap: () => void = (): void => {};

  build() {
    Button(this.label)
      .layoutWeight(1)
      .height('34vp')
      .fontSize('12fp')
      .fontColor($r('app.color.text_on_accent'))
      .backgroundColor(this.accent)
      .borderRadius('17vp')
      .onClick((): void => {
        this.onTap();
      })
  }
}

@Component
struct ThresholdSlider {
  @Prop title: string = '';
  @Prop unit: string = '';
  @Link value: number;
  @Prop min: number = 0;
  @Prop max: number = 1;
  @Prop step: number = 0.1;

  build() {
    Column({ space: '8vp' }) {
      Row({ space: '8vp' }) {
        Text(this.title)
          .layoutWeight(1)
          .fontSize('13fp')
          .fontColor($r('app.color.text'))
        Text(`${this.value.toFixed(this.step >= 1 ? 0 : 2)} ${this.unit}`)
          .fontSize('12fp')
          .fontColor($r('app.color.module3_accent'))
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')
      Slider({
        value: this.value,
        min: this.min,
        max: this.max,
        step: this.step,
        style: SliderStyle.InSet
      })
        .blockColor($r('app.color.module3_accent'))
        .trackColor($r('app.color.track_background'))
        .selectedColor($r('app.color.module3_accent'))
        .onChange((val: number) => {
          this.value = val;
        })
    }
    .width('100%')
  }
}
