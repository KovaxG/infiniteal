module TabName exposing (TabName(..), toString)

type TabName = ArticleProposal | ArticleList

toString : TabName -> String
toString tabName = case tabName of
  ArticleProposal -> "article-proposal"
  ArticleList -> "article-list"
