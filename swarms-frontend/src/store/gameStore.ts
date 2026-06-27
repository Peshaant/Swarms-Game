import { create } from 'zustand'
import { GameWorld, Delta } from '../types/world'
import { Phase } from '../types/entities'

// ---------------------------------------------------------------------------
// Store shape
// ---------------------------------------------------------------------------

interface GameStore {
  world:          GameWorld | null
  connectionStatus: 'connecting' | 'open' | 'closed'
  gameOver:       { score: number; wave: number; reason: string } | null

  // Actions
  setWorld:       (w: GameWorld) => void
  applyDeltas:    (deltas: Delta[]) => void
  setStatus:      (s: 'connecting' | 'open' | 'closed') => void
  setGameOver:    (info: { score: number; wave: number; reason: string }) => void
  reset:          () => void
}

// ---------------------------------------------------------------------------
// Delta application
-- The key optimization: patch only what changed, don't replace the whole world.
// ---------------------------------------------------------------------------

function applyDelta(world: GameWorld, delta: Delta): GameWorld {
  switch (delta.tag) {
    case 'DeltaEntitySpawned': {
      return {
        ...world,
        worldEntities: { ...world.worldEntities, [delta.id]: delta.entity },
      }
    }
    case 'DeltaEntityMoved': {
      const entity = world.worldEntities[delta.id]
      if (!entity) return world
      // Update entity position based on its type
      const moved = updateEntityPos(entity, delta.to)
      return {
        ...world,
        worldEntities: { ...world.worldEntities, [delta.id]: moved },
      }
    }
    case 'DeltaEntityDamaged': {
      const entity = world.worldEntities[delta.id]
      if (!entity) return world
      const damaged = updateEntityHp(entity, delta.hp)
      return {
        ...world,
        worldEntities: { ...world.worldEntities, [delta.id]: damaged },
      }
    }
    case 'DeltaEntityDied': {
      const { [delta.id]: _removed, ...rest } = world.worldEntities
      return { ...world, worldEntities: rest }
    }
    case 'DeltaTileChanged': {
      const key = `${delta.pos.posX},${delta.pos.posY}`
      return {
        ...world,
        worldGrid: { ...world.worldGrid, [key]: delta.tile },
      }
    }
    case 'DeltaWaveChanged':
      return { ...world, worldWave: delta.wave }
    case 'DeltaPhaseChanged':
      return { ...world, worldPhase: delta.phase }
    case 'DeltaScoreChanged':
      return { ...world, worldScore: delta.score }
    case 'DeltaBaseHpChanged':
      return { ...world, worldBase: { ...world.worldBase, baseHp: delta.hp } }
    default:
      return world
  }
}

// ---------------------------------------------------------------------------
// Entity position/hp patching helpers
// ---------------------------------------------------------------------------

import { Entity, Pos } from '../types/entities'

function updateEntityPos(entity: Entity, to: Pos): Entity {
  switch (entity.tag) {
    case 'EEnemy':
      return { ...entity, contents: { ...entity.contents, enemyPos: to } }
    case 'ETurret':
      return { ...entity, contents: { ...entity.contents, turretPos: to } }
    case 'EProjectile':
      return { ...entity, contents: { ...entity.contents, projPos: to } }
    default:
      return entity
  }
}

function updateEntityHp(entity: Entity, hp: number): Entity {
  switch (entity.tag) {
    case 'EEnemy':
      return { ...entity, contents: { ...entity.contents, enemyHp: hp } }
    case 'ETurret':
      return { ...entity, contents: { ...entity.contents, turretHp: hp } }
    case 'EBase':
      return { ...entity, contents: { ...entity.contents, baseHp: hp } }
    default:
      return entity
  }
}

// ---------------------------------------------------------------------------
// Store
// ---------------------------------------------------------------------------

export const useGameStore = create<GameStore>((set, get) => ({
  world:            null,
  connectionStatus: 'connecting',
  gameOver:         null,

  setWorld: (w) => set({ world: w }),

  applyDeltas: (deltas) => {
    const { world } = get()
    if (!world) return
    const next = deltas.reduce(applyDelta, world)
    set({ world: next })
  },

  setStatus: (s) => set({ connectionStatus: s }),

  setGameOver: (info) => set({ gameOver: info }),

  reset: () => set({ world: null, gameOver: null, connectionStatus: 'connecting' }),
}))
