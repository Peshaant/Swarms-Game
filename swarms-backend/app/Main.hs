module Main where

import Control.Concurrent (forkIO, threadDelay)
import Control.Concurrent.STM
import Control.Monad (forever, when)
import qualified Network.WebSockets as WS
import qualified Network.Wai.Handler.Warp as Warp
import qualified Network.Wai as Wai
import Network.Wai.Handler.WebSockets (websocketsOr)

import Game.Types
import Game.Tick (stepWorld)
import Server.State
import Server.Handler (handleClient)
import Server.Broadcast (broadcast)
import qualified Config as C

-- ---------------------------------------------------------------------------
-- Entry point
-- ---------------------------------------------------------------------------

main :: IO ()
main = do
    putStrLn $ "Swarms server starting on port " <> show C.serverPort
    ss <- newServerState

    -- Game loop in its own thread
    _ <- forkIO (gameLoop ss)

    -- WebSocket server (wrapped in WAI for easy CORS/HTTP upgrade handling)
    let wsApp     = WS.defaultServerApp (handleClient ss)
        httpApp   = corsMiddleware (websocketsOr WS.defaultConnectionOptions wsApp fallbackApp)

    Warp.run C.serverPort httpApp

-- ---------------------------------------------------------------------------
-- Game loop
-- ---------------------------------------------------------------------------

-- | Runs every tickRateMs milliseconds. Reads world, steps it, writes back,
-- broadcasts deltas to all connected clients.
gameLoop :: ServerState -> IO ()
gameLoop ss = forever $ do
    (world', deltas, rng') <- atomically $ do
        world <- readTVar (ssWorld ss)
        rng   <- readTVar (ssRng ss)
        let (world', deltas, rng') = stepWorld rng world
        writeTVar (ssWorld ss) world'
        writeTVar (ssRng   ss) rng'
        return (world', deltas, rng')

    when (not (null deltas)) $
        broadcast ss (SStateDelta deltas)

    -- Check game over and broadcast
    when (worldPhase world' == PhaseGameOver) $ do
        let info = GameOverInfo
                { gameOverScore  = worldScore world'
                , gameOverWave   = waveNumber' world'
                , gameOverReason = "Base destroyed"
                }
        broadcast ss (SGameOver info)

    threadDelay (C.tickRateMs * 1000)   -- microseconds

waveNumber' :: GameWorld -> Int
waveNumber' w = case worldWave w of
    WaveIdle                             -> 0
    WaveInProgress { waveNumber = n }    -> n
    WaveCooldown   { waveNumber = n }    -> n

-- ---------------------------------------------------------------------------
-- HTTP fallback (for health checks, CORS preflight)
-- ---------------------------------------------------------------------------

fallbackApp :: Wai.Application
fallbackApp _req respond =
    respond $ Wai.responseLBS
        (toEnum 200)
        [("Content-Type", "text/plain"), corsHeaders]
        "Swarms WebSocket server"

corsMiddleware :: Wai.Middleware
corsMiddleware app req respond =
    app req $ \res ->
        respond (Wai.mapResponseHeaders (<> corsHeaders) res)

corsHeaders :: (Wai.HeaderName, WS.Headers)
corsHeaders = ("Access-Control-Allow-Origin", "*")
