// 1. import 需要的 socket 模块。
import socket from '@ohos.net.socket';
import promptAction from '@ohos.promptAction';

const TAG = "TCPClientManager";


class SocketInfo {
  message: ArrayBuffer = new ArrayBuffer(1);
  remoteInfo: socket.SocketRemoteInfo = {} as socket.SocketRemoteInfo;
}

/**
 * 全局tcp工具
 */
export class TCPClientManager {
  /**私有静态实例，懒汉式单例*/
  private static instance: TCPClientManager;

  /**私有构造方法，防止外部直接实例化*/
  private constructor() {
  }

  /**提供一个公共的静态方法返回实例对象*/
  public static getInstance(): TCPClientManager {
    // 如果对象单例不存在那么构建对象
    if (!TCPClientManager.instance)
      TCPClientManager.instance = new TCPClientManager();
    return TCPClientManager.instance;
  }

  /** 服务器对象 */
  private socket: socket.TCPSocket  = socket.constructTCPSocketInstance();
  /**
   * 网络配置类
   */
  private options: socket.TCPConnectOptions = {
    address: {
      address: "127.0.0.1",
      // family?: number,
      port: 12345
    },
    timeout: 3000
  }

  /**
   * 留给外部给网路信息初始化的接口
   * @param netAddress
   */
  initNetAddress(netAddress: socket.NetAddress) {
    console.log(TAG, 'initNetAddress', JSON.stringify(netAddress))

    if (netAddress.address) this.options.address.address = netAddress.address;
    if (netAddress.family) this.options.address.family = netAddress.family;
    if (netAddress.port) this.options.address.port = netAddress.port;
  }

  /**
   * 初始化连接（可以在需要时调用，或者放在构造方法中）
   * @returns 是否连接成功
   */
  public async connect() {
    const wasConnected = await this.isConnect();
    if (wasConnected) {
      this.socket.close();
    }

    this.socket = socket.constructTCPSocketInstance();
    try {
      // 绑定目标服务端IP地址
      await this.socket.connect(this.options)
      this.showInfo(`连接成功`)
      // 信号接收
      this.socket.on("message", (value: SocketInfo) => {

        console.log(TAG, `receiveMessage`, "message")
        let messageView = '';

        // 拼接字符串
        for (let i: number = 0; i < value.message.byteLength; i++) {
          let uint8Array = new Uint8Array(value.message);
          let messages = uint8Array[i];
          let message = String.fromCharCode(messages);
          messageView += message;
        }

        console.log(TAG, `receiveMessage`, messageView)
        // 接受数据 , 这里使用try catch 包裹是为了防止拿到垃圾数导致闪退
        try {
          TCPClientManager._receiveMessage(messageView);
        } catch (e) {
          console.error(TAG, "MESSAGE ERROR", JSON.stringify(e))
        }


      })
      return true;
    } catch (e) {
      console.error(TAG, 'connect failed', JSON.stringify(e))
      // 如果连接失败需要断开连接
      // 在Mate50 HarmonyOS 4.2.0.130 API 9上连接失败 如果不断开导致下次无法正常连接
      this.socket.close();
      // this.socket = undefined;
      return false;
    }


  }

  /**
   * 判断网络是否连接成功
   * @returns
   */
  public async isConnect() {
    //如果没有创建socket连接，那么就算没有连接
    if (this.socket == null)
      return false;

    let state: socket.SocketStateBase | undefined = undefined;

    try {
      state = await this.socket.getState();
    } catch (e) {
      console.error(TAG, 'getState failed', JSON.stringify(e))
      return false;
    }
    console.log(TAG, `isConnect`,
      `isClose = ${state.isClose} ` +
        `isConnected = ${state.isConnected}`)
    // 如果没有断开连接 && 已经成功连接上
    return state.isClose == false
      && state.isConnected == true;
  }

  /**
   * 发送数据
   * @param message
   * @returns 是否连接成功
   */
  public async sendMessage(message: string) {
    console.log(TAG, `sendMessage called, target=${this.options.address.address}:${this.options.address.port}, message=${message}`)
    const isConnected = await this.isConnect();
    console.log(TAG, `sendMessage connection status: ${isConnected}`)
    
    if (isConnected == true) {
      console.log(TAG, `sendMessage sending data: ${message}`)
      try {
        await this.socket.send({ data: message })
        console.log(TAG, `sendMessage success: ${message}`)
        return true
      } catch (e) {
        console.error(TAG, `sendMessage failed with error: ${JSON.stringify(e)}`)
        return false
      }
    }

    console.log(TAG, 'sendMessage connection lost, reconnecting...')
    if (await this.connect()) {
      console.log(TAG, `sendMessage reconnected, sending data: ${message}`)
      try {
        await this.socket.send({ data: message })
        console.log(TAG, `sendMessage success after reconnect: ${message}`)
        return true;
      } catch (e) {
        console.error(TAG, `sendMessage failed after reconnect: ${JSON.stringify(e)}`)
        return false
      }
    }
    console.error(TAG, `sendMessage failed: could not reconnect`)
    return false;

  }

  public async sendMessageToPort(port: number, message: string): Promise<boolean> {
    console.log(TAG, `sendMessageToPort called, port=${port}, address=${this.options.address.address}, message=${message}`);
    const tempSocket = socket.constructTCPSocketInstance();
    try {
      console.log(TAG, `sendMessageToPort binding to 0.0.0.0`);
      await tempSocket.bind({ address: '0.0.0.0', family: 1 });
      console.log(TAG, `sendMessageToPort connecting to ${this.options.address.address}:${port}`);
      await tempSocket.connect({
        address: {
          address: this.options.address.address,
          family: this.options.address.family,
          port: port
        },
        timeout: 3000
      });
      console.log(TAG, `sendMessageToPort connected successfully`);
      console.log(TAG, `sendMessageToPort sending: ${message}`);
      await tempSocket.send({ data: message });
      console.log(TAG, `sendMessageToPort send success`);
      tempSocket.close();
      return true;
    } catch (e) {
      console.error(TAG, `sendMessageToPort failed, port=${port}, address=${this.options.address.address}, error=${JSON.stringify(e)}, message=${message}`);
      try {
        tempSocket.close();
      } catch (closeErr) {
        console.error(TAG, `sendMessageToPort close failed: ${JSON.stringify(closeErr)}`);
      }
      return false;
    }
  }

  public async requestMessageFromPort(port: number, message: string): Promise<string> {
    const tempSocket = socket.constructTCPSocketInstance();
    let finished: boolean = false;
    try {
      await tempSocket.bind({ address: '0.0.0.0', family: 1 })
      await tempSocket.connect({
        address: {
          address: this.options.address.address,
          family: this.options.address.family,
          port: port
        },
        timeout: 3000
      })

      const responsePromise: Promise<string> = new Promise((resolve, reject): void => {
        const timer: number = setTimeout((): void => {
          if (finished) {
            return;
          }
          finished = true;
          tempSocket.close();
          reject(new Error('request timeout'));
        }, 3000);

        tempSocket.on('message', (value: SocketInfo): void => {
          if (finished) {
            return;
          }
          finished = true;
          clearTimeout(timer);
          const messageView = TCPClientManager.bufferToString(value.message);
          tempSocket.close();
          resolve(messageView);
        })

        tempSocket.on('close', (): void => {
          if (finished) {
            return;
          }
          finished = true;
          clearTimeout(timer);
          reject(new Error('socket closed'));
        })
      });

      await tempSocket.send({ data: message })
      return await responsePromise;
    } catch (e) {
      console.error(TAG, 'requestMessageFromPort failed', JSON.stringify(e))
      if (!finished) {
        tempSocket.close();
      }
      return '';
    }
  }

  /**关闭连接*/
  public closeConnection() {
    this.socket.close()
  }

  /**
   * 日志输出
   * @param message
   */
  private showInfo(message: string) {
    promptAction.showToast({ message: message })
    console.log(TAG, message)
  }

  /**接收数据*/
  private static _receiveMessage = (message: string) => {
  };

  private static bufferToString(buffer: ArrayBuffer): string {
    let messageView = '';
    const uint8Array = new Uint8Array(buffer);
    for (let i: number = 0; i < buffer.byteLength; i++) {
      messageView += String.fromCharCode(uint8Array[i]);
    }
    return messageView;
  }

  /** 接收数据的setder */
  public static set receiveMessage(value: (message: string) => void) {
    TCPClientManager._receiveMessage = value;
  }
}
