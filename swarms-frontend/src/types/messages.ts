import { GameWorld, Delta } from './world'

// ---------------------------------------------------------------------------
// Client → Server
// ---------------------------------------------------------------------------

export type ClientMessage =
  | { tag: 'CPlaceTurret'; pos: { posX: number; posY: number } }
  | { tag: 'CStartWave' }
  | { tag: 'CSurrender' }
  | { tag: 'CPing' }

// ---------------------------------------------------------------------------
// Server → Client
// ---------------------------------------------------------------------------

export type ServerMessage =
  | { tag: 'SStateSnapshot'; contents: GameWorld }
  | { tag: 'SStateDelta';    contents: Delta[] }
  | { tag: 'SWaveAnnounce';  waveInfoNumber: number; waveInfoEnemies: number; waveInfoStarting: boolean }
  | { tag: 'SGameOver';      gameOverScore: number; gameOverWave: number; gameOverReason: string }
  | { tag: 'SPong' }
  | { tag: 'SError';         contents: string }
