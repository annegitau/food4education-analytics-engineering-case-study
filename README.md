# From Tap to Meal: Food4Education Analytics Engineering Case Study

> A hypothetical analytics engineering case study exploring how a reliable, governed data platform could support meal operations at scale using **BigQuery, dbt, Python, and automated data-quality controls**.

## About this project

Food4Education operates a technology-enabled school feeding model where operational data spans meal production, deliveries, schools, payments, and meal consumption through Tap2Eat.

This project asks a simple operational question:

> **How many meals did we prepare, dispatch, receive, and ultimately serve — and can we trust the data behind those numbers?**

I built a synthetic analytics engineering pipeline to explore how these data sources could be integrated into a reliable analytical model as an organisation scales.

**Important:** This is an independent portfolio project created using synthetic data and publicly available information. It does not use or represent Food4Education's internal data, systems, architecture, thresholds, or business rules.

---

## What I built

The project implements an end-to-end analytical workflow that:

- loads synthetic operational datasets into **Google BigQuery**;
- transforms and models them using **dbt**;
- pseudonymises student identifiers before analytical use;
- deduplicates Tap2Eat transactions;
- validates referential integrity and business rules;
- separates valid records from quarantined data-quality exceptions;
- reconciles meal operations at both **school/day** and **kitchen/day** grain;
- publishes tested analytical marts for downstream reporting; and
- demonstrates how orchestration and monitoring could be incorporated into the workflow.

---

## Architecture

```text
Synthetic Operational Sources
        │
        ├── Schools
        ├── Meal Production
        ├── Deliveries
        ├── Tap2Eat Transactions
        └── Payments
        │
        ▼
Python Ingestion
        │
        ▼
BigQuery Raw Layer
        │
        ▼
dbt Staging
  ├── cleaning
  ├── standardisation
  ├── deduplication
  └── student ID pseudonymisation
        │
        ▼
Data Quality & Intermediate Layer
  ├── referential-integrity checks
  ├── business-rule validation
  ├── valid transaction stream
  └── quarantine stream
        │
        ▼
Reconciliation Models
  ├── Kitchen / Day
  │     Prepared → Dispatched
  │
  └── School / Day
        Dispatched → Received → Served
        │
        ▼
Analytics Marts
        │
        ▼
BI / Operational Reporting
```

---

## Why the reconciliation uses two grains

One of the most important modelling decisions in this project was **not** to force the entire meal lifecycle into a single table.

Meal production is recorded at:

```text
kitchen + service_date
```

while delivery and meal-consumption activity occurs at:

```text
school + service_date
```

Joining kitchen-level production directly to every school would duplicate the number of meals prepared.

The pipeline therefore separates reconciliation into two models:

### Kitchen/day

```text
Meals Prepared → Meals Dispatched
```

This answers questions such as:

- How much of the kitchen's production was dispatched?
- Where is there a material prepared-to-dispatched variance?

### School/day

```text
Meals Dispatched → Meals Received → Meals Served
```

This answers:

- Did the school receive what was dispatched?
- How many received meals were subsequently recorded as served?
- Which schools require investigation?

This preserves the natural grain of each operational process and prevents misleading aggregation.

---

## Data quality strategy

The pipeline distinguishes between **blocking failures** and **non-blocking data-quality exceptions**.

The synthetic Tap2Eat dataset deliberately contains:

- one duplicate transaction ID;
- one transaction with a missing `school_id`; and
- one transaction referencing an unknown school.

The duplicate is deterministically removed during staging.

Records with invalid school relationships are preserved in a quarantine model rather than silently discarded.

### Transaction audit

```text
Raw Tap2Eat records             191,234
Duplicate removed                    -1
                               --------
Staged records                  191,233

Data-quality exceptions              -2
                               --------
Valid analytical records        191,231
```

This gives the pipeline an explainable record trail:

```text
raw → staged → valid + quarantine
```

No records disappear without an explicit transformation or quality decision.

---

## Privacy by design

The synthetic raw source contains a `student_id`.

Before records leave the staging layer, the identifier is pseudonymised using SHA-256:

```sql
to_hex(sha256(student_id)) as student_id_hash
```

Downstream analytical models therefore use `student_id_hash` rather than the raw student identifier.

This is **pseudonymisation, not anonymisation**. In a production environment it would be combined with appropriate access controls, retention policies, encryption, and governance procedures.

---

## Testing

The dbt project includes tests for:

- uniqueness and non-null constraints;
- school referential integrity;
- accepted transaction statuses;
- school/day grain uniqueness;
- kitchen/day grain uniqueness;
- meal-production grain uniqueness;
- positive meal quantities;
- positive meal production; and
- received meals not exceeding dispatched meals.

Expected source-quality exceptions are configured as warnings and routed into the quarantine layer, while structural failures remain blocking.

This demonstrates a deliberate distinction between:

> **“The pipeline is broken”**

and

> **“The pipeline is working and has detected source data that requires investigation.”**

---

## Repository structure

```text
.
├── airflow/
│   └── f4e_daily_pipeline.py
├── data/
│   ├── deliveries.csv
│   ├── meal_production.csv
│   ├── payments.csv
│   ├── schools.csv
│   └── tap2eat_transactions.csv
├── dbt/
│   └── f4e_analytics/
│       ├── analyses/
│       ├── models/
│       │   ├── staging/
│       │   ├── intermediate/
│       │   └── marts/
│       └── tests/
├── docs/
│   └── kpi_dictionary.csv
├── outputs/
├── src/
│   └── load_bigquery.py
├── requirements.txt
└── requirements-dbt.txt
```

---

## Technology

| Area | Technology |
|---|---|
| Data warehouse | Google BigQuery |
| Transformation | dbt |
| Ingestion | Python |
| Querying | SQL |
| Data quality | dbt tests + quarantine modelling |
| Privacy | SHA-256 pseudonymisation |
| Version control | Git / GitHub |
| Orchestration design | Airflow |

---

## Key analytical outputs

### School daily meal reconciliation

`fct_school_daily_meal_reconciliation`

Combines school metadata with daily dispatch, receipt and serving activity.

Key measures include:

- meals dispatched;
- meals received;
- meals served;
- dispatch-to-receipt variance;
- receipt-to-served variance;
- receipt rate;
- serving rate; and
- learner serving rate.

### Kitchen daily meal reconciliation

`fct_kitchen_daily_meal_reconciliation`

Reconciles:

```text
meals prepared → meals dispatched
```

and calculates the prepared-to-dispatched variance and dispatch rate.

Any thresholds demonstrated in this repository are **illustrative case-study thresholds**, not Food4Education operational targets.

---

## Design principles

I approached the project around six principles:

1. **Preserve operational grain** rather than forcing incompatible processes into one model.
2. **Make data loss explainable** through explicit deduplication and quarantine logic.
3. **Protect sensitive identifiers early** in the transformation lifecycle.
4. **Separate data-quality exceptions from pipeline failures.**
5. **Test business assumptions as code.**
6. **Build reporting models from governed definitions rather than dashboard-specific logic.**

---

## What I would add in production

A production implementation would extend this design with:

- incremental ingestion and CDC where appropriate;
- idempotent loading and automated backfills;
- source freshness monitoring and alerting;
- CI/CD validation before deployment;
- production orchestration and retry policies;
- lineage and observability;
- role- and column-level BigQuery access controls;
- retention and deletion policies;
- secrets management;
- late-arriving-data handling;
- historical dimension management where required; and
- formal incident response and root-cause-analysis procedures.

---

## Project status

This case study is being developed as a portfolio demonstration of analytics engineering, data modelling, governance, reliability, and operational reporting.

The datasets are entirely synthetic.

---

## Author

**Anne Gitau**

Data & Analytics | Business Intelligence | Analytics Engineering

Nairobi, Kenya