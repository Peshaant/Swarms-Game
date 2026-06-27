module Game.Entity
    ( canPlaceTurret
    , makeTurret
    , moveEnemy
    ) where

import qualified Data.Map.Strict as Map

import Game.Types
import Game.World (inBounds)
import qualified Config as C

-- ---------------------------------------------------------------------------
-- Turret placement
-- ---------------------------------------------------------------------------

-- | Validate that a turret can be placed at the given position.
canPlaceTurret :: GameWorld -> Pos -> Either String ()
canPlaceTurret world pos
    | not (inBounds pos)
        = Left "Position out of bounds"
    | pos == basePos (worldBase world)
        = Left "Cannot place turret on the base"
    | Map.member pos (worldGrid world) && isSolid (worldGrid world Map.! pos)
        = Left "Position is already occupied"
    | otherwise
        = Right ()
  where
    isSolid TileEmpty        = False
    isSolid TileWall         = True
    isSolid (TileOccupied _) = True

-- | Construct a fresh turret at the given position (id assigned later)
makeTurret :: Pos -> Turret
makeTurret pos = Turret
    { turretId       = 0
    , turretPos      = pos
    , turretHp       = C.turretHp
    , turretRange    = C.turretRange
    , turretDamage   = C.turretDamage
    , turretCooldown = 0
    , turretTarget   = Nothing
    }

-- ---------------------------------------------------------------------------
-- Enemy movement
-- ---------------------------------------------------------------------------

-- | Advance an enemy one step along its pre-computed path.
-- Returns Nothing if the enemy has no path left (it has arrived).
moveEnemy :: Enemy -> Maybe Enemy
moveEnemy enemy = case enemyPath enemy of
    []     -> Nothing          -- arrived (handled by combat resolution)
    (next:rest) ->
        if enemyMoveTick enemy > 0
            then Just enemy { enemyMoveTick = enemyMoveTick enemy - 1 }
            else Just enemy
                { enemyPos      = next
                , enemyPath     = rest
                , enemyMoveTick = C.enemyMoveIntervalTicks
                }
