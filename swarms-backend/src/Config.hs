module Config where

-- | Game loop tick rate in milliseconds
tickRateMs :: Int
tickRateMs = 100

-- | Grid dimensions
gridWidth :: Int
gridWidth = 30

gridHeight :: Int
gridHeight = 20

-- | Base starting HP
baseHp :: Int
baseHp = 100

-- | Turret stats
turretRange :: Int
turretRange = 4

turretDamage :: Int
turretDamage = 15

turretCooldownTicks :: Int
turretCooldownTicks = 5

turretHp :: Int
turretHp = 50

-- | Enemy base stats (scaled per wave)
enemyBaseHp :: Int
enemyBaseHp = 30

enemyBaseDamage :: Int
enemyBaseDamage = 10

enemyBaseReward :: Int
enemyBaseReward = 10

-- | Number of ticks between enemy movement steps
enemyMoveIntervalTicks :: Int
enemyMoveIntervalTicks = 3

-- | Wave configuration
baseEnemiesPerWave :: Int
baseEnemiesPerWave = 5

enemiesPerWaveScaling :: Int
enemiesPerWaveScaling = 3

ticksBetweenSpawns :: Int
ticksBetweenSpawns = 8

-- | Ticks to wait between wave end and next wave start
waveIntervalTicks :: Int
waveIntervalTicks = 50

-- | WebSocket server port
serverPort :: Int
serverPort = 8080
