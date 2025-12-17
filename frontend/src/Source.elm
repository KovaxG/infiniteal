module Source exposing (Source(..), encoder, decoder)

import Json.Decode as Decoder exposing (Decoder)
import Json.Encode as Encoder exposing (Value)

type Source = Url String | Path String

prefix : Source -> String
prefix source = case source of
  Url _ -> "Url"
  Path _ -> "Path"

contents : Source -> String
contents source = case source of
  Url str -> str
  Path str -> str

encoder : Source -> Value
encoder source = Encoder.object [(prefix source, Encoder.string (contents source))]

decoder : Decoder Source
decoder = Decoder.oneOf
  [ Decoder.map Url (Decoder.field "Url" Decoder.string)
  , Decoder.map Path (Decoder.field "Path" Decoder.string)
  ]
