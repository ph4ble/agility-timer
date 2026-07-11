import Taro from '@tarojs/taro';
import { DirectionSignalType } from '../models/config';
import * as Tone from './toneGenerator';

const BASE64_CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

function toBase64(bytes: Uint8Array): string {
  const len = bytes.length;
  let result = '';
  for (let i = 0; i < len; i += 3) {
    const a = bytes[i];
    const b = i + 1 < len ? bytes[i + 1] : 0;
    const c = i + 2 < len ? bytes[i + 2] : 0;
    result += BASE64_CHARS[a >> 2];
    result += BASE64_CHARS[((a & 3) << 4) | (b >> 4)];
    result += i + 1 < len ? BASE64_CHARS[((b & 15) << 2) | (c >> 6)] : '=';
    result += i + 2 < len ? BASE64_CHARS[c & 63] : '=';
  }
  return result;
}

function arrayBufferToBase64(buffer: ArrayBuffer): string {
  return 'data:audio/wav;base64,' + toBase64(new Uint8Array(buffer));
}

class AudioManager {
  private pool: Taro.InnerAudioContext[] = [];
  private poolIndex = 0;
  private tickDataUri = '';
  private signalUris: Record<string, string> = {};
  private countInUris: Record<number, string> = {};
  private countInStartUri = '';
  private countdownWarningUri = '';
  private endBellUri = '';
  private initialized = false;

  init(): void {
    if (this.initialized) return;
    this.initialized = true;

    this.tickDataUri = arrayBufferToBase64(Tone.tickWav());
    this.countInUris[3] = arrayBufferToBase64(Tone.countIn3Wav());
    this.countInUris[2] = arrayBufferToBase64(Tone.countIn2Wav());
    this.countInUris[1] = arrayBufferToBase64(Tone.countIn1Wav());
    this.countInStartUri = arrayBufferToBase64(Tone.countInStartWav());
    this.countdownWarningUri = arrayBufferToBase64(Tone.countdownWarningWav());
    this.endBellUri = arrayBufferToBase64(Tone.endBellWav());

    const signalTypes = Object.values(DirectionSignalType);
    for (const type of signalTypes) {
      this.signalUris[type] = arrayBufferToBase64(Tone.signalWav(type as DirectionSignalType));
    }

    // Pre-create audio context pool
    for (let i = 0; i < 6; i++) {
      const ctx = Taro.createInnerAudioContext();
      this.pool.push(ctx);
    }
  }

  private getNextPlayer(): Taro.InnerAudioContext {
    this.poolIndex = (this.poolIndex + 1) % this.pool.length;
    return this.pool[this.poolIndex];
  }

  playTick(volume: number): void {
    if (!this.initialized) return;
    const player = this.getNextPlayer();
    player.stop();
    player.src = this.tickDataUri;
    player.volume = volume;
    player.play();
  }

  playSignal(type: DirectionSignalType, volume: number): void {
    if (!this.initialized) return;
    const uri = this.signalUris[type];
    if (!uri) return;
    const player = this.pool[this.pool.length - 1];
    player.stop();
    player.src = uri;
    player.volume = volume;
    player.play();
  }

  playCountInBeep(num: number, volume: number): void {
    if (!this.initialized) return;
    const uri = num > 0 ? this.countInUris[num] : this.countInStartUri;
    if (!uri) return;
    const player = this.pool[this.pool.length - 1];
    player.stop();
    player.src = uri;
    player.volume = volume;
    player.play();
  }

  playCountdownWarning(volume: number): void {
    if (!this.initialized) return;
    const player = this.pool[this.pool.length - 1];
    player.stop();
    player.src = this.countdownWarningUri;
    player.volume = volume;
    player.play();
  }

  playEndBell(volume: number): void {
    if (!this.initialized) return;
    const player = this.pool[this.pool.length - 1];
    player.stop();
    player.src = this.endBellUri;
    player.volume = volume;
    player.play();
  }

  destroy(): void {
    for (const p of this.pool) {
      p.destroy();
    }
    this.pool = [];
    this.initialized = false;
  }
}

export const audioManager = new AudioManager();
