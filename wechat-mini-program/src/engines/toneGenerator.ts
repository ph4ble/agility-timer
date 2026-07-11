import { DirectionSignalType } from '../models/config';

const SAMPLE_RATE = 44100;
const BITS_PER_SAMPLE = 16;

function encodeWav(samples: Int16Array): ArrayBuffer {
  const dataSize = samples.length * (BITS_PER_SAMPLE / 8);
  const fileSize = 36 + dataSize;
  const byteRate = SAMPLE_RATE * BITS_PER_SAMPLE / 8;
  const buffer = new ArrayBuffer(44 + dataSize);
  const view = new DataView(buffer);

  // RIFF header
  view.setUint8(0, 0x52); view.setUint8(1, 0x49); // "RI"
  view.setUint8(2, 0x46); view.setUint8(3, 0x46); // "FF"
  view.setUint32(4, fileSize, true);
  view.setUint8(8, 0x57); view.setUint8(9, 0x41); // "WA"
  view.setUint8(10, 0x56); view.setUint8(11, 0x45); // "VE"
  view.setUint8(12, 0x66); view.setUint8(13, 0x6D); // "fm"
  view.setUint8(14, 0x74); view.setUint8(15, 0x20); // "t "
  view.setUint32(16, 16, true); // chunk size
  view.setUint16(20, 1, true); // PCM
  view.setUint16(22, 1, true); // mono
  view.setUint32(24, SAMPLE_RATE, true);
  view.setUint32(28, byteRate, true);
  view.setUint16(32, BITS_PER_SAMPLE / 8, true);
  view.setUint16(34, BITS_PER_SAMPLE, true);
  view.setUint8(36, 0x64); view.setUint8(37, 0x61); // "da"
  view.setUint8(38, 0x74); view.setUint8(39, 0x61); // "ta"
  view.setUint32(40, dataSize, true);

  const byteData = new Uint8Array(dataSize);
  const sampleView = new DataView(samples.buffer);
  for (let i = 0; i < dataSize; i++) {
    byteData[i] = sampleView.getUint8(i);
  }
  const out = new Uint8Array(buffer);
  out.set(byteData, 44);
  return buffer;
}

function generateWav(freq: number, durMs: number, vol: number): ArrayBuffer {
  const n = Math.floor(SAMPLE_RATE * durMs / 1000);
  const samples = new Int16Array(n);
  for (let i = 0; i < n; i++) {
    const t = i / SAMPLE_RATE;
    const env = Math.max(0, 1 - i / n);
    samples[i] = Math.max(-32768, Math.min(32767, Math.round(vol * env * Math.sin(2 * Math.PI * freq * t) * 32767)));
  }
  return encodeWav(samples);
}

function generateSweepWav(startFreq: number, endFreq: number, durMs: number, vol: number): ArrayBuffer {
  const n = Math.floor(SAMPLE_RATE * durMs / 1000);
  const samples = new Int16Array(n);
  for (let i = 0; i < n; i++) {
    const t = i / SAMPLE_RATE;
    const env = Math.max(0, 1 - i / n);
    const freq = startFreq + (endFreq - startFreq) * (i / n);
    samples[i] = Math.max(-32768, Math.min(32767, Math.round(vol * env * Math.sin(2 * Math.PI * freq * t) * 32767)));
  }
  return encodeWav(samples);
}

function twoNoteWav(f1: number, f2: number, d1: number, d2: number, vol: number): ArrayBuffer {
  const gapSamples = Math.floor(SAMPLE_RATE * 15 / 1000);
  const n1 = Math.floor(SAMPLE_RATE * d1 / 1000);
  const n2 = Math.floor(SAMPLE_RATE * d2 / 1000);
  const total = n1 + gapSamples + n2;
  const samples = new Int16Array(total);
  let idx = 0;
  for (let i = 0; i < n1; i++, idx++) {
    const t = i / SAMPLE_RATE;
    const env = Math.max(0, 1 - i / n1 * 0.3);
    samples[idx] = Math.max(-32768, Math.min(32767, Math.round(vol * env * Math.sin(2 * Math.PI * f1 * t) * 32767)));
  }
  idx += gapSamples;
  for (let i = 0; i < n2; i++, idx++) {
    const t = i / SAMPLE_RATE;
    const env = Math.max(0, 1 - i / n2);
    samples[idx] = Math.max(-32768, Math.min(32767, Math.round(vol * env * Math.sin(2 * Math.PI * f2 * t) * 32767)));
  }
  return encodeWav(samples);
}

function multiBeepWav(freq: number, durMs: number, gapMs: number, count: number, vol: number): ArrayBuffer {
  const beepSamples = Math.floor(SAMPLE_RATE * durMs / 1000);
  const gapSamples = Math.floor(SAMPLE_RATE * gapMs / 1000);
  const total = (beepSamples + gapSamples) * count;
  const samples = new Int16Array(total);
  for (let b = 0; b < count; b++) {
    const offset = b * (beepSamples + gapSamples);
    for (let i = 0; i < beepSamples; i++) {
      const t = i / SAMPLE_RATE;
      const env = Math.max(0, 1 - i / beepSamples);
      samples[offset + i] = Math.max(-32768, Math.min(32767, Math.round(vol * env * Math.sin(2 * Math.PI * freq * t) * 32767)));
    }
  }
  return encodeWav(samples);
}

function chimeWav(freqs: number[], durMs: number, gapMs: number, vol: number): ArrayBuffer {
  const noteSamples = Math.floor(SAMPLE_RATE * durMs / 1000);
  const gapSamples = Math.floor(SAMPLE_RATE * gapMs / 1000);
  const total = (noteSamples + gapSamples) * freqs.length;
  const samples = new Int16Array(total);
  for (let n = 0; n < freqs.length; n++) {
    const offset = n * (noteSamples + gapSamples);
    const freq = freqs[n];
    for (let i = 0; i < noteSamples; i++) {
      const t = i / SAMPLE_RATE;
      const env = Math.max(0, 1 - i / noteSamples);
      samples[offset + i] = Math.max(-32768, Math.min(32767, Math.round(vol * env * Math.sin(2 * Math.PI * freq * t) * 32767)));
    }
  }
  return encodeWav(samples);
}

// Exported functions
export function tickWav(): ArrayBuffer {
  return generateWav(1800, 40, 0.7);
}

export function countIn3Wav(): ArrayBuffer {
  return generateWav(440, 120, 0.7);
}

export function countIn2Wav(): ArrayBuffer {
  return generateWav(660, 120, 0.7);
}

export function countIn1Wav(): ArrayBuffer {
  return generateWav(880, 120, 0.7);
}

export function countInStartWav(): ArrayBuffer {
  return generateWav(1200, 200, 0.9);
}

export function countdownWarningWav(): ArrayBuffer {
  return multiBeepWav(1000, 60, 50, 3, 0.8);
}

export function countdownFinalWav(): ArrayBuffer {
  return multiBeepWav(1200, 40, 30, 5, 0.9);
}

export function endBellWav(): ArrayBuffer {
  return chimeWav([1200, 1000, 800, 600], 200, 40, 0.9);
}

export function signalWav(type: DirectionSignalType): ArrayBuffer {
  switch (type) {
    case DirectionSignalType.alert:
      return generateSweepWav(600, 1200, 150, 0.9);
    case DirectionSignalType.whistle:
      return generateSweepWav(1200, 2000, 120, 0.85);
    case DirectionSignalType.drum:
      return generateWav(120, 100, 1.0);
    case DirectionSignalType.dirForward:
      return twoNoteWav(800, 1300, 45, 55, 0.95);
    case DirectionSignalType.dirBackward:
      return twoNoteWav(1200, 600, 45, 55, 0.95);
    case DirectionSignalType.dirLeft:
      return generateSweepWav(1600, 2600, 75, 0.9);
    case DirectionSignalType.dirRight:
      return generateSweepWav(2600, 1400, 75, 0.9);
  }
}
