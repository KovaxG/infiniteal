mod article;
mod db;

use crate::article::Article;
use rusqlite::{Connection, Result};
use std::sync::{Arc, Mutex};
use warp::reply::json;
use warp::{Filter, Rejection, Reply};

struct MockArticle {
  id: i32,
  title: String,
}
async fn get_all_articles(connection: Arc<Mutex<Connection>>) -> Result<impl Reply, Rejection> {
  let a = connection.lock().unwrap();
  // let response = store.articles.read().await.clone();
  let response = db::get_all_articles(&a).unwrap();
  Ok(json(&response))
}

#[tokio::main]
async fn main() {
  let connection = db::init();

  db::insert_article(Article::default(), &connection).unwrap();

  let connection: Arc<Mutex<Connection>> = Arc::new(Mutex::new(connection));

  let connection_filter = warp::any().map(move || connection.clone());

  let root = warp::path::end().map(|| "Hello, world!");

  let hello = warp::path!("hello" / String).map(|name: String| format!("Hello, {}!", name));

  let get_articles = warp::path!("articles")
    .and(connection_filter.clone())
    .and_then(get_all_articles);

  let routes = root.or(hello).or(get_articles);

  warp::serve(routes).run(([127, 0, 0, 1], 3030)).await;
}
