import { Callback } from '@ohos.base';
import { IjkMediaPlayer, InterruptEvent, InterruptHintType, DeviceChangeReason } from '@ohos/ijkplayer';
import { OnPreparedListener } from '@ohos/ijkplayer';
import { OnVideoSizeChangedListener } from '@ohos/ijkplayer';
import { OnCompletionListener } from '@ohos/ijkplayer';
import { OnBufferingUpdateListener } from '@ohos/ijkplayer';
import { OnErrorListener, OnTimedTextListener } from '@ohos/ijkplayer';
import { OnInfoListener } from '@ohos/ijkplayer';
import { OnSeekCompleteListener } from '@ohos/ijkplayer';
import { LogUtils } from '@ohos/ijkplayer';
import { IjkplayerMapManager } from '../viewmodel/IjkplayerMapManager';
import { router } from '@kit.ArkUI';
import window from '@ohos.window';
import { DialogUtil, ObjectUtil, ToastUtil, WindowUtil } from '@pura/harmony-utils';
import { BasicConstants } from '../viewmodel/BasicConstants'
import { SubtitleItem, SubtitleProcessor } from '../utils/SubtitleProcessor';
import { SubtitleList } from '../utils/InfoFilter';
import { FetchSubtitleApi } from '../apis/AuxiliaryApi';
import { FetchDetailsApi, ReturnProgressApi } from '../apis/ProductApi';
import { DetailsModel } from '../viewmodel/DataConstraints';

export enum PlayStatus {
  INIT,
  PLAY,
  PAUSE,
  DONE
}

class videoUrlModel {
  video: string = ''
  name: string = ''
  videoId: string = ''
  mediaSourceId: string = ''
  playSessionId: string = ''
  subtitleList: SubtitleList[] = []
  subtitles: SubtitleItem[] = []
}

@Entry
@Component
struct IjkVideoPlayer {
  @State progressValue: number = 0;
  @State currentTime: string = "00:00"
  @State totalTime: string = "00:00"
  @State loadingVisible: Visibility = Visibility.None
  @State replayVisible: Visibility = Visibility.None
  @State slideEnable: boolean = false
  @State aspRatio: number = 0.5
  @State mContext: object | undefined = undefined
  @State mFirst: boolean = true
  @State mDestroyPage: boolean = false
  @State playSpeed: string = '1f'
  @State volume: number = 1.0
  @State oldSeconds: number = 0
  @State isSeekTo: boolean = false
  @State isCurrentTime: boolean = false
  @State videoWidth: string = '100%'
  @State initAspectRatio: number = 1
  @State videoAspectRatio: number = this.initAspectRatio
  @State videoData: videoUrlModel = router.getParams() as videoUrlModel
  private last: number = 0
  @State videoParentAspectRatio: number = this.initAspectRatio
  private mIjkMediaPlayer = IjkMediaPlayer.getInstance()
  private CONTROL_PlayStatus = PlayStatus.INIT
  @State PROGRESS_MAX_VALUE: number = 100
  @State updateProgressTimer: number = 0
  @State curIndex: number = 0
  @State recordProgressVisible: Visibility = Visibility.None
  @State screenshotProgressVisible: Visibility = Visibility.None
  @State recordSaveFilePath: string = "";
  private xcomponentId: string = ""
  private updateSubtitleTimer: number = -1
  //是否点击屏幕
  @State TapScreen: boolean = false
  private TapScreenTime:number = -1
  //播放状态
  @State isPlayer: boolean = true
  //当前显示字幕
  @State CurrentSubtitle: string = ''
  private subtitleList: SubtitleList[] = this.videoData.subtitleList
  @State subtitlesCodec: string = ''
  //字幕index
  @State @Watch('onSubtitlesIdChanged') subtitlesId: number = 0
  private subtitleProcessor: SubtitleProcessor = new SubtitleProcessor()
  @State @Watch('onSubtitle') subtitles: SubtitleItem[] = this.videoData.subtitles
  private playbackPositionTicks: number = 0

  aboutToAppear() {
    this.xcomponentId = "xcomponentId_" + IjkplayerMapManager.generateId();
    let event: Callback<InterruptEvent> = (event) => {
      LogUtils.getInstance().LOGI(`event: ${JSON.stringify(event)}`);
      if (event.hintType === InterruptHintType.INTERRUPT_HINT_PAUSE) {
        this.pause();
      } else if (event.hintType === InterruptHintType.INTERRUPT_HINT_RESUME) {
        this.startPlayOrResumePlay();
      } else if (event.hintType === InterruptHintType.INTERRUPT_HINT_STOP) {
        this.stop();
      }
    }
    this.mIjkMediaPlayer.on('audioInterrupt', event);
    let deviceChangeEvent: Callback<InterruptEvent> = (event) => {
      LogUtils.getInstance().LOGI(`deviceChange event: ${JSON.stringify(event)}`);
      if (event.reason === DeviceChangeReason.REASON_NEW_DEVICE_AVAILABLE) {
        this.pause();
      } else if (event.reason === DeviceChangeReason.REASON_OLD_DEVICE_UNAVAILABLE) {
        this.pause();
      }
    }
    this.mIjkMediaPlayer.on('deviceChange', deviceChangeEvent);
    WindowUtil.setPreferredOrientation(window.Orientation.AUTO_ROTATION_LANDSCAPE)
    WindowUtil.setWindowSystemBarEnable([])
    this.fetchDetails()
  }

  aboutToDisappear() {
    IjkplayerMapManager.getInstance().destroyStatusMap.set(this.xcomponentId, true);
    this.mDestroyPage = true;
    this.mIjkMediaPlayer.setScreenOnWhilePlaying(false);
    if (this.CONTROL_PlayStatus !== PlayStatus.INIT) {
      this.stop();
    }
    this.mIjkMediaPlayer.off('audioInterrupt');
    this.mIjkMediaPlayer.off('deviceChange');
    this.videoData = new videoUrlModel()
    WindowUtil.setPreferredOrientation(window.Orientation.PORTRAIT)
    WindowUtil.setWindowSystemBarEnable(["status", "navigation"])
    this.subtitles = []
  }

  onPageShow() {
    if (this.mContext && !this.mFirst) {
      this.startPlayOrResumePlay();
    }
  }

  onPageHide() {
    this.pause()
  }

  onSubtitle() {
    if (this.subtitles.length > 0) {
      this.startSubTitle()
    } else {
      this.stopSubTitle()
    }
  }

  fetchSubtitle = async () => {
    this.subtitles = []
    const res = await FetchSubtitleApi(this.videoData.videoId, this.videoData.mediaSourceId, this.subtitlesId,
      this.subtitlesCodec)
    this.subtitles = this.subtitleProcessor.parse(res, this.subtitlesCodec)
  }
  returnProgress = async () => {
    const time = this.mIjkMediaPlayer.getCurrentPosition() - 60000
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
  xcomponentController: XComponentController = new XComponentController()

  onSubtitlesIdChanged() {
    this.fetchSubtitle()
  }

  build() {
    Flex({ direction: FlexDirection.Column }) {
      Stack({ alignContent: Alignment.Center }) {
        //视频
        Column() {
          XComponent({
            id: this.xcomponentId,
            type: 'surface',
            libraryname: 'ijkplayer_napi'
          })
            .onLoad((event?: object) => {
              if (!!event) {
                this.initDelayPlay(event);
              }
            })
            .onDestroy(() => {
            })
            .width('100%')
            .id(this.xcomponentId)
        }
        .height('100%')

        //字幕
        if (this.subtitles.length > 0) {
          Stack() {
            Text(this.CurrentSubtitle)
              .fontSize(25)
              .fontColor(Color.White)
              .width('100%')
              .padding(20)
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
              Text(this.currentTime).fontSize(BasicConstants.FONT_SMALL).fontColor(Color.White)
              Slider({
                value: this.progressValue,
                min: 0,
                max: this.PROGRESS_MAX_VALUE,
                step: 1,
                style: SliderStyle.OutSet
              })
                .layoutWeight(1)
                .blockColor(Color.Blue)
                .trackColor(Color.Gray)
                .selectedColor(Color.Blue)
                .enabled(this.slideEnable)
                .onChange((value: number, mode: SliderChangeMode) => {
                  if (mode === SliderChangeMode.End) {
                    this.isSeekTo = true;
                    this.mDestroyPage = false;
                    this.showLoadIng();
                    let seekValue = value * (this.mIjkMediaPlayer.getDuration() / 100);
                    this.seekTo(seekValue + "");
                    this.setProgress()
                    this.isSeekTo = false;
                  }
                })
              Text(this.totalTime).fontSize(BasicConstants.FONT_SMALL).fontColor(Color.White)
            }
            .margin({ left: 20, right: 20 })
            .height(20)

            //控制按钮
            Row() {
              Row() {
                Image(this.isPlayer ? $r('app.media.ic_pause') : $r('app.media.ic_play'))
                  .height('60%')
                  .margin({ right: 10 })
                  .onClick(() => {
                    if (this.isPlayer) {
                      this.isPlayer = false
                      this.pause()
                    } else {
                      this.isPlayer = true
                      this.startPlayOrResumePlay()
                    }
                  })
                Image($r('app.media.ic_next'))
                  .height('60%')
              }
              .justifyContent(FlexAlign.Start)
              .layoutWeight(1)

              Row() {
                Text('音频')
                  .fontColor(Color.White)
                  .margin({ right: 10 })
                  .fontSize(BasicConstants.FONT_NORMAL)
                Text('字幕')
                  .fontColor(Color.White)
                  .fontSize(BasicConstants.FONT_NORMAL)
                  .onClick(() => {
                    if (this.subtitleList.length > 1) {
                      DialogUtil.showTextPicker({
                        range: this.subtitleList.map((item: SubtitleList) => item.displayLanguage),
                        canLoop: false,
                        onAccept: (result) => {
                          this.subtitlesCodec = this.subtitleList[result.index as number].codec
                          this.subtitlesId = this.subtitleList[result.index as number].index
                        }
                      })
                    }
                  })
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

        Image($r('app.media.icon_replay'))
          .objectFit(ImageFit.Auto)
          .width('120px')
          .height('120px')
          .visibility(this.replayVisible)
          .border({ width: 0 })
          .borderStyle(BorderStyle.Dashed)
          .onClick(() => {
            this.startPlayOrResumePlay();
          })
        Image($r('app.media.icon_load'))
          .objectFit(ImageFit.Auto)
          .width('120px')
          .height('120px')
          .visibility(this.loadingVisible)
          .border({ width: 0 })
          .borderStyle(BorderStyle.Dashed)
      }.width('100%').backgroundColor($r('sys.color.black')).clip(true)

      //倍数播放设置
      // Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Start }) {
      //   Button('1X')
      //     .onClick(() => {
      //       if (!this.debounce()) {
      //         return;
      //       }
      //       this.playSpeed = '1f'
      //       this.mIjkMediaPlayer.setSpeed("1f");
      //     })
      //     .width('400px')
      //     .height('80px')
      //     .margin('15px')
      //
      //   Button('1.5X')
      //     .onClick(() => {
      //       if (!this.debounce()) {
      //         return;
      //       }
      //       this.playSpeed = '1.5f'
      //       this.mIjkMediaPlayer.setSpeed("1.5f");
      //     })
      //     .width('400px')
      //     .height('80px')
      //     .margin('15px')
      //
      //   Button('2X')
      //     .onClick(() => {
      //       this.playSpeed = '2f'
      //       this.mIjkMediaPlayer.setSpeed("2f");
      //     })
      //     .width('400px')
      //     .height('80px')
      //     .margin('15px')
      // }

      //音量设置
      // Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
      //   Text('音量').width('120px').fontSize('30px').margin('15px')
      //   Slider({
      //     value: this.volume,
      //     min: 0.0,
      //     max: 1.0,
      //     step: 0.1,
      //     style: SliderStyle.OutSet
      //   })
      //     .blockColor(Color.Blue)
      //     .trackColor(Color.Gray)
      //     .selectedColor(Color.Blue)
      //     .showSteps(true)
      //     .showTips(true)
      //     .onChange((value: number, mode: SliderChangeMode) => {
      //       if (mode === SliderChangeMode.End) {
      //         this.volume = value;
      //         this.mIjkMediaPlayer.setVolume(this.volume.toString(), this.volume.toString());
      //       }
      //     })
      // }

    }
  }

  private initDelayPlay(context: object) {
    this.mContext = context;
    setTimeout(() => {
      this.startPlayOrResumePlay();
      this.mFirst = false;
    }, 300)
  }

  private startPlayOrResumePlay() {
    this.mDestroyPage = false;
    LogUtils.getInstance().LOGI("startPlayOrResumePlay start this.CONTROL_PlayStatus:" + this.CONTROL_PlayStatus)
    if (this.CONTROL_PlayStatus === PlayStatus.INIT) {
      this.stopProgressTask()
      this.startProgressTask()
      this.play(this.videoData.video)
    }
    if (this.CONTROL_PlayStatus === PlayStatus.PAUSE) {
      this.mIjkMediaPlayer.start()
      this.setProgress()
      this.CONTROL_PlayStatus = PlayStatus.PLAY
    }
  }

  private completionNum(num: number): string | number {
    if (num < 10) {
      return '0' + num;
    } else {
      return num;
    }
  }

  private stringForTime(timeMs: number): string {
    let totalSeconds: number | string = (timeMs / 1000);
    let newSeconds: number | string = totalSeconds % 60;
    let minutes: number | string = (totalSeconds / 60) % 60;
    let hours: number | string = totalSeconds / 3600;
    LogUtils.getInstance().LOGI("stringForTime hours:" + hours + ",minutes:" + minutes + ",seconds:" + newSeconds);
    hours = this.completionNum(Math.floor(Math.floor(hours * 100) / 100));
    minutes = this.completionNum(Math.floor(Math.floor(minutes * 100) / 100));
    newSeconds = Math.floor(Math.floor(newSeconds * 100) / 100)
    if (this.isCurrentTime) {
      if (this.oldSeconds < newSeconds || newSeconds === 0 || this.isSeekTo) {
        this.oldSeconds = newSeconds
      } else {
        newSeconds = this.oldSeconds
      }
    }
    newSeconds = this.completionNum(newSeconds);
    if (hours > 0) {
      return hours + ":" + minutes + ":" + newSeconds;
    } else {
      return minutes + ":" + newSeconds;
    }
  }

  private setProgress() {
    if (IjkplayerMapManager.getInstance().destroyStatusMap.get(this.xcomponentId)) {
      return;
    }
    if (!IjkplayerMapManager.getInstance().playStatusMap.get(this.xcomponentId)) {
      return;
    }
    let position = this.mIjkMediaPlayer.getCurrentPosition()
    let duration = this.mIjkMediaPlayer.getDuration();
    let pos = 0;
    if (duration > 0) {
      this.slideEnable = true;
      let curPercent = position / duration;
      pos = curPercent * 100;
      if (pos > this.PROGRESS_MAX_VALUE) {
        this.progressValue = this.PROGRESS_MAX_VALUE
      } else {
        this.progressValue = pos;
      }
    }
    LogUtils.getInstance()
      .LOGI("setProgress position:" + position + ",duration:" + duration + ",progressValue:" + pos);
    this.totalTime = this.stringForTime(duration);
    if (position > duration) {
      position = duration;
    }
    this.isCurrentTime = true;
    this.currentTime = this.stringForTime(position);
    this.isCurrentTime = false
  }

  private startProgressTask() {
    this.updateProgressTimer = setInterval(() => {
      if (IjkplayerMapManager.getInstance().destroyStatusMap.get(this.xcomponentId)) {
        clearInterval(this.updateProgressTimer);
        return;
      }
      if (!this.mDestroyPage) {
        this.setProgress();
      }
    }, 300);
  }

  private stopProgressTask() {
    LogUtils.getInstance().LOGI("stopProgressTask");
    clearInterval(this.updateProgressTimer);
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

  private play(url: string) {
    if (IjkplayerMapManager.getInstance().destroyStatusMap.get(this.xcomponentId)) {
      return;
    }
    this.showLoadIng();
    //设置XComponent回调的context
    if (!!this.mContext) {
      this.mIjkMediaPlayer.setContext(this.mContext, this.xcomponentId);
    }
    if (this.CONTROL_PlayStatus === PlayStatus.INIT) {
      this.mIjkMediaPlayer.reset();
    }
    this.CONTROL_PlayStatus = PlayStatus.PLAY;
    //设置debug模式
    this.mIjkMediaPlayer.setDebug(false);
    //初始化配置
    this.mIjkMediaPlayer.native_setup();
    // 初始化配置后需要重新设置音频流音量，否则音量为默认值1.0
    this.mIjkMediaPlayer.setVolume(this.volume.toString(), this.volume.toString());
    //设置视频源
    this.mIjkMediaPlayer.setDataSource(url);
    //设置视频源http请求头
    // let headers = new Map([
    //   ["user_agent", "Mozilla/5.0 BiliDroid/7.30.0 (bbcallen@gmail.com)"],
    //   ["referer", "https://www.bilibili.com"]
    // ]);
    // this.mIjkMediaPlayer.setDataSourceHeader(headers);
    //使用精确寻帧 例如，拖动播放后，会寻找最近的关键帧进行播放，很有可能关键帧的位置不是拖动后的位置，而是较前的位置.可以设置这个参数来解决问题
    this.mIjkMediaPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "enable-accurate-seek", "1");
    //预读数据的缓冲区大小
    this.mIjkMediaPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "max-buffer-size", "102400");
    //停止预读的最小帧数
    this.mIjkMediaPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "min-frames", "100");
    //启动预加载
    this.mIjkMediaPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "start-on-prepared", "1");
    // 设置无缓冲，这是播放器的缓冲区，有数据就播放
    this.mIjkMediaPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "packet-buffering", "0");
    //跳帧处理,放CPU处理较慢时，进行跳帧处理，保证播放流程，画面和声音同步
    this.mIjkMediaPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "framedrop", "5");
    // 最大缓冲cache是3s， 有时候网络波动，会突然在短时间内收到好几秒的数据
    // 因此需要播放器丢包，才不会累积延时
    // 这个和第三个参数packet-buffering无关。
    this.mIjkMediaPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "max_cached_duration", "3000");
    // // 开启h264与h265硬解码
    // this.mIjkMediaPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "mediacodec-all-videos", "1");
    // 开启h265硬解码
    // this.mIjkMediaPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "mediacodec-hevc", "1");
    // 无限制收流
    // this.mIjkMediaPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "infbuf", "1");
    // this.mIjkMediaPlayer.setOptionLong(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "infbuf", "1")
    // 屏幕常亮
    this.mIjkMediaPlayer.setScreenOnWhilePlaying(true);
    // 开启hls起播优化 默认是关闭的
    this.mIjkMediaPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_FORMAT, "fetch_first", "on");
    // 设置超时
    this.mIjkMediaPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_FORMAT, "timeout", "10000000");
    this.mIjkMediaPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_FORMAT, "connect_timeout", "10000000");
    this.mIjkMediaPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_FORMAT, "addrinfo_timeout", "10000000");
    this.mIjkMediaPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_FORMAT, "dns_cache_timeout", "10000000");
    // 变速播放
    this.mIjkMediaPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "soundtouch", "1");
    this.mIjkMediaPlayer.setSpeed(this.playSpeed);
    let Speed = this.mIjkMediaPlayer.getSpeed()
    LogUtils.getInstance().LOGI('getSpeed--' + Speed)
    //是否开启循环播放
    this.mIjkMediaPlayer.setLoopCount(false);
    let mOnVideoSizeChangedListener: OnVideoSizeChangedListener = {
      onVideoSizeChanged: (width: number, height: number, sar_num: number, sar_den: number) => {
        if (height === 0) {
          return;
        }
        const va = width / height;
        const vpa = this.videoParentAspectRatio;
        if (vpa > va) {
          this.videoWidth = (width / (height * vpa)) * 100 + '%';
        } else {
          this.videoWidth = '100%';
        }
        if (width && height) {
          this.videoAspectRatio = width / height;
        }
        LogUtils.getInstance()
          .LOGI("setOnVideoSizeChangedListener-->go:" + width + "," + height + "," + sar_num + "," + sar_den);
        this.getVideoSize()
        this.hideLoadIng()
      }
    }
    this.mIjkMediaPlayer.setOnVideoSizeChangedListener(mOnVideoSizeChangedListener);
    let mOnPreparedListener: OnPreparedListener = {
      onPrepared: () => {
        this.isSeekTo = true
        this.mDestroyPage = false
        this.seekTo(this.playbackPositionTicks + "")
        this.setProgress()
        this.isSeekTo = false
        this.onSubtitle()
        this.updateProgress()
      }
    }
    this.mIjkMediaPlayer.setOnPreparedListener(mOnPreparedListener);

    let mOnTimedTextListener: OnTimedTextListener = {
      onTimedText: () => {
      }
    }
    this.mIjkMediaPlayer.setOnTimedTextListener(mOnTimedTextListener)

    let mOnCompletionListener: OnCompletionListener = {
      onCompletion: () => {
        LogUtils.getInstance().LOGI("OnCompletionListener-->go")
        this.showRePlay();
        this.currentTime = this.stringForTime(this.mIjkMediaPlayer.getDuration());
        this.progressValue = this.PROGRESS_MAX_VALUE;
        this.slideEnable = false;
        this.stop();
      }
    }
    this.mIjkMediaPlayer.setOnCompletionListener(mOnCompletionListener);

    let mOnBufferingUpdateListener: OnBufferingUpdateListener = {
      onBufferingUpdate: (percent: number) => {
        // LogUtils.getInstance().LOGI("OnBufferingUpdateListener-->go:" + percent);
        // let MediaInfo = this.mIjkMediaPlayer.getMediaInfo()
        // LogUtils.getInstance().LOGI('getMediaInfo---' + MediaInfo);
        // let VideoWidth = this.mIjkMediaPlayer.getVideoWidth()
        // LogUtils.getInstance().LOGI('getVideoWidth---' + VideoWidth);
        //
        // let VideoHeight = this.mIjkMediaPlayer.getVideoHeight()
        // LogUtils.getInstance().LOGI('getVideoHeight---' + VideoHeight);
        //
        // let VideoSarNum = this.mIjkMediaPlayer.getVideoSarNum()
        // LogUtils.getInstance().LOGI('getVideoSarNum---' + VideoSarNum);
        //
        // let VideoSarDen = this.mIjkMediaPlayer.getVideoSarDen()
        // LogUtils.getInstance().LOGI('getVideoSarDen---' + VideoSarDen);
        //
        // let AudioSessionId = this.mIjkMediaPlayer.getAudioSessionId()
        // LogUtils.getInstance().LOGI('getAudioSessionId---' + AudioSessionId);
        //
        // let Looping = this.mIjkMediaPlayer.isLooping()
        // LogUtils.getInstance().LOGI('isLooping---' + Looping);
      }
    }
    this.mIjkMediaPlayer.setOnBufferingUpdateListener(mOnBufferingUpdateListener);

    let mOnSeekCompleteListener: OnSeekCompleteListener = {
      onSeekComplete: () => {
        LogUtils.getInstance().LOGI("OnSeekCompleteListener-->go");
        this.startPlayOrResumePlay()
      }
    }
    this.mIjkMediaPlayer.setOnSeekCompleteListener(mOnSeekCompleteListener);

    let mOnInfoListener: OnInfoListener = {
      onInfo: (what: number, extra: number) => {
        LogUtils.getInstance().LOGI("OnInfoListener-->go:" + what + "===" + extra);
        this.hideLoadIng()
      }
    }
    this.mIjkMediaPlayer.setOnInfoListener(mOnInfoListener);


    let mOnErrorListener: OnErrorListener = {
      onError: (what: number, extra: number) => {
        this.stopProgressTask();
        LogUtils.getInstance().LOGI("OnErrorListener-->go:" + what + "===" + extra)
        this.hideLoadIng();
        try {
          this.getUIContext().getPromptAction().showToast({
            message: this.getUIContext()
              .getHostContext()?.resourceManager.getStringByNameSync("视频播放失败")
          });
        } catch (error) {
          console.log(error)
        }
      }
    }

    this.mIjkMediaPlayer.setOnErrorListener(mOnErrorListener);

    this.mIjkMediaPlayer.setMessageListener();

    this.mIjkMediaPlayer.prepareAsync();

    this.mIjkMediaPlayer.start()

    IjkplayerMapManager.getInstance().playStatusMap.set(this.xcomponentId, true);

  }

  private getVideoSize() {
    let VideoWidth = this.mIjkMediaPlayer.getVideoWidth();
    LogUtils.getInstance().LOGI("getVideoWidth---" + VideoWidth);

    let VideoHeight = this.mIjkMediaPlayer.getVideoHeight();
    LogUtils.getInstance().LOGI("getVideoHeight---" + VideoHeight);
  }

  private pause() {
    if (this.mIjkMediaPlayer.isPlaying()) {
      this.mIjkMediaPlayer.pause();
      this.setProgress();
      this.mDestroyPage = true;
      this.CONTROL_PlayStatus = PlayStatus.PAUSE;
    }
  }

  private stop() {
    if (!IjkplayerMapManager.getInstance().playStatusMap.get(this.xcomponentId)) {
      return;
    }
    this.CONTROL_PlayStatus = PlayStatus.INIT;
    this.mIjkMediaPlayer.stop();
    this.mIjkMediaPlayer.release();
    this.stopProgressTask();
  }

  private seekTo(value: string) {
    this.mIjkMediaPlayer.seekTo(value)
    this.seekToSubtitle()
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
    const currentTime = this.mIjkMediaPlayer.getCurrentPosition()
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

  private updateProgress() {
    if (this.CONTROL_PlayStatus === PlayStatus.INIT) {
      return
    }
    setTimeout(() => {
      if (this.CONTROL_PlayStatus === PlayStatus.PLAY) {
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