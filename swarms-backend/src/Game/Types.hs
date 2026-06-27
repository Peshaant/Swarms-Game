module Game.Types where

import Data.Map.Strict (Map)
import Data.Aeson (ToJSON, FromJSON)
import GHC.Generics (Generic)

-- ---------------------------------------------------------------------------
-- Primitives
-- ---------------------------------------------------------------------------

type EntityId = Int

data Pos = Pos
    { posX :: !Int
    , posY :: !Int
    } deriving (Show, Eq, Ord, Generic, ToJSON, FromJSON)

-- | Manhattan distance between two positions
manhattan :: Pos -> Pos -> Int
manhattan (Pos x1 y1) (Pos x2 y2) = abs (x1 - x2) + abs (y1 - y2)

-- | Euclidean distance squared (avoid sqrt for range checks)
distSq :: Pos -> Pos -> Int
distSq (Pos x1 y1) (Pos x2 y2) = (x1 - x2) ^ (2 :: Int) + (y1 - y2) ^ (2 :: Int)

-- ---------------------------------------------------------------------------
-- Tiles
-- ---------------------------------------------------------------------------

data Tile
    = TileEmpty
    | TileWall
    | TileOccupied !EntityId
    deriving (Show, Eq, Generic, ToJSON, FromJSON)

type Grid = Map Pos Tile

-- ---------------------------------------------------------------------------
-- Entities
-- ---------------------------------------------------------------------------

-- | A turret placed by the player
data Turret = Turret
    { turretId       :: !EntityId
    , turretPos      :: !Pos
    , turretHp       :: !Int
    , turretRange    :: !Int        -- in tiles (Chebyshev)
    , turretDamage   :: !Int
    , turretCooldown :: !Int        -- ticks remaining until next shot
    , turretTarget   :: !(Maybe EntityId)
    } deriving (Show, Eq, Generic, ToJSON, FromJSON)

-- | An enemy unit pathfinding toward the base
data Enemy = Enemy
    { enemyId     :: !EntityId
    , enemyPos    :: !Pos
    , enemyHp     :: !Int
    , enemyDamage :: !Int           -- damage dealt to base on arrival
    , enemyReward :: !Int           -- score on kill
    , enemyPath   :: ![Pos]         -- pre-computed path (head = next step)
    , enemyMoveTick :: !Int         -- ticks until next movement
    } deriving (Show, Eq, Generic, ToJSON, FromJSON)

-- | A projectile in flight
data Projectile = Projectile
    { projId      :: !EntityId
    , projPos     :: !Pos
    , projTarget  :: !EntityId      -- enemy id
    , projDamage  :: !Int
    } deriving (Show, Eq, Generic, ToJSON, FromJSON)

-- | The player's base
data Base = Base
    { basePos :: !Pos
    , baseHp  :: !Int
    } deriving (Show, Eq, Generic, ToJSON, FromJSON)

-- | Top-level entity sum type — no OOP hierarchy
data Entity
    = EBase       !Base
    | ETurret     !Turret
    | EEnemy      !Enemy
    | EProjectile !Projectile
    deriving (Show, Eq, Generic, ToJSON, FromJSON)

entityId :: Entity -> EntityId
entityId = \case
    EBase _       -> 0          -- base always has id 0
    ETurret t     -> turretId t
    EEnemy e      -> enemyId e
    EProjectile p -> projId p

entityPos :: Entity -> Pos
entityPos = \case
    EBase b       -> basePos b
    ETurret t     -> turretPos t
    EEnemy e      -> enemyPos e
    EProjectile p -> projPos p

-- ---------------------------------------------------------------------------
-- Wave
-- ---------------------------------------------------------------------------

data WaveStatus
    = WaveIdle                     -- no wave running, waiting for player
    | WaveInProgress
        { waveNumber    :: !Int
        , enemiesToSpawn :: !Int   -- remaining to spawn this wave
        , spawnTimer    :: !Int    -- ticks until next spawn
        }
    | WaveCooldown
        { waveNumber    :: !Int
        , cooldownTicks :: !Int    -- ticks until next wave can start
        }
    deriving (Show, Eq, Generic, ToJSON, FromJSON)

-- ---------------------------------------------------------------------------
-- Game phase
-- ---------------------------------------------------------------------------

data Phase
    = PhaseWaiting    -- lobby / between waves
    | PhaseRunning    -- wave active
    | PhaseGameOver   -- base destroyed
    deriving (Show, Eq, Generic, ToJSON, FromJSON)

-- ---------------------------------------------------------------------------
-- World
-- ---------------------------------------------------------------------------

data GameWorld = GameWorld
    { worldGrid       :: !Grid
    , worldEntities   :: !(Map EntityId Entity)
    , worldBase       :: !Base
    , worldWave       :: !WaveStatus
    , worldPhase      :: !Phase
    , worldScore      :: !Int
    , worldTick       :: !Int
    , worldNextId     :: !EntityId   -- monotonic id counter
    } deriving (Show, Eq, Generic, ToJSON, FromJSON)

-- ---------------------------------------------------------------------------
-- Deltas (incremental state updates sent to clients)
-- ---------------------------------------------------------------------------

data Delta
    = DeltaEntitySpawned  !EntityId !Entity
    | DeltaEntityMoved    !EntityId !Pos !Pos        -- id, from, to
    | DeltaEntityDamaged  !EntityId !Int             -- id, new hp
    | DeltaEntityDied     !EntityId
    | DeltaTileChanged    !Pos !Tile
    | DeltaWaveChanged    !WaveStatus
    | DeltaPhaseChanged   !Phase
    | DeltaScoreChanged   !Int
    | DeltaBaseHpChanged  !Int
    deriving (Show, Eq, Generic, ToJSON, FromJSON)

-- ---------------------------------------------------------------------------
-- Client → Server messages
-- ---------------------------------------------------------------------------

data ClientMessage
    = CPlaceTurret !Pos
    | CStartWave
    | CSurrender
    | CPing
    deriving (Show, Eq, Generic, ToJSON, FromJSON)

-- ---------------------------------------------------------------------------
-- Server → Client messages
-- ---------------------------------------------------------------------------

data ServerMessage
    = SStateSnapshot !GameWorld
    | SStateDelta    ![Delta]
    | SWaveAnnounce  !WaveInfo
    | SGameOver      !GameOverInfo
    | SPong
    | SError         !String
    deriving (Show, Eq, Generic, ToJSON, FromJSON)

data WaveInfo = WaveInfo
    { waveInfoNumber   :: !Int
    , waveInfoEnemies  :: !Int
    , waveInfoStarting :: !Bool
    } deriving (Show, Eq, Generic, ToJSON, FromJSON)

data GameOverInfo = GameOverInfo
    { gameOverScore  :: !Int
    , gameOverWave   :: !Int
    , gameOverReason :: !String
    } deriving (Show, Eq, Generic, ToJSON, FromJSON)
