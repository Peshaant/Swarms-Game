module Game.Pathfinding
    ( findPath
    , neighbours
    ) where

import Data.Map.Strict (Map)
import qualified Data.Map.Strict as Map
import Data.Maybe (mapMaybe)
import Data.Sequence (Seq (..))
import qualified Data.Sequence as Seq

import Game.Types
import Game.World (isPassable, inBounds)

-- ---------------------------------------------------------------------------
-- BFS pathfinding
-- ---------------------------------------------------------------------------

-- | BFS from @start@ to @goal@, respecting passability.
-- Returns the path from start to goal (exclusive of start, inclusive of goal),
-- or Nothing if no path exists.
findPath :: GameWorld -> Pos -> Pos -> Maybe [Pos]
findPath world start goal =
    case bfs world goal (Seq.singleton start) (Map.singleton start start) of
        Nothing      -> Nothing
        Just parents -> Just (reconstructPath parents start goal)

-- | BFS over the grid.
-- @parents@ maps each visited position to the position it was reached from.
bfs :: GameWorld
    -> Pos
    -> Seq Pos
    -> Map Pos Pos      -- ^ pos -> parent
    -> Maybe (Map Pos Pos)
bfs _     _    Empty          _       = Nothing
bfs world goal (pos :<| queue) parents
    | pos == goal = Just parents
    | otherwise   =
        let nexts    = filter (canVisit parents) (neighbours world pos)
            parents' = foldl (\m n -> Map.insert n pos m) parents nexts
            queue'   = queue <> Seq.fromList nexts
        in bfs world goal queue' parents'

-- | Whether a position can be added to the frontier
canVisit :: Map Pos Pos -> Pos -> Bool
canVisit parents pos = not (Map.member pos parents)

-- | Valid neighbouring positions (4-directional, passable, in-bounds)
neighbours :: GameWorld -> Pos -> [Pos]
neighbours world (Pos x y) =
    filter (\p -> inBounds p && isPassable world p)
        [ Pos (x+1) y
        , Pos (x-1) y
        , Pos x     (y+1)
        , Pos x     (y-1)
        ]

-- | Walk back through the parent map to reconstruct the path
reconstructPath :: Map Pos Pos -> Pos -> Pos -> [Pos]
reconstructPath parents start goal = reverse (go goal)
  where
    go pos
        | pos == start = []
        | otherwise    =
            case Map.lookup pos parents of
                Nothing     -> []
                Just parent -> pos : go parent
