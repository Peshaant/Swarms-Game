module Game.Wave
    ( waveEnemyCount
    , spawnEnemy
    , nextWaveStatus
    , waveNumber
    ) where

import System.Random (StdGen, randomR)

import Game.Types
import Game.World (spawnPositions, centerPos)
import Game.Pathfinding (findPath)
import qualified Config as C

-- ---------------------------------------------------------------------------
-- Wave metadata
-- ---------------------------------------------------------------------------

-- | Total enemies for a given wave number (1-indexed)
waveEnemyCount :: Int -> Int
waveEnemyCount n = C.baseEnemiesPerWave + (n - 1) * C.enemiesPerWaveScaling

-- | Enemy HP scaled by wave
waveEnemyHp :: Int -> Int
waveEnemyHp n = C.enemyBaseHp + (n - 1) * 10

-- | Enemy damage scaled by wave
waveEnemyDamage :: Int -> Int
waveEnemyDamage n = C.enemyBaseDamage + (n - 1) * 2

-- | Reward for killing an enemy scaled by wave
waveEnemyReward :: Int -> Int
waveEnemyReward n = C.enemyBaseReward + (n - 1) * 5

-- ---------------------------------------------------------------------------
-- Enemy spawning
-- ---------------------------------------------------------------------------

-- | Spawn a new enemy for the given wave, picking a random edge position.
-- Returns the enemy (without an id — caller assigns one) and updated RNG.
spawnEnemy :: StdGen -> GameWorld -> Int -> (Enemy, StdGen)
spawnEnemy rng world waveN =
    let positions         = spawnPositions
        (idx, rng')       = randomR (0, length positions - 1) rng
        spawnPos          = positions !! idx
        path              = case findPath world spawnPos centerPos of
                                Just p  -> p
                                Nothing -> []   -- no path — enemy is stuck
        enemy = Enemy
            { enemyId       = 0   -- assigned by insertEntity
            , enemyPos      = spawnPos
            , enemyHp       = waveEnemyHp waveN
            , enemyDamage   = waveEnemyDamage waveN
            , enemyReward   = waveEnemyReward waveN
            , enemyPath     = path
            , enemyMoveTick = C.enemyMoveIntervalTicks
            }
    in (enemy, rng')

-- ---------------------------------------------------------------------------
-- Wave state transitions
-- ---------------------------------------------------------------------------

-- | Compute the next WaveStatus when a wave has completed (all enemies dead)
nextWaveStatus :: Int -> WaveStatus
nextWaveStatus completedWave = WaveCooldown
    { waveNumber    = completedWave
    , cooldownTicks = C.waveIntervalTicks
    }

-- | Extract the current wave number from WaveStatus
waveNumber :: WaveStatus -> Int
waveNumber WaveIdle                     = 0
waveNumber (WaveInProgress { waveNumber = n }) = n
waveNumber (WaveCooldown   { waveNumber = n }) = n
