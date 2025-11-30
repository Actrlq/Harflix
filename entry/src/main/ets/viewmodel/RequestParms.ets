export class AuthenticateByName {
  Username: string = ''
  Password: string = ''
  Pw: string = ''
}

export class PlayInfo {
  MaxStreamingBitrate: number = 50000000
  DeviceProfile: DeviceProfile = new DeviceProfile
}

class DeviceProfile {
  MaxStaticBitrate: number = 50000000
  MaxStreamingBitrate: number = 50000000
  MusicStreamingTranscodingBitrate: number = 50000000
  DirectPlayProfiles: Array<DirectPlayProfiles> = [new DirectPlayProfiles]
}

class DirectPlayProfiles {
  Container: string =
    "mkv,mp4,flv,f4v,f4p,f4a,f4b,swf,rmvb,rm,vob,ogm,ogv,avi,mov,wmv,qt,divx,dv,asf,wtv,mpg,mpeg,mpeg1,mpeg2,m1v,m2v,mpv,mpeg4,m4v,m2p,ps,ts, m2ts,mts,mt2s,3gp,3gpp,3g2,3gp2,webm,dat,amv,mxf,mcf,xvid,yuv"
  Type: string = "Video"
  VideoCodec: string = "h264,hevc,dvhe,dvh1,hev1,mpeg4,vp8,mpeg,vp9,vc1,mpeg2video,rv40,wmv2,wmv3,av1,dva1,dvav"
  AudioCodec: string =
    "aac,aac_latm,mp3,mp2,pcm_s16le,pcm_s24le,pcm_s32le,wav,ac3,eac3,flac,truehd,dts,dtshd,dca,opus,wmav2,wmav3,cook"
}

export class Progress {
  PositionTicks: number = 0
  PlaySessionId: string = ''
  MediaSourceId: string = ''
  ItemId: string = ''
  EventName: string = ''
}