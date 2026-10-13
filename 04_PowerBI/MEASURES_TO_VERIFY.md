# Final Power BI Validation Checks

Complete these checks in Power BI Desktop before describing the report as final. The screenshots are the current report state, and a few displayed metrics/labels should be reconciled with the refreshed source data.

## 1. Product label

The chart currently displays `Juices`. The source field is `MntWines`, so change the displayed category to **Wines** if that bar is bound to `MntWines`. Do not change the source values themselves.

## 2. Total campaign acceptances

`AcceptedCmp1` through `AcceptedCmp5` represent the five previous campaigns. Create or check a measure equivalent to:

```DAX
Total Campaign Acceptances =
    SUM('marketing_customer_enriched'[AcceptedCmp1])
    + SUM('marketing_customer_enriched'[AcceptedCmp2])
    + SUM('marketing_customer_enriched'[AcceptedCmp3])
    + SUM('marketing_customer_enriched'[AcceptedCmp4])
    + SUM('marketing_customer_enriched'[AcceptedCmp5])
```

The current Python output reports acceptance counts of 144, 30, 163, 167, and 163 for Campaigns 1–5, respectively. Their sum is **667**. After refreshing Power BI, the total-acceptance card and individual campaign bars should agree with the underlying data. If the model table has a different name, replace `marketing_customer_enriched` with the actual table name.

## 3. Average campaign acceptance

For the average number of acceptances of the five previous campaigns per customer, use:

```DAX
Avg Campaign Acceptance =
    DIVIDE([Total Campaign Acceptances], [Total Customers], 0)
```

With 667 acceptances across 2,240 customers, this is about **0.30 per customer**. This measure should not include the final `Response` field unless you deliberately rename it to indicate that it includes the final response.

## 4. Final response measures

```DAX
Total Responses =
    SUM('marketing_customer_enriched'[Response])

Response Rate =
    DIVIDE([Total Responses], [Total Customers], 0)
```

Format `Response Rate` as Percentage. Keep response counts and campaign acceptance counts as whole numbers.

## 5. Refresh and verify

- Refresh the model from the final enriched CSV.
- Verify Total Customers = 2,240, Total Responses = 334, and Response Rate is approximately 14.91% when no slicers are selected.
- Check that all campaign counts agree with `03_Python/outputs/campaign_performance.csv`.
- Re-export all three screenshots after the final fixes and replace the images in `screenshots/`.
