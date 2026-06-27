import React from 'react'
import { useBase } from '../../hooks/useGameState'

const MAX_HP = 100

export default function BaseHP() {
  const base = useBase()
  const hp   = base?.baseHp ?? MAX_HP
  const pct  = Math.max(0, (hp / MAX_HP) * 100)
  const color = pct > 50 ? '#00ffcc' : pct > 25 ? '#ffeb3b' : '#ff4444'

  return (
    <div style={containerStyle}>
      <div style={{ color: '#888', fontSize: 11, fontFamily: 'monospace', letterSpacing: 1 }}>
        BASE HP
      </div>
      <div style={{ color, fontSize: 20, fontFamily: 'monospace', fontWeight: 'bold' }}>
        {hp}
      </div>
      <div style={{ width: 100, height: 6, background: '#1a1a2e', borderRadius: 3, marginTop: 4 }}>
        <div style={{ width: `${pct}%`, height: '100%', background: color, borderRadius: 3, transition: 'width 0.2s' }} />
      </div>
    </div>
  )
}

const containerStyle: React.CSSProperties = {
  display:    'flex',
  flexDirection: 'column',
  alignItems: 'center',
  fontFamily: 'monospace',
}
