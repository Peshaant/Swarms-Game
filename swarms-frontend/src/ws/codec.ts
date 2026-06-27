import { ServerMessage } from '../types/messages'

// All incoming messages enter here. This is the trust boundary:
// raw JSON → typed ServerMessage or null (malformed/unknown).

export function decodeServerMessage(raw: string): ServerMessage | null {
  try {
    const parsed = JSON.parse(raw) as unknown
    if (!isObject(parsed) || typeof parsed['tag'] !== 'string') return null
    return parsed as ServerMessage   // shallow trust — extend with zod if needed
  } catch {
    return null
  }
}

export function encodeClientMessage(msg: object): string {
  return JSON.stringify(msg)
}

function isObject(v: unknown): v is Record<string, unknown> {
  return typeof v === 'object' && v !== null
}
