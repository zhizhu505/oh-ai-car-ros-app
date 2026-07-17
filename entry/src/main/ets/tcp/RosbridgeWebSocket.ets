import socket from '@ohos.net.socket';

const TAG = 'RosbridgeWebSocket';

type WsTextHandler = (message: string) => void;
type WsDisconnectHandler = () => void;

interface WsMessageEvent {
  message: ArrayBuffer;
}

interface RosMessageData {
  data: string;
}

interface RosPublishMessage {
  op: string;
  topic: string;
  msg: RosMessageData;
}

interface RosSubscribeMessage {
  op: string;
  topic: string;
}

export class RosbridgeWebSocket {
  private static instance: RosbridgeWebSocket;
  private tcpSocket: socket.TCPSocket = socket.constructTCPSocketInstance();
  private connected: boolean = false;
  private handshakeComplete: boolean = false;
  private messageHandler: WsTextHandler | null = null;
  private disconnectHandler: WsDisconnectHandler | null = null;
  private receiveBuffer: Uint8Array = new Uint8Array(0);
  private resolveConnect: ((value: boolean) => void) | null = null;
  private wsKey: string = '';

  private constructor() {}

  public static getInstance(): RosbridgeWebSocket {
    if (!RosbridgeWebSocket.instance) {
      RosbridgeWebSocket.instance = new RosbridgeWebSocket();
    }
    return RosbridgeWebSocket.instance;
  }

  setMessageHandler(handler: WsTextHandler): void {
    this.messageHandler = handler;
  }

  async connect(ip: string): Promise<boolean> {
    if (this.connected) {
      await this.close();
    }

    this.tcpSocket = socket.constructTCPSocketInstance();
    this.receiveBuffer = new Uint8Array(0);
    this.connected = false;
    this.handshakeComplete = false;
    this.wsKey = this.generateWsKey();

    return new Promise<boolean>((resolve): void => {
      this.resolveConnect = resolve;
      this.registerSocketEvents(ip);

      const address: socket.NetAddress = {
        address: ip,
        port: 9090
      };
      const connectOptions: socket.TCPConnectOptions = {
        address: address,
        timeout: 5000
      };
      this.tcpSocket.connect(connectOptions).then((): void => {
        this.sendHandshake(ip);
      }).catch((err: Error): void => {
        console.error(TAG, 'TCP connect failed:', err);
        this.finishConnect(false);
      });

      setTimeout((): void => {
        if (!this.connected) {
          this.finishConnect(false);
        }
      }, 5000);
    });
  }

  private registerSocketEvents(ip: string): void {
    this.tcpSocket.on('message', (value: WsMessageEvent): void => {
      this.appendBuffer(new Uint8Array(value.message));
      this.processReceivedData(ip);
    });

    this.tcpSocket.on('close', (): void => {
      console.info(TAG, 'TCP connection closed');
      this.connected = false;
      this.handshakeComplete = false;
    });

    this.tcpSocket.on('error', (err: Error): void => {
      console.error(TAG, 'TCP connection error:', err);
      this.connected = false;
      this.handshakeComplete = false;
      this.finishConnect(false);
    });
  }

  private finishConnect(ok: boolean): void {
    if (this.resolveConnect) {
      this.resolveConnect(ok);
      this.resolveConnect = null;
    }
  }

  private generateWsKey(): string {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    let key = '';
    for (let i = 0; i < 24; i++) {
      key += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return key + '==';
  }

  private sendHandshake(ip: string): void {
    const handshake =
      `GET / HTTP/1.1\r\n` +
      `Host: ${ip}:9090\r\n` +
      `Upgrade: websocket\r\n` +
      `Connection: Upgrade\r\n` +
      `Sec-WebSocket-Key: ${this.wsKey}\r\n` +
      `Sec-WebSocket-Version: 13\r\n\r\n`;

    const sendOptions: socket.TCPSendOptions = { data: this.stringToArrayBuffer(handshake) };
    this.tcpSocket.send(sendOptions).then((): void => {
      console.info(TAG, 'WebSocket handshake sent');
    }).catch((err: Error): void => {
      console.error(TAG, 'Handshake send failed:', err);
      this.finishConnect(false);
    });
  }

  private appendBuffer(newData: Uint8Array): void {
    const combined = new Uint8Array(this.receiveBuffer.length + newData.length);
    combined.set(this.receiveBuffer, 0);
    combined.set(newData, this.receiveBuffer.length);
    this.receiveBuffer = combined;
  }

  private processReceivedData(ip: string): void {
    if (!this.handshakeComplete) {
      const text = this.bufferToString(this.receiveBuffer);
      const headerEnd = text.indexOf('\r\n\r\n');
      if (headerEnd === -1) {
        return;
      }
      this.handshakeComplete = true;
      this.connected = true;
      console.info(TAG, 'WebSocket handshake success:', text.substring(0, headerEnd));
      this.receiveBuffer = new Uint8Array(this.receiveBuffer.buffer.slice(headerEnd + 4));
      this.finishConnect(true);
      if (this.receiveBuffer.length > 0) {
        this.processWsFrames();
      }
      return;
    }
    this.processWsFrames();
  }

  private processWsFrames(): void {
    while (this.receiveBuffer.length >= 2) {
      const firstByte = this.receiveBuffer[0];
      const secondByte = this.receiveBuffer[1];
      const opcode = firstByte & 0x0F;
      const masked = (secondByte & 0x80) !== 0;
      let payloadLength = secondByte & 0x7F;
      let headerSize = 2;
      let maskStart = -1;

      if (payloadLength === 126) {
        if (this.receiveBuffer.length < 4) {
          return;
        }
        payloadLength = (this.receiveBuffer[2] << 8) | this.receiveBuffer[3];
        headerSize = masked ? 8 : 4;
        maskStart = masked ? 4 : -1;
      } else if (payloadLength === 127) {
        if (this.receiveBuffer.length < 10) {
          return;
        }
        payloadLength = 0;
        for (let i = 0; i < 8; i++) {
          payloadLength = payloadLength * 256 + this.receiveBuffer[2 + i];
        }
        headerSize = masked ? 14 : 10;
        maskStart = masked ? 10 : -1;
      } else if (masked) {
        maskStart = 2;
        headerSize = 6;
      }

      if (this.receiveBuffer.length < headerSize + payloadLength) {
        return;
      }

      const payloadStart = headerSize;
      const payload = this.receiveBuffer.slice(payloadStart, payloadStart + payloadLength);
      if (maskStart >= 0) {
        const maskKey = this.receiveBuffer.slice(maskStart, maskStart + 4);
        for (let i = 0; i < payload.length; i++) {
          payload[i] = payload[i] ^ maskKey[i % 4];
        }
      }

      if (opcode === 0x01) {
        const text = this.bufferToString(payload);
        if (this.messageHandler) {
          this.messageHandler(text);
        }
      } else if (opcode === 0x08) {
        this.connected = false;
        this.handshakeComplete = false;
      } else if (opcode === 0x09) {
        this.sendPong(payload);
      }

      this.receiveBuffer = this.receiveBuffer.slice(payloadStart + payloadLength);
    }
  }

  private sendPong(payload: Uint8Array): void {
    const frame = this.buildWsFrame(0x0A, payload);
    const sendOptions: socket.TCPSendOptions = { data: frame.buffer };
    this.tcpSocket.send(sendOptions).catch((err: Error): void => {
      console.error(TAG, 'Pong send failed:', err);
    });
  }

  private buildWsFrame(opcode: number, payload: Uint8Array): Uint8Array {
    const maskKey = new Uint8Array(4);
    for (let i = 0; i < 4; i++) {
      maskKey[i] = Math.floor(Math.random() * 256);
    }

    const maskedPayload = new Uint8Array(payload.length);
    for (let i = 0; i < payload.length; i++) {
      maskedPayload[i] = payload[i] ^ maskKey[i % 4];
    }

    let header: Uint8Array;
    if (payload.length <= 125) {
      header = new Uint8Array(6);
      header[0] = 0x80 | opcode;
      header[1] = 0x80 | payload.length;
      header[2] = maskKey[0];
      header[3] = maskKey[1];
      header[4] = maskKey[2];
      header[5] = maskKey[3];
    } else if (payload.length <= 65535) {
      header = new Uint8Array(8);
      header[0] = 0x80 | opcode;
      header[1] = 0x80 | 126;
      header[2] = (payload.length >> 8) & 0xFF;
      header[3] = payload.length & 0xFF;
      header[4] = maskKey[0];
      header[5] = maskKey[1];
      header[6] = maskKey[2];
      header[7] = maskKey[3];
    } else {
      header = new Uint8Array(14);
      header[0] = 0x80 | opcode;
      header[1] = 0x80 | 127;
      for (let i = 0; i < 8; i++) {
        header[2 + i] = (payload.length >> (56 - i * 8)) & 0xFF;
      }
      header[10] = maskKey[0];
      header[11] = maskKey[1];
      header[12] = maskKey[2];
      header[13] = maskKey[3];
    }

    const frame = new Uint8Array(header.length + maskedPayload.length);
    frame.set(header, 0);
    frame.set(maskedPayload, header.length);
    return frame;
  }

  async sendTopicMessage(topic: string, data: string): Promise<boolean> {
    if (!this.connected || !this.handshakeComplete) {
      console.error(TAG, 'WebSocket not connected');
      return false;
    }

    const messageData: RosMessageData = {
      data: data
    };
    const message: RosPublishMessage = {
      op: 'publish',
      topic: topic,
      msg: messageData
    };
    return this.sendJsonMessage(message);
  }

  async subscribeTopic(topic: string): Promise<boolean> {
    if (!this.connected || !this.handshakeComplete) {
      console.error(TAG, 'WebSocket not connected');
      return false;
    }

    const message: RosSubscribeMessage = {
      op: 'subscribe',
      topic: topic
    };
    return this.sendJsonMessage(message);
  }

  private async sendJsonMessage(message: RosPublishMessage | RosSubscribeMessage): Promise<boolean> {
    const jsonStr = JSON.stringify(message);
    const payload = this.stringToUint8Array(jsonStr);
    const frame = this.buildWsFrame(0x01, payload);
    try {
      const sendOptions: socket.TCPSendOptions = { data: frame.buffer };
      await this.tcpSocket.send(sendOptions);
      return true;
    } catch (err) {
      console.error(TAG, 'Send failed:', err);
      return false;
    }
  }

  async close(): Promise<void> {
    if (this.connected || this.handshakeComplete) {
      if (this.handshakeComplete) {
        const closeFrame = this.buildWsFrame(0x08, new Uint8Array(0));
        try {
          const sendOptions: socket.TCPSendOptions = { data: closeFrame.buffer };
          await this.tcpSocket.send(sendOptions);
        } catch (err) {
          console.error(TAG, 'Close frame send failed:', err);
        }
      }
      try {
        await this.tcpSocket.close();
      } catch (err) {
        console.error(TAG, 'Close failed:', err);
      }
      this.connected = false;
      this.handshakeComplete = false;
    }
  }

  isConnected(): boolean {
    return this.connected && this.handshakeComplete;
  }

  private bufferToString(buffer: Uint8Array): string {
    let result = '';
    for (let i = 0; i < buffer.length; i++) {
      result += String.fromCharCode(buffer[i]);
    }
    return result;
  }

  private stringToUint8Array(str: string): Uint8Array {
    const arr = new Uint8Array(str.length);
    for (let i = 0; i < str.length; i++) {
      arr[i] = str.charCodeAt(i);
    }
    return arr;
  }

  private stringToArrayBuffer(str: string): ArrayBuffer {
    const buffer = new ArrayBuffer(str.length);
    const uint8Array = new Uint8Array(buffer);
    for (let i = 0; i < str.length; i++) {
      uint8Array[i] = str.charCodeAt(i);
    }
    return buffer;
  }
}
