import { ObjectUtil } from '@pura/harmony-utils'
import { FetchImagePrimary, FetchServerUrl } from '../apis/AuxiliaryApi'
import { FetchSeasonApi, FetchSeasonListApi } from '../apis/ProductApi'
import { BasicConstants } from '../viewmodel/BasicConstants'
import { SeasonListModel, SLItems, ViewingRecord, VRItems } from '../viewmodel/DataConstraints'

@Component
export struct SeasonList {
  @State SeasonNumber: Array<SLItems> = []
  @State SeasonData: Array<VRItems> = []
  @Prop videoIndex: string
  @Link videoId: string
  @State onChoose: number = 1
  @State @Watch('onSeasonIdChanged') SeasonId: string = ''
  @State serverUrl: string = ''

  aboutToAppear(): void {
    this.fetchSeason().then(() => {
      this.fetchSeasonList()
    })
    this.fetchServerUrl()
  }

  fetchSeason = async () => {
    const res = await FetchSeasonApi<SeasonListModel>(this.videoIndex)
    this.SeasonNumber = res.Items
  }
  fetchSeasonList = async () => {
    this.SeasonData = []
    const res = await FetchSeasonListApi<ViewingRecord>(this.videoIndex, this.SeasonId)
    this.SeasonData = res.Items
    this.onChoose = this.SeasonData[0].ParentIndexNumber
  }
  fetchServerUrl = async () => {
    const res = await FetchServerUrl()
    this.serverUrl = res
  }

  onSeasonIdChanged() {
    this.fetchSeasonList()
  }

  build() {
    Column() {
      if (this.SeasonNumber.length > 0) {
        Flex({ direction: FlexDirection.Column }) {
          Scroll() {
            Row() {
              ForEach(this.SeasonNumber, (item: SLItems) => {
                Text(`第 ${item.IndexNumber} 季`)
                  .fontSize(BasicConstants.FONT_NORMAL)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Color.White)
                  .margin({ right: 10 })
                  .padding({ bottom: 5 })
                  .borderColor(Color.White)
                  .borderWidth({ bottom: this.onChoose == item.IndexNumber ? 2 : 0 })
                  .onClick(() => {
                    this.onChoose = item.IndexNumber
                    this.SeasonId = item.Id
                  })
              }, (item: SLItems) => item.IndexNumber?.toString())
            }
            .margin({ bottom: 5 })
          }
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off)

          List({ space: 5 }) {
            ForEach(this.SeasonData.filter((item: VRItems) => item.ParentIndexNumber === this.onChoose),
              (item: VRItems) => {
                ListItem() {
                  Flex({ direction: FlexDirection.Column }) {

                    Stack() {
                      Column() {
                        Image(this.serverUrl + FetchImagePrimary(item.Id) + '?maxWidth=400')
                          .borderRadius(10)
                          .clip(true)
                          .alt($r('app.media.Image_loading_failed'))
                          .width('100%')
                      }
                      .onClick(() => {
                        this.videoId = item.Id
                      })
                      .layoutWeight(1)

                      Column() {
                        Image($r('app.media.right'))
                          .height(25)
                          .visibility(ObjectUtil.getValue<boolean>(item.UserData, 'Played') ? Visibility.Visible :
                            Visibility.None)
                      }
                      .justifyContent(FlexAlign.Center)
                      .alignItems(HorizontalAlign.Center)

                    }

                    Column() {
                      Text(`${item.IndexNumber}. ${item.Name}`)
                        .fontSize(BasicConstants.FONT_SMALL)
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                        .fontColor(Color.White)
                        .fontWeight(FontWeight.Bold)
                    }
                    .height(20)
                    .width('100%')
                  }
                  .width(180)
                  .height('100%')
                }
              }, (item: VRItems) => item.IndexNumber.toString())
          }
          .width('100%')
          .height('100%')
          .listDirection(Axis.Horizontal)
          .scrollBar(BarState.Off)
        }
        .width('100%')
        .height(140)
      }
    }
  }
}