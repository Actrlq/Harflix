import { mediaquery } from '@kit.ArkUI';

export class MediaQueryUtil {
  private MediaQueryText: string = 'sm';

  //媒体查询条件
  private xslistener = mediaquery.matchMediaSync('(0vp <= device-width < 320vp)');
  private smlistener = mediaquery.matchMediaSync('(320vp <= device-width < 600vp)');
  private mdlistener = mediaquery.matchMediaSync('(600vp <= device-width < 840vp)');
  private lglistener = mediaquery.matchMediaSync('(840vp <= device-width < 1440vp)');
  private xllistener = mediaquery.matchMediaSync('(1440vp <= device-width)');

  // 当满足媒体查询条件时，触发回调
  private updatelistener(returnvalue:string) {
      if (this.MediaQueryText !== returnvalue){
        this.MediaQueryText = returnvalue;
        AppStorage.setOrCreate<string>('MediaQueryText',this.MediaQueryText)
      }
  }

  // 绑定回调函数
  private listenerxs = (mediaQueryResult:mediaquery.MediaQueryResult) => {
    if (mediaQueryResult.matches) {
      this.updatelistener('xs')
    }
  }
  private listenersm = (mediaQueryResult:mediaquery.MediaQueryResult) => {
    if (mediaQueryResult.matches) {
      this.updatelistener('sm')
    }
  }
  private listenermd = (mediaQueryResult:mediaquery.MediaQueryResult) => {
    if (mediaQueryResult.matches) {
      this.updatelistener('md')
    }
  }
  private listenerlg = (mediaQueryResult:mediaquery.MediaQueryResult) => {
    if (mediaQueryResult.matches) {
      this.updatelistener('lg')
    }
  }
  private listenerxl = (mediaQueryResult:mediaquery.MediaQueryResult) => {
    if (mediaQueryResult.matches) {
      this.updatelistener('xl')
    }
  }

  // 注册的回调函数
  public  register(){
    this.xslistener = mediaquery.matchMediaSync('(0vp <= device-width < 320vp)');
    this.xslistener.on('change',this.listenerxs);
    this.smlistener = mediaquery.matchMediaSync('(320vp <= device-width < 600vp)');
    this.smlistener.on('change',this.listenersm);
    this.mdlistener = mediaquery.matchMediaSync('(600vp <= device-width < 840vp)');
    this.mdlistener.on('change',this.listenermd);
    this.lglistener = mediaquery.matchMediaSync('(840vp <= device-width < 1440vp)');
    this.lglistener.on('change',this.listenerlg);
    this.xllistener = mediaquery.matchMediaSync('(1440vp <= device-width)');
    this.xllistener.on('change',this.listenerxl);
  }
  //解绑监听
  public unregister(){
    this.xslistener.off('change',this.listenerxs);
    this.smlistener.off('change',this.listenersm);
    this.mdlistener.off('change',this.listenermd);
    this.lglistener.off('change',this.listenerlg);
    this.xllistener.off('change',this.listenerxl);
  }


}

