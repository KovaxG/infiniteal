use crate::article::Article;
use std::sync::Arc;
use tokio::sync::RwLock;

#[derive(Clone)]
pub struct Store {
  pub articles: Arc<RwLock<Vec<Article>>>,
}

impl Store {
  pub fn init() -> Store {
    Store {
      articles: Arc::new(RwLock::new(vec![Article::default()])),
    }
  }

  pub async fn insert(mut self, art: Article) {
    self.articles.write().await.push(art);
  }
}
