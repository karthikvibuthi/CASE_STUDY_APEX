# Role of a Planner in the Finance Planning Application

The Planner is the primary business user responsible for creating, configuring, and executing financial planning scenarios for BMW & MINI sales.
This role performs all analytical and forecasting activities before anything is submitted to an Approver.

Think of the Planner as the person who creates the plan, while the Approver validates and authorizes it.

🔎 Core Responsibilities of a Planner
1. Upload & Validate Historical Sales Data

Planners ingest the raw sales data (CSV) into the system.

They ensure:

Dealer codes are valid

Model codes exist

No negative sales units

Units do not exceed inventory

Discount, promo, blackout_flag, inventory_end are consistent

This ensures clean and audit-ready data for forecasting.

2. Set Up Planning Scenarios

Planners create different “what-if” scenarios.

A scenario typically includes:

Forecasting method (Moving Avg + Seasonality, Trend + Seasonality)

Forecast horizon (how many months forward?)

Elasticity assumptions
(e.g., “If price drops 2%, demand increases 3%”)

Promo uplift
(e.g., “Holiday promo increases sales by 5%”)

Inventory caps
(maximum inventory constraints)

These scenario drivers allow planners to simulate strategic business decisions.

3. Execute Forecasting Logic

Planners run the system’s forecasting procedures.

The system:

Reads historical sales

Applies forecasting algorithms

Applies scenario adjustments

Generates future month predictions

Saves results into FORECAST_OUTPUT

Planners can create multiple versions of the future.

4. Analyze Forecast Results

Planners evaluate system-generated KPIs & reports:

Key metrics for analysis:

Forecasted units

Adjusted units (after elasticity, promo uplift, inventory cap)

Price effect

Promo effect

Inventory constraint impact

Dealer performance

Turnover rate

Days-to-sell

Variance vs historical baseline

This gives them insight into operational and financial impact.

5. Review Dashboards and KPI Summaries

Planners use dashboards for:

Total units sold

Average selling price

Discount%

Turnover rate

Fastest dealer

Inventory health

These KPIs update dynamically based on selected filters (month, region, brand, model).

Planners use these insights to refine planning assumptions.

6. Submit Scenario for Approval

Once a scenario looks realistic and aligned with business goals:

The Planner submits the scenario → enters "Pending Approval" workflow.

They may add:

Comments

Rationale for scenario assumptions

Expected financial outcomes

This provides documentation for Approvers.
