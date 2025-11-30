import { FetchEpisodeListApi } from '../apis/ProductApi'
import { MyDataSource } from '../utils/MyDataSource'
import { BasicConstants } from '../viewmodel/BasicConstants'
import { SVItems, ViewingRecord, VRItems } from '../viewmodel/DataConstraints'
import { router } from '@kit.ArkUI'
import { FetchImagePrimary, FetchServerUrl } from '../apis/AuxiliaryApi'

@Entry
@Component
struct EpisodeList {
  @State ViewList: MyDataSource<VRItems> = new MyDataSource()
  @State params: SVItems = router.getParams() as SVItems
  @State serverUrl:string = ''

  aboutToAppear(): void {
    this.fetchEpisodeList()
    this.fetchServerUrl()
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
    Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center }) {
      Row() {
        Column() {
          Image($r('app.media.fanhuijiantou'))
            .height('90%')
        }
        .width('10%')
        .onClick(() => {
          router.back()
        })

        Column() {
          Text(this.params.Name)
            .fontSize(BasicConstants.FONT_BIG)
        }
        .width('80%')
      }
      .width('100%')
      .height(40)
      .margin({ top: 40 })
      .padding({ left: 10, right: 10 })

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
                router.pushUrl({
                  url: 'pages/Details',
                  params: { Id: item.Id }
                }).catch(() => {
                })
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
  }
}