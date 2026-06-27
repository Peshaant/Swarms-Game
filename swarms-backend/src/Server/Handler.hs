module Server.Handler
    ( handleClient
    ) where

import Control.Concurrent (forkIO)
import Control.Concurrent.STM
import Control.Exception (SomeException, catch, finally)
import qualified Network.WebSockets as WS

import Game.Types
import Game.Tick (applyClientMessage)
import Server.State
import Server.Broadcast (sendTo, broadcast)
import Server.Protocol (decodeMessage)

-- ---------------------------------------------------------------------------
-- Per-client handler
-- ---------------------------------------------------------------------------

-- | Called for each new WebSocket connection.
-- Registers the client, sends a state snapshot, then loops on messages.
handleClient :: ServerState -> WS.PendingConnection -> IO ()
handleClient ss pending = do
    conn <- WS.acceptRequest pending
    cid  <- addClient ss conn

    -- Send current world snapshot on connect
    world <- readTVarIO (ssWorld ss)
    sendTo ss cid (SStateSnapshot world)

    -- Handle messages until disconnect
    let loop = do
            msg <- WS.receiveData conn
            case decodeMessage msg of
                Left err  -> sendTo ss cid (SError ("Bad message: " <> err))
                Right cmsg -> handleClientMessage ss cid cmsg
            loop

    loop `finally` removeClient ss cid

-- ---------------------------------------------------------------------------
-- Message dispatch
-- ---------------------------------------------------------------------------

handleClientMessage :: ServerState -> ClientId -> ClientMessage -> IO ()
handleClientMessage ss cid = \case
    CPing -> sendTo ss cid SPong

    msg   -> atomically $ do
        world <- readTVar (ssWorld ss)
        case applyClientMessage msg world of
            Left err      -> return ()   -- could send error back outside STM
            Right (world', deltas) -> do
                writeTVar (ssWorld ss) world'
                return ()
        -- Broadcast happens outside STM (see note below)
      -- NOTE: We broadcast outside the STM block to avoid IO inside atomically.
      -- This means there's a tiny window where another tick could fire between
      -- the write and the broadcast. For a game this is acceptable.
      -- For strict ordering guarantees, use a broadcast queue (TQueue).
