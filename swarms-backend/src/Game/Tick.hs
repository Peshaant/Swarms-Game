module Game.Tick
    ( stepWorld
    , applyClientMessage
    ) where

import Data.Map.Strict (Map)
import qualified Data.Map.Strict as Map
import System.Random (StdGen)

import Game.Types
import Game.World
import Game.Entity    (canPlaceTurret, makeTurret, moveEnemy)
import Game.Combat    (resolveTurrets, resolveProjectiles, resolveEnemyReachedBase)
import Game.Wave      (waveEnemyCount, spawnEnemy, nextWaveStatus, waveNumber)
import qualified Config as C

-- ---------------------------------------------------------------------------
-- Main tick — pure function, no IO
-- ---------------------------------------------------------------------------

-- | Advance the world by one tick.
-- Returns the new world, accumulated deltas, and updated RNG.
stepWorld :: StdGen -> GameWorld -> (GameWorld, [Delta], StdGen)
stepWorld rng world =
    case worldPhase world of
        PhaseGameOver -> (world, [], rng)
        PhaseWaiting  -> (tickWorld, [], rng)
        PhaseRunning  ->
            let (world1, deltas1, rng') = tickWave rng world
                (world2, deltas2)       = tickMovement world1
                (world3, deltas3)       = tickCombat world2
                (world4, deltas4)       = tickGameOverCheck world3
                allDeltas               = deltas1 <> deltas2 <> deltas3 <> deltas4
            in (world4, allDeltas, rng')
  where
    tickWorld = world { worldTick = worldTick world + 1 }

-- ---------------------------------------------------------------------------
-- Wave spawning
-- ---------------------------------------------------------------------------

tickWave :: StdGen -> GameWorld -> (GameWorld, [Delta], StdGen)
tickWave rng world = case worldWave world of
    WaveIdle -> (world { worldTick = worldTick world + 1 }, [], rng)

    WaveCooldown { waveNumber = n, cooldownTicks = t }
        | t <= 0 ->
            -- Transition to waiting for player to start next wave
            let wave'  = WaveIdle
                world' = world
                    { worldWave  = wave'
                    , worldPhase = PhaseWaiting
                    , worldTick  = worldTick world + 1
                    }
            in (world', [DeltaWaveChanged wave', DeltaPhaseChanged PhaseWaiting], rng)
        | otherwise ->
            let wave'  = WaveCooldown n (t - 1)
                world' = world
                    { worldWave = wave'
                    , worldTick = worldTick world + 1
                    }
            in (world', [DeltaWaveChanged wave'], rng)

    WaveInProgress { waveNumber = n, enemiesToSpawn = remaining, spawnTimer = timer }
        | remaining <= 0 && null (worldEnemies world) ->
            -- Wave complete
            let wave'  = nextWaveStatus n
                world' = world
                    { worldWave  = wave'
                    , worldPhase = PhaseWaiting
                    , worldTick  = worldTick world + 1
                    }
            in (world', [DeltaWaveChanged wave', DeltaPhaseChanged PhaseWaiting], rng)

        | remaining > 0 && timer <= 0 ->
            -- Spawn an enemy
            let (enemy, rng') = spawnEnemy rng world n
                (eid, world1) = insertEntity (EEnemy enemy) world
                wave'  = WaveInProgress n (remaining - 1) C.ticksBetweenSpawns
                world' = world1
                    { worldWave = wave'
                    , worldTick = worldTick world1 + 1
                    }
                spawnedEnemy = case Map.lookup eid (worldEntities world') of
                    Just e  -> e
                    Nothing -> EEnemy enemy
                deltas = [ DeltaEntitySpawned eid spawnedEnemy
                         , DeltaWaveChanged wave'
                         ]
            in (world', deltas, rng')

        | otherwise ->
            let wave'  = WaveInProgress n remaining (timer - 1)
                world' = world
                    { worldWave = wave'
                    , worldTick = worldTick world + 1
                    }
            in (world', [DeltaWaveChanged wave'], rng)

-- ---------------------------------------------------------------------------
-- Enemy movement
-- ---------------------------------------------------------------------------

tickMovement :: GameWorld -> (GameWorld, [Delta])
tickMovement world =
    let enemies  = worldEnemies world
        (world', deltas) = foldl stepEnemy (world, []) enemies
    in (world', deltas)

stepEnemy :: (GameWorld, [Delta]) -> Enemy -> (GameWorld, [Delta])
stepEnemy (world, deltas) enemy =
    case moveEnemy enemy of
        Nothing     -> (world, deltas)   -- arrived, handled in combat
        Just enemy' ->
            let from = enemyPos enemy
                to   = enemyPos enemy'
                world' = updateEntity (enemyId enemy') (EEnemy enemy') world
                delta  = if from /= to
                            then [DeltaEntityMoved (enemyId enemy') from to]
                            else []
            in (world', delta <> deltas)

-- ---------------------------------------------------------------------------
-- Combat resolution
-- ---------------------------------------------------------------------------

tickCombat :: GameWorld -> (GameWorld, [Delta])
tickCombat world =
    -- 1. Turrets acquire targets and fire
    let (newProjs, _, world1) = resolveTurrets world

    -- 2. Assign ids to new projectiles and insert them
        (world2, projDeltas, insertedProjs) =
            foldl insertProj (world1, [], []) newProjs

    -- 3. Resolve projectile → enemy damage (instant travel for simplicity)
        (dmgDeltas, scoreGained, world3) = resolveProjectiles world2 insertedProjs

    -- 4. Remove projectiles after resolution
        world4 = foldl (\w p -> removeEntity (projId p) w) world3 insertedProjs

    -- 5. Enemies that reached the base deal damage
        (baseDeltas, world5) = resolveEnemyReachedBase world4

    -- 6. Apply score
        world6 = world5
            { worldScore = worldScore world5 + scoreGained }

    in (world6, projDeltas <> dmgDeltas <> baseDeltas)

insertProj
    :: (GameWorld, [Delta], [Projectile])
    -> Projectile
    -> (GameWorld, [Delta], [Projectile])
insertProj (world, deltas, projs) proj =
    let (eid, world') = insertEntity (EProjectile proj) world
        proj'         = proj { projId = eid }
        entity        = EProjectile proj'
        delta         = DeltaEntitySpawned eid entity
    in (world', delta : deltas, proj' : projs)

-- ---------------------------------------------------------------------------
-- Game over check
-- ---------------------------------------------------------------------------

tickGameOverCheck :: GameWorld -> (GameWorld, [Delta])
tickGameOverCheck world
    | baseHp (worldBase world) <= 0 =
        let world' = world { worldPhase = PhaseGameOver }
        in (world', [DeltaPhaseChanged PhaseGameOver])
    | otherwise = (world, [])

-- ---------------------------------------------------------------------------
-- Client message handling — pure
-- ---------------------------------------------------------------------------

-- | Apply a client action to the world. Returns updated world + deltas.
applyClientMessage
    :: ClientMessage
    -> GameWorld
    -> (Either String (GameWorld, [Delta]))
applyClientMessage msg world = case msg of
    CPing -> Right (world, [])

    CSurrender ->
        Right (world { worldPhase = PhaseGameOver }, [DeltaPhaseChanged PhaseGameOver])

    CPlaceTurret pos ->
        case canPlaceTurret world pos of
            Left err -> Left err
            Right () ->
                let turret        = makeTurret pos
                    (eid, world') = insertEntity (ETurret turret) world
                    entity        = ETurret (turret { turretId = eid })
                in Right (world', [DeltaEntitySpawned eid entity])

    CStartWave ->
        case worldPhase world of
            PhaseWaiting ->
                let n     = waveNumber (worldWave world) + 1
                    count = waveEnemyCount n
                    wave' = WaveInProgress
                        { waveNumber     = n
                        , enemiesToSpawn = count
                        , spawnTimer     = 0
                        }
                    world' = world
                        { worldWave  = wave'
                        , worldPhase = PhaseRunning
                        }
                in Right (world', [ DeltaWaveChanged wave'
                                  , DeltaPhaseChanged PhaseRunning
                                  ])
            _ -> Left "A wave is already in progress"
