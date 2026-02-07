import streamlit as st
import pandas as pd
import plotly.express as px

from db import get_engine
import queries as q
import nlpqueries as nlq


# --------------------------------------------------
# PAGE CONFIG
# --------------------------------------------------
st.set_page_config(
    page_title="TechMart SQL Analytics",
    layout="wide"
)

st.title("📊 TechMart Enterprise SQL Analytics Dashboard")

engine = get_engine()

# ==================================================
# 🔍 NATURAL LANGUAGE QUERYING (NEW SECTION)
# ==================================================
st.markdown("## 🔍 Natural Language Business Analysis")

nl_select = st.selectbox(
    "Select an analysis:",
    [""] + [v["description"] for v in nlq.NL_QUERY_REGISTRY.values()]
)

nl_text = st.text_input(
    "Or type a business question (e.g. 'top payment method used', 'monthly revenue')"
)

intent = None

# Dropdown-based intent
if nl_select:
    for v in nlq.NL_QUERY_REGISTRY.values():
        if v["description"] == nl_select:
            intent = v

# Text-based intent
if nl_text:
    detected = nlq.detect_intent(nl_text)
    if detected:
        intent = detected

if intent:
    st.success(f"✅ Analysis selected: {intent['title']}")

    df_nl = pd.read_sql(intent["sql"], engine)
    st.dataframe(df_nl, use_container_width=True)

    if intent["viz"] == "bar":
        st.plotly_chart(
            px.bar(df_nl, x=intent["x"], y=intent["y"], title=intent["title"]),
            use_container_width=True
        )
    elif intent["viz"] == "line":
        st.plotly_chart(
            px.line(df_nl, x=intent["x"], y=intent["y"], title=intent["title"], markers=True),
            use_container_width=True
        )
    elif intent["viz"] == "pie":
        st.plotly_chart(
            px.pie(df_nl, names=intent["x"], values=intent["y"], title=intent["title"]),
            use_container_width=True
        )

else:
    st.info("ℹ️ Select an analysis or type a supported business question.")

st.markdown("---")


# --------------------------------------------------
# TABS FOR PHASES (ORIGINAL CODE BELOW – UNCHANGED)
# --------------------------------------------------
tab3, tab6, tab7 = st.tabs([
    "Phase 3: Core SQL Queries & Business Analytics",
    "Phase 6: Business Intelligence (BI)",
    "Phase 7: Practice Challenges"
])

# ==================================================
# PHASE 3: CORE SQL QUERIES & BUSINESS ANALYTICS
# ==================================================
with tab3:
    st.header("📘 Phase 3: Core SQL Queries & Business Analytics")

    st.subheader("3.1 Basic SELECT & Filtering Queries")

    st.markdown("### Q1. Products below reorder level")
    st.dataframe(pd.read_sql(q.Q3_1_PRODUCTS_BELOW_REORDER, engine), use_container_width=True)

    st.markdown("### Q2. Customers who haven’t ordered in the last 30 days")
    st.dataframe(pd.read_sql(q.Q3_2_INACTIVE_CUSTOMERS_30_DAYS, engine), use_container_width=True)

    st.markdown("---")

    st.subheader("3.2 INNER JOIN – Transactional Queries")

    st.markdown("### Q3. Complete order details (customers + products)")
    st.dataframe(pd.read_sql(q.Q3_3_ORDER_DETAILS, engine), use_container_width=True)

    st.markdown("### Q4. Revenue & profit by product category")
    df_cat = pd.read_sql(q.Q3_4_REVENUE_BY_CATEGORY, engine)
    st.dataframe(df_cat, use_container_width=True)
    st.plotly_chart(
        px.bar(df_cat, x="category_name", y="total_revenue", title="Revenue by Product Category"),
        use_container_width=True
    )

    st.markdown("---")

    st.subheader("3.3 LEFT JOIN – Finding Gaps")

    st.markdown("### Q5. Products with no sales")
    st.dataframe(pd.read_sql(q.Q3_5_PRODUCTS_NO_SALES, engine), use_container_width=True)

    st.markdown("### Q6. Customers with no orders in 2024")
    st.dataframe(pd.read_sql(q.Q3_6_CUSTOMERS_NO_ORDERS_2024, engine), use_container_width=True)

    st.markdown("---")

    st.subheader("3.4 SELF JOIN – Hierarchical Data")

    st.markdown("### Q7. Employee hierarchy (Manager → Employee)")
    st.dataframe(pd.read_sql(q.Q3_7_EMPLOYEE_HIERARCHY, engine), use_container_width=True)

    st.markdown("---")

    st.subheader("3.6 & 3.7 Advanced Analytics")

    st.markdown("### Q11. Top customers above average spending")
    st.dataframe(pd.read_sql(q.Q3_11_TOP_CUSTOMERS, engine), use_container_width=True)

    st.markdown("### Q14. Daily revenue trend")
    df_daily = pd.read_sql(q.Q3_14_DAILY_REVENUE_TREND, engine)
    st.dataframe(df_daily, use_container_width=True)
    st.plotly_chart(
        px.line(df_daily, x="order_day", y="daily_revenue", title="Daily Revenue Trend"),
        use_container_width=True
    )

# ==================================================
# PHASE 6: BUSINESS INTELLIGENCE DASHBOARD
# ==================================================
with tab6:
    st.header("📊 Phase 6: Business Intelligence (BI) Queries")

    st.markdown("### 6.1 Monthly Sales Dashboard")
    df_monthly = pd.read_sql(q.Q6_MONTHLY_SALES, engine)
    st.dataframe(df_monthly, use_container_width=True)
    st.plotly_chart(px.line(df_monthly, x="month", y="revenue", title="Monthly Revenue"),
                    use_container_width=True)

    st.markdown("### 6.2 Daily Revenue Trend")
    df_day = pd.read_sql(q.Q6_DAILY_REVENUE, engine)
    st.plotly_chart(px.line(df_day, x="order_day", y="daily_revenue", title="Daily Revenue"),
                    use_container_width=True)

    st.markdown("### 6.3 Customer Activity Metrics")

    st.plotly_chart(
        px.bar(pd.read_sql(q.Q6_NEW_CUSTOMERS, engine), x="month", y="new_customers",
               title="New Customers per Month"),
        use_container_width=True
    )

    st.plotly_chart(
        px.bar(pd.read_sql(q.Q6_ACTIVE_CUSTOMERS, engine), x="month", y="active_customers",
               title="Active Customers per Month"),
        use_container_width=True
    )

    st.markdown("### 6.4 Revenue Breakdown")

    st.plotly_chart(
        px.pie(pd.read_sql(q.Q6_REVENUE_BY_PAYMENT, engine),
               names="payment_method", values="revenue",
               title="Revenue by Payment Method"),
        use_container_width=True
    )

    st.plotly_chart(
        px.bar(pd.read_sql(q.Q6_REVENUE_BY_STATUS, engine),
               x="order_status", y="revenue",
               title="Revenue by Order Status"),
        use_container_width=True
    )

    aov = pd.read_sql(q.Q6_AOV, engine).iloc[0, 0]
    st.metric("Average Order Value (AOV)", f"₹ {aov}")

# ==================================================
# PHASE 7: PRACTICE CHALLENGES
# ==================================================
with tab7:
    st.header("🧩 Phase 7: Practice Challenges")

    st.subheader("Challenge 1: Inventory Management")
    st.dataframe(pd.read_sql(q.Q7_C1_REORDER, engine), use_container_width=True)

    restock_cost = pd.read_sql(q.Q7_C1_RESTOCK_COST, engine).iloc[0, 0]
    st.metric("Total Restocking Cost", f"₹ {restock_cost}")

    st.dataframe(pd.read_sql(q.Q7_C1_TRANSFER, engine), use_container_width=True)

    st.subheader("Challenge 2: Customer Analytics")
    st.dataframe(pd.read_sql(q.Q7_C2_COHORT, engine), use_container_width=True)
    st.dataframe(pd.read_sql(q.Q7_C2_CHURN, engine), use_container_width=True)

    churn_rate = pd.read_sql(q.Q7_C2_CHURN_RATE, engine).iloc[0, 0]
    st.metric("Customer Churn Rate (%)", churn_rate)

    st.dataframe(pd.read_sql(q.Q7_C2_UPGRADE, engine), use_container_width=True)

    st.subheader("Challenge 3: Revenue Optimization")
    st.dataframe(pd.read_sql(q.Q7_C3_COMBINATIONS, engine), use_container_width=True)

    st.plotly_chart(
        px.bar(pd.read_sql(q.Q7_C3_DISCOUNTS, engine),
               x="discount_type", y="total_revenue",
               title="Discount vs Revenue"),
        use_container_width=True
    )

    st.plotly_chart(
        px.bar(pd.read_sql(q.Q7_C3_REVENUE_BY_WAREHOUSE, engine),
               x="warehouse_name", y="total_revenue",
               title="Revenue by Warehouse"),
        use_container_width=True
    )