use warp::Filter;

#[tokio::main]
async fn main() {
  let root = warp::path::end()
    .map(|| "Hello, world!");

  let hello = warp::path!("hello" / String)
    .map(|name: String| format!("Hello, {}!", name));

  let routes = root.or(hello);

  warp::serve(routes).run(([127, 0, 0, 1], 3030)).await;
}