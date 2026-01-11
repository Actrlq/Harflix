import { FetchEpisodeListApi } from '../apis/ProductApi'
import { MyDataSource } from '../utils/MyDataSource'
import { BasicConstants } from '../viewmodel/BasicConstants'
import { NewViewsList, SVItems, ViewingRecord, VRItems } from '../viewmodel/DataConstraints'
import { FetchImagePrimary, FetchServerUrl } from '../apis/AuxiliaryApi'
import { LoadingView } from '../common/LoadingView'
import { AppUtil } from '@pura/harmony-utils'

@Component
struct EpisodeView{
  @State ViewList: MyDataSource<VRItems> = new MyDataSource()
  @State params: SVItems = new SVItems()
  @State serverUrl:string = ''
  @Consume pageInfo: NavPathStack
  @State isLoading: boolean = true

  aboutToAppear(): void {
    setTimeout(() => {
      this.isLoading = false
    }, 30000)
  }

  fetchEpisodeList = async () => {
    const res = await FetchEpisodeListApi<ViewingRecord>(this.params.Id)
    this.ViewList.pushAllData(res.Items)
  }
  fetchServerUrl = async () => {
    const res = await FetchServerUrl()
    this.serverUrl = res
  }

  build() {
    NavDestination(){
      Stack(){
        Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center }) {

          List() {
            LazyForEach(this.ViewList, (item: VRItems) => {
              ListItem() {
                Flex({ direction: FlexDirection.Column }) {
                  Column() {
                    Image(this.serverUrl + FetchImagePrimary(item.Id) + '?maxWidth=400')
                      .alt($r('app.media.Image_loading_failed'))
                  }
                  .width('100%')
                  .borderRadius(10)
                  .clip(true)
                  .onClick(() => {
                    this.pageInfo.pushPathByName('Details', { Id: item.Id, Type: item.Type } as NewViewsList)
                  })

                  Column() {
                    Text(item.Name)
                      .fontSize(BasicConstants.FONT_NORMAL)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                  }
                  .alignItems(HorizontalAlign.End)
                }
                .height(200)
                .margin(5)
              }
            }, (item: VRItems) => item.Id)
          }
          .width('100%')
          .height('100%')
          .listDirection(Axis.Vertical)
          .lanes(3)
          .padding({ left: 5, right: 5 })

        }
        .width('100%')
        .height('100%')
        .padding({ left: 5, right: 5 })

        if (this.isLoading) {
          LoadingView()
        }
      }

    }
    .title(this.params.Name)
    .onReady((context)=>{
      this.params = context.pathInfo.param as SVItems
      this.fetchServerUrl()
      this.fetchEpisodeList().then(()=>{
        setTimeout(() => {
          this.isLoading = false
        }, 1000)
      })
    })
    .padding({ top: px2vp(AppUtil.getStatusBarHeight()) })
    .backgroundColor($r('sys.color.background_secondary'))
  }
}

@Builder
export function EpisodeViewBuilder(){
  EpisodeView()
}