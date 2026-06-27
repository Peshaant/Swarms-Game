import React, { useCallback } from 'react'
import Cell from './Cell'
import { useWorld } from '../../hooks/useGameState'
import { Pos, Entity } from '../../types/entities'
import { gameSocket } from '../../ws/client'

const GRID_W = 30
const GRID_H = 20
const CELL_SIZE = 24   // px

export default function Grid() {
  const world = useWorld()

  const handleCellClick = useCallback((pos: Pos) => {
    if (!world || world.worldPhase === 'PhaseGameOver') return
    gameSocket.send({ tag: 'CPlaceTurret', pos })
  }, [world])

  if (!world) {
    return (
      <div style={containerStyle}>
        <p style={{ color: '#4fc3f7', fontFamily: 'monospace' }}>Connecting...</p>
      </div>
    )
  }

  // Build a pos → entity map for O(1) cell lookup
  const entityByPos: Record<string, Entity> = {}
  for (const entity of Object.values(world.worldEntities)) {
    const pos = getEntityPos(entity)
    if (pos) {
      entityByPos[`${pos.posX},${pos.posY}`] = entity
    }
  }

  const basePosKey = `${world.worldBase.basePos.posX},${world.worldBase.basePos.posY}`

  const cells = []
  for (let y = 0; y < GRID_H; y++) {
    for (let x = 0; x < GRID_W; x++) {
      const pos: Pos = { posX: x, posY: y }
      const key = `${x},${y}`
      const entity = entityByPos[key] ?? null
      const isBase = key === basePosKey
      cells.push(
        <Cell
          key={key}
          pos={pos}
          entity={entity}
          isBase={isBase}
          onClick={handleCellClick}
        />
      )
    }
  }

  return (
    <div style={containerStyle}>
      <div
        style={{
          display: 'grid',
          gridTemplateColumns: `repeat(${GRID_W}, ${CELL_SIZE}px)`,
          gridTemplateRows:    `repeat(${GRID_H}, ${CELL_SIZE}px)`,
          border: '2px solid #1e1e3f',
          borderRadius: 4,
          overflow: 'hidden',
        }}
      >
        {cells}
      </div>
    </div>
  )
}

const containerStyle: React.CSSProperties = {
  display:        'flex',
  justifyContent: 'center',
  alignItems:     'center',
  padding:        '16px',
}

function getEntityPos(entity: Entity): Pos | null {
  switch (entity.tag) {
    case 'EBase':       return entity.contents.basePos
    case 'ETurret':     return entity.contents.turretPos
    case 'EEnemy':      return entity.contents.enemyPos
    case 'EProjectile': return entity.contents.projPos
    default:            return null
  }
}
