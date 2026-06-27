import React from 'react'
import { useScore } from '../../hooks/useGameState'

export default function Score() {
  const score = useScore()
  return (
    <div style={{ textAlign: 'center', fontFamily: 'monospace' }}>
      <div style={{ color: '#888', fontSize: 11, letterSpacing: 1 }}>SCORE</div>
      <div style={{ color: '#ffeb3b', fontSize: 20, fontWeight: 'bold' }}>{score}</div>
    </div>
  )
}
