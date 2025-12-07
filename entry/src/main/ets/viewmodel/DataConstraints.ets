export class UserServerInformation {
  ServerName?: string
  ServerUrl?: string
  Username?: string
  Password?: string
}

export class ServerViews {
  Items: Array<SVItems> = []
  TotalRecordCount: number = 0
}

export class SVItems {
  Name: string = ''
  Id: string = ''
  Guid: string = ''
  Type: string = ''
}

export class ImportantInformation {
  User: Array<User> = []
  SessionInfo: Record<string, object> = {}
  AccessToken: string = ''
  ServerId: string = ''
}

export class User {
  Name: string = ''
  Id: string = ''
}

export class NewViewsList {
  Name: string = ''
  Id: string = ''
  Path: string = ''
  OfficialRating: string = ''
  CommunityRating: number = 0
  RunTimeTicks: number = 0
  ProductionYear: number = 0
  Type: string = ''
  ImageTags: Array<ImageTags> = []
}

export class ImageTags {
  Primary: string = ''
  Thumb: string = ''
}

export class ViewingRecord {
  Items: Array<VRItems> = []
  TotalRecordCount: number = 0
}


export class VRItems {
  Name: string = ''
  Id: string = ''
  RunTimeTicks: number = 0
  ProductionYear: number = 0
  IndexNumber: number = 1
  ParentIndexNumber: number = 1
  IsFolder: boolean = false
  ParentBackdropItemId: string = ''
  SeriesName: string = ''
  SeriesId: string = ''
  SeasonId: string = ''
  SeasonName: string = ''
  UserData: Array<UserData> = []
  Type: string = ''
}

export class DetailsModel {
  Name: string = ''
  OriginalTitle: string = ''
  Id: string = ''
  PresentationUniqueKey: string = ''
  PremiereDate: string = ''
  Path: string = ''
  OfficialRating: string = ''
  Overview: string = ''
  Genres: string[] = []
  CommunityRating: number = 0
  ProductionYear: number = 0
  ChildCount: number = 1
  UserData: Array<UserData> = []
  People:Array<ActorInformation> = []
}

export class SeasonListModel {
  Items: Array<SLItems> = []
  TotalRecordCount: number = 0
}

export class SLItems {
  Name: string = ''
  Id: string = ''
  IndexNumber: number = 1
  UserData: Array<UserData> = []
}

export class UserData {
  PlayedPercentage: number = 0
  PlaybackPositionTicks: number = 0
  PlayCount: number = 0
  IsFavorite: boolean = false
  Played: boolean = false
}

export class PlaybackInfo {
  MediaSources: Array<MediaSources> = []
  PlaySessionId: string = ''
}

export class MediaSources {
  Id: string = ''
  Path: string = ''
  Type: string = ''
  Container: string = ''
  Size: number = 0
  Name: string = ''
  RunTimeTicks: number = 0
  MediaStreams: Array<MediaStreams> = []
  Bitrate: number = 0
  DirectStreamUrl: string = ''
  DefaultAudioStreamIndex: number = 1
  DefaultSubtitleStreamIndex: number = 1
  UserData: Array<UserData> = []
}

export class MediaStreams {
  Codec: string = ''
  Language: string = ''
  ColorTransfer: string = ''
  ColorPrimaries: string = ''
  ColorSpace: string = ''
  Title: string = ''
  TimeBase: string = ''
  VideoRange: string = ''
  DisplayTitle: string = ''
  DisplayLanguage: string = ''
  BitRate: number = 0
  BitDepth: number = 0
  Height: number = 0
  Width: number = 0
  AverageFrameRate: number = 0
  RealFrameRate: number = 0
  Profile: string = ''
  Type: string = ''
  AspectRatio: string = ''
  Index: number = 0
  PixelFormat: string = ''
  ExtendedVideoType: string = ''
  ExtendedVideoSubType: string = ''
  ExtendedVideoSubTypeDescription: string = ''
  AttachmentSize: number = 0
  ChannelLayout: string = ''
  Channels: number = 0
  SampleRate: number = 0
  SubtitleLocationType: string = ''
  DeliveryMethod: string = ''
  IsDefault: boolean = true
}

export class UserInfo {
  serverUrl: string = ''
  username: string = ''
  token: string = ''
  serverId: string = ''
  servername: string = ''
  userId: string = ''
  address: string = ''
  http: string = 'https'
  port: string = ''
}

export class SystemInfo {
  ServerName: string = ''
  Version: string = ''
  Id: string = ''
}

export class ActorInformation {
  Name?: string
  Id?: string
  Role?: string
  Type?: string
  PrimaryImageTag?: string
}