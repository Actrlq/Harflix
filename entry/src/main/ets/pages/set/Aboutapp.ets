import { AppUtil } from "@pura/harmony-utils"
import { BasicConstants } from "../../viewmodel/BasicConstants"
import { common } from "@kit.AbilityKit"
import { BusinessError } from '@kit.BasicServicesKit'

@Entry
@Component
struct Aboutapp {
  Gitee() {
    let context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext
    let webUrl: string = "https://gitee.com/Actrlq/harflix"

    try {
      context.openLink(webUrl)
        .catch((err: BusinessError) => {
          console.error(`跳转失败，错误码: ${err.code}, 错误信息: ${err.message}`);
        });
    } catch (paramError) {
      console.error(`调用openLink失败，错误码: ${paramError.code}, 错误信息: ${paramError.message}`);
    }
  }

  Github() {
    let context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext
    let webUrl: string = "https://github.com/Actrlq/Harflix"

    try {
      context.openLink(webUrl)
        .catch((err: BusinessError) => {
          console.error(`跳转失败，错误码: ${err.code}, 错误信息: ${err.message}`);
        });
    } catch (paramError) {
      console.error(`调用openLink失败，错误码: ${paramError.code}, 错误信息: ${paramError.message}`);
    }
  }

  build() {
    Column() {
      Column() {
        Image($r('app.media.app_logo'))
          .width('100%')
          .margin({ bottom: 10 })
        Text($r('app.string.app_name'))
          .fontSize(BasicConstants.FONT_BIG)
          .margin({ bottom: 5 })
        Text(`V ${AppUtil.getVersionName()}`)
          .fontSize(BasicConstants.FONT_NORMAL)
      }
      .height('50%')
      .padding(150)

      Column() {
        Row() {
          Text('Github仓库地址')
            .fontSize(BasicConstants.FONT_NORMAL)
          Image($r('app.media.fanhuijiantou'))
            .height('50%')
            .rotate({ angle: 180 })
            .margin({ right: 20 })
        }
        .width('100%')
        .height(50)
        .justifyContent(FlexAlign.SpaceBetween)
        .alignItems(VerticalAlign.Center)
        .onClick(() => {
          this.Github()
        })

        Row() {
          Text('Gitee仓库地址')
            .fontSize(BasicConstants.FONT_NORMAL)
          Image($r('app.media.fanhuijiantou'))
            .height('50%')
            .rotate({ angle: 180 })
            .margin({ right: 20 })
        }
        .width('100%')
        .height(50)
        .justifyContent(FlexAlign.SpaceBetween)
        .alignItems(VerticalAlign.Center)
        .onClick(() => {
          this.Gitee()
        })

      }
      .width('100%')
      .backgroundColor(Color.White)
      .borderRadius(10)
      .padding(10)
    }
    .width('100%')
    .height('100%')
    .padding({ left: 10, right: 10 })
    .backgroundColor($r('app.color.theme_background_1'))

  }
}