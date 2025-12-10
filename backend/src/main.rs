mod article;
mod db;

use crate::article::Article;
use bytes::Buf;
use futures::{StreamExt, TryStreamExt};
use rusqlite::{Connection, Result};
use std::fs;
use std::sync::{Arc, Mutex};
use tokio::io::AsyncWriteExt;
use warp::reply::{html, json};
use warp::{Filter, Rejection, Reply};

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

    let root = warp::path::end().map(|| {
        let contents = if fs::exists("index.html").unwrap() {
            fs::read_to_string("index.html").unwrap()
        } else {
            "Go to frontend folder and run sh compile.sh to get an index.html".to_string()
        };

        html(contents)
    });

    let upload = warp::post()
        .and(warp::path("upload"))
        .and(warp::multipart::form().max_length(10_000_000)) // limit size (5MB)
        .and_then(handle_upload);

    let hello = warp::path!("hello" / String).map(|name: String| format!("Hello, {}!", name));

    let get_articles = warp::path!("articles")
        .and(connection_filter.clone())
        .and_then(get_all_articles);

    let routes = root.or(hello).or(get_articles).or(upload);

    warp::serve(routes).run(([127, 0, 0, 1], 3030)).await;
}

async fn handle_upload(mut form: warp::multipart::FormData) -> Result<impl Reply, Rejection> {
    while let Some(part) = form.try_next().await.map_err(|_| warp::reject())? {
        println!("Part name     : {}", part.name());
        let name = part.name().to_string();

        if let Some(filename) = part.filename() {
            println!("Part filename : {}", filename);
        } else {
            println!("Part has no filename");
        }
        let filename = part.filename().map(str::to_owned);

        println!("Part content-type: {:?}", part.content_type());

        if name == "file" {
            let filename = filename.unwrap_or_else(|| "upload.pdf".to_string());
            let mut file = tokio::fs::File::create(&filename)
                .await
                .map_err(|_| warp::reject())?;

            let mut stream = part.stream();

            while let Some(chunk) = stream.next().await {
                let chunk = chunk.map_err(|_| warp::reject())?;
                file.write_all(chunk.chunk())
                    .await
                    .map_err(|_| warp::reject())?;
            }

            file.flush().await.map_err(|_| warp::reject())?;
        }
    }
    Ok("ok")
}
