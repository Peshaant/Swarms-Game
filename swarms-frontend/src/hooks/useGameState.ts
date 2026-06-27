import { useGameStore } from '../store/gameStore'
import { Enemy, Turret, Projectile } from '../types/entities'

// Typed selectors — components import from here, not directly from the store.

export const useWorld        = () => useGameStore(s => s.world)
export const usePhase        = () => useGameStore(s => s.world?.worldPhase ?? 'PhaseWaiting')
export const useScore        = () => useGameStore(s => s.world?.worldScore ?? 0)
export const useBase         = () => useGameStore(s => s.world?.worldBase)
export const useWave         = () => useGameStore(s => s.world?.worldWave)
export const useGameOver     = () => useGameStore(s => s.gameOver)
export const useConnStatus   = () => useGameStore(s => s.connectionStatus)

export function useEnemies(): Enemy[] {
  const entities = useGameStore(s => s.world?.worldEntities)
  if (!entities) return []
  return Object.values(entities)
    .filter(e => e.tag === 'EEnemy')
    .map(e => (e as { tag: 'EEnemy'; contents: Enemy }).contents)
}

export function useTurrets(): Turret[] {
  const entities = useGameStore(s => s.world?.worldEntities)
  if (!entities) return []
  return Object.values(entities)
    .filter(e => e.tag === 'ETurret')
    .map(e => (e as { tag: 'ETurret'; contents: Turret }).contents)
}

export function useProjectiles(): Projectile[] {
  const entities = useGameStore(s => s.world?.worldEntities)
  if (!entities) return []
  return Object.values(entities)
    .filter(e => e.tag === 'EProjectile')
    .map(e => (e as { tag: 'EProjectile'; contents: Projectile }).contents)
}
