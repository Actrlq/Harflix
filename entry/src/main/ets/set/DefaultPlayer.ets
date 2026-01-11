import { AppUtil, PreferencesUtil } from "@pura/harmony-utils"

@Component
struct DefaultPlayer {
  @State defaultPlayer: string = 'IJK'

  aboutToAppear(): void {
    this.defaultPlayer = PreferencesUtil.getStringSync('defaultPlayer', 'IJK')
  }

  build() {
    NavDestination() {
      Column() {
        Column() {
          Row() {
            Text('IJK播放引擎：')

            Toggle({ type: ToggleType.Switch, isOn: this.defaultPlayer === 'IJK' ? true : false })
              .selectedColor('rgba(0,85,255,1)')
              .margin({ right: 10 })
              .onChange((isOn) => {
                if (isOn) {
                  this.defaultPlayer = 'IJK'
                  PreferencesUtil.putSync('defaultPlayer', 'IJK')
                }else {
                  this.defaultPlayer = 'RED'
                  PreferencesUtil.putSync('defaultPlayer', 'RED')
                }
              })
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)

          Column(){
            Text('支持视频格式多，HDR视频颜色显示不正确')
              .fontSize($r('sys.float.Body_M'))
              .fontWeight(FontWeight.Regular)
              .fontColor($r('sys.color.font_tertiary'))
          }
          .margin({top :10,bottom:10})
        }
        .width('100%')
        .margin({ bottom: 10 })
        .alignItems(HorizontalAlign.Start)
        .padding(10)

        Column() {
          Row() {
            Text('RED播放引擎：')

            Toggle({ type: ToggleType.Switch, isOn: this.defaultPlayer === 'RED' ? true : false })
              .selectedColor('rgba(0,85,255,1)')
              .margin({ right: 10 })
              .onChange((isOn) => {
                if (isOn) {
                  this.defaultPlayer = 'RED'
                  PreferencesUtil.putSync('defaultPlayer', 'RED')
                }else {
                  this.defaultPlayer = 'IJK'
                  PreferencesUtil.putSync('defaultPlayer', 'IJK')
                }
              })
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)

          Column(){
            Text('支持视频格式少，HDR 杜比/DTS 视频播放正常')
              .fontSize($r('sys.float.Body_M'))
              .fontWeight(FontWeight.Regular)
              .fontColor($r('sys.color.font_tertiary'))
          }
          .margin({top :10,bottom:10})
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .padding(10)
      }
      .backgroundColor($r('sys.color.comp_background_list_card'))
      .borderRadius($r('sys.float.corner_radius_level8'))
      .margin(10)
    }
    .title('默认播放器')
    .padding({ top: px2vp(AppUtil.getStatusBarHeight()) })
    .backgroundColor($r('sys.color.background_secondary'))
  }
}

@Builder
export function DefaultPlayerBuilder() {
  DefaultPlayer()
}