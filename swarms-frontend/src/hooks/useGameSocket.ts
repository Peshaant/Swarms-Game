import { useEffect } from 'react'
import { gameSocket } from '../ws/client'
import { useGameStore } from '../store/gameStore'

// Connects the WebSocket singleton to the Zustand store.
// Mount once at the app root.
export function useGameSocket(): void {
  const setWorld    = useGameStore(s => s.setWorld)
  const applyDeltas = useGameStore(s => s.applyDeltas)
  const setStatus   = useGameStore(s => s.setStatus)
  const setGameOver = useGameStore(s => s.setGameOver)

  useEffect(() => {
    const unsubMsg = gameSocket.onMessage(msg => {
      switch (msg.tag) {
        case 'SStateSnapshot': setWorld(msg.contents);    break
        case 'SStateDelta':    applyDeltas(msg.contents); break
        case 'SGameOver':
          setGameOver({
            score:  msg.gameOverScore,
            wave:   msg.gameOverWave,
            reason: msg.gameOverReason,
          })
          break
        case 'SPong':  break   // heartbeat ack
        case 'SError': console.warn('[WS] Server error:', msg.contents); break
      }
    })

    const unsubStatus = gameSocket.onStatus(setStatus)

    gameSocket.connect()

    return () => {
      unsubMsg()
      unsubStatus()
      gameSocket.disconnect()
    }
  }, [])
}
