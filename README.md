# US Real Estate — SQL & Power BI Analysis

End-to-end analysis of the US residential property market (focused on the Northeast: NY, NJ, CT, PA, MA, RI, DE, NH, VT, ME, plus Puerto Rico and the Virgin Islands). Raw listing data is cleaned and transformed in **SQL**, aggregated into analysis-ready extracts, and visualized in three interactive **Power BI** dashboards.

**Tools:** MySQL, Power BI
**Data:** USA Real Estate dataset (realtor.com listings, via Kaggle) — columns include price, beds, baths, lot size, address, house size, and sold date.

## Pipeline

```
raw CSV  →  SQL cleaning (Data_Cleaning_MySQL.sql)
         →  SQL exploration & aggregation (Data_Exploration_MySQL.sql)
         →  two pre-aggregated CSV extracts
         →  Power BI (3 dashboards)
```


## Step 1 — Data cleaning (SQL)

The raw file was heavily duplicated and messy. The cleaning script:

- Removes exact duplicates (**the dataset shrank ~9×**) and near-duplicates that differ only in street spelling, using `ROW_NUMBER()` partitioned by the property's attributes.
- Fixes data types (`bed`/`bath` → INT, `zip_code` → text) and renames columns.
- Excludes `ready_to_build` rows (no sale date — not existing buildings) and six states with too few rows to compare fairly.
- Standardizes city spellings (`New York City`, `Nyc`, `Ny` → `New York`) and repairs 23 null cities from their verified street addresses.
- Removes null and junk prices (< $5,000) and corrects three verified bad records (e.g. a $120M listing with "123 bedrooms" fixed to its real $8.75M / 8-bedroom values).
- Adds metric columns (`hectare_lot`, `house_size_m2`) and a `year` column extracted from the sale date.
- Splits the result into three tables: **`re_us_property`** (all properties), **`re_us_sold`** (only rows with a sale date, for time-series analysis), and **`re_us_plots`** (vacant land).

## Step 2 — Exploration & aggregation (SQL)

Aggregate statistics (count, avg/min/max of price, size, and lot) are computed by year, state, city, bedrooms, and bathrooms. Two final queries produce the extracts that feed Power BI:

| Extract | Grain |
|---|---|
| `Quered data property sold.csv` | state × city × year × bedrooms × bathrooms (+ market size) |
| `Quered data year and month.csv` | the same, plus month — for seasonality analysis |

## Step 3 — Power BI dashboards

Three pages built on the two extracts:

1. **Sales stats overview** — properties sold by state, market size treemap, bedroom/bathroom mix, and min/avg/max KPI cards for price, size, and lot, with state and year slicers.
2. **Average price calculator** — pick a state, city, bedroom count, and year range, and read off the average price and property count for that segment.
3. **State & seasonality trends** — properties sold per year by state, city-level cards, and a monthly sales curve showing the summer peak.

## Results

- A cleaned, de-duplicated dataset (~9× smaller than the raw file) split into property / sold / plots tables.
- Three interactive dashboards for self-serve market exploration.
- Headline findings: New Jersey and New York dominate listing volume, New York leads market size (~$21bn), sales volume climbs steeply after 2010 and peaks in 2023, and monthly sales peak in summer (June–August).

## Repository

- `Data_Cleaning_MySQL.sql` — full cleaning pipeline
- `Data_Exploration_MySQL.sql` — exploration + the two Power BI extract queries
- `Quered data property sold.csv`, `Quered data year and month.csv` — pre-aggregated extracts
- `Real Estate USA Dashboards.pbix` — Power BI file
- `Real-Estate USA Dashboards.pdf` — static export of the three dashboards
