/*
Project: Sales Performance Analysis
File: 01_data_quality_checks.sql

Purpose:
Evaluate the main data quality conditions that could affect the
identification and comparison of top-performing sales representatives.

Database: SQL Server
*/

USE EjercicioX;
GO


/* ============================================================
   1. PAID INVOICES WITH MISSING PAYMENT DATES
   ------------------------------------------------------------
   Payment date is required to determine the customer's first
   successful payment and the applicable exchange rate.
   ============================================================ */

SELECT
    COUNT(*) AS paid_invoices_without_payment_date
FROM Invoice
WHERE LOWER(LTRIM(RTRIM(invoice_status))) = 'paid'
  AND payment_date IS NULL;


/* ============================================================
   2. IMPACT OF MISSING PAYMENT DATES
   ------------------------------------------------------------
   Measures the proportion and monetary value of paid invoices
   that cannot be placed accurately on the payment timeline.
   ============================================================ */

SELECT
    COUNT(*) AS total_paid_invoices,

    SUM(
        CASE
            WHEN payment_date IS NULL THEN 1
            ELSE 0
        END
    ) AS paid_invoices_without_payment_date,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN payment_date IS NULL THEN 1
                ELSE 0
            END
        )
        / NULLIF(COUNT(*), 0)
        AS DECIMAL(10, 2)
    ) AS missing_payment_date_percentage,

    SUM(
        CASE
            WHEN payment_date IS NULL THEN invoice_amount
            ELSE 0
        END
    ) AS amount_without_payment_date
FROM Invoice
WHERE LOWER(LTRIM(RTRIM(invoice_status))) = 'paid';


/* ============================================================
   3. PAID INVOICES WITH MISSING ACCOUNT IDENTIFIERS
   ------------------------------------------------------------
   An account identifier is required to calculate customer LTV
   and connect payments with CRM opportunities.
   ============================================================ */

SELECT
    COUNT(*) AS paid_invoices_without_account_id
FROM Invoice
WHERE LOWER(LTRIM(RTRIM(invoice_status))) = 'paid'
  AND account_id IS NULL;


/* ============================================================
   4. CURRENCIES FOUND IN PAID INVOICES
   ------------------------------------------------------------
   Identifies which currencies require conversion before revenue
   and customer value can be compared.
   ============================================================ */

SELECT
    currency,
    COUNT(*) AS paid_invoice_count,
    MIN(payment_date) AS earliest_payment_date,
    MAX(payment_date) AS latest_payment_date
FROM Invoice
WHERE LOWER(LTRIM(RTRIM(invoice_status))) = 'paid'
  AND payment_date IS NOT NULL
GROUP BY currency
ORDER BY paid_invoice_count DESC;


/* ============================================================
   5. EXCHANGE RATE AVAILABILITY
   ------------------------------------------------------------
   Reviews the available exchange-rate records and their date
   coverage for each currency.
   ============================================================ */

SELECT
    currency,
    COUNT(*) AS exchange_rate_records,
    MIN(rate_date) AS earliest_rate_date,
    MAX(rate_date) AS latest_rate_date,
    SUM(
        CASE
            WHEN rate_to_usd IS NULL THEN 1
            ELSE 0
        END
    ) AS missing_exchange_rates
FROM Exchange_rates
GROUP BY currency
ORDER BY currency;


/* ============================================================
   6. ACCOUNTS WITH MULTIPLE OPPORTUNITIES
   ------------------------------------------------------------
   A direct join between accounts and opportunities could
   duplicate customers and incorrectly inflate seller results.
   ============================================================ */

SELECT
    account_id,
    COUNT(*) AS opportunity_count,
    COUNT(DISTINCT sales_rep_id) AS distinct_sales_reps
FROM Opportunities
GROUP BY account_id
HAVING COUNT(*) > 1
ORDER BY
    distinct_sales_reps DESC,
    opportunity_count DESC;


/* ============================================================
   7. WON OPPORTUNITIES WITHOUT A SALES REPRESENTATIVE
   ------------------------------------------------------------
   Customers linked to these opportunities cannot be attributed
   confidently to an individual salesperson.
   ============================================================ */

SELECT
    opportunity_id,
    account_id,
    sales_rep_id,
    Actual_Close_date
FROM Opportunities
WHERE Current_Stage2 = 'Won'
  AND sales_rep_id IS NULL
ORDER BY Actual_Close_date;
