import AbilityConstant from '@ohos.app.ability.AbilityConstant';
import hilog from '@ohos.hilog';
import UIAbility from '@ohos.app.ability.UIAbility';
import Want from '@ohos.app.ability.Want';
import window from '@ohos.window';
import { ScreenUtils } from "../utils/ScreenUtils"
import { TCPClientManager } from '../tcp/TCPClientManager';
import { TCPClientSendUtils } from '../tcp/TCPClientSendUtils';
import { PreferencesUtils } from '../utils/PreferencesUtils';
import { PatrolStore } from '../store/PatrolStore';
import { AlertLevel } from '../model/PatrolModels';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onCreate');

    // 初始化首选项单例
    PreferencesUtils.getInstance().init(this.context)

    // 初始化测试告警数据，用于验证AI分析功能
    this.initTestAlerts();
  }

  private initTestAlerts(): void {
    const store = PatrolStore.getInstance();
    store.createAlert('17:05:32', 'B区P4货架', 'lidar_block', '雷达检测到通道堵塞，前方距离0.42m', AlertLevel.Critical);
    store.createAlert('17:08:15', 'A区P2通道', 'vision_person', '视觉检测到人员闯入禁区', AlertLevel.Warning);
    store.createAlert('17:12:48', 'C区P6仓库', 'env_temp', '环境温度异常，当前35.2°C', AlertLevel.Warning);
    store.createAlert('17:15:22', 'B区P3货架', 'lidar_near', '雷达检测到近距离障碍物', AlertLevel.Critical);
    store.createAlert('17:18:05', 'D区P1入口', 'vision_box', '视觉检测到通道有货箱堆积', AlertLevel.Warning);
  }

  onDestroy(): void {
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    // windowStage.loadContent('pages/NetworkSettings', (err) => {
    // windowStage.loadContent('pages/MecanumWheel', (err) => {
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(0x0000, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err) ?? '');
        return;
      }
      hilog.info(0x0000, 'testTag', 'Succeeded in loading the content.');
    });

    // 设置应用为竖屏
    ScreenUtils.setPortrait(this.context)
    // 设置屏幕常量
    ScreenUtils.keepScreenOn(this.context, true)
    // 设置标题栏不可见
    // ScreenUtils.setSystemBarEnable_api9(this.context)
    ScreenUtils.setSystemBarEnable_api10(windowStage)

  }


  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onBackground');
  }
}
