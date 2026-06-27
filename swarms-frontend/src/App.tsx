import React from 'react'
import { useGameSocket } from './hooks/useGameSocket'
import { useGameOver, useConnStatus } from './hooks/useGameState'
import Grid from './components/Grid/Grid'
import WaveInfo from './components/HUD/WaveInfo'
import BaseHP from './components/HUD/BaseHP'
import Score from './components/HUD/Score'
import ActionBar from './components/Controls/ActionBar'

export default function App() {
  useGameSocket()   // mount once — connects WS and wires to store

  const gameOver = useGameOver()
  const connStatus = useConnStatus()

  return (
    <div style={rootStyle}>
      {/* Title */}
      <h1 style={titleStyle}>SWARMS</h1>

      {/* Connection badge */}
      <div style={badgeStyle(connStatus)}>
        {connStatus === 'open' ? '● CONNECTED' : connStatus === 'connecting' ? '◌ CONNECTING' : '○ DISCONNECTED'}
      </div>

      {/* HUD bar */}
      <div style={hudStyle}>
        <BaseHP />
        <WaveInfo />
        <Score />
      </div>

      {/* Game grid */}
      <Grid />

      {/* Controls */}
      <ActionBar />

      {/* Game over overlay */}
      {gameOver && (
        <div style={overlayStyle}>
          <div style={overlayCardStyle}>
            <h2 style={{ color: '#ff4444', fontFamily: 'monospace', margin: 0 }}>GAME OVER</h2>
            <p style={{ color: '#888', fontFamily: 'monospace', fontSize: 13 }}>{gameOver.reason}</p>
            <div style={{ color: '#ffeb3b', fontFamily: 'monospace', fontSize: 24, fontWeight: 'bold' }}>
              {gameOver.score} pts
            </div>
            <div style={{ color: '#4fc3f7', fontFamily: 'monospace', fontSize: 13, marginTop: 4 }}>
              Survived {gameOver.wave} wave{gameOver.wave !== 1 ? 's' : ''}
            </div>
            <button
              style={{ ...btnStyle, marginTop: 16 }}
              onClick={() => window.location.reload()}
            >
              PLAY AGAIN
            </button>
          </div>
        </div>
      )}
    </div>
  )
}

// ---------------------------------------------------------------------------
// Styles
// ---------------------------------------------------------------------------

const rootStyle: React.CSSProperties = {
  minHeight:       '100vh',
  background:      '#080818',
  display:         'flex',
  flexDirection:   'column',
  alignItems:      'center',
  padding:         '24px 16px',
  gap:             16,
}

const titleStyle: React.CSSProperties = {
  color:       '#4fc3f7',
  fontFamily:  'monospace',
  fontSize:    28,
  letterSpacing: 8,
  margin:      0,
}

const hudStyle: React.CSSProperties = {
  display:         'flex',
  gap:             40,
  alignItems:      'center',
  padding:         '12px 32px',
  border:          '1px solid #1e1e3f',
  borderRadius:    6,
  background:      '#0a0a1e',
}

const overlayStyle: React.CSSProperties = {
  position:        'fixed',
  inset:           0,
  background:      'rgba(0,0,0,0.85)',
  display:         'flex',
  alignItems:      'center',
  justifyContent:  'center',
  zIndex:          100,
}

const overlayCardStyle: React.CSSProperties = {
  background:  '#0d0d1f',
  border:      '1px solid #ff4444',
  borderRadius: 8,
  padding:     '32px 48px',
  textAlign:   'center',
  display:     'flex',
  flexDirection: 'column',
  alignItems:  'center',
  gap:         8,
}

const btnStyle: React.CSSProperties = {
  padding:     '10px 24px',
  background:  'transparent',
  border:      '1px solid #4fc3f7',
  color:       '#4fc3f7',
  fontFamily:  'monospace',
  fontSize:    13,
  letterSpacing: 2,
  cursor:      'pointer',
  borderRadius: 3,
}

function badgeStyle(status: string): React.CSSProperties {
  const color = status === 'open' ? '#00ffcc' : status === 'connecting' ? '#ffeb3b' : '#ff4444'
  return { color, fontFamily: 'monospace', fontSize: 11, letterSpacing: 1 }
}
