import preferences from '@ohos.data.preferences';

export const DEFAULT_CAR_IP = '192.168.43.5';
export const DEFAULT_TCP_PORT = '12345';
export const LIDAR_SNAPSHOT_PORT = 6000;
export const DEFAULT_VIDEO_PORT = '6500';

/**首选项对象*/
export class PreferencesUtils {
  /**私有静态实例，懒汉式单例*/
  private static instance: PreferencesUtils | undefined = undefined;

  /**私有构造方法，防止外部直接实例化*/
  private constructor() {
  }

  /**提供一个公共的静态方法返回实例对象*/
  public static getInstance(): PreferencesUtils {
    // 如果对象单例不存在那么构建对象
    if (!PreferencesUtils.instance)
      PreferencesUtils.instance = new PreferencesUtils();
    return PreferencesUtils.instance;
  }

  /**网络工具对象*/
  netUtils: NetInfoPreferencesUtils | undefined = undefined

  /*
    * 初始化preferences实例
    * @context  应用上下文
   */
  async init(context: Context): Promise<void> {
    this.netUtils = new NetInfoPreferencesUtils(context)
  }
}

/**
 * 网络配置首选项工具
 */
export class NetInfoPreferencesUtils {
  /**首选项名称*/
  public static readonly NAME = "net_preferences_utils"
  /**KEY IP*/
  public static readonly KEY_IP = "KEY_IP";
  /**KEY IP*/
  public static readonly KEY_TCP_PORT = "KEY_TCP_PORT";
  /**KEY IP*/
  public static readonly KEY_VIDEO_PORT = "KEY_TCP_VIDEO";
  /**首选项实例*/
  private pref: preferences.Preferences | undefined = undefined

  /**构造函数*/
  constructor(context: Context) {
    this.init(context)
  }

  /**初始化首首选项实例*/
  private async init(context: Context): Promise<void> {
    let name = NetInfoPreferencesUtils.NAME;
    try {
      this.pref = await preferences.getPreferences(context, name)
      console.log(`preferences[${name}]初始化成功`)
    } catch (err) {
      console.error(`preferences[${name}]初始化失败`)
      console.error('err: ', JSON.stringify(err))
    }
  }

  // ------------------------------对外接口------------------------------

  getIP(): Promise<preferences.ValueType> {
    if (!this.pref) {
      return Promise.resolve(DEFAULT_CAR_IP)
    }
    return this.pref.get(NetInfoPreferencesUtils.KEY_IP, DEFAULT_CAR_IP)
  }

  setIp(v: string): void {
    if (!this.pref) {
      return
    }
    this.pref.put(NetInfoPreferencesUtils.KEY_IP, v);
    this.pref.flush()
  }


  getTcpPort(): Promise<preferences.ValueType> {
    if (!this.pref) {
      return Promise.resolve(DEFAULT_TCP_PORT)
    }
    return this.pref.get(NetInfoPreferencesUtils.KEY_TCP_PORT, DEFAULT_TCP_PORT)
  }

  setTcpPort(v: string): void {
    if (!this.pref) {
      return
    }
    this.pref.put(NetInfoPreferencesUtils.KEY_TCP_PORT, v);
    this.pref.flush()
  }

  setVideoPort(v: string): void {
    if (!this.pref) {
      return
    }
    this.pref.put(NetInfoPreferencesUtils.KEY_VIDEO_PORT, v);
    this.pref.flush()
  }

  getVideoPort(): Promise<preferences.ValueType> {
    if (!this.pref) {
      return Promise.resolve(DEFAULT_VIDEO_PORT)
    }
    return this.pref.get(NetInfoPreferencesUtils.KEY_VIDEO_PORT, DEFAULT_VIDEO_PORT)
  }
}

