module Server.Protocol
    ( encodeMessage
    , decodeMessage
    ) where

import Data.Aeson (encode, eitherDecode, ToJSON, FromJSON)
import Data.ByteString.Lazy (ByteString)

import Game.Types

-- | Encode a ServerMessage to JSON ByteString
encodeMessage :: ServerMessage -> ByteString
encodeMessage = encode

-- | Decode a ClientMessage from JSON ByteString
decodeMessage :: ByteString -> Either String ClientMessage
decodeMessage = eitherDecode
