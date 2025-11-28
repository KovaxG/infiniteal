mod article;
mod store;

use store::Store;
use warp::reply::json;
use warp::{Filter, Rejection, Reply};

async fn get_all_articles(store: Store) -> Result<impl Reply, Rejection> {
    let response = store.articles.read().await.clone();
    Ok(json(&response))
}

#[tokio::main]
async fn main() {
    let store = Store::init();

    let store_filter = warp::any().map(move || store.clone());

    let root = warp::path::end().map(|| "Hello, world!");

    let hello = warp::path!("hello" / String).map(|name: String| format!("Hello, {}!", name));

    let get_article = warp::path!("articles")
        .and(store_filter.clone())
        .and_then(get_all_articles);

    let routes = root.or(hello).or(get_article);

    warp::serve(routes).run(([127, 0, 0, 1], 3030)).await;
}
