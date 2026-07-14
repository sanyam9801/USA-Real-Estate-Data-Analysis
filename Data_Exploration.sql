USE real_estate_us;

/* ---------- Properties sold by year ---------- */

SELECT
    year,
    COUNT(*) AS property_sold
FROM re_us_sold
GROUP BY year
ORDER BY property_sold DESC;

/* 2023 - highest, 1901 - lowest */


/* ---------- Explore by state ---------- */

SELECT
    state,
    COUNT(*)           AS num_of_property,
    AVG(price)         AS avg_price,
    MIN(price)         AS min_price,
    MAX(price)         AS max_price,
    AVG(house_size_m2) AS avg_size,
    MIN(house_size_m2) AS min_size,
    MAX(house_size_m2) AS max_size,
    AVG(hectare_lot)   AS avg_lot,
    MIN(hectare_lot)   AS min_lot,
    MAX(hectare_lot)   AS max_lot
FROM re_us_property
GROUP BY state
ORDER BY num_of_property DESC;

/* Same stats by state and year */

SELECT
    year,
    state,
    COUNT(*)           AS num_of_property,
    AVG(price)         AS avg_price,
    MIN(price)         AS min_price,
    MAX(price)         AS max_price,
    AVG(house_size_m2) AS avg_size,
    MIN(house_size_m2) AS min_size,
    MAX(house_size_m2) AS max_size,
    AVG(hectare_lot)   AS avg_lot,
    MIN(hectare_lot)   AS min_lot,
    MAX(hectare_lot)   AS max_lot
FROM re_us_property
WHERE year IS NOT NULL
GROUP BY state, year
ORDER BY num_of_property DESC;


/* ---------- Explore by city ---------- */

SELECT
    city,
    COUNT(*)           AS num_of_property,
    AVG(price)         AS avg_price,
    MIN(price)         AS min_price,
    MAX(price)         AS max_price,
    AVG(house_size_m2) AS avg_size,
    MIN(house_size_m2) AS min_size,
    MAX(house_size_m2) AS max_size,
    AVG(hectare_lot)   AS avg_lot,
    MIN(hectare_lot)   AS min_lot,
    MAX(hectare_lot)   AS max_lot
FROM re_us_property
GROUP BY city
ORDER BY num_of_property DESC;


/* ---------- Explore by bathrooms ---------- */

SELECT
    state,
    bathrooms,
    COUNT(*)           AS count_bath,
    AVG(price)         AS avg_price,
    MIN(price)         AS min_price,
    MAX(price)         AS max_price,
    AVG(house_size_m2) AS avg_size,
    MIN(house_size_m2) AS min_size,
    MAX(house_size_m2) AS max_size
FROM re_us_property
GROUP BY state, bathrooms
ORDER BY count_bath DESC, state;

SELECT
    bathrooms,
    COUNT(*)           AS count_bath,
    AVG(price)         AS avg_price,
    MIN(price)         AS min_price,
    MAX(price)         AS max_price,
    AVG(house_size_m2) AS avg_size,
    MIN(house_size_m2) AS min_size,
    MAX(house_size_m2) AS max_size
FROM re_us_property
GROUP BY bathrooms
ORDER BY count_bath DESC;


/* ---------- Explore by bedrooms ---------- */

SELECT
    state,
    bedrooms,
    COUNT(*)           AS count_bed,
    AVG(price)         AS avg_price,
    MIN(price)         AS min_price,
    MAX(price)         AS max_price,
    AVG(house_size_m2) AS avg_size,
    MIN(house_size_m2) AS min_size,
    MAX(house_size_m2) AS max_size
FROM re_us_property
GROUP BY bedrooms, state
ORDER BY count_bed DESC;

SELECT
    bedrooms,
    COUNT(*)           AS count_bed,
    AVG(price)         AS avg_price,
    MIN(price)         AS min_price,
    MAX(price)         AS max_price,
    AVG(house_size_m2) AS avg_size,
    MIN(house_size_m2) AS min_size,
    MAX(house_size_m2) AS max_size
FROM re_us_property
GROUP BY bedrooms
ORDER BY count_bed DESC;



ALTER TABLE re_us_property ADD COLUMN year INT;
UPDATE re_us_property SET year = YEAR(sold_date);




SELECT
    state,
    city,
    year,
    bedrooms,
    bathrooms,
    COUNT(*)           AS num_of_property,
    SUM(price)         AS market_size,
    AVG(price)         AS avg_price,
    MIN(price)         AS min_price,
    MAX(price)         AS max_price,
    AVG(house_size_m2) AS avg_size,
    MIN(house_size_m2) AS min_size,
    MAX(house_size_m2) AS max_size,
    AVG(hectare_lot)   AS avg_lot,
    MIN(hectare_lot)   AS min_lot,
    MAX(hectare_lot)   AS max_lot
FROM re_us_property
WHERE year IS NOT NULL
GROUP BY state, city, year, bedrooms, bathrooms
ORDER BY num_of_property DESC;




SELECT
    state,
    city,
    year,
    DATE_FORMAT(sold_date, '%M') AS month,
    bedrooms,
    bathrooms,
    COUNT(*)           AS num_of_property,
    AVG(price)         AS avg_price,
    MIN(price)         AS min_price,
    MAX(price)         AS max_price,
    AVG(house_size_m2) AS avg_size,
    MIN(house_size_m2) AS min_size,
    MAX(house_size_m2) AS max_size,
    AVG(hectare_lot)   AS avg_lot,
    MIN(hectare_lot)   AS min_lot,
    MAX(hectare_lot)   AS max_lot
FROM re_us_property
WHERE year IS NOT NULL
GROUP BY state, city, year, month, bedrooms, bathrooms
ORDER BY num_of_property DESC;


/* ---------- Explore rows with no sold date (still on market) ---------- */

SELECT
    state,
    city,
    bedrooms,
    bathrooms,
    COUNT(*)           AS num_of_property,
    SUM(price)         AS market_size,
    AVG(price)         AS avg_price,
    MIN(price)         AS min_price,
    MAX(price)         AS max_price,
    AVG(house_size_m2) AS avg_size,
    MIN(house_size_m2) AS min_size,
    MAX(house_size_m2) AS max_size,
    AVG(hectare_lot)   AS avg_lot,
    MIN(hectare_lot)   AS min_lot,
    MAX(hectare_lot)   AS max_lot
FROM re_us_property
WHERE year IS NULL
GROUP BY state, city, bedrooms, bathrooms
ORDER BY num_of_property DESC;


/* ---------- Explore from lowest price ---------- */

SELECT *
FROM re_us_property
WHERE year IS NULL
ORDER BY price ASC;

