import { FetchDetailsApi, FetchPlaybackInfoApi, FetchUnWatchedApi } from '../apis/ProductApi'
import { BasicConstants } from '../viewmodel/BasicConstants'
import {
  ActorInformation,
  DetailsModel,
  MediaSources,
  NewViewsList,
  PlaybackInfo,
  ViewingRecord
} from '../viewmodel/DataConstraints'
import router from '@ohos.router'
import { NetworkUtil, ToastUtil, DialogUtil } from '@pura/harmony-utils'
import { FetchImagePrimary, FetchServerUrl, FetchSubtitleApi } from '../apis/AuxiliaryApi'
import { SubtitleItem, SubtitleProcessor } from '../utils/SubtitleProcessor'
import { AudioList, InfoFilter, SubtitleList, VideoInfo } from '../utils/InfoFilter'
import { SeasonList } from '../view/SeasonList'
import { LoadingView } from '../common/LoadingView'

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
  private subtitleList: SubtitleList[] = []
  private audioList: AudioList[] = []
  //首选字幕
  @State preferredSubtitle: string = ''
  //首选音频
  @State preferredAudio: string = ''
  @State videoRange: string = ''
  //播放视频id
  @State mediaSourceId: string = ''
  //字幕index
  @State @Watch('onSubtitlesIdChanged') subtitlesId: number = 0
  //音频index
  private audioId: number = 1
  @State subtitlesCodec: string = ''
  //视频信息
  @State videoInfo: VideoInfo[] = []
  @State serverUrl: string = ''
  private playSessionId: string = ''
  private subtitleSelect: number | number[] = 0
  private audioSelect: number | number[] = 0
  @State actorInformation: ActorInformation[] = []
  //弹窗
  @State isShowSheet: boolean = false
  @State isLoading: boolean = true

  aboutToAppear(): void {
    setTimeout(() => {
      this.isLoading = false
    }, 30000)
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

  }

  fetchDetails = async () => {
    const res = await FetchDetailsApi<DetailsModel>(this.Id.Id)
    this.PageData = [res]
    this.actorInformation = this.PageData[0].People as ActorInformation[]
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
    this.audioList = this.InfoFilter.filterAudio(this.data[this.videoIndex].MediaStreams)
    this.mediaSourceId = this.data[this.videoIndex].Id
    this.videoRange = this.videoInfo[this.videoIndex].displayTitle
    for (const text of this.subtitleList) {
      if (text.displayLanguage === 'Chinese Simplified') {
        this.preferredSubtitle = text.displayLanguage
        this.subtitlesCodec = text.codec
        this.subtitlesId = text.index
        break
      } else {
        this.preferredSubtitle = this.subtitleList[0].displayLanguage
        this.subtitlesCodec = this.subtitleList[0].codec
        this.subtitlesId = this.subtitleList[0].index
      }
    }
    for (const text of this.audioList) {
      if (text.isDefault) {
        this.preferredAudio = text.displayTitle
        this.audioId = text.index
        break
      } else {
        this.preferredAudio = this.audioList[0].displayTitle
        this.audioId = this.audioList[0].index
      }
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

  @Builder
  VideoSheet() {
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
              Text(FrameConversion(item.Size))
                .fontSize(BasicConstants.FONT_SMALL)
            }
            .Format()

            Column() {
              Text(TimeConversion(this.data[this.videoIndex].RunTimeTicks))
                .fontSize(BasicConstants.FONT_SMALL)
            }
            .Format()
          }
          .margin({ top: 5 })
        }
        .width('100%')
        .margin({ bottom: 5 })
        .padding(5)
        .borderRadius(10)
        .backgroundColor($r('sys.color.comp_background_list_card'))
        .onClick(() => {
          this.videoIndex = index
          this.isShowSheet = false
          console.log(JSON.stringify(this.videoIndex))
        })
      }, (item: MediaSources) => item.Id)
    }
    .padding({ left: 10., right: 10, top: 5 })
  }
  .scrollBar(BarState.Off)

}

  build() {
    Stack() {
      Scroll() {
        Column() {
          Column() {
            Image(this.serverUrl + FetchImagePrimary(this.Id.Id))
              .alt($r('app.media.Image_loading_failed'))
              .onComplete(()=>{
                setTimeout(() => {
                  this.isLoading = false
                }, 500)
              })
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

            //视频
            Row() {
              Column() {
                Text(`视频：`)
                  .fontSize(BasicConstants.FONT_NORMAL)
              }

              Column() {
                Text(this.videoRange ? this.videoRange : '无视频信息')
                  .fontSize(BasicConstants.FONT_NORMAL)
              }
              .border({ width: 1 })
              .padding(5)
              .borderRadius(5)
            }
            .margin({ bottom: 10 })

            //音频
            Row() {
              Column() {
                Text(`音频：`)
                  .fontSize(BasicConstants.FONT_NORMAL)
              }

              Column() {
                Text(this.preferredAudio ? this.preferredAudio : '默认(无可选音频)')
                  .fontSize(BasicConstants.FONT_NORMAL)
              }
              .border({ width: 1 })
              .onClick(() => {
                if (this.audioList.length > 1) {
                  DialogUtil.showTextPicker({
                    range: this.audioList.map((item: AudioList) => item.displayTitle),
                    canLoop: false,
                    selected: this.audioSelect,
                    onAccept: (result) => {
                      this.audioSelect = result.index
                      this.preferredAudio = this.audioList[result.index as number].displayTitle
                      this.audioId = this.audioList[result.index as number].index
                    }
                  })
                }
              })
              .padding(5)
              .borderRadius(5)
            }
            .margin({ bottom: 10 })

            //字幕
            Row() {
              Column() {
                Text(`字幕：`)
                  .fontSize(BasicConstants.FONT_NORMAL)
              }

              Column() {
                Text(this.preferredSubtitle ? this.preferredSubtitle : '默认(无可选字幕)')
                  .fontSize(BasicConstants.FONT_NORMAL)
              }
              .border({ width: 1 })
              .onClick(() => {
                if (this.subtitleList.length > 1) {
                  DialogUtil.showTextPicker({
                    range: this.subtitleList.map((item: SubtitleList) => item.displayLanguage),
                    canLoop: false,
                    selected: this.subtitleSelect,
                    onAccept: (result) => {
                      this.subtitleSelect = result.index
                      this.preferredSubtitle = this.subtitleList[result.index as number].displayLanguage
                      this.subtitlesCodec = this.subtitleList[result.index as number].codec
                      this.subtitlesId = this.subtitleList[result.index as number].index
                    }
                  })
                }
              })
              .padding(5)
              .borderRadius(5)
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
            .bindSheet($$this.isShowSheet, this.VideoSheet(), {
              height: 350,
              title: { title: '版本' },
            })
            .onClick(() => {
              this.isShowSheet = true
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
                        subtitles: this.subtitles,
                        audioList: this.audioList,
                        audioId: this.audioId,
                        subtitlesId: this.subtitlesId
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
                        subtitles: this.subtitles,
                        audioList: this.audioList,
                        audioId: this.audioId,
                        subtitlesId: this.subtitlesId
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

            //演员
            Column() {
              Text('演员')
                .width('100%')
                .fontSize(BasicConstants.FONT_BIG)
                .fontWeight(FontWeight.Bold)
                .margin({ top: 10, bottom: 10 })

              List({ space: 5 }) {
                ForEach(this.actorInformation, (item: ActorInformation) => {
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
                          .fontSize(BasicConstants.FONT_SMALL)
                          .maxLines(1)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })
                      }
                      .margin({ top: 5, bottom: 5 })

                      Column() {
                        Text(item.Role)
                          .fontSize(BasicConstants.FONT_MIN_SMALL)
                          .maxLines(1)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })
                      }
                      .padding({ bottom: 5 })

                    }
                    .width(100)
                  }
                })
              }
              .width('100%')
              .height('100%')
              .listDirection(Axis.Horizontal)
              .scrollBar(BarState.Off)
            }
            .height(180)
            .width('100%')

          }
          .width('90%')
          .alignSelf(ItemAlign.Center)
        }
        .width('100%')
        .backgroundColor($r('sys.color.background_secondary'))
        .padding({ bottom: 60 })

      }
      .scrollBar(BarState.Off)

      if (this.isLoading) {
        LoadingView()
      }
    }

  }
}

function FrameConversion(bytes:number){
  if (bytes > 1047527424) {
    const value = bytes / Math.pow(1024, 3)
    return value.toFixed(2) + 'GB'
  } else {
    const value = bytes / Math.pow(1024, 2)
    return value.toFixed(2) + 'MB'
  }
}

function TimeConversion(ms:number){
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

@Styles
function Format() {
  .margin({ right: 10 })
  .border({ width: 1 })
  .borderRadius(5)
  .padding(2)
}