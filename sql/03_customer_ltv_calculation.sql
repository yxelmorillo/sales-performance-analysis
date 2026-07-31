/*
=============================================================
Project: Sales Performance Analysis
File: 03_customer_ltv_calculation.sql

Business Question:
How much is each acquired customer worth over their lifetime?

Purpose:
Calculate the Lifetime Value (LTV) of every customer whose
first successful payment occurred during the evaluation period.

Database: SQL Server
=============================================================
*/

USE EjercicioX;
GO

/*=============================================================
STEP 1
Convert every paid invoice to USD using the latest available
exchange rate before the payment date.
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
Keep customers whose first payment occurred during the
evaluation period.
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
Calculate Lifetime Value by summing every historical payment
made by each selected customer.
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

)

SELECT

    account_id,

    first_payment_date,

    first_payment_usd,

    customer_ltv_usd

FROM Customer_LTV

ORDER BY
    customer_ltv_usd DESC;


/*=============================================================
Conclusion

Each acquired customer now has a standardized Lifetime Value
(LTV) in USD.

This output will be used in the final sales performance
analysis to evaluate salesperson quality, not only revenue.
=============================================================
*/
