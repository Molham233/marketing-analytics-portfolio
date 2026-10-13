# ============================================================
# PROJECT 3 - MARKETING ANALYTICS
# marketing_analysis.py
# ============================================================

from pathlib import Path
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

BASE_DIR = Path(__file__).resolve().parent
DATA_PATH = BASE_DIR.parent / "01_Data" / "marketing_data.csv"
OUTPUT_DIR = BASE_DIR / "outputs"
CHART_DIR = OUTPUT_DIR / "charts"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
CHART_DIR.mkdir(parents=True, exist_ok=True)

# ------------------------------------------------------------
# 1. Load data
# ------------------------------------------------------------
df = pd.read_csv(DATA_PATH)
df.columns = df.columns.str.replace("\\ufeff", "", regex=False).str.strip()

print("Shape:", df.shape)
print("\\nColumns:")
print(df.columns.tolist())

# ------------------------------------------------------------
# 2. Basic cleaning
# ------------------------------------------------------------
df["Dt_Customer"] = pd.to_datetime(df["Dt_Customer"], errors="coerce")

# Remove exact duplicate rows if any.
df = df.drop_duplicates().copy()

# Validate unique customer IDs.
duplicate_ids = df["ID"].duplicated().sum()
print("\\nDuplicate customer IDs:", duplicate_ids)

# Keep original income for data-quality reporting.
df["Income_Original"] = df["Income"]

# Impute missing income with the median for analysis.
income_median = df["Income"].median()
df["Income"] = df["Income"].fillna(income_median)

# ------------------------------------------------------------
# 3. Data-quality treatment
# ------------------------------------------------------------
# Age is based on 2015 because the campaign dataset covers the
# 2012-2014 customer/campaign period.
df["Age"] = 2015 - df["Year_Birth"]

# Flag unusual birth years instead of silently deleting them.
df["Age_Valid"] = df["Age"].between(18, 100)

# Income quality flag.
df["Income_Valid"] = df["Income"] > 0

# ------------------------------------------------------------
# 4. Feature engineering
# ------------------------------------------------------------
product_cols = [
    "MntWines", "MntFruits", "MntMeatProducts",
    "MntFishProducts", "MntSweetProducts", "MntGoldProds"
]

channel_cols = [
    "NumWebPurchases", "NumCatalogPurchases", "NumStorePurchases"
]

past_campaign_cols = [
    "AcceptedCmp1", "AcceptedCmp2", "AcceptedCmp3",
    "AcceptedCmp4", "AcceptedCmp5"
]

all_campaign_cols = past_campaign_cols + ["Response"]

df["Total_Spending"] = df[product_cols].sum(axis=1)

# Deals purchases are not added to Total_Purchases because they
# are discount purchases and can overlap with the channel purchases.
df["Total_Purchases"] = df[channel_cols].sum(axis=1)

df["Total_Children"] = df["Kidhome"] + df["Teenhome"]
df["Household_Size"] = df["Total_Children"] + 1

df["Past_Campaign_Accepted"] = df[past_campaign_cols].sum(axis=1)
df["Total_Campaign_Accepted"] = df[all_campaign_cols].sum(axis=1)

# ------------------------------------------------------------
# 5. Customer segmentation
# ------------------------------------------------------------
df["Spending_Segment"] = pd.qcut(
    df["Total_Spending"],
    q=4,
    labels=["Low Value", "Medium-Low Value", "Medium-High Value", "High Value"],
    duplicates="drop"
)

# RFM-style segmentation
# Recency: lower is better.
df["R_Score"] = pd.qcut(
    df["Recency"].rank(method="first"),
    4,
    labels=[4, 3, 2, 1]
).astype(int)

df["F_Score"] = pd.qcut(
    df["Total_Purchases"].rank(method="first"),
    4,
    labels=[1, 2, 3, 4]
).astype(int)

df["M_Score"] = pd.qcut(
    df["Total_Spending"].rank(method="first"),
    4,
    labels=[1, 2, 3, 4]
).astype(int)

df["RFM_Score"] = df["R_Score"] + df["F_Score"] + df["M_Score"]

df["RFM_Segment"] = np.select(
    [
        df["RFM_Score"] >= 10,
        df["RFM_Score"].between(8, 9),
        df["RFM_Score"].between(6, 7),
        df["RFM_Score"] <= 5,
    ],
    ["High Value / Loyal", "Potential Loyalist", "Needs Attention", "At Risk"],
    default="Needs Attention"
)

# Age groups
bins = [0, 29, 39, 49, 59, 69, np.inf]
labels = ["Under 30", "30-39", "40-49", "50-59", "60-69", "70+"]
df["Age_Group"] = pd.cut(df["Age"], bins=bins, labels=labels)

# Income groups
income_bins = [-np.inf, 30000, 50000, 70000, 100000, np.inf]
income_labels = ["Under 30K", "30K-50K", "50K-70K", "70K-100K", "100K+"]
df["Income_Group"] = pd.cut(df["Income"], bins=income_bins, labels=income_labels)

# ------------------------------------------------------------
# 6. KPI outputs
# ------------------------------------------------------------
kpis = pd.DataFrame({
    "KPI": [
        "Total Customers", "Total Spending", "Average Customer Spending",
        "Total Purchases", "Average Purchases per Customer", "Average Income",
        "Average Age", "Average Recency", "Campaign Responses",
        "Campaign Response Rate", "Complaints"
    ],
    "Value": [
        len(df),
        df["Total_Spending"].sum(),
        df["Total_Spending"].mean(),
        df["Total_Purchases"].sum(),
        df["Total_Purchases"].mean(),
        df["Income"].mean(),
        df["Age"].mean(),
        df["Recency"].mean(),
        df["Response"].sum(),
        df["Response"].mean() * 100,
        df["Complain"].sum(),
    ]
})
kpis.to_csv(OUTPUT_DIR / "customer_kpis.csv", index=False)

# ------------------------------------------------------------
# 7. Product performance
# ------------------------------------------------------------
product_map = {
    "Wines": "MntWines",
    "Fruits": "MntFruits",
    "Meat": "MntMeatProducts",
    "Fish": "MntFishProducts",
    "Sweets": "MntSweetProducts",
    "Gold": "MntGoldProds",
}
product_perf = pd.DataFrame({
    "Product": list(product_map.keys()),
    "Total_Spending": [df[c].sum() for c in product_map.values()],
})
product_perf["Avg_Spending_Per_Customer"] = [
    df[c].mean() for c in product_map.values()
]
product_perf = product_perf.sort_values("Total_Spending", ascending=False)
product_perf.to_csv(OUTPUT_DIR / "product_performance.csv", index=False)

# ------------------------------------------------------------
# 8. Channel performance
# ------------------------------------------------------------
channel_map = {
    "Web": "NumWebPurchases",
    "Catalog": "NumCatalogPurchases",
    "Store": "NumStorePurchases",
    "Deals": "NumDealsPurchases",
}
channel_perf = pd.DataFrame({
    "Channel": list(channel_map.keys()),
    "Total_Purchases": [df[c].sum() for c in channel_map.values()],
    "Avg_Purchases_Per_Customer": [df[c].mean() for c in channel_map.values()],
})
channel_perf = channel_perf.sort_values("Total_Purchases", ascending=False)
channel_perf.to_csv(OUTPUT_DIR / "channel_performance.csv", index=False)

# ------------------------------------------------------------
# 9. Campaign performance
# ------------------------------------------------------------
campaign_map = {
    "Campaign 1": "AcceptedCmp1",
    "Campaign 2": "AcceptedCmp2",
    "Campaign 3": "AcceptedCmp3",
    "Campaign 4": "AcceptedCmp4",
    "Campaign 5": "AcceptedCmp5",
    "Final Campaign": "Response",
}
campaign_perf = pd.DataFrame({
    "Campaign": list(campaign_map.keys()),
    "Accepted_Customers": [df[c].sum() for c in campaign_map.values()],
    "Response_Rate_Pct": [df[c].mean() * 100 for c in campaign_map.values()],
})
campaign_perf = campaign_perf.sort_values("Response_Rate_Pct", ascending=False)
campaign_perf.to_csv(OUTPUT_DIR / "campaign_performance.csv", index=False)

# ------------------------------------------------------------
# 10. Customer segments
# ------------------------------------------------------------
segment_perf = (
    df.groupby("Spending_Segment", observed=True)
      .agg(
          Customers=("ID", "count"),
          Avg_Spending=("Total_Spending", "mean"),
          Avg_Income=("Income", "mean"),
          Avg_Purchases=("Total_Purchases", "mean"),
          Response_Rate=("Response", "mean"),
          Avg_Recency=("Recency", "mean"),
      )
      .reset_index()
)
segment_perf["Response_Rate"] *= 100
segment_perf.to_csv(OUTPUT_DIR / "customer_segments.csv", index=False)

rfm_perf = (
    df.groupby("RFM_Segment")
      .agg(
          Customers=("ID", "count"),
          Avg_Spending=("Total_Spending", "mean"),
          Avg_Purchases=("Total_Purchases", "mean"),
          Avg_Recency=("Recency", "mean"),
          Response_Rate=("Response", "mean"),
      )
      .reset_index()
)
rfm_perf["Response_Rate"] *= 100
rfm_perf.to_csv(OUTPUT_DIR / "rfm_segments.csv", index=False)

# ------------------------------------------------------------
# 11. Demographic analysis
# ------------------------------------------------------------
for group_col, filename in [
    ("Age_Group", "age_group_analysis.csv"),
    ("Income_Group", "income_group_analysis.csv"),
    ("Education", "education_analysis.csv"),
    ("Marital_Status", "marital_status_analysis.csv"),
    ("Country", "country_analysis.csv"),
]:
    out = (
        df.groupby(group_col, observed=True)
          .agg(
              Customers=("ID", "count"),
              Avg_Spending=("Total_Spending", "mean"),
              Total_Spending=("Total_Spending", "sum"),
              Avg_Purchases=("Total_Purchases", "mean"),
              Response_Rate=("Response", "mean"),
          )
          .reset_index()
    )
    out["Response_Rate"] *= 100
    out.to_csv(OUTPUT_DIR / filename, index=False)

# ------------------------------------------------------------
# 12. Correlation analysis
# ------------------------------------------------------------
corr_cols = [
    "Age", "Income", "Recency", "Total_Spending", "Total_Purchases",
    "NumWebVisitsMonth", "NumWebPurchases", "NumCatalogPurchases",
    "NumStorePurchases", "NumDealsPurchases", "Response"
]
corr = df[corr_cols].corr(numeric_only=True)
corr.to_csv(OUTPUT_DIR / "correlation_matrix.csv")

# Correlation with key outcomes
corr_summary = pd.DataFrame({
    "Variable": corr_cols,
    "Corr_with_Total_Spending": [corr.loc[c, "Total_Spending"] for c in corr_cols],
    "Corr_with_Web_Purchases": [corr.loc[c, "NumWebPurchases"] for c in corr_cols],
    "Corr_with_Response": [corr.loc[c, "Response"] for c in corr_cols],
})
corr_summary.to_csv(OUTPUT_DIR / "correlation_summary.csv", index=False)

# ------------------------------------------------------------
# 13. Missing values & data quality
# ------------------------------------------------------------
missing = df.isna().sum().reset_index()
missing.columns = ["Column", "Missing_Count"]
missing["Missing_Pct"] = missing["Missing_Count"] / len(df) * 100
missing.to_csv(OUTPUT_DIR / "missing_values.csv", index=False)

quality = pd.DataFrame({
    "Check": [
        "Rows",
        "Unique IDs",
        "Duplicate IDs",
        "Original Missing Income",
        "Invalid Age",
        "Invalid Income",
        "Exact Duplicate Rows",
    ],
    "Result": [
        len(df),
        df["ID"].nunique(),
        df["ID"].duplicated().sum(),
        df["Income_Original"].isna().sum(),
        (~df["Age_Valid"]).sum(),
        (~df["Income_Valid"]).sum(),
        0,
    ]
})
quality.to_csv(OUTPUT_DIR / "data_quality_checks.csv", index=False)

# ------------------------------------------------------------
# 14. Save enriched customer-level dataset for Power BI
# ------------------------------------------------------------
powerbi_cols = [
    "ID", "Year_Birth", "Age", "Age_Group", "Education", "Marital_Status",
    "Income", "Income_Group", "Kidhome", "Teenhome", "Total_Children",
    "Household_Size", "Dt_Customer", "Recency", *product_cols,
    "Total_Spending", "NumDealsPurchases", "NumWebPurchases",
    "NumCatalogPurchases", "NumStorePurchases", "Total_Purchases",
    "NumWebVisitsMonth", *past_campaign_cols, "Response",
    "Past_Campaign_Accepted", "Total_Campaign_Accepted", "Complain",
    "Country", "Spending_Segment", "R_Score", "F_Score", "M_Score",
    "RFM_Score", "RFM_Segment"
]
df[powerbi_cols].to_csv(OUTPUT_DIR / "marketing_customer_enriched.csv", index=False)

# ------------------------------------------------------------
# 15. Charts
# ------------------------------------------------------------
def save_bar(data, x, y, title, filename, rotation=0):
    plt.figure(figsize=(10, 6))
    plt.bar(data[x].astype(str), data[y])
    plt.title(title)
    plt.xlabel(x)
    plt.ylabel(y)
    plt.xticks(rotation=rotation)
    plt.tight_layout()
    plt.savefig(CHART_DIR / filename, dpi=150)
    plt.close()

save_bar(
    product_perf, "Product", "Total_Spending",
    "Total Spending by Product", "spending_by_product.png"
)

save_bar(
    channel_perf, "Channel", "Total_Purchases",
    "Purchases by Channel", "purchases_by_channel.png"
)

save_bar(
    campaign_perf, "Campaign", "Response_Rate_Pct",
    "Campaign Response Rate", "campaign_response_rate.png", rotation=25
)

save_bar(
    segment_perf, "Spending_Segment", "Avg_Spending",
    "Average Spending by Customer Segment", "spending_by_customer_segment.png", rotation=20
)

# Scatter: website visits vs web purchases
plt.figure(figsize=(10, 6))
plt.scatter(df["NumWebVisitsMonth"], df["NumWebPurchases"], alpha=0.35)
plt.title("Website Visits vs Web Purchases")
plt.xlabel("Web Visits per Month")
plt.ylabel("Web Purchases")
plt.tight_layout()
plt.savefig(CHART_DIR / "web_visits_vs_web_purchases.png", dpi=150)
plt.close()

# Correlation heatmap without seaborn
plt.figure(figsize=(11, 8))
plt.imshow(corr, aspect="auto")
plt.colorbar(label="Correlation")
plt.xticks(range(len(corr.columns)), corr.columns, rotation=75, ha="right")
plt.yticks(range(len(corr.index)), corr.index)
plt.title("Correlation Matrix")
plt.tight_layout()
plt.savefig(CHART_DIR / "correlation_matrix.png", dpi=150)
plt.close()

print("\\nAnalysis complete.")
print("Outputs saved to:", OUTPUT_DIR)
print("Charts saved to:", CHART_DIR)
