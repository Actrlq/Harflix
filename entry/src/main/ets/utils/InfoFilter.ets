import { MediaStreams } from "../viewmodel/DataConstraints"

export interface SubtitleList {
  codec: string // 编解码器
  index: number // 序号
  displayLanguage: string // 字幕语言
  type: string // 类型
  isDefault: boolean // 默认值
}

export interface VideoInfo {
  displayTitle: string // 标题
  bitrate: number // 比特率
  averageFramerate: number // 帧率
  videoRange: string // 动态范围
}

export interface AudioList {
  codec: string // 编码器
  displayTitle: string // 标题
  displayLanguage: string // 显示音频
  index: number // 序号
  isDefault: boolean // 默认值
}

export class InfoFilter {
  private subtitles: SubtitleList[] = []
  private videoInfo: VideoInfo[] = []
  private audio: AudioList[] = []

  //筛选字幕
  filterSubtitle(resText: MediaStreams[]) {
    const lists: SubtitleList[] = []
    for (const res of resText) {
      if (res.Type === 'Subtitle' && res.Codec != 'PGSSUB') {

        const codec = res.Codec
        const index = res.Index
        const displayLanguage = res.DisplayLanguage
        const type = res.Type
        const isDefault = res.IsDefault

        const subtitle: SubtitleList = {
          codec: codec,
          index: index,
          displayLanguage: displayLanguage,
          type: type,
          isDefault: isDefault
        }
        lists.push(subtitle)
      }
    }
    this.subtitles = lists
    return this.subtitles
  }

  //视频信息
  filterVideoInfo(resText: MediaStreams[]) {
    const data: VideoInfo[] = []
    for (const res of resText) {
      if (res.Type === 'Video') {
        const displayTitle = res.DisplayTitle
        const bit = res.BitRate
        const averageFramerate = res.AverageFrameRate
        const videoRange = res.VideoRange

        //转换比特率Mbps
        const bitrate = bit * (1 / (1024 * 1024))

        const video: VideoInfo = {
          displayTitle: displayTitle,
          bitrate: bitrate,
          averageFramerate: averageFramerate,
          videoRange: videoRange,
        }
        data.push(video)
      }
    }
    this.videoInfo = data
    return this.videoInfo
  }

  //筛选音频
  filterAudio(resText: MediaStreams[]){
    const lists: AudioList[] = []
    for (const res of resText) {
      if (res.Type === 'Audio') {

        const codec = res.Codec
        const index = res.Index
        const displayLanguage = res.DisplayLanguage
        const displayTitle = res.DisplayTitle
        const isDefault = res.IsDefault

        const audio: AudioList = {
          codec: codec,
          index: index,
          displayLanguage: displayLanguage,
          displayTitle: displayTitle,
          isDefault: isDefault
        }
        lists.push(audio)
      }
    }
    this.audio = lists
    return this.audio
  }

}