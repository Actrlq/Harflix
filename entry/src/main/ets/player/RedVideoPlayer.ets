import {
  IMediaPlayer,
  IMediaPlayerStateListener,
  PlayerCoreType,
  RedPlayerDataSource,
  RedPlayerFactory,
  RedPlayerXComponentController,
  SourceType
} from '@rte-xhs/redplayer'
import { LengthMetrics, router, window } from '@kit.ArkUI'
import { NetworkUtil, ObjectUtil, WindowUtil } from '@pura/harmony-utils'
import { VideoDataModel } from './VideoDataModel'
import { BasicConstants } from '../viewmodel/BasicConstants'
import { SubtitleItem, SubtitleProcessor } from '../utils/SubtitleProcessor'
import { SubtitleList } from '../utils/InfoFilter'
import { FetchSubtitleApi } from '../apis/AuxiliaryApi'
import { FetchDetailsApi, ReturnProgressApi } from '../apis/ProductApi'
import { DetailsModel } from '../viewmodel/DataConstraints'

class StateHolder {
  videoDuration: number = 0
  videoPosition: number = 0
  currentTime: string = "00:00"
  videoWidth: number = 0
  videoHeight: number = 0
  videoRatio: number = 16 / 9
  url: string = ''
  isStart: boolean = false
  speedIndex: number = 1
  videoCodec: string = ''
  audioCodec: string = ''
}

class PlayerController implements IMediaPlayerStateListener {
  static TAG = "PlayerController"
  private player: IMediaPlayer | null = null
  StateHolder: StateHolder
  dataSource: RedPlayerDataSource | undefined

  constructor(stateHolder: StateHolder) {
    this.StateHolder = stateHolder
  }

  public createMediaPlayer(coreType: PlayerCoreType) {
    return RedPlayerFactory.createMediaPlayer(this, coreType).then((player) => {
      this.player = player
    })
  }

  public setDataSource(dataSource: RedPlayerDataSource): Promise<void> | undefined {
    this.dataSource = dataSource
    return this.player?.setDataSource(dataSource)
  }

  public setSurfaceId(id: string) {
    this.player?.setSurfaceId(id)
  }

  public prepare(): Promise<void> | undefined {
    return this.player?.prepare()
  }

  public start() {
    this.player?.start()
  }

  public pause() {
    this.player?.pause()
  }

  public stop() {
    this.player?.stop()
  }

  public release() {
    this.player?.release()
  }

  public seek(time: number) {
    if (this.dataSource?.isLive != true) {
      this.player?.seek(time)
    }
  }

  public setSpeed(speed: number) {
    this.player?.setSpeed(speed)
  }

  public setVolume(volume: number) {
    this.player?.setVolume(volume)
  }

  onPlayerCreated() {

  }

  onInitialized() {

  }

  onPrepared() {
    if (this.StateHolder && this.player) {
      this.StateHolder.videoDuration = this.player.getVideoDuration()
      let width = this.player.getVideoWidth()
      let height = this.player.getVideoHeight()

      this.StateHolder.videoWidth = width
      this.StateHolder.videoHeight = height
      this.StateHolder.url = this.player.getUrl()

      this.StateHolder.videoCodec = this.player.getVideoCodecInfo()
      this.StateHolder.audioCodec = this.player.getAudioCodecInfo()

      this.StateHolder.videoRatio = width / height
    }
    if (this.dataSource && this.dataSource.isAutoStart) {
      this.StateHolder.isStart = true
    }

  }

  onStarted() {
    this.StateHolder.isStart = true
  }

  onFirstFrameRendered() {

  }

  onPositionUpdated(time: number) {
    if (this.StateHolder) {
      this.StateHolder.videoPosition = time
      setTimeout(() => {
        this.StateHolder.currentTime = timeForString(Math.floor(time / 1000))
      }, 500)
    }
  }

  onPaused() {
    this.StateHolder.isStart = false
  }

  onStopped() {
    this.StateHolder.isStart = false
  }

  onCompleted() {
    if (this.dataSource && this.dataSource.isAutoLoop) {
      this.StateHolder.isStart = false
    }
  }

  onReleased() {
    this.StateHolder.isStart = false
  }

  onError(reason: string) {
    console.log(PlayerController.TAG + " onError " + reason)
  }

  onSeekDone(): void {

  }

  onBufferingStart(): void {

  }

  onBufferingEnd(): void {

  }
}

@Entry
@Component
struct RedVideoPlayer {
  coreType: PlayerCoreType = PlayerCoreType.TYPE_RED_PLAYER
  @State stateHolder: StateHolder = new StateHolder()
  xComponentController: RedPlayerXComponentController = new RedPlayerXComponentController(this.coreType)
  playerController = new PlayerController(this.stateHolder)
  @State videoData: VideoDataModel = router.getParams() as VideoDataModel
  @State loadingVisible: Visibility = Visibility.None
  @State replayVisible: Visibility = Visibility.None
  @State TapScreen: boolean = false
  private TapScreenTime: number = -1
  @State totalTime: string = "00:00"
  @State @Watch('onSubtitle') subtitles: SubtitleItem[] = this.videoData.subtitles
  private updateSubtitleTimer: number = -1
  //当前显示字幕
  @State CurrentSubtitle: string = ''
  private subtitleList: SubtitleList[] = this.videoData.subtitleList
  private subtitlesCodec: string = ''
  //字幕index
  @State @Watch('onSubtitlesIdChanged') subtitlesId: number = this.videoData.subtitlesId
  private subtitleProcessor: SubtitleProcessor = new SubtitleProcessor()
  @State playSpeed: number = 1
  private last: number = 0
  private playbackPositionTicks: number = 0

  aboutToAppear(): void {
    WindowUtil.setPreferredOrientation(window.Orientation.AUTO_ROTATION_LANDSCAPE)
    WindowUtil.setWindowSystemBarEnable([])
    this.showLoadIng()
    this.fetchDetails()
  }

  aboutToDisappear(): void {
    clearTimeout(this.TapScreenTime)
    this.playerController.stop()
    this.playerController.release()
    WindowUtil.setPreferredOrientation(window.Orientation.PORTRAIT)
    WindowUtil.setWindowSystemBarEnable(["status", "navigation"])
  }

  onSubtitle() {
    if (this.subtitles.length > 0) {
      this.startSubTitle()
    } else {
      this.stopSubTitle()
    }
  }

  onSubtitlesIdChanged() {
    this.fetchSubtitle()
  }

  fetchSubtitle = async () => {
    const res = await FetchSubtitleApi(this.videoData.videoId, this.videoData.mediaSourceId, this.subtitlesId,
      this.subtitlesCodec)
    this.subtitles = this.subtitleProcessor.parse(res, this.subtitlesCodec)
  }

  returnProgress = async () => {
    if (NetworkUtil.isNetworkAvailable() === false) {
      return
    }
    const time = this.stateHolder.videoPosition - 60000
    await ReturnProgressApi<null>({
      PositionTicks: time * 10000,
      PlaySessionId: this.videoData.playSessionId,
      MediaSourceId: this.videoData.mediaSourceId,
      ItemId: this.videoData.videoId,
      EventName: 'TimeUpdate',
    })
  }

  fetchDetails = async () => {
    const res = await FetchDetailsApi<DetailsModel>(this.videoData.videoId)
    this.playbackPositionTicks = ObjectUtil.getValue<number>(res.UserData, 'PlaybackPositionTicks') / 10000
  }

  @Builder
  speedMenu() {
    Menu() {
      MenuItem({
        content: '0.75X'
      }).selectIcon(true)
        .selected(this.playSpeed == 0.75)
        .onClick(() => {
          if (!this.debounce()) {
            return;
          }
          this.playSpeed = 0.75
          this.playerController.setSpeed(0.75)
        })

      MenuItem({
        content: '1X'
      }).selectIcon(true)
        .selected(this.playSpeed == 1)
        .onClick(() => {
          if (!this.debounce()) {
            return;
          }
          this.playSpeed = 1
          this.playerController.setSpeed(1)
        })

      MenuItem({
        content: '1.25X'
      }).selectIcon(true)
        .selected(this.playSpeed == 1.25)
        .onClick(() => {
          if (!this.debounce()) {
            return;
          }
          this.playSpeed = 1.25
          this.playerController.setSpeed(1.25)
        })

      MenuItem({
        content: '1.5X'
      }).selectIcon(true)
        .selected(this.playSpeed == 1.5)
        .onClick(() => {
          if (!this.debounce()) {
            return;
          }
          this.playSpeed = 1.5
          this.playerController.setSpeed(1.5)
        })

      MenuItem({
        content: '2.0X'
      }).selectIcon(true)
        .selected(this.playSpeed == 2)
        .onClick(() => {
          if (!this.debounce()) {
            return;
          }
          this.playSpeed = 2
          this.playerController.setSpeed(2)
        })

      MenuItem({
        content: '3.0X'
      }).selectIcon(true)
        .selected(this.playSpeed == 3)
        .onClick(() => {
          if (!this.debounce()) {
            return;
          }
          this.playSpeed = 3
          this.playerController.setSpeed(3)
        })

    }
    .menuItemDivider({
      strokeWidth: LengthMetrics.vp(1.5),
      color: '#d5d5d5',
    })
  }

  @Builder
  subtitleMenu() {
    Menu() {
      ForEach(this.subtitleList, (item: SubtitleList) => {
        MenuItem({
          content: item.displayLanguage
        }).selectIcon(true)
          .selected(this.subtitlesId == item.index)
          .onClick(() => {
            this.subtitlesCodec = item.codec
            this.subtitlesId = item.index
          })
      })
    }
    .menuItemDivider({
      strokeWidth: LengthMetrics.vp(1.5),
      color: '#d5d5d5',
    })
  }

  build() {
    Flex({ direction: FlexDirection.Column }) {
      Stack() {
        Column() {
          XComponent({
            id: this.xComponentController.getSurfaceId(),
            type: this.xComponentController.getSurfaceType(),
            libraryname: this.xComponentController.getLibraryName(),
            controller: this.xComponentController
          }).onLoad(() => {
            this.playerController.createMediaPlayer(this.coreType).then(() => {
              this.playerController.setDataSource({
                url: this.videoData.videoSrc,
                sourceType: SourceType.URL,
                logHead: "RedPlay",
                enableAccurateSeek: true,
                useSoftDecoder: false,
              })?.then(() => {
                this.playerController.setSurfaceId(this.xComponentController.getSurfaceId())
                this.playerController.prepare()?.then(() => {
                  this.totalTime = timeForString(Math.floor(this.stateHolder.videoDuration / 1000))
                  this.hideLoadIng()
                  if (this.playbackPositionTicks > 0) {
                    this.playerController.seek(this.playbackPositionTicks)
                    this.seekToSubtitle()
                    console.log(`进度时间${this.playbackPositionTicks}`)
                  }
                  this.onSubtitle()
                  this.playerController.start()
                  this.updateProgress()
                })
              })
            })
          }).width('100%')
        }
        .width('100%')
        .aspectRatio(16 / 9)
        .justifyContent(FlexAlign.Center)

        //字幕
        if (this.subtitles.length > 0) {
          Stack() {
            Text(this.CurrentSubtitle)
              .fontSize(25)
              .fontColor(Color.White)
              .width('100%')
              .padding(10)
              .textAlign(TextAlign.Center)
              .textShadow({
                radius: vp2px(2),
              })
              .hitTestBehavior(HitTestMode.None)
          }.height('100%').alignContent(Alignment.Bottom)
        }

        //控制组件
        Column() {
          //顶部菜单
          Row() {
            Column() {
              Image($r('app.media.ic_back'))
                .height('80%')
                .onClick(() => {
                  router.back()
                })
            }
            .margin({ left: 20, right: 20 })

            Column() {
              Text(this.videoData.name)
                .fontColor(Color.White)
                .fontSize(BasicConstants.FONT_BIG)
            }
          }
          .width('100%')
          .height(40)
          .padding({ top: 5, bottom: 5 })
          .visibility(this.TapScreen ? Visibility.Visible : Visibility.Hidden)

          //中间区域
          Blank()
            .layoutWeight(1)
            .gesture(TapGesture().onAction(() => {
              if (this.TapScreen) {
                clearTimeout(this.TapScreenTime)
                this.TapScreenTime = -1
                this.TapScreen = false
              } else {
                this.TapScreen = true
                this.TapScreenTime = setTimeout(() => {
                  this.TapScreen = false
                }, 5000)
              }
            }))

          //底部菜单
          Column() {
            //播放进度条
            Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Start }) {
              Text(this.stateHolder.currentTime).fontSize(BasicConstants.FONT_SMALL).fontColor(Color.White)
              Slider({
                value: this.stateHolder.videoPosition,
                min: 0,
                max: this.stateHolder.videoDuration,
                step: 1,
                style: SliderStyle.OutSet
              })
                .layoutWeight(1)
                .blockColor(Color.White)
                .trackColor(Color.Gray)
                .selectedColor(Color.White)
                .enabled(this.stateHolder.isStart)
                .onChange((value: number, mode: SliderChangeMode) => {
                  if (mode == SliderChangeMode.End) {
                    this.playerController.seek(value)
                    this.seekToSubtitle()
                  }
                })
              Text(this.totalTime).fontSize(BasicConstants.FONT_SMALL).fontColor(Color.White)
            }
            .margin({ left: 20, right: 20 })
            .height(20)

            //控制按钮
            Row() {
              Row() {
                Image(this.stateHolder.isStart ? $r('app.media.ic_pause') : $r('app.media.ic_play'))
                  .height('60%')
                  .margin({ right: 20 })
                  .onClick(() => {
                    if (this.stateHolder.isStart) {
                      this.playerController.pause()
                    } else {
                      this.playerController.start()
                    }
                  })
                Image($r('app.media.ic_next'))
                  .height('60%')
              }
              .justifyContent(FlexAlign.Start)
              .layoutWeight(1)

              Row() {
                Text('倍速')
                  .fontColor(Color.White)
                  .margin({ right: 20 })
                  .fontSize(BasicConstants.FONT_NORMAL)
                  .bindMenu(this.speedMenu())

                Text('音频')
                  .fontColor(Color.White)
                  .margin({ right: 20 })
                  .fontSize(BasicConstants.FONT_NORMAL)
                // .bindMenu(this.audioMenu())

                Text('字幕')
                  .fontColor(Color.White)
                  .fontSize(BasicConstants.FONT_NORMAL)
                  .bindMenu(this.subtitleMenu())
              }
              .justifyContent(FlexAlign.End)
              .layoutWeight(1)
            }
            .margin({ left: 20, right: 20 })
            .layoutWeight(1)
          }
          .width('100%')
          .height(60)
          .alignItems(HorizontalAlign.Start)
          .visibility(this.TapScreen ? Visibility.Visible : Visibility.Hidden)

        }
        .height('100%')
        .backgroundColor(Color.Transparent)
        .padding(10)

        Image($r('app.media.icon_replay'))
          .objectFit(ImageFit.Auto)
          .width('120px')
          .height('120px')
          .visibility(this.replayVisible)
          .border({ width: 0 })
          .borderStyle(BorderStyle.Dashed)
          .onClick(() => {
            this.playerController.start()
          })
        Image($r('app.media.icon_load'))
          .objectFit(ImageFit.Auto)
          .width('120px')
          .height('120px')
          .visibility(this.loadingVisible)
          .border({ width: 0 })
          .borderStyle(BorderStyle.Dashed)

      }.width('100%').backgroundColor($r('sys.color.black')).clip(true)
    }

  }

  private showLoadIng() {
    this.loadingVisible = Visibility.Visible;
    this.replayVisible = Visibility.None;
  }

  private hideLoadIng() {
    this.loadingVisible = Visibility.None;
    this.replayVisible = Visibility.None;
  }

  private showRePlay() {
    this.loadingVisible = Visibility.None;
    this.replayVisible = Visibility.Visible;
  }

  // 开始播放字幕
  private startSubTitle() {
    if (this.subtitles.length === 0) {
      return
    }
    this.updateSubtitles();
  }

  // 停止播放字幕
  private stopSubTitle() {
    if (this.updateSubtitleTimer !== -1) {
      clearTimeout(this.updateSubtitleTimer);
      this.updateSubtitleTimer = -1;
    }
    this.CurrentSubtitle = '';
  }

  //更新字幕
  private updateSubtitles() {
    if (this.subtitles.length === 0) {
      return
    }
    const currentTime = this.stateHolder.videoPosition
    let currentSubtitle: SubtitleItem | null = null
    let nextUpdateTime: number = Number.MAX_VALUE;

    // 查找当前时间应显示的字幕
    for (const subtitle of this.subtitles) {
      if (currentTime >= subtitle.startTime && currentTime < subtitle.endTime) {
        currentSubtitle = subtitle;
        nextUpdateTime = subtitle.endTime;
        break;
      } else if (subtitle.startTime > currentTime) {
        nextUpdateTime = subtitle.startTime;
        break;
      }
    }

    // 更新字幕显示
    this.CurrentSubtitle = currentSubtitle ? currentSubtitle.text : ''

    // 安排下一次更新
    if (nextUpdateTime !== Number.MAX_VALUE) {
      const delay = nextUpdateTime - currentTime;
      this.updateSubtitleTimer = setTimeout(() => {
        this.updateSubtitles();
      }, delay);
    }
  }

  // 跳转到指定时间
  private seekToSubtitle() {
    if (this.subtitles.length === 0) {
      return
    }
    if (this.updateSubtitleTimer !== -1) {
      clearTimeout(this.updateSubtitleTimer);
    }
    this.updateSubtitles()
  }

  //上传进度
  private updateProgress() {
    setTimeout(() => {
      if (this.playerController.StateHolder.isStart) {
        this.returnProgress()
      }
      this.updateProgress()
    }, 30000)
  }

  debounce() {
    const delay = 600;
    let cur = new Date().getTime();
    if (cur - this.last > delay) {
      this.last = cur;
      return true;
    }
    return false;
  }
}

function timeForString(seconds: number): string {
  const HOUR_UNIT: number = 60;
  const TIME_CONST_TEN: number = 10;
  let hourUnit: number = HOUR_UNIT * HOUR_UNIT;
  let hour: number = Math.floor(seconds / hourUnit);
  let minute: number = Math.floor((seconds - hour * hourUnit) / HOUR_UNIT);
  let second: number = seconds - hour * hourUnit - minute * HOUR_UNIT;
  let hourStr: string = hour < TIME_CONST_TEN ? `0${hour.toString()}` : `${hour.toString()}`
  let minuteStr: string = minute < TIME_CONST_TEN ? `0${minute.toString()}` : `${minute.toString()}`
  let secondStr: string = second < TIME_CONST_TEN ? `0${second.toString()}` : `${second.toString()}`
  if (hour > 0) {
    return `${hourStr}:${minuteStr}:${secondStr}`;
  }
  if (minute > 0) {
    return `${minuteStr}:${secondStr}`;
  } else {
    return `00:${secondStr}`;
  }
}