import { View, Text } from '@tarojs/components';
import { useEffect, useState } from 'react';
import './index.scss';

interface BeatRingProps {
  beatNumber: number;
  beatsPerBar: number;
  pulse: boolean;
  currentBpm: number;
}

export default function BeatRing({ beatNumber, beatsPerBar, pulse, currentBpm }: BeatRingProps) {
  const [animating, setAnimating] = useState(false);

  useEffect(() => {
    if (!pulse) return;
    setAnimating(true);
    const timer = setTimeout(() => setAnimating(false), 150);
    return () => clearTimeout(timer);
  }, [beatNumber, pulse]);

  const dots = Array.from({ length: beatsPerBar }, (_, i) => {
    const active = i < beatNumber % beatsPerBar || (beatNumber > 0 && i === 0 && beatNumber % beatsPerBar === 0);
    return (
      <View
        key={i}
        className={`beat-dot ${i === (beatNumber - 1) % beatsPerBar && beatNumber > 0 ? 'beat-dot--current' : ''} ${active ? 'beat-dot--active' : ''}`}
      />
    );
  });

  return (
    <View className='beat-ring-container'>
      <View className={`beat-ring ${animating ? 'beat-ring--pulse' : ''}`}>
        <View className='beat-ring-inner'>
          <Text className='beat-ring-bpm'>{currentBpm}</Text>
          <Text className='beat-ring-label'>BPM</Text>
        </View>
      </View>
      <View className='beat-dots-row'>{dots}</View>
    </View>
  );
}
