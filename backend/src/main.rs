mod handlers;
mod article;
mod db;

use std::sync::{Arc, Mutex};
use rusqlite::Connection;
use warp::Filter;

#[tokio::main]
async fn main() {
    let connection = db::init();
    let connection: Arc<Mutex<Connection>> = Arc::new(Mutex::new(connection));
    let connection_filter = warp::any().map(move || connection.clone());

    let root = warp::path::end().map(handlers::serve_webpage);

    let save_article =
        warp::post()
        .and(warp::path!("api" / "articles"))
        .and(warp::body::json())
        .and(connection_filter.clone())
        .map(handlers::save_article);

    let get_articles = warp::path!("articles")
        .and(connection_filter.clone())
        .and_then(handlers::get_all_articles);

    let upload = warp::post()
        .and(warp::path("upload"))
        .and(warp::multipart::form().max_length(10_000_000))
        .and_then(handlers::handle_upload);

    let routes = root.or(save_article).or(get_articles).or(upload);

    warp::serve(routes).run(([127, 0, 0, 1], 3030)).await;
}
