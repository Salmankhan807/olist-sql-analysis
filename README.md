# Olist E-commerce Sales Analytics (MySQL)

SQL analysis of a Brazilian online marketplace: ~100k orders across 8 related tables, covering revenue trends, product categories, delivery performance, customer retention, seller concentration, and payment behaviour.

**Tools:** MySQL 8.0, MySQL Workbench
**Dataset:** [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) (Kaggle, 2016-2018)

## What this project covers

- **Database design:** 8 tables with primary keys, a composite key, and foreign keys
- **Data loading and cleaning:** bulk loading with `LOAD DATA`, converting blank values to `NULL`, fixing missing category translations, handling non-unique review IDs
- **Views:** reusable clean layers (`delivered_orders`, `product_info`)
- **Analysis SQL:** multi-table joins, `LEFT JOIN`, `GROUP BY`, `CASE`, CTEs (including chained CTEs), window functions (`LAG`, `RANK`, `NTILE`, `SUM() OVER`), `COALESCE`, date functions

## Schema

`customers` -> `orders` -> `order_items` -> `products` / `sellers`
`orders` -> `order_payments`, `order_reviews`
`products` -> `product_category_name_translation`

The `geolocation` table (~1M rows) was left out because the analysis did not need it.

## Data quality notes

- Only `delivered` orders with a delivery date are used (96,470 of 99,441 orders), through the `delivered_orders` view.
- 8 orders were marked delivered but had no delivery date and were excluded.
- 610 products had no category and are labelled `unknown`; 2 categories were missing English translations and were added manually.
- `review_id` is not unique in the source data, so reviews use a surrogate key.
- Revenue means product price only (shipping excluded), in Brazilian reais (R$).

## Key findings

**1. Growth came from order volume, then plateaued.** Monthly revenue grew about 9x from Jan 2017 (R$112k) to Nov 2017 (R$988k, Black Friday), then flattened between R$830k and R$980k through Aug 2018. Average order value stayed around R$130-150, so growth was driven by more orders, not larger ones. Data before Jan 2017 is sparse and was excluded from trend claims.

**2. Order volume does not predict revenue by category.** Health & beauty led revenue (R$1.23M). Watches & gifts ranked 2nd with about 40% fewer orders than bed & bath, because its average order value was about R$212 versus about R$110.

**3. Late delivery sharply lowers reviews.** Delivered orders took 12.5 days on average and arrived about 12 days ahead of the estimate, but 8.1% (about 7,700 reviewed orders) arrived late. On-time orders averaged **4.29 stars** and late orders **2.57**.

**4. Very few customers come back.** Only 3.0% of customers (2,801 of 93,350) placed more than one order, which suggests growth was driven by new-customer acquisition rather than retention.

**5. Seller revenue is highly concentrated.** The top 10% of sellers (297) generated 67% of revenue and the top 20% generated 82%, while the bottom 50% generated 3%. No single seller exceeded 2% of the total.

**6. Credit cards dominate payments.** Credit cards made up 78.5% of payment value at an average of 3.5 installments, followed by boleto (18.0%), vouchers (2.2%), and debit cards (1.3%).

## Limitations

- The dataset covers about two years, so retention (finding 4) is likely understated for recent customers.
- Late-delivery figures only include delivered orders; canceled or lost orders are not counted.
- Revenue excludes shipping; payment totals include it.

## How to run

1. Download the dataset from Kaggle and extract the CSVs.
2. Open `olist_analysis.sql` in MySQL Workbench.
3. Update the file paths in the data loading section.
4. Enable `local_infile` (see the comments in the script) and run the sections in order.

## Files

- `olist_analysis.sql`: schema, loading, data quality checks, views, and all analysis queries
- `screenshots/`: query results
