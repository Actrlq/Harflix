import { FetchDetailsApi, FetchPlaybackInfoApi, FetchUnWatchedApi } from '../apis/ProductApi'
import { BasicConstants } from '../viewmodel/BasicConstants'
import { DetailsModel, MediaSources, NewViewsList, PlaybackInfo, ViewingRecord } from '../viewmodel/DataConstraints'
import { VideoDialog } from '../utils/VideoDialog'
import router from '@ohos.router'
import { NetworkUtil, ToastUtil, DialogUtil } from '@pura/harmony-utils'
import { FetchImagePrimary, FetchServerUrl, FetchSubtitleApi } from '../apis/AuxiliaryApi'
import { SubtitleItem, SubtitleProcessor } from '../utils/SubtitleProcessor'
import { InfoFilter, SubtitleList, VideoInfo } from '../utils/InfoFilter'
import { SeasonList } from '../view/SeasonList'

@Entry
@Component
struct Details {
  private Id: NewViewsList = router.getParams() as NewViewsList
  @State PageData: Array<DetailsModel> = []
  @State data: Array<MediaSources> = []
  @State VideoUrl: string = ''
  @State videoIndex: number = 0
  @State @Watch('onVideoIdChanged') videoId: string = ''
  private subtitleProcessor: SubtitleProcessor = new SubtitleProcessor()
  private InfoFilter: InfoFilter = new InfoFilter()
  @State subtitles: SubtitleItem[] = []
  @State subtitleList: SubtitleList[] = []
  //首选字幕
  @State preferredSubtitle: string = ''
  //播放视频id
  @State mediaSourceId: string = ''
  //字幕index
  @State @Watch('onSubtitlesIdChanged') subtitlesId: number = 0
  @State subtitlesCodec: string = ''
  //视频信息
  @State videoInfo: VideoInfo[] = []
  @State serverUrl: string = ''
  private playSessionId: string = ''
  @State bgColor: string = '#f7f8fa'
  //弹窗组件
  dialogController: CustomDialogController | null = new CustomDialogController({
    builder: VideoDialog({ videoIndex: $videoIndex, data: this.data, videoInfo: this.videoInfo }),
    alignment: DialogAlignment.Bottom,
    cornerRadius: 15,
    offset: { dx: 0, dy: 0 },
    width: '95%',
    height: '40%',
  })

  aboutToAppear(): void {
    if (NetworkUtil.isNetworkAvailable()) {
      if (this.Id.Type === 'Movie') {
        this.videoId = this.Id.Id
        this.fetchDetails()
      } else {
        this.fetchDetails()
        this.fetchUnWatched()
        this.fetchPlaybackInfo()
      }
    } else {
      ToastUtil.showToast('网络不可以')
    }
    this.fetchServerUrl()
  }

  aboutToDisappear() {
    this.dialogController = null // 将dialogController置空
  }

  fetchDetails = async () => {
    const res = await FetchDetailsApi<DetailsModel>(this.Id.Id)
    this.PageData = [res]
  }
  fetchPlaybackInfo = async () => {
    if (!this.videoId) {
      return
    }
    const res = await FetchPlaybackInfoApi<PlaybackInfo>(this.videoId)
    this.data = res.MediaSources
    this.playSessionId = res.PlaySessionId
    this.subtitleList = this.InfoFilter.filterSubtitle(this.data[this.videoIndex].MediaStreams)
    this.videoInfo = this.InfoFilter.filterVideoInfo(this.data[this.videoIndex].MediaStreams)
    this.mediaSourceId = this.data[this.videoIndex].Id
    for (const text of this.subtitleList) {
      if (text.displayLanguage === 'Chinese Simplified') {
        this.preferredSubtitle = text.displayLanguage
        this.subtitlesCodec = text.codec
        this.subtitlesId = text.index
        break
      }
    }
    if (this.subtitlesId === 0) {
      this.preferredSubtitle = this.subtitleList[0].displayLanguage
      this.subtitlesCodec = this.subtitleList[0].codec
      this.subtitlesId = this.subtitleList[0].index
    }
  }
  fetchUnWatched = async () => {
    const res = await FetchUnWatchedApi<ViewingRecord>(this.Id.Id)
    this.videoId = res.Items[0].Id
  }
  fetchSubtitle = async () => {
    if (!this.subtitlesId) {
      return
    }
    const res = await FetchSubtitleApi(this.videoId, this.mediaSourceId, this.subtitlesId, this.subtitlesCodec)
    this.subtitles = this.subtitleProcessor.parse(res, this.subtitlesCodec)
  }
  fetchServerUrl = async () => {
    const res = await FetchServerUrl()
    this.serverUrl = res
  }

  onVideoIdChanged() {
    this.fetchPlaybackInfo()
    this.fetchSubtitle()
  }

  onSubtitlesIdChanged() {
    this.fetchSubtitle()
  }

  build() {
    Scroll() {
      Column() {
        Column() {
          Image(this.serverUrl + FetchImagePrimary(this.Id.Id))
            .alt($r('app.media.Image_loading_failed'))
        }
        .width('100%')

        Column()
          .width('100%')
          .height(10)
          .margin({ bottom: 5 })
          .linearGradient({
            direction: GradientDirection.Bottom,
            colors: [[Color.Black, 0], [$r('app.color.theme_background_1'), 1]]
          })

        Flex({ direction: FlexDirection.Column }) {
          Text(`${this.PageData[0]?.Name}`)
            .width('100%')
            .fontSize(BasicConstants.FONT_MAX_BIG)
            .fontWeight(FontWeight.Bold)
            .textAlign(TextAlign.Center)

          Column() {
            Text(`${this.PageData?.map((item: DetailsModel) => item.CommunityRating?.toFixed(1) ??
              0)} | ${this.PageData?.map((item: DetailsModel) => item.PremiereDate.split('T')[0] ??
              '未知日期')} | 共 ${this.PageData?.map((item: DetailsModel) => item.ChildCount ?? 1)} 季`)
              .fontSize(BasicConstants.FONT_NORMAL)
              .margin(5)

            Text(`${this.PageData[0]?.Genres}`)
              .fontSize(BasicConstants.FONT_NORMAL)
          }
          .width('100%')
          .height(50)
          .margin({ top: 5, bottom: 5 })

          //字幕
          Row() {
            if (this.preferredSubtitle) {
              Column() {
                Text(`字幕：`)
                  .fontSize(BasicConstants.FONT_NORMAL)
              }

              Column() {
                Text(this.preferredSubtitle)
                  .fontSize(BasicConstants.FONT_NORMAL)
              }
              .border({ width: 1 })
              .onClick(() => {
                if (this.subtitleList.length > 1) {
                  DialogUtil.showTextPicker({
                    range: this.subtitleList.map((item: SubtitleList) => item.displayLanguage),
                    canLoop: false,
                    onAccept: (result) => {
                      this.subtitlesCodec = this.subtitleList[result.index as number].codec
                      this.subtitlesId = this.subtitleList[result.index as number].index
                      this.preferredSubtitle = this.subtitleList[result.index as number].displayLanguage
                    }
                  })
                }
              })
              .padding(5)
              .borderRadius(5)
            }
          }

          //版本选择
          Column() {
            Text(this.data[this.videoIndex]?.Name || '暂无数据')
              .fontSize(BasicConstants.FONT_BIG)
          }
          .width('100%')
          .margin({ top: 10, bottom: 10 })
          .border({ width: 1 })
          .borderRadius(5)
          .padding(5)
          .onClick(() => {
            if (this.dialogController) {
              this.dialogController.open();
            }
          })

          //播放按钮
          Button('播放')
            .width('80%')
            .height(50)
            .margin({ top: 10, bottom: 10 })
            .alignSelf(ItemAlign.Center)
            .onClick(() => {
              if (this.videoId) {
                if (!this.VideoUrl) {
                  this.VideoUrl = this.serverUrl + '/emby' + this.data[0]?.DirectStreamUrl
                  router.pushUrl({
                    url: 'pages/IjkVideoPlayer',
                    params: {
                      video: this.VideoUrl,
                      name: this.PageData[0].Name,
                      videoId: this.videoId,
                      mediaSourceId: this.mediaSourceId,
                      playSessionId: this.playSessionId,
                      subtitleList: this.subtitleList,
                      subtitles: this.subtitles
                    }
                  }).catch(() => {
                  })
                } else {
                  router.pushUrl({
                    url: 'pages/IjkVideoPlayer',
                    params: {
                      video: this.VideoUrl,
                      name: this.PageData[0].Name,
                      videoId: this.videoId,
                      mediaSourceId: this.mediaSourceId,
                      playSessionId: this.playSessionId,
                      subtitleList: this.subtitleList,
                      subtitles: this.subtitles
                    }
                  }).catch(() => {
                  })
                }
              } else {
                ToastUtil.showToast('请选择播放剧集')
              }
            })

          //集数
          Column() {
            if (this.Id.Type != 'Movie') {
              SeasonList({ videoIndex: this.Id.Id, videoId: $videoId })
            }
          }
          .width('100%')
          .margin({ top: 10, bottom: 10 })

          //简介
          Column() {
            Text(`简介：${this.PageData.map((item: DetailsModel) => item.Overview)}`)
              .fontSize(BasicConstants.FONT_NORMAL)
          }
          .width('100%')
          .margin({ top: 10, bottom: 10 })
        }
        .width('90%')
        .alignSelf(ItemAlign.Center)
      }
      .width('100%')
      .backgroundColor($r('app.color.theme_background_1'))
    }
    .scrollBar(BarState.Off)
  }
}