mod article;
mod db;

use warp::{Filter, Rejection, Reply};
use rusqlite::{Connection, Result};
use crate::article::Article;
use std::sync::{Arc, Mutex};
use warp::reply::{json, html};
use std::fs;

async fn get_all_articles(connection: Arc<Mutex<Connection>>) -> Result<impl Reply, Rejection> {
  let connection = connection.lock().unwrap();
  let response = db::get_all_articles(&connection).unwrap();
  Ok(json(&response))
}

#[tokio::main]
async fn main() {
  let connection = db::init();

  db::insert_article(Article::default(), &connection).unwrap();

  let connection: Arc<Mutex<Connection>> = Arc::new(Mutex::new(connection));

  let connection_filter = warp::any().map(move || connection.clone());

  let root =
    warp::path::end()
      .map(|| {
        let contents = if fs::exists("index.html").unwrap() {
            fs::read_to_string("index.html").unwrap()
          } else {
            "Go to frontend folder and run sh compile.sh to get an index.html".to_string()
          };

        html(contents)
      });

  let hello = warp::path!("hello" / String).map(|name: String| format!("Hello, {}!", name));

  let get_articles = warp::path!("articles")
    .and(connection_filter.clone())
    .and_then(get_all_articles);

  let routes = root.or(hello).or(get_articles);

  warp::serve(routes).run(([127, 0, 0, 1], 3030)).await;
}
