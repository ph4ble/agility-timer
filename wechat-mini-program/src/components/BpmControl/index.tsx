import { View, Text, Slider } from '@tarojs/components';
import './index.scss';

interface BpmControlProps {
  bpm: number;
  onBpmChange: (bpm: number) => void;
}

export default function BpmControl({ bpm, onBpmChange }: BpmControlProps) {
  const changeBpm = (delta: number) => {
    const next = Math.max(20, Math.min(300, bpm + delta));
    onBpmChange(next);
  };

  return (
    <View className='bpm-control'>
      <Text className='bpm-label'>BPM</Text>
      <View className='bpm-value-row'>
        <View className='bpm-btn' onClick={() => changeBpm(-10)}>
          <Text className='bpm-btn-text'>-10</Text>
        </View>
        <View className='bpm-btn' onClick={() => changeBpm(-1)}>
          <Text className='bpm-btn-text'>-1</Text>
        </View>
        <Text className='bpm-value'>{bpm}</Text>
        <View className='bpm-btn' onClick={() => changeBpm(1)}>
          <Text className='bpm-btn-text'>+1</Text>
        </View>
        <View className='bpm-btn' onClick={() => changeBpm(10)}>
          <Text className='bpm-btn-text'>+10</Text>
        </View>
      </View>
      <View className='bpm-slider-row'>
        <Text className='bpm-range'>20</Text>
        <Slider
          className='bpm-slider'
          value={bpm}
          min={20}
          max={300}
          step={1}
          activeColor='#E91E63'
          backgroundColor='rgba(255,255,255,0.12)'
          blockColor='#E91E63'
          blockSize={20}
          onChange={(e) => onBpmChange(e.detail.value)}
        />
        <Text className='bpm-range'>300</Text>
      </View>
    </View>
  );
}
