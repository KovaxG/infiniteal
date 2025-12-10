module Main exposing (..)

import Html exposing (Html, div, h1, h2, text)
import Browser
import Bootstrap.Form.Input as Input
import Bootstrap.Button as Button
import Bootstrap.Grid.Col as Col
import Bootstrap.Grid as Grid
import Bootstrap.CDN as CDN
import Bootstrap.Button as Button

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
  , proposedBy : String
  , proposedOn : String
  }

type Msg
  = SetTitle String
  | SetAuthors String
  | SetYear String
  | SetUrl String
  | SetDescr String
  | SetTags String
  | SetProposedBy String
  | SetProposedOn String

init : Flag -> (State, Cmd Msg)
init _ =
  ( { title = ""
    , authors = ""
    , year = 1969
    , url = ""
    , descr = ""
    , tags = ""
    , proposedBy = ""
    , proposedOn = ""
    }
  , Cmd.none
  )

subscriptions : State -> Sub Msg
subscriptions _ = Sub.none

update : Msg -> State -> (State, Cmd Msg)
update msg state = case msg of
  SetTitle str -> ({ state | title = str }, Cmd.none)
  SetAuthors str -> ({ state | authors = str }, Cmd.none)
  SetYear str ->
    let year = str |> String.toInt |> Maybe.withDefault state.year
    in ({state | year = year }, Cmd.none)
  SetUrl str -> ({state | url = str}, Cmd.none)
  SetDescr str -> ({state | descr = str}, Cmd.none)
  SetTags str -> ({state | tags = str}, Cmd.none)
  SetProposedBy str -> ({state | proposedBy = str}, Cmd.none)
  SetProposedOn str -> ({state | proposedOn = str}, Cmd.none)

view : State -> Html Msg
view state = div []
  [ CDN.stylesheet
  , CDN.fontAwesome
  , Grid.container []
    [ Grid.row [] [Grid.col [] [h1 [] [text "Infiniteal"]]]
    , Grid.row [] [Grid.col [] [addArticle state]]
    ]
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
    , Grid.col [] [Input.text [Input.value state.proposedBy, Input.onInput SetProposedBy]]
    ]
  , Grid.row []
    [ Grid.col [Col.xs2] [text "Proposed On"]
    , Grid.col [] [Input.date [Input.value state.proposedOn, Input.onInput SetProposedOn]]
    ]
  , Button.button [Button.info] [text "Save"]
  ]
