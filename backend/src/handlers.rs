use bytes::Buf;
use futures::{StreamExt, TryStreamExt};
use rusqlite::{Connection, Result};
use std::fs;
use std::sync::{Arc, Mutex};
use tokio::io::AsyncWriteExt;
use warp::reply::{html, json};
use warp::{Rejection, Reply};

use crate::db;

pub async fn handle_upload(mut form: warp::multipart::FormData) -> Result<impl Reply, Rejection> {
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

pub async fn get_all_articles(connection: Arc<Mutex<Connection>>) -> Result<impl Reply, Rejection> {
    let connection = connection.lock().unwrap();
    let response = db::get_all_articles(&connection).unwrap();
    Ok(json(&response))
}

pub fn serve_webpage() -> impl Reply {
    let contents = if fs::exists("index.html").unwrap() {
        fs::read_to_string("index.html").unwrap()
    } else {
        "Go to frontend folder and run sh compile.sh to get an index.html".to_string()
    };

    html(contents)
}

pub fn save_article() -> impl Reply {
  format!("Saving article!")
}