import {
  TrainingConfig,
  TrainingMode,
  TrainingPhase,
  Direction,
  DirectionSignalType,
  SignalSoundType,
  getActiveDirections,
} from '../models/config';
import { Metronome, BeatEvent } from './metronome';

export interface TrainingState {
  phase: TrainingPhase;
  elapsedSeconds: number;
  totalSeconds: number;
  beatCount: number;
  signalCount: number;
  currentBpm: number;
  roundNumber: number;
  totalRounds: number;
  lastDirection: Direction | null;
}

export interface SignalEvent {
  direction: Direction;
  signalType: DirectionSignalType;
}

export interface CountdownEvent {
  remainingSeconds: number;
}

type EventHandler = {
  state?: (s: TrainingState) => void;
  signal?: (e: SignalEvent) => void;
  beat?: (e: BeatEvent) => void;
  tick?: () => void;
  countdown?: (e: CountdownEvent) => void;
  endBell?: () => void;
};

export class TrainingEngine {
  private config: TrainingConfig;
  private metronome: Metronome = new Metronome();
  private handler: EventHandler = {};

  private signalCount = 0;
  private beatsSinceLastSignal = 0;
  private elapsedSeconds = 0;
  private roundNumber = 1;
  private currentBpm: number;
  private baseBpm: number;
  private lastDirection: Direction | null = null;
  private phase: TrainingPhase = TrainingPhase.idle;
  private countdown10Fired = false;
  private countdown5Fired = false;

  private durationTimer: ReturnType<typeof setInterval> | null = null;
  private bpmTimer: ReturnType<typeof setInterval> | null = null;
  private boundOnBeat: (e: BeatEvent) => void;

  constructor(config: TrainingConfig) {
    this.config = config;
    this.currentBpm = config.bpm;
    this.baseBpm = config.bpm;
    this.boundOnBeat = this.onBeat.bind(this);
  }

  on(handler: EventHandler): void {
    this.handler = handler;
  }

  get isPaused(): boolean {
    return this.phase === TrainingPhase.paused;
  }

  get currentPhase(): TrainingPhase {
    return this.phase;
  }

  getCurrentBpm(): number {
    return this.currentBpm;
  }

  getElapsedSeconds(): number {
    return this.elapsedSeconds;
  }

  getSignalCount(): number {
    return this.signalCount;
  }

  async start(): Promise<void> {
    this.signalCount = 0;
    this.beatsSinceLastSignal = 0;
    this.elapsedSeconds = 0;
    this.roundNumber = 1;
    this.lastDirection = null;
    this.currentBpm = this.config.bpm;
    this.baseBpm = this.config.bpm;
    this.countdown10Fired = false;
    this.countdown5Fired = false;

    const intervalMs = this.beatIntervalMs();
    this.metronome.configure(intervalMs, this.config.beatsPerBar);
    this.metronome.onBeat(this.boundOnBeat);

    this.phase = TrainingPhase.countIn;
    this.emitState();

    // 3-2-1-开始 count-in
    for (let i = 3; i >= 0; i--) {
      const event: BeatEvent = {
        beatNumber: i === 0 ? 0 : i,
        isFirstBeat: i === 0,
        isCountIn: true,
      };
      this.handler.beat?.(event);
      this.handler.tick?.();
      await this.delay(intervalMs);
    }

    this.phase = TrainingPhase.running;
    this.emitState();
    this.metronome.start();
    this.startDurationTracking();
    this.startRandomBpmVariation();
  }

  pause(): void {
    if (this.phase !== TrainingPhase.running && this.phase !== TrainingPhase.rest) return;
    this.phase = TrainingPhase.paused;
    this.metronome.stop();
    this.clearTimers();
    this.emitState();
  }

  resume(): void {
    if (this.phase !== TrainingPhase.paused) return;
    this.phase = TrainingPhase.running;
    this.metronome.start();
    this.startDurationTracking();
    this.startRandomBpmVariation();
    this.emitState();
  }

  stop(): void {
    this.phase = TrainingPhase.finished;
    this.emitState();
    this.metronome.stop();
    this.metronome.removeListener(this.boundOnBeat);
    this.clearTimers();
  }

  dispose(): void {
    this.stop();
    this.metronome.removeListener(this.boundOnBeat);
  }

  private clearTimers(): void {
    if (this.durationTimer !== null) { clearInterval(this.durationTimer); this.durationTimer = null; }
    if (this.bpmTimer !== null) { clearInterval(this.bpmTimer); this.bpmTimer = null; }
  }

  private delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  private beatIntervalMs(): number {
    return 60000 / this.currentBpm / this.config.beatSubdivision;
  }

  private onBeat(beat: BeatEvent): void {
    this.beatsSinceLastSignal++;
    this.handler.beat?.(beat);
    this.handler.tick?.();

    if (this.beatsSinceLastSignal >= this.config.minBeatsToChange) {
      const maxBeats = this.config.maxBeatsToChange;
      const chance = this.beatsSinceLastSignal >= maxBeats
        ? 1
        : 1 / (maxBeats - this.beatsSinceLastSignal + 1);
      if (Math.random() < chance) {
        this.fireSignal();
      }
    }
  }

  private fireSignal(): void {
    this.beatsSinceLastSignal = 0;
    this.signalCount++;

    const directions = getActiveDirections(this.config.directionCount);
    let dir: Direction;
    if (directions.length > 1 && this.lastDirection !== null) {
      const others = directions.filter(d => d !== this.lastDirection);
      dir = others[Math.floor(Math.random() * others.length)];
    } else {
      dir = directions[Math.floor(Math.random() * directions.length)];
    }
    this.lastDirection = dir;

    const signalType = this.pickSignalType(dir);
    this.handler.signal?.({ direction: dir, signalType });
  }

  private pickSignalType(dir: Direction): DirectionSignalType {
    if (this.config.signalSoundType === SignalSoundType.voiceDirection) {
      switch (dir) {
        case Direction.forward: return DirectionSignalType.dirForward;
        case Direction.backward: return DirectionSignalType.dirBackward;
        case Direction.left: return DirectionSignalType.dirLeft;
        case Direction.right: return DirectionSignalType.dirRight;
      }
    }
    return DirectionSignalType.alert;
  }

  private startRandomBpmVariation(): void {
    if (!this.config.enableRandomBpm) return;
    this.bpmTimer = setInterval(() => {
      if (this.phase !== TrainingPhase.running) return;
      const range = Math.round(this.config.bpm * this.config.randomBpmPercent / 100);
      const minBpm = Math.max(40, this.config.bpm - range);
      const maxBpm = Math.min(500, this.config.bpm + range);
      this.currentBpm = minBpm + Math.floor(Math.random() * Math.max(maxBpm - minBpm, 1));
      this.metronome.configure(this.beatIntervalMs(), this.config.beatsPerBar);
      this.emitState();
    }, this.beatIntervalMs() * this.config.beatsPerBar * 2);
  }

  private startDurationTracking(): void {
    this.clearTimers();

    if (this.config.mode === TrainingMode.free) {
      this.durationTimer = setInterval(() => {
        this.elapsedSeconds++;
        this.emitState();
      }, 1000);
    } else if (this.config.mode === TrainingMode.timed) {
      const totalSecs = this.config.trainingDuration * 60;
      this.durationTimer = setInterval(() => {
        this.elapsedSeconds++;
        this.emitState();
        this.checkCountdown(totalSecs);
        if (this.elapsedSeconds >= totalSecs) {
          this.handler.endBell?.();
          this.stop();
        }
      }, 1000);
    } else if (this.config.mode === TrainingMode.progressive) {
      this.durationTimer = setInterval(() => {
        this.elapsedSeconds++;
        this.emitState();
      }, 1000);
      setInterval(() => {
        if (this.phase === TrainingPhase.running && this.currentBpm < 500) {
          this.baseBpm = Math.min(500, this.baseBpm + 5);
          this.currentBpm = this.baseBpm;
          this.metronome.configure(this.beatIntervalMs(), this.config.beatsPerBar);
          this.emitState();
        }
      }, 20000);
    } else if (this.config.mode === TrainingMode.interval) {
      this.startIntervalWorkPhase();
    }
  }

  private checkCountdown(totalSecs: number): void {
    const remaining = totalSecs - this.elapsedSeconds;
    if (remaining <= 10 && remaining > 5 && !this.countdown10Fired) {
      this.countdown10Fired = true;
      this.handler.countdown?.({ remainingSeconds: remaining });
    } else if (remaining <= 5 && remaining > 0 && !this.countdown5Fired) {
      this.countdown5Fired = true;
      this.handler.countdown?.({ remainingSeconds: remaining });
    }
  }

  private startIntervalWorkPhase(): void {
    this.phase = TrainingPhase.running;
    this.emitState();
    this.elapsedSeconds = 0;
    this.countdown10Fired = false;
    this.countdown5Fired = false;

    this.durationTimer = setInterval(() => {
      this.elapsedSeconds++;
      this.emitState();
      this.checkCountdown(this.config.intervalWorkSeconds);
      if (this.elapsedSeconds >= this.config.intervalWorkSeconds) {
        if (this.roundNumber >= this.config.intervalRounds) {
          this.handler.endBell?.();
          this.stop();
        } else {
          this.startRestPhase();
        }
      }
    }, 1000);
  }

  private startRestPhase(): void {
    this.phase = TrainingPhase.rest;
    this.emitState();
    this.elapsedSeconds = 0;
    this.countdown10Fired = false;
    this.countdown5Fired = false;

    this.durationTimer = setInterval(() => {
      this.elapsedSeconds++;
      this.emitState();
      if (this.elapsedSeconds >= this.config.intervalRestSeconds) {
        this.roundNumber++;
        this.startIntervalWorkPhase();
      }
    }, 1000);
  }

  private emitState(): void {
    let totalSecs = 0;
    if (this.config.mode === TrainingMode.timed) {
      totalSecs = this.config.trainingDuration * 60;
    }
    this.handler.state?.({
      phase: this.phase,
      elapsedSeconds: this.elapsedSeconds,
      totalSeconds: totalSecs,
      beatCount: 0,
      signalCount: this.signalCount,
      currentBpm: this.currentBpm,
      roundNumber: this.roundNumber,
      totalRounds: this.config.mode === TrainingMode.interval ? this.config.intervalRounds : 1,
      lastDirection: this.lastDirection,
    });
  }
}
