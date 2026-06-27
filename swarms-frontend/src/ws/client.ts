import { ServerMessage } from '../types/messages'
import { ClientMessage } from '../types/messages'
import { decodeServerMessage, encodeClientMessage } from './codec'

type MessageHandler = (msg: ServerMessage) => void
type StatusHandler  = (status: 'connecting' | 'open' | 'closed') => void

const WS_URL          = 'ws://localhost:8080'
const RECONNECT_MS    = 2000
const MAX_RECONNECTS  = 10

class GameSocketClient {
  private ws:          WebSocket | null = null
  private handlers:    Set<MessageHandler> = new Set()
  private statusCbs:   Set<StatusHandler>  = new Set()
  private reconnects   = 0
  private intentional  = false

  connect(): void {
    this.intentional = false
    this.reconnects  = 0
    this._open()
  }

  disconnect(): void {
    this.intentional = true
    this.ws?.close()
  }

  send(msg: ClientMessage): void {
    if (this.ws?.readyState === WebSocket.OPEN) {
      this.ws.send(encodeClientMessage(msg))
    }
  }

  onMessage(handler: MessageHandler): () => void {
    this.handlers.add(handler)
    return () => this.handlers.delete(handler)
  }

  onStatus(handler: StatusHandler): () => void {
    this.statusCbs.add(handler)
    return () => this.statusCbs.delete(handler)
  }

  private _open(): void {
    this._emitStatus('connecting')
    this.ws = new WebSocket(WS_URL)

    this.ws.onopen = () => {
      this.reconnects = 0
      this._emitStatus('open')
    }

    this.ws.onmessage = (ev: MessageEvent<string>) => {
      const msg = decodeServerMessage(ev.data)
      if (msg) this.handlers.forEach(h => h(msg))
    }

    this.ws.onclose = () => {
      this._emitStatus('closed')
      if (!this.intentional && this.reconnects < MAX_RECONNECTS) {
        this.reconnects++
        setTimeout(() => this._open(), RECONNECT_MS)
      }
    }

    this.ws.onerror = () => {
      this.ws?.close()
    }
  }

  private _emitStatus(s: 'connecting' | 'open' | 'closed'): void {
    this.statusCbs.forEach(cb => cb(s))
  }
}

// Singleton — one socket per tab
export const gameSocket = new GameSocketClient()
