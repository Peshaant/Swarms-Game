import React from 'react'
import { usePhase, useConnStatus } from '../../hooks/useGameState'
import { gameSocket } from '../../ws/client'

export default function ActionBar() {
  const phase  = usePhase()
  const status = useConnStatus()

  const canStartWave = phase === 'PhaseWaiting' && status === 'open'
  const canSurrender = phase === 'PhaseRunning'  && status === 'open'

  return (
    <div style={containerStyle}>
      <button
        disabled={!canStartWave}
        onClick={() => gameSocket.send({ tag: 'CStartWave' })}
        style={btnStyle(canStartWave, '#00ffcc')}
      >
        ▶ Start Wave
      </button>

      <button
        disabled={!canSurrender}
        onClick={() => gameSocket.send({ tag: 'CSurrender' })}
        style={btnStyle(canSurrender, '#ff4444')}
      >
        ✕ Surrender
      </button>

      <div style={{ color: '#555', fontSize: 11, fontFamily: 'monospace', marginTop: 8 }}>
        Click any empty tile to place a turret
      </div>
    </div>
  )
}

const containerStyle: React.CSSProperties = {
  display:        'flex',
  flexDirection:  'column',
  alignItems:     'center',
  gap:            8,
}

function btnStyle(active: boolean, color: string): React.CSSProperties {
  return {
    padding:        '8px 20px',
    background:     active ? 'transparent' : '#111',
    border:         `1px solid ${active ? color : '#333'}`,
    color:          active ? color : '#444',
    fontFamily:     'monospace',
    fontSize:       13,
    letterSpacing:  1,
    cursor:         active ? 'pointer' : 'not-allowed',
    borderRadius:   3,
    transition:     'all 0.15s',
  }
}
