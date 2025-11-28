use chrono::{DateTime, Utc};
use serde::{Serialize, Serializer};

#[derive(Clone, Debug, Serialize)]
pub struct Article {
  title: String,
  authors: String,
  year: u32,
  source: Source,
  description: String,
  tags: Vec<String>,
  proposed_by: UserId,
  proposed_on: DateTime<Utc>
}
impl Default for Article {
  fn default() -> Article {
    Article {
      title: "Ueber das Gesetz der Energieverteilung im Normalspektrum".to_string(),
      authors: "Max Planck".to_string(),
      year: 1900,
      source: Source("https://myweb.rz.uni-augsburg.de/~eckern/adp/history/historic-papers/1901_309_553-563.pdf".to_string()),
      description: "".to_string(),
      tags: vec!["physics".to_string()],
      proposed_by: UserId("0".to_string()),
      proposed_on: Utc::now()
    }
  }
}

#[derive(Clone, Debug, Serialize)]
struct Source(String);
#[derive(Clone, Debug, Serialize)]
struct UserId(String);