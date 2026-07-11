import { useState, useEffect, useRef, useCallback } from 'react';
import Taro, { useLoad, useDidShow, useDidHide, useShareAppMessage, useShareTimeline } from '@tarojs/taro';
import { View, Text } from '@tarojs/components';
import BeatRing from '../../components/BeatRing';
import DirectionArrow from '../../components/DirectionArrow';
import { TrainingEngine, TrainingState, SignalEvent } from '../../engines/trainingEngine';
import { audioManager } from '../../engines/audioManager';
import { BeatEvent } from '../../engines/metronome';
import {
  TrainingConfig,
  TrainingMode,
  TrainingPhase,
  DEFAULT_CONFIG,
} from '../../models/config';
import './index.scss';

function formatTime(totalSeconds: number): string {
  const mins = Math.floor(totalSeconds / 60);
  const secs = totalSeconds % 60;
  return `${String(mins).padStart(2, '0')}:${String(secs).padStart(2, '0')}`;
}

function getDisplaySeconds(state: TrainingState, config: TrainingConfig): number {
  if (config.mode === TrainingMode.timed) {
    return Math.max(0, state.totalSeconds - state.elapsedSeconds);
  }
  if (config.mode === TrainingMode.interval) {
    if (state.phase === TrainingPhase.rest) {
      return config.intervalRestSeconds - state.elapsedSeconds;
    }
    return config.intervalWorkSeconds - state.elapsedSeconds;
  }
  return state.elapsedSeconds;
}

export default function TrainingPage() {
  const [state, setState] = useState<TrainingState | null>(null);
  const [config, setConfig] = useState<TrainingConfig>(DEFAULT_CONFIG);
  const [signalEvent, setSignalEvent] = useState<SignalEvent | null>(null);
  const [beatEvent, setBeatEvent] = useState<BeatEvent | null>(null);
  const [isCountdown, setIsCountdown] = useState(false);
  const engineRef = useRef<TrainingEngine | null>(null);
  const cfgRef = useRef<TrainingConfig>(DEFAULT_CONFIG);

  useLoad((options) => {
    const raw = options?.config;
    let cfg = DEFAULT_CONFIG;
    if (raw) {
      try {
        cfg = { ...DEFAULT_CONFIG, ...JSON.parse(decodeURIComponent(raw)) };
      } catch { /* use default */ }
    }
    cfgRef.current = cfg;
    setConfig(cfg);

    audioManager.init();
    const engine = new TrainingEngine(cfg);
    engineRef.current = engine;

    engine.on({
      state: (s) => setState({ ...s }),
      signal: (e) => setSignalEvent({ ...e }),
      beat: (e) => {
        setBeatEvent({ ...e });
        if (!e.isCountIn) {
          audioManager.playTick(cfgRef.current.regularVolume);
        }
        try { Taro.vibrateShort({ type: 'light' }); } catch { /* ok */ }
      },
      tick: () => {},
      countdown: () => {
        setIsCountdown(true);
        audioManager.playCountdownWarning(cfgRef.current.signalVolume);
      },
      endBell: () => {
        audioManager.playEndBell(cfgRef.current.signalVolume);
        try { Taro.vibrateShort({ type: 'heavy' }); } catch { /* ok */ }
      },
    });

    engine.start();
  });

  useDidShow(() => {
    const engine = engineRef.current;
    if (engine && engine.isPaused) {
      engine.resume();
    }
  });

  useDidHide(() => {
    const engine = engineRef.current;
    if (engine && !engine.isPaused && engine.currentPhase !== TrainingPhase.idle && engine.currentPhase !== TrainingPhase.finished) {
      engine.pause();
    }
  });

  useEffect(() => {
    return () => {
      engineRef.current?.dispose();
      audioManager.destroy();
      // 离开页面时恢复系统自动熄屏
      Taro.setKeepScreenOn({ keepScreenOn: false }).catch(() => { /* ok */ });
    };
  }, []);

  // 屏幕常亮：训练进行中保持亮屏，暂停/完成时恢复自动熄屏
  useEffect(() => {
    const phase = state?.phase;
    const active =
      phase === TrainingPhase.countIn ||
      phase === TrainingPhase.running ||
      phase === TrainingPhase.rest;
    Taro.setKeepScreenOn({ keepScreenOn: !!active }).catch(() => { /* ok */ });
  }, [state?.phase]);

  // 转发给好友
  useShareAppMessage(() => ({
    title: '我在用敏捷训练计时器练变向反应，一起来！',
    path: '/pages/index/index',
  }));

  // 分享到朋友圈（仅安卓微信显示）
  useShareTimeline(() => ({
    title: '敏捷训练计时器 — 变向反应训练神器',
  }));

  // Play count-in audio
  useEffect(() => {
    if (!beatEvent?.isCountIn) return;
    if (beatEvent.beatNumber === 0) {
      audioManager.playCountInBeep(0, cfgRef.current.signalVolume);
    } else {
      audioManager.playCountInBeep(beatEvent.beatNumber, cfgRef.current.regularVolume);
    }
  }, [beatEvent]);

  // Play signal audio
  useEffect(() => {
    if (!signalEvent) return;
    audioManager.playSignal(signalEvent.signalType, cfgRef.current.signalVolume);
  }, [signalEvent]);

  const handlePauseResume = useCallback(() => {
    const engine = engineRef.current;
    if (!engine) return;
    if (engine.isPaused) {
      engine.resume();
    } else {
      engine.pause();
    }
  }, []);

  const handleStop = useCallback(() => {
    engineRef.current?.stop();
    Taro.navigateBack();
  }, []);

  const getPhaseLabel = (): string => {
    if (!state) return '';
    switch (state.phase) {
      case TrainingPhase.countIn: return '准备';
      case TrainingPhase.running: return config.mode === TrainingMode.interval ? `训练 ${state.roundNumber}/${state.totalRounds}` : '训练中';
      case TrainingPhase.rest: return `休息 ${state.roundNumber}/${state.totalRounds}`;
      case TrainingPhase.paused: return '已暂停';
      case TrainingPhase.finished: return '完成';
      default: return '';
    }
  };

  if (!state) {
    return (
      <View className='training-page'>
        <Text className='training-loading'>加载中...</Text>
      </View>
    );
  }

  const displaySeconds = getDisplaySeconds(state, config);
  const phaseLabel = getPhaseLabel();
  const isFinished = state.phase === TrainingPhase.finished;
  const isPaused = state.phase === TrainingPhase.paused;

  return (
    <View className='training-page'>
      {/* Timer */}
      <View className={`timer-section ${isCountdown ? 'timer-section--countdown' : ''}`}>
        <Text className='phase-label'>{phaseLabel}</Text>
        <Text className={`timer-value ${isCountdown ? 'timer-value--warning' : ''}`}>
          {formatTime(displaySeconds)}
        </Text>
        <Text className='bpm-sub'>信号计数: {state.signalCount}</Text>
      </View>

      {/* Center area: Beat Ring or Direction Arrow */}
      <View className='center-area'>
        {signalEvent ? (
          <DirectionArrow
            direction={signalEvent.direction}
            signalType={signalEvent.signalType}
          />
        ) : (
          <BeatRing
            beatNumber={beatEvent?.beatNumber ?? 0}
            beatsPerBar={config.beatsPerBar}
            pulse={!!beatEvent && !beatEvent.isCountIn}
            currentBpm={state.currentBpm}
          />
        )}
      </View>

      {/* Controls */}
      {!isFinished && (
        <View className='training-controls'>
          <View className='control-btn control-btn--stop' onClick={handleStop}>
            <Text className='control-btn-text'>停止</Text>
          </View>
          <View
            className={`control-btn ${isPaused ? 'control-btn--resume' : 'control-btn--pause'}`}
            onClick={handlePauseResume}
          >
            <Text className='control-btn-text'>{isPaused ? '继续' : '暂停'}</Text>
          </View>
        </View>
      )}

      {isFinished && (
        <View className='finished-section'>
          <Text className='finished-text'>训练完成!</Text>
          <Text className='finished-stats'>共 {state.signalCount} 次变向</Text>
          <View className='control-btn control-btn--back' onClick={handleStop}>
            <Text className='control-btn-text'>返回首页</Text>
          </View>
        </View>
      )}
    </View>
  );
}
