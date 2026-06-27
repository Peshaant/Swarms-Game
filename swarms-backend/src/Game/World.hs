module Game.World where

import Data.Map.Strict (Map)
import qualified Data.Map.Strict as Map

import Game.Types
import qualified Config as C

-- ---------------------------------------------------------------------------
-- World construction
-- ---------------------------------------------------------------------------

-- | Build the initial game world. Base sits at grid center.
initialWorld :: GameWorld
initialWorld = GameWorld
    { worldGrid     = buildGrid
    , worldEntities = Map.singleton 0 (EBase initialBase)
    , worldBase     = initialBase
    , worldWave     = WaveIdle
    , worldPhase    = PhaseWaiting
    , worldScore    = 0
    , worldTick     = 0
    , worldNextId   = 1
    }

initialBase :: Base
initialBase = Base
    { basePos = centerPos
    , baseHp  = C.baseHp
    }

centerPos :: Pos
centerPos = Pos (C.gridWidth `div` 2) (C.gridHeight `div` 2)

-- | Empty grid — walls can be added later for map variety
buildGrid :: Grid
buildGrid = Map.fromList
    [ (Pos x y, TileEmpty)
    | x <- [0 .. C.gridWidth  - 1]
    , y <- [0 .. C.gridHeight - 1]
    ]

-- ---------------------------------------------------------------------------
-- World queries
-- ---------------------------------------------------------------------------

-- | All enemies currently in the world
worldEnemies :: GameWorld -> [Enemy]
worldEnemies w =
    [ e | EEnemy e <- Map.elems (worldEntities w) ]

-- | All turrets currently in the world
worldTurrets :: GameWorld -> [Turret]
worldTurrets w =
    [ t | ETurret t <- Map.elems (worldEntities w) ]

-- | All projectiles currently in the world
worldProjectiles :: GameWorld -> [Projectile]
worldProjectiles w =
    [ p | EProjectile p <- Map.elems (worldEntities w) ]

-- | Look up an entity by id
lookupEntity :: EntityId -> GameWorld -> Maybe Entity
lookupEntity eid w = Map.lookup eid (worldEntities w)

-- | Check if a position is within grid bounds
inBounds :: Pos -> Bool
inBounds (Pos x y) =
    x >= 0 && x < C.gridWidth &&
    y >= 0 && y < C.gridHeight

-- | Check if a position is passable (not a wall, not occupied by a turret/base)
isPassable :: GameWorld -> Pos -> Bool
isPassable w pos = case Map.lookup pos (worldGrid w) of
    Just TileEmpty      -> True
    Just (TileOccupied eid) ->
        -- enemies can walk through other enemies but not structures
        case Map.lookup eid (worldEntities w) of
            Just (EEnemy _) -> True
            _               -> False
    _                   -> False

-- ---------------------------------------------------------------------------
-- World mutation helpers (return new world + delta list)
-- ---------------------------------------------------------------------------

-- | Insert a new entity, assign it the next available id
insertEntity :: Entity -> GameWorld -> (EntityId, GameWorld)
insertEntity entity w =
    let eid   = worldNextId w
        entity' = setEntityId eid entity
        w' = w
            { worldEntities = Map.insert eid entity' (worldEntities w)
            , worldNextId   = eid + 1
            , worldGrid     = updateGridForEntity eid (entityPos entity') (worldGrid w)
            }
    in (eid, w')

-- | Remove an entity and clear its tile
removeEntity :: EntityId -> GameWorld -> GameWorld
removeEntity eid w =
    case Map.lookup eid (worldEntities w) of
        Nothing -> w
        Just e  ->
            let pos = entityPos e
                grid' = Map.insert pos TileEmpty (worldGrid w)
            in w
                { worldEntities = Map.delete eid (worldEntities w)
                , worldGrid     = grid'
                }

-- | Update an entity in place (same id, possibly new position)
updateEntity :: EntityId -> Entity -> GameWorld -> GameWorld
updateEntity eid entity w =
    let oldPos = fmap entityPos (Map.lookup eid (worldEntities w))
        newPos = entityPos entity
        grid'  = case oldPos of
            Just op | op /= newPos ->
                Map.insert op TileEmpty $
                Map.insert newPos (TileOccupied eid) (worldGrid w)
            _ -> worldGrid w
    in w
        { worldEntities = Map.insert eid entity (worldEntities w)
        , worldGrid     = grid'
        }

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

setEntityId :: EntityId -> Entity -> Entity
setEntityId eid = \case
    EBase b       -> EBase b
    ETurret t     -> ETurret t { turretId = eid }
    EEnemy e      -> EEnemy  e { enemyId  = eid }
    EProjectile p -> EProjectile p { projId = eid }

updateGridForEntity :: EntityId -> Pos -> Grid -> Grid
updateGridForEntity eid pos = Map.insert pos (TileOccupied eid)

-- | Spawn positions: all 4 edges of the grid
spawnPositions :: [Pos]
spawnPositions =
    [ Pos x 0               | x <- [0, 3 .. C.gridWidth  - 1] ] ++
    [ Pos x (C.gridHeight-1)| x <- [0, 3 .. C.gridWidth  - 1] ] ++
    [ Pos 0 y               | y <- [0, 3 .. C.gridHeight - 1] ] ++
    [ Pos (C.gridWidth-1) y | y <- [0, 3 .. C.gridHeight - 1] ]
