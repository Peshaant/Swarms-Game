module Server.State
    ( ServerState (..)
    , ClientId
    , ClientConn
    , newServerState
    , addClient
    , removeClient
    , getClients
    ) where

import Control.Concurrent.STM
import Data.Map.Strict (Map)
import qualified Data.Map.Strict as Map
import qualified Network.WebSockets as WS
import System.Random (StdGen, newStdGen)

import Game.Types
import Game.World (initialWorld)

-- ---------------------------------------------------------------------------
-- Types
-- ---------------------------------------------------------------------------

type ClientId   = Int
type ClientConn = WS.Connection

-- | All shared mutable state for the server.
-- Wrapped in STM so WebSocket threads and the game loop can safely share it.
data ServerState = ServerState
    { ssWorld   :: !(TVar GameWorld)
    , ssRng     :: !(TVar StdGen)
    , ssClients :: !(TVar (Map ClientId ClientConn))
    , ssNextCid :: !(TVar ClientId)
    }

-- ---------------------------------------------------------------------------
-- Construction
-- ---------------------------------------------------------------------------

newServerState :: IO ServerState
newServerState = do
    rng     <- newStdGen
    world   <- newTVarIO initialWorld
    rngVar  <- newTVarIO rng
    clients <- newTVarIO Map.empty
    nextCid <- newTVarIO 0
    return ServerState
        { ssWorld   = world
        , ssRng     = rngVar
        , ssClients = clients
        , ssNextCid = nextCid
        }

-- ---------------------------------------------------------------------------
-- Client registry
-- ---------------------------------------------------------------------------

-- | Register a new client. Returns the assigned ClientId.
addClient :: ServerState -> ClientConn -> IO ClientId
addClient ss conn = atomically $ do
    cid <- readTVar (ssNextCid ss)
    modifyTVar' (ssClients ss) (Map.insert cid conn)
    writeTVar (ssNextCid ss) (cid + 1)
    return cid

-- | Deregister a client by id.
removeClient :: ServerState -> ClientId -> IO ()
removeClient ss cid =
    atomically $ modifyTVar' (ssClients ss) (Map.delete cid)

-- | Get a snapshot of all connected clients.
getClients :: ServerState -> IO (Map ClientId ClientConn)
getClients ss = readTVarIO (ssClients ss)
