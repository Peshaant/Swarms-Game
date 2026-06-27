import { Entity, Pos, Tile, Base, WaveStatus, Phase } from './entities'

// ---------------------------------------------------------------------------
// World
// ---------------------------------------------------------------------------

export interface GameWorld {
  worldGrid:     Record<string, Tile>    // "x,y" → Tile
  worldEntities: Record<number, Entity>  // EntityId → Entity
  worldBase:     Base
  worldWave:     WaveStatus
  worldPhase:    Phase
  worldScore:    number
  worldTick:     number
  worldNextId:   number
}

// ---------------------------------------------------------------------------
// Deltas
// ---------------------------------------------------------------------------

export type Delta =
  | { tag: 'DeltaEntitySpawned';  id: number; entity: Entity }
  | { tag: 'DeltaEntityMoved';    id: number; from: Pos; to: Pos }
  | { tag: 'DeltaEntityDamaged';  id: number; hp: number }
  | { tag: 'DeltaEntityDied';     id: number }
  | { tag: 'DeltaTileChanged';    pos: Pos; tile: Tile }
  | { tag: 'DeltaWaveChanged';    wave: WaveStatus }
  | { tag: 'DeltaPhaseChanged';   phase: Phase }
  | { tag: 'DeltaScoreChanged';   score: number }
  | { tag: 'DeltaBaseHpChanged';  hp: number }
