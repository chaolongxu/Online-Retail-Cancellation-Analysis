# Online Retail Sales and Cancellation Analysis

## Project Overview

This project analyses an online retail dataset using SQL Server, with a focus on sales performance, customer behaviour and cancellations.

The objective was to clean and structure the raw transactional data, calculate key commercial metrics and investigate cancellation patterns that may represent customer-retention or revenue risks.

## Business Questions

The analysis was designed to answer the following questions:

- How do net sales change over time?
- Which countries and products generate the most revenue?
- Who are the highest-value repeat customers?
- What percentage of transaction value is cancellations?
- Which customers generate the greatest cancellation value?
- Which valuable repeat customers have above-average cancellation rates?
- Are there cancellation patterns that require further investigation?

## Tools Used

- SQL Server
- SQL Server Management Studio
- Microsoft Excel for presenting the final results

## Data Preparation

The cleaning process included:

- Removing fully duplicated rows
- Standardising text using `UPPER`, `LTRIM` and `RTRIM`
- Converting blank descriptions into `NULL`
- Converting quantity, price, customer and date fields into appropriate data types
- Replacing unclear country abbreviations with standard country names
- Separating the date from the original date-time field
- Classifying each transaction as a sale, cancellation or another transaction type
- Calculating net sales using only genuine sales and cancellations

## Analysis

The project first provides a descriptive overview of the business, including:

- Total net sales
- Number of customers
- Monthly sales performance
- Revenue by country
- Revenue by product
- Highest-value repeat customers
<img width="1347" height="772" alt="image" src="https://github.com/user-attachments/assets/13ff5eaa-689b-4823-89a1-2cd50f6e8fc6" />

The analysis then examines cancellations in greater detail:

- Total sales and cancellation lines
- Overall cancellation rate
- **Cancellation value by customer**
- Customers with only one purchase followed by a cancellation
- **High-value repeat customers with above-average cancellation rates**
- Potential matches between sales and cancellation transactions
<img width="1352" height="740" alt="image" src="https://github.com/user-attachments/assets/d231ccab-4016-4003-bff4-1734642354f8" />

## Key Findings

### High-value one-time cancellations

Several of the customers generating the highest cancellation values made only one purchase and cancelled it without returning. These cases may indicate order-entry errors, payment problems, unavailable stock, duplicate orders or issues with the customer experience.

### Valuable customers with elevated cancellation rates

Some repeat customers generated significant purchase value but also had cancellation rates above the customer average. Because these customers contribute meaningful revenue, recurring cancellations may represent an important retention and operational risk.

## Recommendations

1. Review high-value one-time cancellations individually to identify possible payment, inventory, order-entry or customer-experience problems.

2. Prioritise high-value repeat customers with elevated cancellation rates and analyse their transactions by product, order size, timing and frequency.

3. Contact strategically important customers where appropriate to understand the reasons behind recurring cancellations.

4. Introduce standardised cancellation-reason codes to improve future analysis.

5. Monitor cancellation rate and cancellation value as recurring customer and operational KPIs.

## Limitations

The data also does not contain cancellation reasons, payment status, delivery information or customer feedback. Therefore, the analysis identifies patterns and areas for investigation rather than proving the causes of cancellation.

## Skills Demonstrated

- SQL data cleaning and transformation
- Common table expressions
- Conditional logic with `CASE`
- Aggregate functions
- Distinct customer counts
- Customer-level segmentation
- Cancellation-rate calculations
- Commercial analysis
- Translating data findings into business recommendations
