use rusqlite::types::ToSqlOutput;
use chrono::{DateTime, Utc};
use serde::Serialize;
use rusqlite::ToSql;

#[derive(Clone, Debug, Serialize)]
pub struct Article {
  pub id: Option<u32>,
  pub title: String,
  pub authors: String,
  pub year: u32,
  pub source: Source,
  pub description: String,
  pub tags: Vec<String>,
  pub proposed_by: UserId,
  pub proposed_on: DateTime<Utc>,
}

impl Default for Article {
  fn default() -> Article {
    Article {
      id: Some(1),
      title: "Ueber das Gesetz der Energieverteilung im Normalspektrum".to_string(),
      authors: "Max Planck".to_string(),
      year: 1900,
      source: Source("https://myweb.rz.uni-augsburg.de/~eckern/adp/history/historic-papers/1901_309_553-563.pdf".to_string()),
      description: "".to_string(),
      tags: vec!["physics".to_string()],
      proposed_by: UserId("0".to_string()),
      proposed_on: Utc::now(),
    }
  }
}

#[derive(Clone, Debug, Serialize)]
pub struct Source(String);

#[derive(Clone, Debug, Serialize)]
pub struct UserId(String);

impl ToSql for Source {
  fn to_sql(&self) -> rusqlite::Result<ToSqlOutput<'_>> {
    Ok(ToSqlOutput::from(self.0.clone()))
  }
}

impl ToSql for UserId {
  fn to_sql(&self) -> rusqlite::Result<ToSqlOutput<'_>> {
    Ok(ToSqlOutput::from(self.0.clone()))
  }
}