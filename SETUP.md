# oh-ai-car-ros-app 使用说明

本项目是一个基于 **HarmonyOS / ArkTS / ArkUI** 的智能小车控制 App，用于通过网络连接小车端服务，并通过按钮、摇杆等组件发送控制指令。

## 环境要求

推荐使用以下环境：

| 项目 | 推荐配置 |
|---|---|
| IDE | DevEco Studio 6.x |
| SDK | HarmonyOS / OpenHarmony SDK API 21 |
| 运行目标 | HarmonyOS |
| 推荐模拟器 | Mate 70 Pro |
| 模拟器版本 | HarmonyOS 6.0.1(21) |
| Node.js | 使用 DevEco Studio 自带 Node |

## 项目结构

```text
oh-ai-car-ros-app
├── AppScope/                  # 应用全局配置
├── entry/                     # 主应用模块
│   └── src/main/ets/           # ArkTS 页面、组件、工具类
├── Rocker/                    # 摇杆组件模块
├── build-profile.json5        # 项目级构建配置
├── hvigorfile.ts              # Hvigor 构建入口
├── oh-package.json5           # 项目依赖配置
├── oh-package-lock.json5      # 依赖锁定文件
└── README.md
```

主要源码位置：

```text
entry/src/main/ets/
Rocker/src/main/ets/
```

## 本地配置

项目根目录需要配置 `local.properties`。
示例：

```properties
sdk.dir=D:/OpenHarmony/SDK
nodejs.dir=D:/Program Files/DevEco Studio/tools/node
```

说明：

- `sdk.dir` 改成自己电脑上的 SDK 路径。
- `nodejs.dir` 建议使用 DevEco Studio 自带 Node。
- 路径建议使用 `/`，避免转义问题。

## 构建配置

根目录 `build-profile.json5` 中，推荐使用以下配置（已改好，无需修改）：

```json5
{
  "app": {
    "signingConfigs": [],
    "products": [
      {
        "name": "default",
        "compileSdkVersion": "6.0.1(21)",
        "compatibleSdkVersion": "6.0.1(21)",
        "targetSdkVersion": "6.0.1(21)",
        "runtimeOS": "HarmonyOS"
      }
    ]
  },
  "modules": [
    {
      "name": "entry",
      "srcPath": "./entry",
      "targets": [
        {
          "name": "default",
          "applyToProducts": [
            "default"
          ]
        }
      ]
    },
    {
      "name": "Rocker",
      "srcPath": "./Rocker"
    }
  ]
}
```

`entry/build-profile.json5` 中确认目标为 HarmonyOS：

```json5
{
  "apiType": "stageMode",
  "buildOption": {},
  "targets": [
    {
      "name": "default",
      "runtimeOS": "HarmonyOS"
    },
    {
      "name": "ohosTest"
    }
  ]
}
```

`Rocker/build-profile.json5` 中也需要保持：

```json5
"runtimeOS": "HarmonyOS"
```

## SysCap 配置

项目需要在以下位置保留 `syscap.json`（已改好）：

```text
entry/src/main/syscap.json
```

推荐内容：

```json5
{
  "devices": {
    "general": [
      "phone"
    ],
    "custom": []
  },
  "development": {
    "addedSysCaps": [],
    "removedSysCaps": [
      "SystemCapability.Communication.Bluetooth.Core",
      "SystemCapability.HiviewDFX.HiDumper",
      "SystemCapability.DistributedHardware.DeviceManager",
      "SystemCapability.Multimedia.Drm.Core",
      "SystemCapability.Advertising.Ads",
      "SystemCapability.Security.DeviceAuth",
      "SystemCapability.Customization.EnterpriseDeviceManager"
    ]
  }
}
```

该配置用于移除项目当前未使用的系统能力，避免模拟器启动时报 SysCap 不匹配错误。

## 运行步骤

1. 使用 DevEco Studio 打开项目根目录 `oh-ai-car-ros-app`。
2. 检查并修改 `local.properties` 中的 SDK 和 Node 路径。
3. 确认 DevEco Studio 已安装 API 21 相关 SDK。
4. 启动 `Mate 70 Pro HarmonyOS 6.0.1(21)` 模拟器。
5. 点击 `Sync Now` 同步项目。
6. 执行：

```text
Build -> Clean Project
```

7. 执行：

```text
Build -> Build Hap(s)/APP(s) -> Build Hap(s)
```

8. 顶部设备选择 `Mate 70 Pro`。
9. 点击绿色运行按钮 `Run`。

## 打包 HAP

执行：

```text
Build -> Build Hap(s)/APP(s) -> Build Hap(s)
```

构建成功后，HAP 产物一般位于：

```text
entry/build/default/outputs/default/
```

或：

```text
entry/build/outputs/hap/
```

具体路径以 DevEco Studio 的 Build 输出为准。

## 小车连接说明

App 启动后会进入连接界面，默认连接参数类似：

```text
IP: 192.168.1.11
Port: 6000
W/eo: 6500
```

需要根据实际小车服务端配置修改 IP 和端口。

注意：

- 模拟器能启动 App，不代表一定能连接真实小车。
- 小车端服务需要提前启动。
- 电脑/模拟器所在网络需要能访问小车 IP。
- 如果连接失败，优先检查 IP、端口、防火墙和小车服务状态。

## 快速启动流程

```text
1. 克隆项目
2. 用 DevEco Studio 打开项目根目录
3. 配置 local.properties
4. 启动 Mate 70 Pro HarmonyOS 6.0.1(21) 模拟器
5. Sync Now
6. Clean Project
7. Build Hap(s)
8. Run
```
