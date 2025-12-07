import { BasicConstants } from "../viewmodel/BasicConstants"
import { ServerViews, SVItems, NewViewsList, VRItems, ViewingRecord } from "../viewmodel/DataConstraints"
import { FetchNewViewsListApi, FetchServerViewsApi, FetchViewingRecordApi } from "../apis/ProductApi"
import { router } from "@kit.ArkUI"
import { KvUtil, NetworkUtil, ToastUtil } from "@pura/harmony-utils"
import { FetchImageBackdrop, FetchImagePrimary, FetchServerUrl } from "../apis/AuxiliaryApi"
import { distributedKVStore } from "@kit.ArkData"
import { UserInfo } from "../viewmodel/DataConstraints"

@Component
export struct MediaLibrary {
  @State ViewList: Array<NewViewsList>[][] = []
  @State MediaList: Array<SVItems> = []
  @State ListId: string[] = []
  @State WatchList: Array<VRItems> = []
  @State serverUrl: string = ''
  //数据库监听
  private callBack: Callback<distributedKVStore.ChangeNotification> = (key) => {
    if (key.updateEntries[0]?.key === 'FirstLoad') {
      this.fetchServerViews().then(() => {
        this.AddonData()
      })
      this.fetchViewingRecord()
      this.fetchServerUrl()
      this.getServername()
      this.fetchKeydata()
    }
  }
  private embyList: UserInfo[] = []
  //弹窗状态
  @State isShow: boolean = false
  @State servername: string = ''

  @Builder
  ListUtils(name: string, index: number, id: string) {
    Flex({ direction: FlexDirection.Column }) {
      Flex({ justifyContent: FlexAlign.SpaceBetween }) {
        Text(name)
          .fontSize(BasicConstants.FONT_BIG)
          .fontWeight(FontWeight.Bold)
        Text('更多')
          .fontSize(BasicConstants.FONT_NORMAL)
          .onClick(() => {
            router.pushUrl({
              url: 'pages/EpisodeList',
              params: { Name: name, Id: id }
            }).catch()
          })
      }
      .height(25)

      List({ space: 5 }) {
        ForEach(this.ViewList[index], (item: NewViewsList) => {
          ListItem() {
            Flex({ direction: FlexDirection.Column }) {
              Column() {
                Image(this.serverUrl + FetchImagePrimary(item.Id) + '?maxWidth=400')
                  .alt($r('app.media.Image_loading_failed'))
              }
              .width('100%')
              .borderRadius(10)
              .clip(true)

              Column() {
                Text(item.Name)
                  .fontSize(BasicConstants.FONT_NORMAL)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .width('100%')
              .height(20)
            }
            .margin({ top: 5, bottom: 5 })

          }
          .height('100%')
          .width(120)
          .onClick(() => {
            router.pushUrl({
              url: 'pages/Details',
              params: { Id: item.Id, Type: item.Type }
            }).catch(() => {
            })
          })
        }, (item: NewViewsList) => item.Id)

      }
      .width('100%')
      .height('100%')
      .listDirection(Axis.Horizontal)
      .scrollBar(BarState.Off)

    }
    .width('100%')
    .height('100%')
  }

  @Builder
  dialogBuilder() {
    Column() {
      ForEach(this.embyList, (item: UserInfo) => {
        Column() {
          Text(item.servername ? item.servername : '无名称')
            .fontSize(BasicConstants.FONT_NORMAL)
        }
        .width('90%')
        .margin(5)
        .onClick(()=>{
          KvUtil.put('FirstLoad','emby_' + item.userId).then(()=>{
            this.fetchServerViews().then(() => {
              this.AddonData()
            })
            this.fetchViewingRecord()
            this.fetchServerUrl()
            this.getServername()
            this.isShow = false
          })
        })
      }, (item: UserInfo) => item.token)
    }
    .padding(5)
  }

  aboutToAppear(): void {
    if (NetworkUtil.isNetworkAvailable()) {
      this.fetchServerViews().then(() => {
        this.AddonData()
      })
      this.fetchViewingRecord()
      this.fetchServerUrl()
      this.fetchKeydata()
      this.getServername()
    } else {
      ToastUtil.showToast('网络不可用')
    }
    KvUtil.onDataChange(distributedKVStore.SubscribeType.SUBSCRIBE_TYPE_ALL, this.callBack)
  }

  aboutToDisappear(): void {
    KvUtil.offDataChange(this.callBack)
  }

  fetchServerViews = async () => {
    this.MediaList = []
    this.ListId = []
    const res = await FetchServerViewsApi<ServerViews>()
    this.MediaList = res.Items
    this.ListId = res.Items.filter(items => items.Name !== '播放列表').map((item: SVItems) => item.Id)
  }
  fetchNewViewsList = async (id: string) => {
    const res = await FetchNewViewsListApi<Array<NewViewsList>[]>(id)
    this.ViewList.push(res)
  }
  AddonData = async () => {
    this.ViewList = []
    for (const item of this.ListId) {
      await this.fetchNewViewsList(item)
    }
  }
  fetchViewingRecord = async () => {
    this.WatchList = []
    const res = await FetchViewingRecordApi<ViewingRecord>()
    this.WatchList = res.Items
  }
  fetchServerUrl = async () => {
    this.serverUrl = ''
    const res = await FetchServerUrl()
    this.serverUrl = res
  }
  fetchKeydata = () => {
    this.embyList = []
    const keyPrefix = "emby"
    KvUtil.getEntries(keyPrefix).then((res) => {
      res.forEach((entry: distributedKVStore.Entry) => {
        this.embyList.push(JSON.parse(entry.value.value as string))
      })
    })
  }
  getServername = async () => {
    const key = await KvUtil.get('FirstLoad') as string
    const res = await KvUtil.get(key)
    const UserInfo: UserInfo = JSON.parse(res as string)
    this.servername = UserInfo.servername
  }

  build() {

    Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center }) {
      Scroll() {
        Column() {
          //顶部状态栏
          Row() {
            Column() {
              Image($r('app.media.emby'))
                .height('80%')
            }
            .width('25%')
            .alignItems(HorizontalAlign.Start)
            .onClick(() => {
              this.isShow = true
            })
            .bindPopup(this.isShow, {
              builder: this.dialogBuilder(),
              width: 150,
              enableArrow: false,
              placement: Placement.BottomLeft,
              radius: 10,
              onStateChange: (e) => {
                if (!e.isVisible) {
                  this.isShow = false
                }
              }
            })

            Column() {
              Text(this.servername ? this.servername : 'Harflix')
                .fontSize(BasicConstants.FONT_NORMAL)
                .fontSize(BasicConstants.FONT_BIG)
            }
            .width('50%')
            .justifyContent(FlexAlign.Center)

            Column() {
              Image($r('app.media.sousuo'))
                .height('60%')
            }
            .width('15%')
            .onClick(() => {
              router.pushUrl({
                url: 'pages/SearchPage'
              }).catch(() => {
              })
            })

            Column() {
              Image($r('app.media.shuaxin'))
                .height('50%')
            }
            .width('10%')
            .onClick(async () => {
              if (NetworkUtil.isNetworkAvailable()) {
                this.fetchServerViews().then(() => {
                  this.AddonData()
                })
                this.fetchViewingRecord()
                this.fetchServerUrl()
                this.getServername()
                this.fetchKeydata()
              } else {
                ToastUtil.showToast('网络不可用')
              }
            })

          }
          .width('100%')
          .height(50)
          .padding({ left: 10, right: 10 })
          .margin({ top: 40 })

          //主页内容
          Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center }) {

            //继续观看
            Flex({ direction: FlexDirection.Column }) {
              if (this.WatchList.length > 0) {
                Text('继续观看')
                  .fontSize(BasicConstants.FONT_BIG)
                  .height(25)
                  .fontWeight(FontWeight.Bold)
                List({ space: 5 }) {
                  ForEach(this.WatchList, (item: VRItems) => {
                    ListItem() {
                      Flex({ direction: FlexDirection.Column }) {
                        Column() {
                          Image(this.serverUrl + FetchImageBackdrop(item.SeriesId))
                            .alt($r('app.media.Image_loading_failed'))
                        }
                        .width('100%')
                        .borderRadius(10)
                        .clip(true)
                        .onClick(() => {
                          router.pushUrl({
                            url: 'pages/Details',
                            params: { Id: item.SeriesId, Type: item.Type }
                          }).catch(() => {
                          })
                        })

                        Column() {
                          Text(`${item.SeriesName}: S${item.ParentIndexNumber}E${item.IndexNumber}`)
                            .fontSize(BasicConstants.FONT_NORMAL)
                        }
                        .width('100%')
                        .justifyContent(FlexAlign.Center)
                      }
                    }
                    .height('100%')
                    .width(240)
                  }, (item: VRItems) => item.Id)

                }
                .width('100%')
                .height(150)
                .listDirection(Axis.Horizontal)
                .scrollBar(BarState.Off)
              }
            }
            .width('100%')

            //媒体库列表
            Flex({ direction: FlexDirection.Column }) {
              if (this.MediaList.length > 0) {
                Text('媒体库')
                  .fontSize(BasicConstants.FONT_BIG)
                  .height(25)
                  .fontWeight(FontWeight.Bold)
                List({ space: 5 }) {
                  ForEach(this.MediaList.filter(items => items.Name !== '播放列表'), (item: SVItems) => {
                    ListItem() {
                      Flex({ direction: FlexDirection.Column }) {
                        Flex({ justifyContent: FlexAlign.Center }) {
                          Image(this.serverUrl + FetchImagePrimary(item.Id) + '?maxWidth=400')
                            .alt($r('app.media.Image_loading_failed'))
                        }
                        .width('100%')
                        .borderRadius(10)
                        .clip(true)

                        Flex({ justifyContent: FlexAlign.Center }) {
                          Text(item.Name)
                            .fontSize(BasicConstants.FONT_NORMAL)
                        }
                        .width('100%')
                      }
                    }
                    .height('100%')
                    .width(150)
                    .onClick(() => {
                      router.pushUrl({
                        url: 'pages/EpisodeList',
                        params: { Name: item.Name, Id: item.Id }
                      }).catch()
                    })
                  }, (item: SVItems) => item.Guid)

                }
                .width('100%')
                .height('100%')
                .listDirection(Axis.Horizontal)
                .scrollBar(BarState.Off)
              }

            }
            .width('100%')
            .height(130)
            .margin({ top: 10 })

            //媒体库
            Flex({ direction: FlexDirection.Column }) {
              ForEach(this.MediaList.filter(items => items.Name !== '播放列表'), (item: SVItems, index: number) => {
                Column() {
                  this.ListUtils(item.Name, index, item.Id)
                }
                .width('100%')
                .height(230)
              }, (item: SVItems) => item.Guid)

            }
            .width('100%')
            .margin({ top: 10 })

          }
          .width('100%')
        }
      }
      .scrollBar(BarState.Off)

    }
    .width('100%')
    .height('100%')

  }
}

