module Tabs.ArticleProposal exposing (Model, Msg, subscriptions, init, update, view)

import Html exposing (Html, h2, text)
import Http exposing (Error(..))
import Bootstrap.Form.Input as Input
import Bootstrap.Button as Button
import Bootstrap.Grid.Col as Col
import Bootstrap.Grid as Grid
import ISO8601
import Time

import Article exposing (Article)
import Source

type alias Model =
  { title : String
  , authors : String
  , year : Int
  , url : String
  , descr : String
  , tags : String
  , proposedBy : Int
  , response : Maybe String
  , now : Time.Posix
  }

type Msg
  = SetTitle String
  | SetAuthors String
  | SetYear String
  | SetUrl String
  | SetDescr String
  | SetTags String
  | SetProposedBy Int
  | SaveArticle
  | SaveSuccess
  | SaveFailed
  | Tick Time.Posix

subscriptions : Model -> Sub Msg
subscriptions _ = Time.every 1000 Tick

init : (Model, Cmd Msg)
init =
  ( { title = ""
    , authors = ""
    , year = 1969
    , url = ""
    , descr = ""
    , tags  = ""
    , proposedBy  = 0
    , response  = Nothing
    , now = Time.millisToPosix 0
    }
  , Cmd.none
  )

update : Msg -> Model -> (Model, Cmd Msg)
update msg model = case msg of
  SetTitle str -> ({ model | title = str }, Cmd.none)
  SetAuthors str -> ({ model | authors = str }, Cmd.none)
  SetYear str ->
    let year = str |> String.toInt |> Maybe.withDefault model.year
    in ({ model | year = year }, Cmd.none)
  SetUrl str -> ({ model | url = str }, Cmd.none)
  SetDescr str -> ({ model | descr = str }, Cmd.none)
  SetTags str -> ({ model | tags = str }, Cmd.none)
  SetProposedBy x -> ({ model | proposedBy = x }, Cmd.none)
  SaveArticle -> (model, saveArticle (articleFromState model))
  SaveSuccess -> ({ model | response = Just "Success!" }, Cmd.none)
  SaveFailed -> ({ model | response = Just "Failed to save!" }, Cmd.none)
  Tick t -> ({ model | now = t }, Cmd.none)

saveArticle : Article -> Cmd Msg
saveArticle article = Http.post
  { url = "http://localhost:3030/api/articles"
  , body = Http.jsonBody (Article.encoder article)
  , expect = Http.expectWhatever (Result.map (\_ -> SaveSuccess) >> Result.withDefault SaveFailed)
  }

view : Model -> Html Msg
view model = Grid.container []
  [ Grid.row [] [Grid.col [] [h2 [] [text "Propose Article"]]]
  , Grid.row []
    [ Grid.col [Col.xs2] [text "Title"]
    , Grid.col [] [Input.text [Input.value model.title, Input.onInput SetTitle]]
    ]
  , Grid.row []
    [ Grid.col [Col.xs2] [text "Authors"]
    , Grid.col [] [Input.text [Input.value model.authors, Input.onInput SetAuthors]]
    ]
  , Grid.row []
    [ Grid.col [Col.xs2] [text "Year"]
    , Grid.col [] [Input.number [Input.value (String.fromInt model.year), Input.onInput SetYear]]
    ]
  , Grid.row []
    [ Grid.col [Col.xs2] [text "Url"]
    , Grid.col [] [Input.url [Input.value model.url, Input.onInput SetUrl]]
    ]
  , Grid.row []
    [ Grid.col [Col.xs2] [text "Description"]
    , Grid.col [] [Input.text [Input.value model.descr, Input.onInput SetDescr]]
    ]
  , Grid.row []
    [ Grid.col [Col.xs2] [text "Tags"]
    , Grid.col [] [Input.text [Input.value model.tags, Input.onInput SetTags]]
    ]
  , Grid.row []
    [ Grid.col [Col.xs2] [text "Proposed By"]
    , Grid.col []
      [ Input.text
        [ Input.value (String.fromInt model.proposedBy)
        , Input.onInput (String.toInt >> Maybe.withDefault 0 >> SetProposedBy)
        ]
      ]
    ]
  , Button.button [Button.info, Button.onClick SaveArticle] [text "Save"]
  , model.response
    |> Maybe.map (\msg -> Grid.row [] [Grid.col [] [text msg]])
    |> Maybe.withDefault (text "")
  ]

articleFromState : Model -> Article
articleFromState s =
  { id = Nothing
  , title = s.title
  , authors = s.authors
  , year = s.year
  , source = Source.Url s.url
  , descr = s.descr
  , tags = s.tags |> String.split "," |> List.map String.trim
  , proposedBy = s.proposedBy
  , proposedOn = s.now |> ISO8601.fromPosix |> ISO8601.toString
  }