import React from 'react'
import { useWave, usePhase } from '../../hooks/useGameState'

export default function WaveInfo() {
  const wave  = useWave()
  const phase = usePhase()

  if (!wave) return null

  let label: string
  let sub:   string

  switch (wave.tag) {
    case 'WaveIdle':
      label = 'READY'
      sub   = phase === 'PhaseWaiting' ? 'Press Start Wave' : ''
      break
    case 'WaveInProgress':
      label = `WAVE ${wave.waveNumber}`
      sub   = `${wave.enemiesToSpawn} enemies remaining`
      break
    case 'WaveCooldown':
      label = `WAVE ${wave.waveNumber} COMPLETE`
      sub   = `Next wave in ${Math.ceil(wave.cooldownTicks / 10)}s`
      break
  }

  return (
    <div style={containerStyle}>
      <div style={{ color: '#4fc3f7', fontSize: 13, letterSpacing: 2 }}>{label}</div>
      <div style={{ color: '#888', fontSize: 11, marginTop: 2 }}>{sub}</div>
    </div>
  )
}

const containerStyle: React.CSSProperties = {
  textAlign:  'center',
  fontFamily: 'monospace',
  minWidth:   140,
}
