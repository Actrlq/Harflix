import { EmbyList } from "../view/EmbyList"
import { BasicConstants } from "../viewmodel/BasicConstants"
import { MediaLibrary } from '../view/MediaLibrary'
import { SetUp } from "../view/SetUp"

@Entry
@Component
struct Index {
  @Provide pageInfo: NavPathStack = new NavPathStack()
  @State currentIndex: number = 0

  aboutToAppear(): void {
    this.currentIndex = 0
  }

  @Builder
  TabList(name: string, index: number, image: Resource) {
    Column() {
      Image(image)
        .height("50%")
      Text(name)
        .height("50%")
        .fontSize(BasicConstants.FONT_SMALL)
        .fontColor(this.currentIndex === index ? Color.Blue : Color.Black)
        .fontWeight(this.currentIndex === index ? FontWeight.Bold : FontWeight.Normal)
    }
    .height("100%")
    .justifyContent(FlexAlign.Center)
    .padding({ top: 5 })
  }

  build() {
    Navigation(this.pageInfo) {
      Column() {
        Tabs({ barPosition: BarPosition.End }) {
          //媒体库
          TabContent() {
            MediaLibrary()
          }.tabBar(this.TabList('媒体库', 0, $r('app.media.meitiku')))

          //添加服务器
          TabContent() {
            EmbyList()
          }.tabBar(this.TabList('服务器', 1, $r("app.media.tianjia")))

          //设置
          TabContent() {
            Column() {
              SetUp()
            }
          }.tabBar(this.TabList('设置', 2, $r("app.media.shezhi")))
        }
        .barWidth(400)
        .onChange((index: number) => {
          this.currentIndex = index
        })
        .scrollable(false)
        .margin({ bottom: 15 })
      }
      .backgroundColor($r('sys.color.background_secondary'))
    }
    .hideTitleBar(true)
    .hideToolBar(true)
    .mode(NavigationMode.Stack)
  }
}