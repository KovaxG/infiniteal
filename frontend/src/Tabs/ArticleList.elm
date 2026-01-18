module Tabs.ArticleList exposing (Model, Msg, subscriptions, init, update, view)

import Html exposing (Html, h2, text, div)
import Http exposing (Error(..))
import Bootstrap.Grid as Grid
import Json.Decode as Decoder

import Article exposing (Article)
import Source

type alias Model = { articles : List Article }

type Msg
  = GetSuccess (List Article)
  | GetFailed

subscriptions : Model -> Sub Msg
subscriptions _ = Sub.none

init : (Model, Cmd Msg)
init = ({ articles = [] }, getAllArticles)

getAllArticles : Cmd Msg
getAllArticles = Http.get
  { url = "http://localhost:3030/api/articles"
  , expect = Http.expectJson (Result.map GetSuccess >> Result.withDefault GetFailed) (Decoder.list Article.decoder)
  }

update : Msg -> Model -> (Model, Cmd Msg)
update msg model = case msg of
  GetSuccess articles -> ({ model | articles = articles }, Cmd.none)
  GetFailed -> ({ model | articles = [] }, Cmd.none) -- TODO(Gyuri): maybe show some error(model, Cmd.none)

view : Model -> Html Msg
view model = Grid.container []
  [ Grid.row [] [Grid.col [] [h2 [] [text "List of Articles"]]]
  , Grid.row [] [Grid.col [] (List.map articleDiv model.articles)]
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