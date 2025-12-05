use crate::article::Article;
use rusqlite::{Connection, Row};
use rusqlite::fallible_iterator::FallibleIterator;
use warp::{Error, Filter};

pub fn init() -> Connection {
  let conn = Connection::open("infiniteal.db").unwrap();

  conn.execute(
    "CREATE TABLE IF NOT EXISTS articles (
              id INTEGER PRIMARY KEY,
              title TEXT NOT NULL,
              authors TEXT NOT NULL,
              year INTEGER,
              source TEXT,
              description TEXT,
              tags TEXT,
              proposed_by INTEGER,
              proposed_on DATETIME
          )",
    (),
  )
    .unwrap();

  conn
}

pub fn insert_article(article: Article, connection: &Connection) -> Result<usize, String> {
  connection
    .execute(
      "INSERT INTO articles (title, authors, year, source, description, tags, \
        proposed_by, proposed_on) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8)",
      (
        article.title,
        article.authors,
        article.year,
        article.source,
        article.description,
        article.tags.join(","),
        article.proposed_by,
        article.proposed_on.timestamp(),
      ),
    )
    .map_err(|e| e.to_string())
}

pub fn delete_article(article_id: i32, connection: Connection) -> Result<usize, String> {
  connection
    .execute("DELETE FROM articles WHERE id = ?1", (article_id,))
    .map_err(|e| e.to_string())
}

// TODO: implement this
fn row_to_article(row: &Row) -> Result<Article, rusqlite::Error> {
  Ok(
    Article {
      id: row.get(0)?,
      .. Article::default()
    }
  )
}
pub fn get_all_articles(connection: &Connection) -> Result<Vec<Article>, String> {
  let mut statement = connection.prepare("SELECT * FROM articles").unwrap();
  let results = statement.query_map([], row_to_article);
  results
    .map(|i| i.map(|a| a.unwrap()).collect())
    .map_err(|e| e.to_string())
}
