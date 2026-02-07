"""
nlpqueries.py
-----------------
Natural Language Query (NLQ) registry for TechMart Analytics.
Maps business questions to approved SQL queries and visualizations.
"""

import queries as q

NL_QUERY_REGISTRY = {
    "top payment method": {
        "description": "Top payment method used by customers",
        "sql": q.Q6_REVENUE_BY_PAYMENT,
        "viz": "pie",
        "x": "payment_method",
        "y": "revenue",
        "title": "Top Payment Methods Used"
    },

    "monthly revenue": {
        "description": "Monthly revenue trend",
        "sql": q.Q6_MONTHLY_SALES,
        "viz": "line",
        "x": "month",
        "y": "revenue",
        "title": "Monthly Revenue Trend"
    },

    "daily revenue": {
        "description": "Daily revenue trend",
        "sql": q.Q6_DAILY_REVENUE,
        "viz": "line",
        "x": "order_day",
        "y": "daily_revenue",
        "title": "Daily Revenue Trend"
    },

    "inactive customers": {
        "description": "Customers inactive for last 30 days",
        "sql": q.Q3_2_INACTIVE_CUSTOMERS_30_DAYS,
        "viz": "table",
        "title": "Inactive Customers (30 Days)"
    },

    "churned customers": {
        "description": "Customers churned in last 60 days",
        "sql": q.Q7_C2_CHURN,
        "viz": "table",
        "title": "Churned Customers"
    },

    "revenue by warehouse": {
        "description": "Revenue contribution by warehouse",
        "sql": q.Q7_C3_REVENUE_BY_WAREHOUSE,
        "viz": "bar",
        "x": "warehouse_name",
        "y": "total_revenue",
        "title": "Revenue by Warehouse"
    }
}


def detect_intent(user_text: str):
    """
    Match user text with known NL intents.
    """
    user_text = user_text.lower()
    for key in NL_QUERY_REGISTRY:
        if key in user_text:
            return NL_QUERY_REGISTRY[key]
    return None