module Main exposing (..)

import Html exposing (Html, div, h1, h2, text)
import Http exposing (Error(..))
import Browser
import Bootstrap.Form.Input as Input
import Bootstrap.Button as Button
import Bootstrap.Grid.Col as Col
import Bootstrap.Grid as Grid
import Bootstrap.CDN as CDN
import Bootstrap.Button as Button
import ISO8601
import Time
import Task

import Article exposing (Article)
import Source

main : Program Flag State Msg
main = Browser.element
  { init = init
  , subscriptions = subscriptions
  , update = update
  , view = view
  }

type alias Flag = ()

type alias State =
  { title : String
  , authors : String
  , year : Int
  , url : String
  , descr : String
  , tags : String
  , proposedBy : Int
  , now : Time.Posix
  , zone : Time.Zone -- Note(Gyuri): the ISO8601 package does not take this into consideration!
  , response: Maybe String
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
  | AdjustTimeZone Time.Zone

init : Flag -> (State, Cmd Msg)
init _ =
  ( { title = ""
    , authors = ""
    , year = 1969
    , url = ""
    , descr = ""
    , tags = ""
    , proposedBy = 0
    , now = Time.millisToPosix 0
    , zone = Time.utc
    , response = Nothing
    }
  , Task.perform AdjustTimeZone Time.here
  )

subscriptions : State -> Sub Msg
subscriptions _ = Time.every 1000 Tick

articleFromState : State -> Article
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

saveArticle : Article -> Cmd Msg
saveArticle article = Http.post
  { url = "http://localhost:3030/api/articles"
  , body = Http.jsonBody (Article.encoder article)
  , expect = Http.expectWhatever (Result.map (\_ -> SaveSuccess) >> Result.withDefault SaveFailed)
  }

update : Msg -> State -> (State, Cmd Msg)
update msg state = case msg of
  AdjustTimeZone z -> ({state | zone = z}, Cmd.none)
  Tick t -> ({state | now = t}, Cmd.none)
  SetTitle str -> ({ state | title = str }, Cmd.none)
  SetAuthors str -> ({ state | authors = str }, Cmd.none)
  SetYear str ->
    let year = str |> String.toInt |> Maybe.withDefault state.year
    in ({state | year = year }, Cmd.none)
  SetUrl str -> ({state | url = str}, Cmd.none)
  SetDescr str -> ({state | descr = str}, Cmd.none)
  SetTags str -> ({state | tags = str}, Cmd.none)
  SetProposedBy x -> ({state | proposedBy = x}, Cmd.none)
  SaveArticle -> (state, saveArticle (articleFromState state))
  SaveSuccess -> ({ state | response = Just "Success!" }, Cmd.none)
  SaveFailed -> ({ state | response = Just "Failed to save!" }, Cmd.none)

view : State -> Html Msg
view state = div []
  [ CDN.stylesheet
  , CDN.fontAwesome
  , Grid.container []
    ( [ Grid.row [] [Grid.col [] [h1 [] [text "Infiniteal"]]]
      , Grid.row [] [Grid.col [] [addArticle state]]
      ] ++
      ( state.response
        |> Maybe.map (\msg -> [Grid.row [] [Grid.col [] [text msg]]])
        |> Maybe.withDefault []
      )
    )
  ]

addArticle : State -> Html Msg
addArticle state = Grid.container []
  [ Grid.row [] [Grid.col [] [h2 [] [text "Add Article"]]]
  , Grid.row []
    [ Grid.col [Col.xs2] [text "Title"]
    , Grid.col [] [Input.text [Input.value state.title, Input.onInput SetTitle]]
    ]
  , Grid.row []
    [ Grid.col [Col.xs2] [text "Authors"]
    , Grid.col [] [Input.text [Input.value state.authors, Input.onInput SetAuthors]]
    ]
  , Grid.row []
    [ Grid.col [Col.xs2] [text "Year"]
    , Grid.col [] [Input.number [Input.value (String.fromInt state.year), Input.onInput SetYear]]
    ]
  , Grid.row []
    [ Grid.col [Col.xs2] [text "Url"]
    , Grid.col [] [Input.url [Input.value state.url, Input.onInput SetUrl]]
    ]
  , Grid.row []
    [ Grid.col [Col.xs2] [text "Description"]
    , Grid.col [] [Input.text [Input.value state.descr, Input.onInput SetDescr]]
    ]
  , Grid.row []
    [ Grid.col [Col.xs2] [text "Tags"]
    , Grid.col [] [Input.text [Input.value state.tags, Input.onInput SetTags]]
    ]
  , Grid.row []
    [ Grid.col [Col.xs2] [text "Proposed By"]
    , Grid.col []
      [ Input.text
        [ Input.value (String.fromInt state.proposedBy)
        , Input.onInput (String.toInt >> Maybe.withDefault 0 >> SetProposedBy)
        ]
      ]
    ]
  , Button.button [Button.info, Button.onClick SaveArticle] [text "Save"]
  ]
