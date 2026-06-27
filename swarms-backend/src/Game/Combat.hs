module Game.Combat
    ( resolveTurrets
    , resolveProjectiles
    , resolveEnemyReachedBase
    ) where

import Data.List (minimumBy)
import Data.Map.Strict (Map)
import qualified Data.Map.Strict as Map
import Data.Ord (comparing)
import Data.Maybe (mapMaybe, listToMaybe)

import Game.Types
import Game.World

-- ---------------------------------------------------------------------------
-- Turret logic
-- ---------------------------------------------------------------------------

-- | For each turret: decrement cooldown, acquire target, fire projectile.
-- Returns updated world, list of new projectiles, and damage deltas.
resolveTurrets
    :: GameWorld
    -> ([Projectile], [EntityId], GameWorld)
    --   new projs   , turrets that fired (for delta gen), updated world
resolveTurrets world =
    let turrets = worldTurrets world
        enemies = worldEnemies world
        (newProjs, firedIds, world') =
            foldl (stepTurret enemies) ([], [], world) turrets
    in (newProjs, firedIds, world')

stepTurret
    :: [Enemy]
    -> ([Projectile], [EntityId], GameWorld)
    -> Turret
    -> ([Projectile], [EntityId], GameWorld)
stepTurret enemies (projs, fired, world) turret =
    let turret' = turret { turretCooldown = max 0 (turretCooldown turret - 1) }
    in if turretCooldown turret' > 0
        then (projs, fired, updateEntity (turretId turret') (ETurret turret') world)
        else
            -- find nearest enemy in range
            case acquireTarget turret' enemies of
                Nothing  ->
                    (projs, fired, updateEntity (turretId turret') (ETurret turret') world)
                Just enemy ->
                    let proj = Projectile
                            { projId     = 0    -- assigned by caller
                            , projPos    = turretPos turret'
                            , projTarget = enemyId enemy
                            , projDamage = turretDamage turret'
                            }
                        turret'' = turret'
                            { turretCooldown = turretCooldownTicks turret'
                            , turretTarget   = Just (enemyId enemy)
                            }
                        world' = updateEntity (turretId turret'') (ETurret turret'') world
                    in (proj : projs, turretId turret'' : fired, world')

-- | Pick the nearest in-range enemy (Chebyshev distance ≤ range)
acquireTarget :: Turret -> [Enemy] -> Maybe Enemy
acquireTarget turret enemies =
    let inRange = filter (isInRange turret) enemies
    in listToMaybe $
        minimumBy (comparing (\e -> distSq (turretPos turret) (enemyPos e))) <$>
        (if null inRange then Nothing else Just inRange)

isInRange :: Turret -> Enemy -> Bool
isInRange turret enemy =
    chebyshev (turretPos turret) (enemyPos enemy) <= turretRange turret

chebyshev :: Pos -> Pos -> Int
chebyshev (Pos x1 y1) (Pos x2 y2) = max (abs (x1-x2)) (abs (y1-y2))

-- ---------------------------------------------------------------------------
-- Projectile resolution
-- ---------------------------------------------------------------------------

-- | Apply projectile damage to their targets.
-- Returns: (updated world, deltas for damaged/killed enemies, score gained)
resolveProjectiles
    :: GameWorld
    -> [Projectile]
    -> ([Delta], Int, GameWorld)
resolveProjectiles world projs =
    foldl applyProjectile ([], 0, world) projs

applyProjectile
    :: ([Delta], Int, GameWorld)
    -> Projectile
    -> ([Delta], Int, GameWorld)
applyProjectile (deltas, score, world) proj =
    case Map.lookup (projTarget proj) (worldEntities world) of
        Just (EEnemy enemy) ->
            let newHp = enemyHp enemy - projDamage proj
            in if newHp <= 0
                then
                    -- enemy dies
                    let world'  = removeEntity (enemyId enemy) world
                        score'  = score + enemyReward enemy
                        deltas' = DeltaEntityDied (enemyId enemy)
                                : DeltaScoreChanged (worldScore world' + score')
                                : deltas
                    in (deltas', score', world')
                else
                    -- enemy damaged
                    let enemy'  = enemy { enemyHp = newHp }
                        world'  = updateEntity (enemyId enemy') (EEnemy enemy') world
                        deltas' = DeltaEntityDamaged (enemyId enemy') newHp : deltas
                    in (deltas', score, world')
        _ -> (deltas, score, world)   -- target already dead or missing

-- ---------------------------------------------------------------------------
-- Enemy reaches base
-- ---------------------------------------------------------------------------

-- | Check for enemies that have reached the base and deal damage.
-- Returns deltas and updated world.
resolveEnemyReachedBase :: GameWorld -> ([Delta], GameWorld)
resolveEnemyReachedBase world =
    let base    = worldBase world
        arrived = filter (\e -> enemyPos e == basePos base) (worldEnemies world)
    in foldl (damageBase) ([], world) arrived

damageBase :: ([Delta], GameWorld) -> Enemy -> ([Delta], GameWorld)
damageBase (deltas, world) enemy =
    let base     = worldBase world
        newHp    = baseHp base - enemyDamage enemy
        base'    = base { baseHp = newHp }
        world'   = (removeEntity (enemyId enemy) world) { worldBase = base' }
        deltas'  = DeltaEntityDied (enemyId enemy)
                 : DeltaBaseHpChanged newHp
                 : deltas
    in (deltas', world')
