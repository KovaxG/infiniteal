use rusqlite::types::ToSqlOutput;
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use rusqlite::types::{FromSql, ToSql, ValueRef, FromSqlError};
use rusqlite::Result;

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct Article {
  pub id: Option<u32>,
  pub title: String,
  pub authors: String,
  pub year: u32,
  pub source: Source,
  pub description: String,
  pub tags: StringList,
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
      source: Source::Url("https://myweb.rz.uni-augsburg.de/~eckern/adp/history/historic-papers/1901_309_553-563.pdf".to_string()),
      description: "".to_string(),
      tags: StringList(vec!["physics".to_string()]),
      proposed_by: UserId(0),
      proposed_on: Utc::now(),
    }
  }
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct StringList(Vec<String>);

impl StringList {
  pub fn to_string(&self) -> String {
    self.0.join(",")
  }

  pub fn from_string(str: &str) -> StringList {
    StringList(str.split(",").map(ToString::to_string).collect())
  }
}

impl ToSql for StringList {
  fn to_sql(&self) -> Result<ToSqlOutput<'_>> {
    Ok(ToSqlOutput::from(self.to_string()))
  }
}

impl FromSql for StringList {
  fn column_result(value: ValueRef<'_>) -> Result<Self, FromSqlError> {
    value.as_str().map(StringList::from_string)
  }
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub enum Source {
  Url(String),
  #[allow(dead_code)]
  Path(String)
}

impl Source {
  fn get_str(&self) -> String {
    match self {
      Source::Url(str) => format!("url--{}", str),
      Source::Path(str) => format!("path-{}", str)
    }
  }
}

impl ToSql for Source {
  fn to_sql(&self) -> Result<ToSqlOutput<'_>> {
    Ok(ToSqlOutput::from(self.get_str()))
  }
}

impl FromSql for Source {
  fn column_result(value: ValueRef<'_>) -> Result<Self, FromSqlError> {
    let str = value.as_str()?;
    let (prefix, rest) = str.split_at(5);
    match prefix {
      "url--" => Ok(Source::Url(rest.to_string())),
      "path-" => Ok(Source::Path(rest.to_string())),
      _ => Err(FromSqlError::Other("Source: Bad prefix!".into()))
    }
  }
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct UserId(i64);

impl ToSql for UserId {
  fn to_sql(&self) -> Result<ToSqlOutput<'_>> {
    Ok(ToSqlOutput::from(self.0))
  }
}

impl FromSql for UserId {
  fn column_result(value: ValueRef<'_>) -> Result<Self, FromSqlError> {
    let nr = value.as_i64()?;
    Ok(UserId(nr))
  }
}
