module Article exposing (Article, encoder)

import Json.Encode as Encoder exposing (Value)

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

-- TODO(Gyuri): implement decoder!