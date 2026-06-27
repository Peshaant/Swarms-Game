// Mirrors Game.Types in Haskell backend exactly.
// Keep in sync with any backend type changes.

export interface Pos {
  posX: number
  posY: number
}

// ---------------------------------------------------------------------------
// Tile
// ---------------------------------------------------------------------------

export type Tile =
  | { tag: 'TileEmpty' }
  | { tag: 'TileWall' }
  | { tag: 'TileOccupied'; contents: number } // EntityId

// ---------------------------------------------------------------------------
// Entities
// ---------------------------------------------------------------------------

export interface Base {
  basePos: Pos
  baseHp: number
}

export interface Turret {
  turretId: number
  turretPos: Pos
  turretHp: number
  turretRange: number
  turretDamage: number
  turretCooldown: number
  turretTarget: number | null
}

export interface Enemy {
  enemyId: number
  enemyPos: Pos
  enemyHp: number
  enemyDamage: number
  enemyReward: number
  enemyPath: Pos[]
  enemyMoveTick: number
}

export interface Projectile {
  projId: number
  projPos: Pos
  projTarget: number
  projDamage: number
}

export type Entity =
  | { tag: 'EBase';       contents: Base }
  | { tag: 'ETurret';     contents: Turret }
  | { tag: 'EEnemy';      contents: Enemy }
  | { tag: 'EProjectile'; contents: Projectile }

// ---------------------------------------------------------------------------
// Wave
// ---------------------------------------------------------------------------

export type WaveStatus =
  | { tag: 'WaveIdle' }
  | { tag: 'WaveInProgress'; waveNumber: number; enemiesToSpawn: number; spawnTimer: number }
  | { tag: 'WaveCooldown';   waveNumber: number; cooldownTicks: number }

// ---------------------------------------------------------------------------
// Phase
// ---------------------------------------------------------------------------

export type Phase = 'PhaseWaiting' | 'PhaseRunning' | 'PhaseGameOver'
