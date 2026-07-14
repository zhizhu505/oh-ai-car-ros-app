import web_webview from '@ohos.web.webview'
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

  aboutToAppear(): void {
    this.refreshVideoConfig();
  }

  build() {
    Column({ space: '10vp' }) {
      RelativeContainer() {
        Web({
          src: this.videoSrc.length > 0 ? this.videoSrc : this.getWebSrc(),
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
            this.refreshVideoConfig();
            setTimeout((): void => {
              this.controller.refresh();
            }, 100)
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
              this.videoSrc = this.getWebSrc();
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
                carApi.send(CarEncode.TakePhotosEncode());
              })
          }

          Button(this.isRecording ? "结束" : "录制")
            .backgroundColor($r('app.color.button_background'))
            .shadow(ButtonShadow)
            .onClick(() => {
              if (this.isRecording) {
                carApi.send(CarEncode.CloselRecordingEncode());
              } else {
                carApi.send(CarEncode.StartRecordingEncode());
              }
              this.isRecording = !this.isRecording;
            })
        }
        .justifyContent(FlexAlign.Center)
      }
    }
    .width('100%')
    .height(this.showActions ? '260vp' : this.previewHeight)
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Start)
  }

  getWebSrc() {
    let v = this.useRawStream ? this.getWrappedStreamSrc() : this.getIndexSrc()
    console.log(TAG, "getWebSrc()", v)
    return v
  }

  private getStreamSrc(): string {
    return `http://${VideoComponents.ip}:${VideoComponents.port}/video_feed?ts=${Date.now()}`
  }

  private getIndexSrc(): string {
    return `http://${VideoComponents.ip}:${VideoComponents.port}/index2?ts=${Date.now()}`
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
      this.videoSrc = this.getWebSrc();
      return;
    }

    Promise.all([netUtils.getIP(), netUtils.getVideoPort()]).then((values: preferences.ValueType[]): void => {
      VideoComponents.ip = String(values[0]).trim();
      VideoComponents.port = Number.parseInt(String(values[1]).trim());
      this.videoSrc = this.getWebSrc();
    })
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
