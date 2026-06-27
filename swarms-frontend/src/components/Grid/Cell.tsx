import React, { memo } from 'react'
import { Pos, Entity } from '../../types/entities'

interface CellProps {
  pos:      Pos
  entity:   Entity | null
  isBase:   boolean
  onClick:  (pos: Pos) => void
}

// Memoized so only cells with changed entity/state re-render
const Cell = memo(function Cell({ pos, entity, isBase, onClick }: CellProps) {
  const { char, color, bg } = resolveCellVisual(entity, isBase)

  return (
    <div
      className="cell"
      style={{
        gridColumn: pos.posX + 1,
        gridRow:    pos.posY + 1,
        display:    'flex',
        alignItems:     'center',
        justifyContent: 'center',
        cursor:     entity?.tag === 'ETurret' || isBase ? 'default' : 'pointer',
        backgroundColor: bg,
        color,
        fontFamily: 'monospace',
        fontSize:   '14px',
        userSelect: 'none',
        border:     '1px solid #1a1a2e',
        transition: 'background-color 0.1s',
      }}
      onClick={() => onClick(pos)}
    >
      {char}
    </div>
  )
})

export default Cell

// ---------------------------------------------------------------------------
// Visual mapping
// ---------------------------------------------------------------------------

interface CellVisual { char: string; color: string; bg: string }

function resolveCellVisual(entity: Entity | null, isBase: boolean): CellVisual {
  if (isBase) return { char: '⬡', color: '#00ffcc', bg: '#0a0a1a' }

  if (!entity) return { char: ' ', color: 'transparent', bg: '#0d0d1f' }

  switch (entity.tag) {
    case 'EBase':
      return { char: '⬡', color: '#00ffcc', bg: '#0a0a1a' }
    case 'ETurret':
      return { char: '▲', color: '#4fc3f7', bg: '#0a0a2e' }
    case 'EEnemy':
      return { char: '●', color: '#ff4444', bg: '#1a0000' }
    case 'EProjectile':
      return { char: '·', color: '#ffeb3b', bg: '#0d0d1f' }
    default:
      return { char: ' ', color: 'transparent', bg: '#0d0d1f' }
  }
}
