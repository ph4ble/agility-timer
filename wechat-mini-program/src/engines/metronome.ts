export interface BeatEvent {
  beatNumber: number;
  isFirstBeat: boolean;
  isCountIn: boolean;
}

type BeatListener = (event: BeatEvent) => void;

export class Metronome {
  private timer: ReturnType<typeof setInterval> | null = null;
  private beatCount = 0;
  private beatsPerBar = 4;
  private intervalMs = 500;
  private listeners: BeatListener[] = [];
  private running = false;

  get isRunning(): boolean {
    return this.running;
  }

  configure(beatIntervalMs: number, beatsPerBar: number = 4): void {
    this.intervalMs = beatIntervalMs;
    this.beatsPerBar = beatsPerBar;
  }

  onBeat(fn: BeatListener): void {
    this.listeners.push(fn);
  }

  removeListener(fn: BeatListener): void {
    this.listeners = this.listeners.filter(l => l !== fn);
  }

  start(): void {
    this.beatCount = 0;
    this.running = true;
    this.timer = setInterval(() => {
      this.beatCount++;
      const isFirst = (this.beatCount - 1) % this.beatsPerBar === 0;
      const event: BeatEvent = {
        beatNumber: this.beatCount,
        isFirstBeat: isFirst,
        isCountIn: false,
      };
      for (const fn of this.listeners) {
        fn(event);
      }
    }, this.intervalMs);
    // Fire first beat immediately
    setTimeout(() => {
      if (!this.running) return;
      this.beatCount++;
      const event: BeatEvent = {
        beatNumber: this.beatCount,
        isFirstBeat: true,
        isCountIn: false,
      };
      for (const fn of this.listeners) {
        fn(event);
      }
    }, 0);
  }

  stop(): void {
    if (this.timer !== null) {
      clearInterval(this.timer);
      this.timer = null;
    }
    this.running = false;
  }

  reset(): void {
    this.stop();
    this.beatCount = 0;
  }
}
