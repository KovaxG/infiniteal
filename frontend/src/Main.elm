module Main exposing (..)

import Html exposing (Html, div, h1, h2, text)
import Html.Events exposing (onClick)
import Http exposing (Error(..))
import Json.Decode as Decoder
import Browser
import Bootstrap.Form.Input as Input
import Bootstrap.Button as Button
import Bootstrap.Grid.Col as Col
import Bootstrap.Grid as Grid
import Bootstrap.CDN as CDN
import Bootstrap.Tab as Tab
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
  , response : Maybe String
  , tabState : Tab.State
  , tab : TabName
  , articles : List Article
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
  | TabMsg Tab.State
  | SetTab TabName
  | GetSuccess (List Article)
  | GetFailed

type TabName = AddArticle | ListArticle

tabNameToString : TabName -> String
tabNameToString tabName = case tabName of
  AddArticle -> "AddArticle"
  ListArticle -> "ListArticle"

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
    , tabState = Tab.initialState
    , tab = AddArticle
    , articles = []
    }
  , Task.perform AdjustTimeZone Time.here
  )

subscriptions : State -> Sub Msg
subscriptions state = Sub.batch
  [ Time.every 1000 Tick
  , Tab.subscriptions state.tabState TabMsg
  ]

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

getAllArticles : Cmd Msg
getAllArticles = Http.get
  { url = "http://localhost:3030/api/articles"
  , expect = Http.expectJson (Result.map GetSuccess >> Result.withDefault GetFailed) (Decoder.list Article.decoder)
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
  TabMsg ts -> ({ state | tabState = ts }, Cmd.none)
  SetTab tab ->
    ( { state
    | tab = tab
    , tabState = Tab.customInitialState (tabNameToString tab)
    , response = Nothing
    }
    , if tab == ListArticle then getAllArticles else Cmd.none
    )
  GetSuccess articles -> ({ state | articles = articles }, Cmd.none)
  GetFailed -> ({ state | articles = [] }, Cmd.none) -- TODO(Gyuri): maybe show some error

view : State -> Html Msg
view state = div []
  [ CDN.stylesheet
  , CDN.fontAwesome
  , Grid.container []
    ( [ Grid.row [] [Grid.col [] [h1 [] [text "Infiniteal"]]]
      , Grid.row [] [Grid.col [] [tabs state]]
      ] ++
      ( state.response
        |> Maybe.map (\msg -> [Grid.row [] [Grid.col [] [text msg]]])
        |> Maybe.withDefault []
      )
    )
  ]

tabs : State -> Html Msg
tabs state =
  Tab.config TabMsg
  |> Tab.withAnimation
  |> Tab.items
    [ Tab.item
      { id = "AddArticle"
      , link = Tab.link [onClick (SetTab AddArticle)] [text "Add Article"]
      , pane = Tab.pane [] [addArticle state]
      }
    , Tab.item
      { id = "ListArticle"
      , link = Tab.link [onClick (SetTab ListArticle)] [text "List Articles"]
      , pane = Tab.pane [] [listArticles state.articles]
      }
    ]
  |> Tab.view state.tabState

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

listArticles : List Article -> Html Msg
listArticles articles = Grid.container []
  [ Grid.row [] [Grid.col [] [h2 [] [text "List of Articles"]]]
  , Grid.row [] [Grid.col [] (List.map articleDiv articles)]
  ]

articleDiv : Article -> Html Msg
articleDiv art = div []
  [ text
    <| "#" ++ String.fromInt (Maybe.withDefault 0 art.id)
    ++ " 📄 " ++ art.title
    ++ ", 👤 " ++ art.authors
    ++ ", 🗓️ " ++ String.fromInt art.year
    ++ ( case art.source of
          Source.Url url -> ", 🔗 " ++ url
          Source.Path _ -> "idk"
       )
  ]
