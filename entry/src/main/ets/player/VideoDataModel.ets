import { AudioList, SubtitleList } from "../utils/InfoFilter"
import { SubtitleItem } from "../utils/SubtitleProcessor"

export class VideoDataModel {
  videoSrc: string = ''
  name: string = ''
  videoId: string = ''
  mediaSourceId: string = ''
  playSessionId: string = ''
  subtitleList: SubtitleList[] = []
  subtitles: SubtitleItem[] = []
  audioList: AudioList[] = []
  audioId: number = 1
  subtitlesId: number = 3
}