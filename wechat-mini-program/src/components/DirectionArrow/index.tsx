import { View, Text } from '@tarojs/components';
import { useEffect, useState } from 'react';
import { Direction, DirectionSignalType } from '../../models/config';
import './index.scss';

interface DirectionArrowProps {
  direction: Direction | null;
  signalType: DirectionSignalType;
}

const DIR_LABELS: Record<Direction, string> = {
  [Direction.forward]: '↑',
  [Direction.backward]: '↓',
  [Direction.left]: '←',
  [Direction.right]: '→',
};

const DIR_WORDS: Record<Direction, string> = {
  [Direction.forward]: '前进',
  [Direction.backward]: '后退',
  [Direction.left]: '向左',
  [Direction.right]: '向右',
};

export default function DirectionArrow({ direction, signalType }: DirectionArrowProps) {
  const [visible, setVisible] = useState(false);
  const [currentDir, setCurrentDir] = useState<Direction | null>(null);

  useEffect(() => {
    if (!direction) return;
    setCurrentDir(direction);
    setVisible(false);
    requestAnimationFrame(() => setVisible(true));
    const timer = setTimeout(() => setVisible(false), 1200);
    return () => clearTimeout(timer);
  }, [direction, signalType]);

  if (!currentDir) {
    return (
      <View className='direction-placeholder'>
        <Text className='direction-placeholder-text'>等待指令</Text>
      </View>
    );
  }

  const isVoice = signalType === DirectionSignalType.dirForward ||
    signalType === DirectionSignalType.dirBackward ||
    signalType === DirectionSignalType.dirLeft ||
    signalType === DirectionSignalType.dirRight;

  return (
    <View className={`direction-arrow-container ${visible ? 'direction-arrow--visible' : ''}`}>
      <Text className='direction-arrow-icon'>{DIR_LABELS[currentDir]}</Text>
      {isVoice && <Text className='direction-arrow-word'>{DIR_WORDS[currentDir]}</Text>}
      {!isVoice && <Text className='direction-arrow-word'>变向!</Text>}
    </View>
  );
}
