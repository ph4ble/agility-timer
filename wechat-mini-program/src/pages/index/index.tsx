import { useState, useEffect } from 'react';
import Taro, { useShareAppMessage, useShareTimeline } from '@tarojs/taro';
import { View, Text, Picker, Switch, Slider } from '@tarojs/components';
import BpmControl from '../../components/BpmControl';
import {
  TrainingConfig,
  TrainingMode,
  SignalSoundType,
  DEFAULT_CONFIG,
} from '../../models/config';
import './index.scss';

const MODE_LABELS: Record<TrainingMode, string> = {
  [TrainingMode.free]: '自由训练',
  [TrainingMode.timed]: '计时训练',
  [TrainingMode.progressive]: '渐进加速',
  [TrainingMode.interval]: '间歇训练',
};

const MODES = Object.values(TrainingMode);

const STORAGE_KEY = 'training_config';

export default function HomePage() {
  const [config, setConfig] = useState<TrainingConfig>(() => {
    try {
      const saved = Taro.getStorageSync(STORAGE_KEY);
      return saved ? { ...DEFAULT_CONFIG, ...JSON.parse(saved) } : { ...DEFAULT_CONFIG };
    } catch {
      return { ...DEFAULT_CONFIG };
    }
  });

  useEffect(() => {
    Taro.setStorageSync(STORAGE_KEY, JSON.stringify(config));
  }, [config]);

  const update = <K extends keyof TrainingConfig>(key: K, value: TrainingConfig[K]) => {
    setConfig(prev => ({ ...prev, [key]: value }));
  };

  const handleStart = () => {
    Taro.navigateTo({
      url: `/pages/training/index?config=${encodeURIComponent(JSON.stringify(config))}`,
    });
  };

  // 转发给好友
  useShareAppMessage(() => ({
    title: '敏捷训练计时器 — 变向反应训练神器',
    path: '/pages/index/index',
  }));

  // 分享到朋友圈（仅安卓微信显示）
  useShareTimeline(() => ({
    title: '敏捷训练计时器 — 变向反应训练神器',
  }));

  return (
    <View className='home-page'>
      <View className='home-header'>
        <Text className='home-title'>敏捷训练计时器</Text>
        <Text className='home-subtitle'>Agility Training Timer</Text>
      </View>

      <View className='home-content'>
        {/* Training Mode */}
        <View className='section'>
          <Text className='section-title'>训练模式</Text>
          <View className='mode-tabs'>
            {MODES.map(mode => (
              <View
                key={mode}
                className={`mode-tab ${config.mode === mode ? 'mode-tab--active' : ''}`}
                onClick={() => update('mode', mode)}
              >
                <Text className='mode-tab-text'>{MODE_LABELS[mode]}</Text>
              </View>
            ))}
          </View>
        </View>

        {/* BPM */}
        <View className='section'>
          <BpmControl
            bpm={config.bpm}
            onBpmChange={(bpm) => update('bpm', bpm)}
          />
        </View>

        {/* Timed mode duration */}
        {config.mode === TrainingMode.timed && (
          <View className='section section--row'>
            <Text className='section-title'>训练时长</Text>
            <View className='duration-control'>
              <View className='duration-btn' onClick={() => update('trainingDuration', Math.max(1, config.trainingDuration - 1))}>
                <Text className='duration-btn-text'>-</Text>
              </View>
              <Text className='duration-value'>{config.trainingDuration} 分钟</Text>
              <View className='duration-btn' onClick={() => update('trainingDuration', Math.min(60, config.trainingDuration + 1))}>
                <Text className='duration-btn-text'>+</Text>
              </View>
            </View>
          </View>
        )}

        {/* Interval settings */}
        {config.mode === TrainingMode.interval && (
          <>
            <View className='section section--row'>
              <Text className='section-title'>训练时长 (秒)</Text>
              <View className='duration-control'>
                <View className='duration-btn' onClick={() => update('intervalWorkSeconds', Math.max(5, config.intervalWorkSeconds - 5))}>
                  <Text className='duration-btn-text'>-5</Text>
                </View>
                <Text className='duration-value'>{config.intervalWorkSeconds}s</Text>
                <View className='duration-btn' onClick={() => update('intervalWorkSeconds', Math.min(300, config.intervalWorkSeconds + 5))}>
                  <Text className='duration-btn-text'>+5</Text>
                </View>
              </View>
            </View>
            <View className='section section--row'>
              <Text className='section-title'>休息时长 (秒)</Text>
              <View className='duration-control'>
                <View className='duration-btn' onClick={() => update('intervalRestSeconds', Math.max(5, config.intervalRestSeconds - 5))}>
                  <Text className='duration-btn-text'>-5</Text>
                </View>
                <Text className='duration-value'>{config.intervalRestSeconds}s</Text>
                <View className='duration-btn' onClick={() => update('intervalRestSeconds', Math.min(120, config.intervalRestSeconds + 5))}>
                  <Text className='duration-btn-text'>+5</Text>
                </View>
              </View>
            </View>
            <View className='section section--row'>
              <Text className='section-title'>轮数</Text>
              <View className='duration-control'>
                <View className='duration-btn' onClick={() => update('intervalRounds', Math.max(1, config.intervalRounds - 1))}>
                  <Text className='duration-btn-text'>-</Text>
                </View>
                <Text className='duration-value'>{config.intervalRounds} 轮</Text>
                <View className='duration-btn' onClick={() => update('intervalRounds', Math.min(30, config.intervalRounds + 1))}>
                  <Text className='duration-btn-text'>+</Text>
                </View>
              </View>
            </View>
          </>
        )}

        {/* Direction Count */}
        <View className='section section--row'>
          <Text className='section-title'>变向数量</Text>
          <View className='chip-row'>
            {[2, 3, 4].map(n => (
              <View
                key={n}
                className={`chip ${config.directionCount === n ? 'chip--active' : ''}`}
                onClick={() => update('directionCount', n)}
              >
                <Text className='chip-text'>{n} 方向</Text>
              </View>
            ))}
          </View>
        </View>

        {/* Beats to change */}
        <View className='section section--row'>
          <Text className='section-title'>变向间隔</Text>
          <View className='range-row'>
            <Text className='range-val'>{config.minBeatsToChange}</Text>
            <Text className='range-sep'>-</Text>
            <Text className='range-val'>{config.maxBeatsToChange}</Text>
            <Text className='range-unit'>拍</Text>
          </View>
        </View>
        <View className='slider-group'>
          <View className='slider-item'>
            <Text className='slider-label'>最小拍数: {config.minBeatsToChange}</Text>
            <Slider
              value={config.minBeatsToChange}
              min={1}
              max={16}
              step={1}
              activeColor='#E91E63'
              backgroundColor='rgba(255,255,255,0.12)'
              blockColor='#E91E63'
              blockSize={20}
              onChange={(e) => update('minBeatsToChange', e.detail.value)}
            />
          </View>
          <View className='slider-item'>
            <Text className='slider-label'>最大拍数: {config.maxBeatsToChange}</Text>
            <Slider
              value={config.maxBeatsToChange}
              min={Math.max(2, config.minBeatsToChange)}
              max={16}
              step={1}
              activeColor='#E91E63'
              backgroundColor='rgba(255,255,255,0.12)'
              blockColor='#E91E63'
              blockSize={20}
              onChange={(e) => update('maxBeatsToChange', e.detail.value)}
            />
          </View>
        </View>

        {/* Signal Sound Type */}
        <View className='section section--row'>
          <Text className='section-title'>提示音</Text>
          <View className='chip-row'>
            <View
              className={`chip ${config.signalSoundType === SignalSoundType.tone ? 'chip--active' : ''}`}
              onClick={() => update('signalSoundType', SignalSoundType.tone)}
            >
              <Text className='chip-text'>提示音</Text>
            </View>
            <View
              className={`chip ${config.signalSoundType === SignalSoundType.voiceDirection ? 'chip--active' : ''}`}
              onClick={() => update('signalSoundType', SignalSoundType.voiceDirection)}
            >
              <Text className='chip-text'>方向音调</Text>
            </View>
          </View>
        </View>

        {/* Random BPM */}
        <View className='section'>
          <View className='section--row'>
            <Text className='section-title'>随机变速</Text>
            <Switch
              checked={config.enableRandomBpm}
              color='#E91E63'
              onChange={(e) => update('enableRandomBpm', e.detail.value)}
            />
          </View>
          {config.enableRandomBpm && (
            <View className='slider-item' style={{ marginTop: 12 }}>
              <Text className='slider-label'>变化幅度: {config.randomBpmPercent}%</Text>
              <Slider
                value={config.randomBpmPercent}
                min={5}
                max={30}
                step={5}
                activeColor='#E91E63'
                backgroundColor='rgba(255,255,255,0.12)'
                blockColor='#E91E63'
                blockSize={20}
                onChange={(e) => update('randomBpmPercent', e.detail.value)}
              />
            </View>
          )}
        </View>

        {/* Volume settings */}
        <View className='section'>
          <Text className='section-title'>音量设置</Text>
          <View className='slider-item'>
            <Text className='slider-label'>提示音量: {Math.round(config.signalVolume * 100)}%</Text>
            <Slider
              value={config.signalVolume * 100}
              min={10}
              max={100}
              step={5}
              activeColor='#00E5FF'
              backgroundColor='rgba(255,255,255,0.12)'
              blockColor='#00E5FF'
              blockSize={20}
              onChange={(e) => update('signalVolume', e.detail.value / 100)}
            />
          </View>
          <View className='slider-item'>
            <Text className='slider-label'>节拍音量: {Math.round(config.regularVolume * 100)}%</Text>
            <Slider
              value={config.regularVolume * 100}
              min={10}
              max={100}
              step={5}
              activeColor='#00E5FF'
              backgroundColor='rgba(255,255,255,0.12)'
              blockColor='#00E5FF'
              blockSize={20}
              onChange={(e) => update('regularVolume', e.detail.value / 100)}
            />
          </View>
        </View>
      </View>

      <View className='home-footer'>
        <View className='start-btn' onClick={handleStart}>
          <Text className='start-btn-text'>开始训练</Text>
        </View>
      </View>
    </View>
  );
}
