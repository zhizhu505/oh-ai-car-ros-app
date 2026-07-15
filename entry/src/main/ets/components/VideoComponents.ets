import web_webview from '@ohos.web.webview'
import promptAction from '@ohos.promptAction';
import { carApi } from '../CarUtill/CarApi';
import { CarEncode } from '../CarUtill/CarEncode';
import { ButtonShadow } from '../styles/styles';
import { DEFAULT_CAR_IP, DEFAULT_VIDEO_PORT, PreferencesUtils } from '../utils/PreferencesUtils';
import preferences from '@ohos.data.preferences';

let TAG = "VideoComponents"

@Component
export struct VideoComponents {
  controller: web_webview.WebviewController = new web_webview.WebviewController()
  public static port: number = Number.parseInt(DEFAULT_VIDEO_PORT);
  public static ip: string = DEFAULT_CAR_IP
  @Prop previewWidth: Length = '300vp';
  @Prop previewHeight: Length = '200vp';
  @Prop showActions: boolean = true;
  @State isRecording: boolean = false
  @State videoSrc: string = ''
  @State useRawStream: boolean = true
  @State reloadKey: number = 0
  @State reloadBlank: boolean = false
  @State actionText: string = '保存目录 ~/Rosmaster-App/rosmaster/capture/'

  aboutToAppear(): void {
    this.refreshVideoConfig();
  }

  build() {
    Column({ space: '10vp' }) {
      RelativeContainer() {
        Web({
          src: this.reloadBlank ? 'about:blank' : (this.videoSrc.length > 0 ? this.videoSrc : this.getWebSrc()),
          controller: this.controller
        })
          .id("Video")
          .width('100%')
          .height('100%')
          .javaScriptAccess(true)
          .domStorageAccess(true)
          .imageAccess(true)
          .onlineImageAccess(true)

        Button('刷新')
          .id("RefreshVideo")
          .height('28vp')
          .fontSize('11fp')
          .fontColor(Color.White)
          .backgroundColor('rgba(15, 23, 42, 0.72)')
          .borderRadius('14vp')
          .zIndex(3)
          .alignRules({
            top: { anchor: "__container__", align: VerticalAlign.Top },
            right: { anchor: "__container__", align: HorizontalAlign.End }
          })
          .offset({
            x: -8,
            y: 8
          })
          .onClick((): void => {
            this.forceReloadVideo();
          })

        Row({ space: '6vp' }) {
          Button(this.useRawStream ? '网页' : '视频流')
            .height('28vp')
            .fontSize('11fp')
            .fontColor(Color.White)
            .backgroundColor('rgba(15, 23, 42, 0.72)')
            .borderRadius('14vp')
            .onClick((): void => {
              this.useRawStream = !this.useRawStream;
              this.forceReloadVideo();
            })
        }
        .id("SwitchVideoMode")
        .zIndex(3)
        .alignRules({
          top: { anchor: "__container__", align: VerticalAlign.Top },
          left: { anchor: "__container__", align: HorizontalAlign.Start }
        })
        .offset({
          x: 8,
          y: 8
        })

        Text(this.useRawStream ? '直接视频流' : '小车网页')
          .id("VideoModeText")
          .fontSize('10fp')
          .fontColor(Color.White)
          .backgroundColor('rgba(15, 23, 42, 0.58)')
          .borderRadius('10vp')
          .padding({ left: '8vp', right: '8vp', top: '3vp', bottom: '3vp' })
          .zIndex(3)
          .alignRules({
            bottom: { anchor: "__container__", align: VerticalAlign.Bottom },
            left: { anchor: "__container__", align: HorizontalAlign.Start }
          })
          .offset({
            x: 8,
            y: -8
          })

        Text(`视频源 ${VideoComponents.ip}:${VideoComponents.port}`)
          .id("VideoSourceText")
          .fontSize('10fp')
          .fontColor(Color.White)
          .backgroundColor('rgba(15, 23, 42, 0.58)')
          .borderRadius('10vp')
          .padding({ left: '8vp', right: '8vp', top: '3vp', bottom: '3vp' })
          .zIndex(3)
          .alignRules({
            bottom: { anchor: "__container__", align: VerticalAlign.Bottom },
            right: { anchor: "__container__", align: HorizontalAlign.End }
          })
          .offset({
            x: -8,
            y: -8
          })

        if (this.isRecording) {
          RedRound()
            .id("RedRound")
            .zIndex(2)
            .alignRules({
              bottom: { anchor: "__container__", align: VerticalAlign.Bottom },
              right: { anchor: "__container__", align: HorizontalAlign.End }
            }).offset({
            x: -24,
            y: -24
          })
        }
      }
      .width(this.previewWidth)
      .height(this.previewHeight)
      .backgroundColor(Color.White)
      .clip(true)

      if (this.showActions) {
        Row({ space: '10vp' }) {
          if (!this.isRecording) {
            Button("拍摄")
              .backgroundColor($r('app.color.button_background'))
              .shadow(ButtonShadow)
              .onClick(() => {
                this.takePhoto();
              })
          }

          Button(this.isRecording ? "结束" : "录制")
            .backgroundColor($r('app.color.button_background'))
            .shadow(ButtonShadow)
            .onClick(() => {
              this.toggleRecording();
            })
        }
        .justifyContent(FlexAlign.Center)

        Text(this.actionText)
          .fontSize('10fp')
          .fontColor('#CBD5E1')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('92%')
          .textAlign(TextAlign.Center)
      }
    }
    .width('100%')
    .height(this.showActions ? '282vp' : this.previewHeight)
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Start)
  }

  getWebSrc() {
    let v = this.useRawStream ? this.getWrappedStreamSrc() : this.getIndexSrc()
    console.log(TAG, "getWebSrc()", v)
    return v
  }

  private getStreamSrc(): string {
    return `http://${VideoComponents.ip}:${VideoComponents.port}/video_feed?ts=${this.reloadKey}`
  }

  private getIndexSrc(): string {
    return `http://${VideoComponents.ip}:${VideoComponents.port}/index2?ts=${this.reloadKey}`
  }

  private getWrappedStreamSrc(): string {
    let streamUrl = this.getStreamSrc();
    let html = `<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
  <style>
    html, body {
      margin: 0;
      padding: 0;
      width: 100%;
      height: 100%;
      overflow: hidden;
      background: #000;
    }
    img {
      width: 100vw;
      height: 100vh;
      object-fit: contain;
      display: block;
      background: #000;
    }
  </style>
</head>
<body>
  <img src="${streamUrl}" alt="video stream">
</body>
</html>`;
    return `data:text/html;charset=utf-8,${encodeURIComponent(html)}`
  }

  private refreshVideoConfig(): void {
    const netUtils = PreferencesUtils.getInstance().netUtils;
    if (!netUtils) {
      this.reloadKey = Date.now();
      this.videoSrc = this.getWebSrc();
      return;
    }

    Promise.all([netUtils.getIP(), netUtils.getVideoPort()]).then((values: preferences.ValueType[]): void => {
      VideoComponents.ip = String(values[0]).trim();
      VideoComponents.port = Number.parseInt(String(values[1]).trim());
      this.reloadKey = Date.now();
      this.videoSrc = this.getWebSrc();
    })
  }

  private forceReloadVideo(): void {
    this.actionText = '正在重新连接视频流...';
    this.reloadBlank = true;
    try {
      this.controller.loadUrl('about:blank');
    } catch (e) {
      console.error(TAG, 'load blank failed', JSON.stringify(e));
    }

    const netUtils = PreferencesUtils.getInstance().netUtils;
    const applyReload = (): void => {
      this.reloadKey = Date.now();
      this.videoSrc = this.getWebSrc();
      this.reloadBlank = false;
      setTimeout((): void => {
        try {
          this.controller.loadUrl(this.videoSrc);
        } catch (e) {
          console.error(TAG, 'load video failed', JSON.stringify(e));
        }
      }, 120);
      this.actionText = '视频流已重新连接';
      promptAction.showToast({ message: '视频流已刷新' });
    };

    if (!netUtils) {
      setTimeout(applyReload, 180);
      return;
    }

    Promise.all([netUtils.getIP(), netUtils.getVideoPort()]).then((values: preferences.ValueType[]): void => {
      VideoComponents.ip = String(values[0]).trim();
      VideoComponents.port = Number.parseInt(String(values[1]).trim());
      setTimeout(applyReload, 180);
    }).catch((e: Error): void => {
      console.error(TAG, 'reload config failed', JSON.stringify(e));
      setTimeout(applyReload, 180);
    })
  }

  private async takePhoto(): Promise<void> {
    const ok = await carApi.send(CarEncode.TakePhotosEncode());
    if (ok) {
      this.actionText = '已发送拍摄命令，保存到 ~/Rosmaster-App/rosmaster/capture/';
      promptAction.showToast({ message: '已拍摄，文件保存在 capture 目录' });
    } else {
      this.actionText = '拍摄命令发送失败，请检查 TCP 连接';
      promptAction.showToast({ message: '拍摄失败：未连接小车' });
    }
  }

  private async toggleRecording(): Promise<void> {
    if (this.isRecording) {
      const ok = await carApi.send(CarEncode.CloselRecordingEncode());
      if (ok) {
        this.isRecording = false;
        this.actionText = '录制已结束，视频保存在 ~/Rosmaster-App/rosmaster/capture/';
        promptAction.showToast({ message: '录制已结束' });
      } else {
        this.actionText = '结束录制命令发送失败，请检查 TCP 连接';
        promptAction.showToast({ message: '结束录制失败' });
      }
      return;
    }

    const ok = await carApi.send(CarEncode.StartRecordingEncode());
    if (ok) {
      this.isRecording = true;
      this.actionText = '正在录制，结束后保存到 ~/Rosmaster-App/rosmaster/capture/';
      promptAction.showToast({ message: '开始录制' });
    } else {
      this.actionText = '开始录制命令发送失败，请检查 TCP 连接';
      promptAction.showToast({ message: '开始录制失败' });
    }
  }
}

@Component
struct RedRound {
  @State isShow: boolean = true;

  aboutToAppear(): void {
    setInterval(() => {
      this.isShow = !this.isShow;
    }, 1000);
  }

  build() {
    Text()
      .width('10vp')
      .height('10vp')
      .backgroundColor(Color.Red)
      .animation({
        duration: 1200,
        curve: Curve.Friction,
        delay: 500,
        iterations: -1,
      })
      .border({
        radius: "5vp"
      })
      .visibility(this.isShow ? Visibility.Visible : Visibility.None)
  }
}
