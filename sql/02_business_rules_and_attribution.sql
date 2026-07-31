/*
=============================================================
Project: Sales Performance Analysis
File: 02_business_rules_and_attribution.sql

Business Question:
Which salesperson should receive credit for each acquired customer?

Purpose:
Apply the business rules required to identify each customer's
first successful payment and correctly attribute that customer
to the appropriate sales representative.

Database: SQL Server
=============================================================
*/

USE EjercicioX;
GO

/*=============================================================
STEP 1
Validate accounts with multiple opportunities.

Some accounts may have multiple opportunities and different
sales representatives. This validation confirms that a direct
JOIN could produce incorrect attribution.
=============================================================*/

SELECT
    account_id,
    COUNT(*) AS opportunity_count,
    COUNT(DISTINCT sales_rep_id) AS distinct_sales_reps
FROM Opportunities
GROUP BY account_id
HAVING COUNT(*) > 1
ORDER BY distinct_sales_reps DESC,
         opportunity_count DESC;


/*=============================================================
STEP 2
Identify each customer's first successful payment,
convert it to USD using the latest available exchange rate,
and attribute the customer to the last Won opportunity
before the first payment.
=============================================================*/

WITH Paid_Invoices_USD AS (

    SELECT
        i.invoice_id,
        i.account_id,
        i.payment_date,
        i.invoice_amount,
        i.currency,

        i.invoice_amount * rate.rate_to_usd_total AS first_payment_usd,

        ROW_NUMBER() OVER (
            PARTITION BY i.account_id
            ORDER BY i.payment_date ASC,
                     i.invoice_id ASC
        ) AS payment_number

    FROM Invoice i

    CROSS APPLY (

        SELECT TOP 1

            CASE
                WHEN er.currency = 'USD'
                    THEN 1.0
                ELSE er.rate_to_usd / 1000000.0
            END AS rate_to_usd_total

        FROM Exchange_rates er

        WHERE er.currency = i.currency
          AND er.rate_to_usd IS NOT NULL
          AND er.rate_date IS NOT NULL
          AND DATEFROMPARTS(
                YEAR(er.rate_date),
                DAY(er.rate_date),
                1
              ) <= i.payment_date

        ORDER BY
            DATEFROMPARTS(
                YEAR(er.rate_date),
                DAY(er.rate_date),
                1
            ) DESC

    ) rate

    WHERE i.invoice_status = 'paid'
      AND i.payment_date IS NOT NULL
      AND i.account_id IS NOT NULL
),

Customers_In_Period AS (

    SELECT
        account_id,
        payment_date,
        first_payment_usd

    FROM Paid_Invoices_USD

    WHERE payment_number = 1
      AND payment_date >= '2025-11-01'
      AND payment_date < '2026-02-01'

),

Customer_Attribution AS (

    SELECT

        c.account_id,
        c.payment_date,
        c.first_payment_usd,

        opportunity.sales_rep_id

    FROM Customers_In_Period c

    OUTER APPLY (

        SELECT TOP 1

            o.sales_rep_id,
            o.opportunity_id,
            o.actual_close_date

        FROM Opportunities o

        WHERE o.account_id = c.account_id
          AND o.Current_Stage2 = 'Won'
          AND o.actual_close_date IS NOT NULL
          AND o.actual_close_date <= c.payment_date

        ORDER BY
            o.actual_close_date DESC,
            o.opportunity_id DESC

    ) opportunity

)

SELECT

    sr.sales_rep_id,
    sr.sales_rep_name,

    COUNT(DISTINCT ca.account_id) AS customers_acquired,

    SUM(ca.first_payment_usd) AS initial_revenue_usd

FROM Customer_Attribution ca

INNER JOIN Sales_rep sr
    ON ca.sales_rep_id = sr.sales_rep_id

GROUP BY
    sr.sales_rep_id,
    sr.sales_rep_name

ORDER BY
    initial_revenue_usd DESC;


/*=============================================================
Conclusion

Each customer is uniquely attributed to the salesperson
responsible for the latest Won opportunity before the first
successful payment.

This attribution model is used in the following LTV analysis.
=============================================================*/
