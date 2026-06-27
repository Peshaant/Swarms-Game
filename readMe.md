# Swarms

A real-time wave defense game with a **Haskell WebSocket backend** and **React/TypeScript frontend**.

```
⬡  — your base (protect it)
▲  — turrets (place these, click any empty tile)
●  — enemies (spawned each wave, pathfind to your base)
·  — projectiles (fired by turrets)
```

## Architecture

```
swarms/
├── swarms-backend/     Haskell — game logic, WebSocket server
└── swarms-frontend/    React/TypeScript — terminal-style UI
```

**Backend highlights:**
- Pure game loop: `stepWorld :: StdGen -> GameWorld -> (GameWorld, [Delta], StdGen)`
- STM (`TVar`) for safe concurrent state between WebSocket threads and the ticker
- BFS pathfinding for enemy routing
- Incremental delta protocol — only changed state is broadcast each tick

**Frontend highlights:**
- Zustand store with delta-patching (no full re-renders per tick)
- WebSocket singleton with auto-reconnect
- Memoized `Cell` components for grid performance
- Typed message protocol mirroring the Haskell types exactly

## Running

### Backend

Requires GHC 9.6+ and `cabal`.

```bash
cd swarms-backend
cabal build
cabal run swarms-server
# Server starts on ws://localhost:8080
```

### Frontend

Requires Node 18+.

```bash
cd swarms-frontend
npm install
npm run dev
# Opens on http://localhost:3000
```

## How to play

1. The game starts in **waiting** phase — place turrets by clicking empty tiles
2. Press **Start Wave** to begin — enemies spawn from the edges and pathfind to your base
3. Turrets automatically target the nearest enemy in range
4. Survive as many waves as possible; each wave is harder
5. Game ends when base HP hits 0

## Tech decisions

| Decision | Rationale |
|---|---|
| Sum types for entities | Closed set — simpler than typeclass hierarchy, exhaustive pattern matching |
| Delta protocol | Avoids re-serializing full world (30×20 grid + entities) every 100ms tick |
| BFS over A* | Grid is small and unweighted; BFS is simpler and correct |
| STM over MVar | Composable, no manual locking, safe multi-reader |
| Zustand over Redux | Minimal boilerplate, selector-level re-renders |
