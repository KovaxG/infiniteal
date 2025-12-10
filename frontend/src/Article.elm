module Article exposing (Article)

type alias Article =
  { id : Maybe Int
  , title : String
  , authors : String
  , year : Int
  , url : String
  , descr : String
  , tags : List String
  , proposedBy : UserId
  , proposedOn : String
  }

type alias UserId = String
