module Article exposing (Article, encoder, decoder)

import Json.Encode as Encoder exposing (Value)
import Json.Decode as Decoder exposing (Decoder)

import Source exposing (Source)

type alias Article =
  { id : Maybe Int
  , title : String
  , authors : String
  , year : Int
  , source : Source
  , descr : String
  , tags : List String
  , proposedBy : UserId
  , proposedOn : String
  }

type alias UserId = Int

encoder : Article -> Value
encoder article = Encoder.object
  ( [ ("title", Encoder.string article.title)
    , ("authors", Encoder.string article.authors)
    , ("year", Encoder.int article.year)
    , ("source", Source.encoder article.source)
    , ("description", Encoder.string article.descr)
    , ("tags", Encoder.list Encoder.string article.tags)
    , ("proposed_by", Encoder.int article.proposedBy)
    , ("proposed_on", Encoder.string article.proposedOn)
    ] ++ (article.id |> Maybe.map (\id -> [("id", Encoder.int id)]) |> Maybe.withDefault [])
  )

decoder : Decoder Article
decoder = Decoder.map Article (Decoder.field "id" (Decoder.maybe Decoder.int))
  |> apply (Decoder.field "title" Decoder.string)
  |> apply (Decoder.field "authors" Decoder.string)
  |> apply (Decoder.field "year" Decoder.int)
  |> apply (Decoder.field "source" Source.decoder)
  |> apply (Decoder.field "description" Decoder.string)
  |> apply (Decoder.field "tags" (Decoder.list Decoder.string))
  |> apply (Decoder.field "proposed_by" Decoder.int)
  |> apply (Decoder.field "proposed_on" Decoder.string)


apply : Decoder a -> Decoder (a -> b) -> Decoder b
apply ad fd = fd |> Decoder.andThen(\f -> Decoder.map f ad)