module Main exposing (..)

import Html exposing (Html, div, h1, text)
import Html.Events exposing (onClick)
import Http exposing (Error(..))
import Bootstrap.Grid as Grid
import Bootstrap.CDN as CDN
import Bootstrap.Tab as Tab
import Browser

import Tabs.ArticleProposal as ArticleProposal
import Tabs.ArticleList as ArticleList
import TabName exposing (TabName)

main : Program Flag Model Msg
main = Browser.element
  { init = init
  , subscriptions = subscriptions
  , update = update
  , view = view
  }

type alias Flag = ()

type TabModel
  = ArticleProposal ArticleProposal.Model
  | ArticleList ArticleList.Model

type alias Model =
  { tabModel : TabModel
  , tabState : Tab.State
  }

type Msg
  = ArticleProposalMsg ArticleProposal.Msg
  | ArticleListMsg ArticleList.Msg
  | TabMsg Tab.State
  | SetTab TabName

init : Flag -> (Model, Cmd Msg)
init _ =
  let (tabModel, cmd) = ArticleList.init |> with ArticleList ArticleListMsg
  in
    ( { tabModel = tabModel
      , tabState = Tab.initialState
      }
    , cmd
    )

with :  (tabModel -> TabModel) -> (tabMsg -> Msg) -> (tabModel, Cmd tabMsg) -> (TabModel, Cmd Msg)
with toTabModel toMsg (tabModel, tabMsg) = (toTabModel tabModel, Cmd.map toMsg tabMsg)

subscriptions : Model -> Sub Msg
subscriptions model =
  let
    tabSubs =
      case model.tabModel of
        ArticleProposal tabModel -> ArticleProposal.subscriptions tabModel |> Sub.map ArticleProposalMsg
        ArticleList tabModel -> ArticleList.subscriptions tabModel |> Sub.map ArticleListMsg
  in Sub.batch [tabSubs, Tab.subscriptions model.tabState TabMsg]

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case (msg, model.tabModel) of
    (TabMsg ts, _) -> ({ model | tabState = ts }, Cmd.none)
    (SetTab tabName, _) ->
      let
        (tabModel, cmd) =
          case tabName of
            TabName.ArticleProposal -> ArticleProposal.init |> with ArticleProposal ArticleProposalMsg
            TabName.ArticleList -> ArticleList.init |> with ArticleList ArticleListMsg
      in
        ( { model
          | tabState = Tab.customInitialState (TabName.toString tabName)
          , tabModel = tabModel
          }
        , cmd
        )
    (ArticleProposalMsg subMsg, ArticleProposal subModel) ->
      ArticleProposal.update subMsg subModel |> updateTab model ArticleProposal ArticleProposalMsg
    (ArticleListMsg subMsg, ArticleList subModel) ->
      ArticleList.update subMsg subModel |> updateTab model ArticleList ArticleListMsg
    _ -> (model, Cmd.none) -- Note(Gyuri): mismatched messages



updateTab : Model -> (tabModel -> TabModel) -> (subMsg -> Msg) -> (tabModel, Cmd subMsg) -> (Model, Cmd Msg)
updateTab model toTabModel toMsg (tabModel, subCmd) =
  ({ model | tabModel = toTabModel tabModel }, Cmd.map toMsg subCmd)

view : Model -> Html Msg
view model = div []
  [ CDN.stylesheet
  , CDN.fontAwesome
  , Grid.container []
    ( [ Grid.row [] [Grid.col [] [h1 [] [text "Infiniteal"]]]
      , Grid.row [] [Grid.col [] [tabs model]]
      ]
    )
  ]

tabs : Model -> Html Msg
tabs model =
  Tab.config TabMsg
  |> Tab.withAnimation
  |> Tab.items
    [ Tab.item
      { id = TabName.toString TabName.ArticleList
      , link = Tab.link [onClick (SetTab TabName.ArticleList)] [text "List of Articles"]
      , pane =
        Tab.pane []
        [ case model.tabModel of
            ArticleList tabModel -> ArticleList.view tabModel |> Html.map ArticleListMsg
            _ -> text "IDK!"
        ]
      }
    , Tab.item
      { id = TabName.toString TabName.ArticleProposal
      , link = Tab.link [onClick (SetTab TabName.ArticleProposal)] [text "Propose Article"]
      , pane =
        Tab.pane []
        [ case model.tabModel of
            ArticleProposal tabModel -> ArticleProposal.view tabModel |> Html.map ArticleProposalMsg
            _ -> text "IDK!"
        ]
      }
    ]
  |> Tab.view model.tabState

