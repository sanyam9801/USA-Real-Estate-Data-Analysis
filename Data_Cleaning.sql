

USE real_estate_us;

/* ---------- First look at the dataset ---------- */

SELECT *
FROM re_us_raw
LIMIT 1000;


/* ---------- 1. Remove exact duplicates ----------
   The raw file is massively duplicated (~9x). DISTINCT * keeps one copy. */

DROP TABLE IF EXISTS re_us1;
CREATE TABLE re_us1 AS
SELECT DISTINCT *
FROM re_us_raw;


/* ---------- 2. Fix data types and rename columns ----------
   In MySQL this is a single ALTER instead of a table rebuild. */

ALTER TABLE re_us1
    CHANGE bed      bedrooms  INT,
    CHANGE bath     bathrooms INT,
    CHANGE zip_code zipcode   VARCHAR(10);



/* ---------- 3. Inspect the status column ---------- */

SELECT status, COUNT(*) AS cnt
FROM re_us1
GROUP BY status;

SELECT *
FROM re_us1
WHERE status = 'ready_to_build'
  AND sold_date IS NOT NULL;

/* Two values: 'for_sale' (majority) and 'ready_to_build' (277 rows).
   No 'ready_to_build' row has a sold_date -> they are not existing
   buildings, exclude them from the analysis. */


/* ---------- 4. Inspect bedrooms / bathrooms ---------- */

SELECT bedrooms, COUNT(*) AS count_bed
FROM re_us1
GROUP BY bedrooms
ORDER BY count_bed DESC;

SELECT * FROM re_us1 WHERE bedrooms > 11;
SELECT * FROM re_us1 WHERE bedrooms IS NULL;

SELECT bathrooms, COUNT(*) AS count_bath
FROM re_us1
GROUP BY bathrooms
ORDER BY count_bath DESC;

SELECT * FROM re_us1 WHERE bathrooms > 12;
SELECT * FROM re_us1 WHERE bathrooms IS NULL;

/* A few absurd outliers (e.g. 123 bedrooms) and ~17.5k / ~16.3k nulls.
   Too few extreme rows to skew aggregates -> left as is, except the
   one verified error fixed below (421 W 250th St). */


/* ---------- 5. Inspect the state column ---------- */

SELECT state, COUNT(*) AS counts
FROM re_us1
GROUP BY state
ORDER BY counts DESC;

/* No nulls. Virginia (7), Georgia (5), South Carolina, Tennessee,
   Wyoming, West Virginia (1 each) have too few rows to compare fairly
   -> exclude. */


/* ---------- 6. Inspect sold_date ---------- */

SELECT COUNT(*) FROM re_us1 WHERE sold_date IS NULL;

/* ~54k rows have no sold_date. They can't be used for time-series work,
   so the plan is to split into a general table and a "sold" table. */


/* ---------- 7. Drop unusable rows and columns ----------
   BigQuery needed a full table rebuild here; MySQL just deletes. */

DELETE FROM re_us1
WHERE status = 'ready_to_build'
   OR state IN ('Virginia','Georgia','South Carolina',
                'Tennessee','Wyoming','West Virginia');

ALTER TABLE re_us1
    DROP COLUMN status,
    DROP COLUMN full_address,
    DROP COLUMN zipcode;


/* ---------- 8. Standardize city spellings ---------- */

SELECT city, state, COUNT(*) AS counts
FROM re_us1
WHERE city LIKE 'N%' AND state = 'New York'
GROUP BY city, state
ORDER BY counts DESC;


UPDATE re_us1
SET city = 'New York'
WHERE state = 'New York'
  AND city IN ('New York City','Nyc','Ny');


/* ---------- 9. Fix 23 null cities from their street address ---------- */

UPDATE re_us1
SET city = CASE
    WHEN street IN ('163 Union and Mt Wash Ea','155-A La Vallee Nb',
                    '123 Catherines Hope Eb','21 N Grapetree Eb',
                    '42 43 Shoys Ea','8-B Teagues Bay Eb',
                    '242 Union and Mt Wash Ea','96 Hard Labor Pr')
         THEN 'Christiansted'
    WHEN street IN ('4 Prosperity Nb','20 River Pr','17 Prosperity Nb',
                    '94V I Corp Lands Pr','14 Diamond Pr','192 La Vallee Nb')
         THEN 'Frederiksted'
    WHEN street = '240 St John Qu'                                  THEN 'Saint John'
    WHEN street = '230 S Stevens Ave'                               THEN 'South Amboy'
    WHEN street = '0 Block 32 Quinton Alloway Quinton Rd Lot 11 01' THEN 'Quinton'
    WHEN street = '641 State Route 82'                              THEN 'Hopewell Junction'
    WHEN street = '32 Devereux Dr'                                  THEN 'Manchester Township'
    WHEN street = '9-11 Putnam Park Rd'                             THEN 'Bethel'
    WHEN street = '68 Avondale St'                                  THEN 'Valley Stream'
    WHEN street = '824-26 Berckman St'                              THEN 'Plainfield'
    WHEN street = '689 Luis M Marin Blvd Unit 1009'                 THEN 'Jersey City'
    ELSE city
END
WHERE city IS NULL;


/* ---------- 10. Remove null / junk prices ---------- */

SELECT * FROM re_us1 WHERE price IS NULL;
SELECT * FROM re_us1 WHERE price < 5000;

DELETE FROM re_us1
WHERE price IS NULL OR price < 5000;   -- 51 junk rows + nulls


/* ---------- 11. Correct verified bad records ---------- */

UPDATE re_us1
SET city = 'Bronx', price = 8750000, bedrooms = 8, bathrooms = 10,
    house_size = 11135, sold_date = NULL
WHERE street = '421 W 250th St';

UPDATE re_us1
SET price = 850000
WHERE street = '952 E 223 St Units 4858 & 66' AND price = 875000000;

UPDATE re_us1
SET price = 180000000
WHERE street = '432 Park Ave Unit Penthouse' AND price = 169000000;


/* ---------- 12. Rename working table ---------- */

DROP TABLE IF EXISTS re_us2;
RENAME TABLE re_us1 TO re_us2;


/* ---------- 13. Inspect near-duplicates ----------
   Rows identical in every column except a slightly different street
   spelling. IFNULL placeholders are needed for the JOIN check because
   NULL = NULL is never true in a join condition. */

SELECT a.*
FROM re_us2 a
JOIN (
    SELECT state, city, price,
           IFNULL(bedrooms,0)  AS bedrooms,
           IFNULL(bathrooms,0) AS bathrooms,
           IFNULL(acre_lot,0)  AS acre_lot,
           IFNULL(house_size,0) AS house_size,
           COUNT(*) AS cnt
    FROM re_us2
    GROUP BY state, city, price,
             IFNULL(bedrooms,0), IFNULL(bathrooms,0),
             IFNULL(acre_lot,0), IFNULL(house_size,0)
    HAVING COUNT(*) > 1
) b
  ON  a.state = b.state
  AND a.city  = b.city
  AND a.price = b.price
  AND IFNULL(a.bedrooms,0)   = b.bedrooms
  AND IFNULL(a.bathrooms,0)  = b.bathrooms
  AND IFNULL(a.acre_lot,0)   = b.acre_lot
  AND IFNULL(a.house_size,0) = b.house_size
ORDER BY a.price;

/* Web checks show most of these are the same property listed twice. */


/* ---------- 14. Remove near-duplicates with ROW_NUMBER ---------- */

DROP TABLE IF EXISTS re_us_noduplicates;
CREATE TABLE re_us_noduplicates AS
WITH cte AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY state, city, price, bedrooms, bathrooms,
                            acre_lot, house_size, sold_date
               ORDER BY price DESC) AS rn
    FROM re_us2
)
SELECT state, city, street, price, bedrooms, bathrooms,
       acre_lot, house_size, sold_date
FROM cte
WHERE rn = 1;

/* Add a surrogate id */
ALTER TABLE re_us_noduplicates
    ADD COLUMN id INT AUTO_INCREMENT PRIMARY KEY FIRST;


/* ---------- 15. Split plots of land from buildings ----------
   A "plot": no bedrooms, no bathrooms, no house size, but has a lot. */

DROP TABLE IF EXISTS re_us_plots;
CREATE TABLE re_us_plots AS
SELECT state, city, street, price, acre_lot, sold_date
FROM re_us_noduplicates
WHERE (bedrooms  IS NULL OR bedrooms  = 0)
  AND (bathrooms IS NULL OR bathrooms = 0)
  AND (house_size IS NULL OR house_size = 0)
  AND acre_lot IS NOT NULL AND acre_lot <> 0;

DELETE FROM re_us_noduplicates
WHERE (bedrooms  IS NULL OR bedrooms  = 0)
  AND (bathrooms IS NULL OR bathrooms = 0)
  AND (house_size IS NULL OR house_size = 0)
  AND acre_lot IS NOT NULL AND acre_lot <> 0;

/* Rows where beds, baths, lot AND size are all missing (~552) are kept:
   most look like real properties with skipped data entry. */


/* ---------- 16. Final property table with metric columns + year ---------- */

DROP TABLE IF EXISTS re_us_property;
CREATE TABLE re_us_property AS
SELECT
    id,
    state,
    city,
    street,
    price,
    bedrooms,
    bathrooms,
    acre_lot,
    acre_lot  * 0.404686  AS hectare_lot,     -- acres  -> hectares
    house_size,
    house_size / 10.7639  AS house_size_m2,   -- sq ft  -> m2
    sold_date,
    YEAR(sold_date)       AS year
FROM re_us_noduplicates;


/* ---------- 17. Sold-only table for time-series analysis ---------- */

DROP TABLE IF EXISTS re_us_sold;
CREATE TABLE re_us_sold AS
SELECT *
FROM re_us_property
WHERE sold_date IS NOT NULL;