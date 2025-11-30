import { MediaSources } from '../viewmodel/DataConstraints'
import { VideoInfo } from './InfoFilter'
import { BasicConstants } from '../viewmodel/BasicConstants'

@CustomDialog
export struct VideoDialog {
  @Prop data: Array<MediaSources> = []
  @Link videoIndex: number
  @Prop videoInfo: VideoInfo[] = []
  controller?: CustomDialogController

  build() {
    Scroll() {
      Column() {
        ForEach(this.data, (item: MediaSources, index: number) => {
          Flex({ direction: FlexDirection.Column }) {
            Column() {
              Text(item.Name)
                .fontSize(BasicConstants.FONT_BIG)
            }

            Row() {
              Column() {
                Text(this.videoInfo[0].displayTitle)
                  .fontSize(BasicConstants.FONT_SMALL)
              }
              .Format()

              Column() {
                Text(this.videoInfo[0].videoRange)
                  .fontSize(BasicConstants.FONT_SMALL)
              }
              .Format()
            }

            Row() {
              Column() {
                Text(`${this.videoInfo[0].averageFramerate.toFixed(2)}FPS`)
                  .fontSize(BasicConstants.FONT_SMALL)
              }
              .Format()

              Column() {
                Text(`${this.videoInfo[0].bitrate.toFixed(2)}Mbps`)
                  .fontSize(BasicConstants.FONT_SMALL)
              }
              .Format()

              Column() {
                Text(this.FrameConversion(item.Size))
                  .fontSize(BasicConstants.FONT_SMALL)
              }
              .Format()

              Column() {
                Text(this.TimeConversion(this.data[this.videoIndex].RunTimeTicks))
                  .fontSize(BasicConstants.FONT_SMALL)
              }
              .Format()
            }
            .margin({ top: 5 })
          }
          .width('100%')
          .margin({ bottom: 5 })
          .borderRadius(5)
          .backgroundColor(Color.White)
          .onClick(() => {
            this.videoIndex = index
            this.controller?.close()
          })
        }, (item: MediaSources) => item.Id)
      }
      .padding({ left: 5, right: 5, top: 5 })
    }
    .scrollBar(BarState.Off)
  }

  private FrameConversion(bytes: number) {
    if (bytes > 1047527424) {
      const value = bytes / Math.pow(1024, 3)
      return value.toFixed(2) + 'GB'
    } else {
      const value = bytes / Math.pow(1024, 2)
      return value.toFixed(2) + 'MB'
    }
  }

  private TimeConversion(ms: number) {
    const totalSeconds = Math.floor(ms / 10000000);
    if (totalSeconds >= 3600) {
      const hours = Math.floor(totalSeconds / 3600)
      const minutes = Math.floor((totalSeconds % 3600) / 60);
      const seconds = totalSeconds % 60;

      // 补零处理（如5秒→05秒）
      const paddedSeconds = seconds.toString().padStart(2, '0');
      return `${hours}时${minutes}分${paddedSeconds}秒`;
    } else {
      const minutes = Math.floor(totalSeconds / 60);
      const seconds = totalSeconds % 60;

      // 补零处理（如5秒→05秒）
      const paddedSeconds = seconds.toString().padStart(2, '0');
      return `${minutes}分${paddedSeconds}秒`;
    }

  }
}

@Styles
function Format() {
  .margin({ right: 10 })
  .border({ width: 1 })
  .borderRadius(5)
  .padding(2)
}