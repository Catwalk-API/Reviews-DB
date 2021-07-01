DROP DATABASE IF EXISTS reviews_sdc;

CREATE DATABASE reviews_sdc;

\c reviews_sdc;

--CREATE SCHEMA

CREATE TABLE meta (
  product_id serial PRIMARY KEY,
  ratingOneCount INT DEFAULT 0,
  ratingTwoCount INT DEFAULT 0,
  ratingThreeCount INT DEFAULT 0,
  ratingFourCount INT DEFAULT 0,
  ratingFiveCount INT DEFAULT 0,
  recommendedFalseCount INT DEFAULT 0,
  recommendedTrueCount INT DEFAULT 0
  );

CREATE TABLE reviews (
   review_id serial PRIMARY KEY,
   product_id INT NOT NULL,
   rating INT,
   date TEXT,
   summary VARCHAR(1000),
   body VARCHAR(1000),
   recommend boolean,
   reported boolean,
   reviewer_name VARCHAR(60),
   reviewer_email VARCHAR(60),
   response VARCHAR,
   helpfulnessCount INT
  );

CREATE TABLE photos (
  photo_id serial PRIMARY KEY,
  review_id INT NOT NULL,
  url TEXT
  );

CREATE TABLE characteristics (
  characteristic_id serial PRIMARY KEY,
  product_id INT NOT NULL,
  characteristic VARCHAR(30),
  ratingOneCount INT DEFAULT 0,
  ratingTwoCount INT DEFAULT 0,
  ratingThreeCount INT DEFAULT 0,
  ratingFourCount INT DEFAULT 0,
  ratingFiveCount INT DEFAULT 0
  );

CREATE TABLE characteristic_reviews (
  id serial PRIMARY KEY,
  characteristic_id INT NOT NULL,
  review_id INT NOT NULL,
  rating INT
);

-- LOAD INTO DATABASE USING COPY METHOD

COPY photos(photo_id, review_id, url)
FROM '/usr/share/app/reviews_photos.csv'
DELIMITER ','
CSV HEADER;

COPY characteristics(characteristic_id, product_id, characteristic)
FROM '/usr/share/app/characteristics.csv'
DELIMITER ','
CSV HEADER;

COPY reviews(review_id, product_id, rating, date, summary, body, recommend, reported, reviewer_name, reviewer_email, response, helpfulnessCount)
FROM '/usr/share/app/reviews.csv'
DELIMITER ','
CSV HEADER;

COPY characteristic_reviews(id, characteristic_id, review_id, rating)
FROM '/usr/share/app/characteristic_reviews.csv'
DELIMITER ','
CSV HEADER;

--Create Indexes
CREATE INDEX reviews_product_id_asc ON reviews(product_id ASC);
CREATE INDEX characteristics_product_id_asc ON characteristics(product_id ASC);
CREATE INDEX photos_review_id_asc ON photos(review_id ASC);
CREATE INDEX reviews_reported_index ON reviews(review_id) WHERE reported is true;

UPDATE reviews
  SET date = to_timestamp(reviews.date::numeric/1000);

INSERT INTO meta (product_id) SELECT DISTINCT product_id FROM characteristics;

-- Update Meta

UPDATE meta
  SET
    ratingOneCount=subquery.ratingOneCount,
    ratingTwoCount=subquery.ratingTwoCount,
    ratingThreeCount=subquery.ratingThreeCount,
    ratingFourCount=subquery.ratingFourCount,
    ratingFiveCount=subquery.ratingFiveCount,
    recommendedFalseCount=subquery.recommendedFalseCount,
    recommendedTrueCount=subquery.recommendedTrueCount
  FROM (
    SELECT
      product_id AS product_id,
      SUM (CASE WHEN r.rating = 1 THEN 1 ELSE 0 END) AS ratingOneCount,
      SUM (CASE WHEN r.rating = 2 THEN 1 ELSE 0 END) AS ratingTwoCount,
      SUM (CASE WHEN r.rating = 3 THEN 1 ELSE 0 END) AS ratingThreeCount,
      SUM (CASE WHEN r.rating = 4 THEN 1 ELSE 0 END) AS ratingFourCount,
      SUM (CASE WHEN r.rating = 5 THEN 1 ELSE 0 END) AS ratingFiveCount,
      SUM (CASE WHEN r.recommend = 'false' THEN 1 ELSE 0 END) AS recommendedFalseCount,
      SUM (CASE WHEN r.recommend = 'true' THEN 1 ELSE 0 END) AS recommendedTrueCount
    FROM
      (SELECT review_id, product_id, rating, recommend FROM reviews) r
    GROUP BY 1
  ) AS subquery
  WHERE meta.product_id = subquery.product_id;

-- Update Characteristics

-- UPDATE characteristics
--   SET
--     characteristic_id=subquery.characteristic_id,
--     ratingOneCount=subquery.ratingOneCount,
--     ratingTwoCount=subquery.ratingTwoCount,
--     ratingThreeCount=subquery.ratingThreeCount,
--     ratingFourCount=subquery.ratingFourCount,
--     ratingFiveCount=subquery.ratingFiveCount
--   FROM (
--     SELECT
--       cr.characteristic_id as characteristic_id,
--       SUM (CASE WHEN cr.rating = 1 THEN 1 ELSE 0 END) AS ratingOneCount,
--       SUM (CASE WHEN cr.rating = 2 THEN 1 ELSE 0 END) AS ratingTwoCount,
--       SUM (CASE WHEN cr.rating = 3 THEN 1 ELSE 0 END) AS ratingThreeCount,
--       SUM (CASE WHEN cr.rating = 4 THEN 1 ELSE 0 END) AS ratingFourCount,
--       SUM (CASE WHEN cr.rating = 5 THEN 1 ELSE 0 END) AS ratingFiveCount
--     FROM
--       (SELECT characteristic_id, rating FROM characteristic_reviews) cr
--     GROUP BY 1
--   ) AS subquery
--   WHERE characteristics.characteristic_id = subquery.characteristic_id;

-- Reset Id For All Tables
SELECT setval('meta_product_id_seq', (SELECT MAX(product_id) FROM meta));
SELECT setval('reviews_review_id_seq', (SELECT MAX(review_id) FROM reviews));
SELECT setval('photos_photo_id_seq', (SELECT MAX(photo_id) FROM photos));
SELECT setval('characteristics_characteristic_id_seq', (SELECT MAX(characteristic_id) FROM characteristics));
SELECT setval('characteristic_reviews_id_seq', (SELECT MAX(id) FROM characteristic_reviews));
