export enum TrainingMode {
  free = 'free',
  timed = 'timed',
  progressive = 'progressive',
  interval = 'interval',
}

export enum TrainingPhase {
  idle = 'idle',
  countIn = 'countIn',
  running = 'running',
  rest = 'rest',
  paused = 'paused',
  finished = 'finished',
}

export enum Direction {
  forward = 'forward',
  backward = 'backward',
  left = 'left',
  right = 'right',
}

export enum SignalSoundType {
  tone = 'tone',
  voiceDirection = 'voiceDirection',
}

export enum DirectionSignalType {
  alert = 'alert',
  whistle = 'whistle',
  drum = 'drum',
  dirForward = 'dirForward',
  dirBackward = 'dirBackward',
  dirLeft = 'dirLeft',
  dirRight = 'dirRight',
}

export interface TrainingConfig {
  bpm: number;
  minBeatsToChange: number;
  maxBeatsToChange: number;
  directionCount: number;
  trainingDuration: number; // minutes
  mode: TrainingMode;
  signalSoundType: SignalSoundType;
  signalVolume: number;
  regularVolume: number;
  enableRandomBpm: boolean;
  randomBpmPercent: number;
  intervalWorkSeconds: number;
  intervalRestSeconds: number;
  intervalRounds: number;
  beatSubdivision: number;
  beatsPerBar: number;
}

export const DEFAULT_CONFIG: TrainingConfig = {
  bpm: 100,
  minBeatsToChange: 4,
  maxBeatsToChange: 8,
  directionCount: 2,
  trainingDuration: 3,
  mode: TrainingMode.free,
  signalSoundType: SignalSoundType.tone,
  signalVolume: 1.0,
  regularVolume: 0.8,
  enableRandomBpm: false,
  randomBpmPercent: 10,
  intervalWorkSeconds: 30,
  intervalRestSeconds: 10,
  intervalRounds: 5,
  beatSubdivision: 1,
  beatsPerBar: 4,
};

export function getActiveDirections(count: number): Direction[] {
  switch (count) {
    case 2: return [Direction.forward, Direction.left, Direction.right];
    case 3: return [Direction.forward, Direction.left, Direction.right];
    case 4: return [Direction.forward, Direction.backward, Direction.left, Direction.right];
    default: return [Direction.forward, Direction.left, Direction.right];
  }
}
