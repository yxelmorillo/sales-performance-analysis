/*
=============================================================
Project: Sales Performance Analysis
File: 04_sales_performance_analysis.sql

Business Question:
Who are the best sales representatives?

Purpose:
Combine customer acquisition, initial revenue and customer
Lifetime Value (LTV) to evaluate sales performance.

Database: SQL Server
=============================================================
*/

USE EjercicioX;
GO

/*=============================================================
STEP 1
Convert every paid invoice to USD.
=============================================================*/

WITH Paid_Invoices_USD AS (

    SELECT
        i.invoice_id,
        i.account_id,
        i.payment_date,
        i.invoice_amount,
        i.currency,

        i.invoice_amount * rate.rate_to_usd_total AS payment_usd,

        ROW_NUMBER() OVER (
            PARTITION BY i.account_id
            ORDER BY i.payment_date,
                     i.invoice_id
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

/*=============================================================
STEP 2
Identify customers acquired during the evaluation period.
=============================================================*/

Customers_In_Period AS (

    SELECT
        account_id,
        payment_date AS first_payment_date,
        payment_usd AS first_payment_usd

    FROM Paid_Invoices_USD

    WHERE payment_number = 1
      AND payment_date >= '2025-11-01'
      AND payment_date < '2026-02-01'

),

/*=============================================================
STEP 3
Calculate Lifetime Value (LTV) for each customer.
=============================================================*/

Customer_LTV AS (

    SELECT
        c.account_id,
        c.first_payment_date,
        c.first_payment_usd,

        SUM(p.payment_usd) AS customer_ltv_usd

    FROM Customers_In_Period c

    INNER JOIN Paid_Invoices_USD p
        ON c.account_id = p.account_id

    GROUP BY
        c.account_id,
        c.first_payment_date,
        c.first_payment_usd

),

/*=============================================================
STEP 4
Assign each customer to the latest Won opportunity before
their first successful payment.
=============================================================*/

Customer_Attribution AS (

    SELECT

        ltv.account_id,
        ltv.first_payment_date,
        ltv.first_payment_usd,
        ltv.customer_ltv_usd,

        opportunity.sales_rep_id

    FROM Customer_LTV ltv

    OUTER APPLY (

        SELECT TOP 1

            o.sales_rep_id,
            o.opportunity_id,
            o.actual_close_date

        FROM Opportunities o

        WHERE o.account_id = ltv.account_id
          AND o.Current_Stage2 = 'Won'
          AND o.actual_close_date IS NOT NULL
          AND o.actual_close_date <= ltv.first_payment_date

        ORDER BY
            o.actual_close_date DESC,
            o.opportunity_id DESC

    ) opportunity

)

/*=============================================================
STEP 5
Sales Performance KPIs.
=============================================================*/

SELECT

    sr.sales_rep_id,

    sr.sales_rep_name,

    COUNT(DISTINCT ca.account_id) AS customers_acquired,

    SUM(ca.first_payment_usd) AS initial_revenue_usd,

    SUM(ca.customer_ltv_usd) AS total_ltv_usd,

    AVG(ca.customer_ltv_usd) AS average_customer_ltv

FROM Customer_Attribution ca

INNER JOIN Sales_rep sr
    ON ca.sales_rep_id = sr.sales_rep_id

GROUP BY

    sr.sales_rep_id,
    sr.sales_rep_name

ORDER BY

    total_ltv_usd DESC;


/*=============================================================
Conclusion

Sales performance is evaluated using four business KPIs:

• Customers Acquired
• Initial Revenue
• Total Customer Lifetime Value
• Average Customer Lifetime Value

This provides a more complete evaluation than revenue alone.
=============================================================
*/
