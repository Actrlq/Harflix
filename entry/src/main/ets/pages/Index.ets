import { EmbyList } from "../view/EmbyList"
import { BasicConstants } from "../viewmodel/BasicConstants"
import { MediaLibrary } from '../view/MediaLibrary'
import { SetUp } from "../view/SetUp"
import { AppUtil } from "@pura/harmony-utils"

@Entry
@Component
struct Index {
  @Provide pageInfo: NavPathStack = new NavPathStack()
  @State currentIndex: number = 0

  aboutToAppear(): void {
    this.currentIndex = 0
  }

  @Builder
  TabList(name: string, index: number, image: Resource, image_fill: Resource) {
    Column() {
      SymbolGlyph(this.currentIndex === index ? image_fill : image)
        .fontSize(25)
      Text(name)
        .height("50%")
        .fontSize(BasicConstants.FONT_SMALL)
        .fontColor(this.currentIndex === index ? Color.Green : Color.Black)
        .fontWeight(this.currentIndex === index ? FontWeight.Bold : FontWeight.Normal)
    }
    .height("100%")
    .justifyContent(FlexAlign.Center)
    .padding({ top: 5, bottom:px2vp(AppUtil.getNavigationIndicatorHeight())})
  }

  build() {
    Navigation(this.pageInfo) {
      Column() {
        Tabs({ barPosition: BarPosition.End }) {
          //媒体库
          TabContent() {
            MediaLibrary()
          }
          .tabBar(this.TabList('媒体库', 0, $r("sys.symbol.house"), $r("sys.symbol.house_fill")))

          //添加服务器
          TabContent() {
            EmbyList()
          }
          .tabBar(this.TabList('服务器', 1, $r("sys.symbol.externaldrive_3"), $r("sys.symbol.externaldrive_fill_3")))

          //设置
          TabContent() {
            Column() {
              SetUp()
            }
          }
          .tabBar(this.TabList('设置', 2, $r("sys.symbol.gearshape"), $r("sys.symbol.gearshape_fill")))
        }
        .barWidth(400)
        .barHeight(65)
        .onChange((index: number) => {
          this.currentIndex = index
        })
        .scrollable(false)
        .barOverlap(true)
      }
      .backgroundColor($r('sys.color.background_secondary'))
    }
    .hideTitleBar(true)
    .hideToolBar(true)
  }
}