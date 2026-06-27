module Server.Broadcast
    ( broadcast
    , sendTo
    ) where

import Control.Exception (SomeException, catch)
import qualified Data.Map.Strict as Map
import qualified Network.WebSockets as WS

import Game.Types
import Server.State
import Server.Protocol (encodeMessage)

-- | Send a message to all connected clients.
-- Silently swallows send errors (client likely disconnected).
broadcast :: ServerState -> ServerMessage -> IO ()
broadcast ss msg = do
    clients <- getClients ss
    let encoded = encodeMessage msg
    mapM_ (\conn -> sendRaw conn encoded) (Map.elems clients)

-- | Send a message to a single client by id.
sendTo :: ServerState -> ClientId -> ServerMessage -> IO ()
sendTo ss cid msg = do
    clients <- getClients ss
    case Map.lookup cid clients of
        Nothing   -> return ()
        Just conn -> sendRaw conn (encodeMessage msg)

-- | Low-level send with error swallowing
sendRaw :: WS.Connection -> WS.WebSocketsData a => a -> IO ()
sendRaw conn payload =
    WS.sendTextData conn payload
        `catch` (\(_ :: SomeException) -> return ())
