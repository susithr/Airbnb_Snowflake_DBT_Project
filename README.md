# 🏠 Airbnb End-to-End Data Engineering Project

## 📋 Overview

A complete end-to-end data engineering pipeline that demonstrates modern cloud data warehouse best practices. This project processes Airbnb listings, bookings, and hosts data through a **medallion architecture** (Bronze → Silver → Gold) using **Snowflake** for warehousing and **dbt** for transformation.

The pipeline implements incremental loading, slowly-changing dimensions (SCD Type 2), custom transformations, and comprehensive data quality testing—all version-controlled and reproducible.

---

## 🏗️ Architecture

### Data Flow
```
CSV Source Data → Snowflake Staging → Bronze (Raw) → Silver (Clean) → Gold (Analytics)
```

### Technology Stack
- **Cloud Data Warehouse**: Snowflake
- **Transformation**: dbt (Data Build Tool)
- **Version Control**: Git/GitHub
- **Language**: SQL + Jinja
- **Python**: 3.12+

---

## 📊 Data Model

### Medallion Architecture

**🥉 Bronze Layer** — Raw data with minimal transformation
- `bronze_bookings` — Raw booking transactions
- `bronze_hosts` — Raw host information
- `bronze_listings` — Raw property listings

**🥈 Silver Layer** — Cleaned, validated, business-logic-ready data
- `silver_bookings` — Incremental booking records with quality checks
- `silver_hosts` — Enhanced host profiles with metrics
- `silver_listings` — Standardized listings with price categorization

**🥇 Gold Layer** — Analytics-ready, denormalized datasets
- `obt_bookings` — One Big Table (fact + dimensions joined)
- `fct_bookings` — Fact table for dimensional modeling
- Dimension snapshots tracking historical changes

### Key Data Features
- **Fact Table**: `fct_bookings` — measurable events (booking_amount, nights_booked)
- **Dimension Tables**: Listings, Hosts, Dates — descriptive attributes
- **One Big Table (OBT)**: Pre-joined denormalized table for BI tools
- **Snapshots (SCD Type 2)**: Historical tracking of host and listing changes

---

## 📁 Project Structure

```
aws_dbt_snowflake_project/
├── dbt_project.yml                 # dbt configuration
├── models/
│   ├── sources.yml                 # Source definitions
│   ├── bronze/                     # Raw data layer
│   │   ├── bronze_bookings.sql
│   │   ├── bronze_hosts.sql
│   │   └── bronze_listings.sql
│   ├── silver/                     # Cleaned data layer
│   │   ├── silver_bookings.sql     # Incremental materialization
│   │   ├── silver_hosts.sql
│   │   └── silver_listings.sql
│   └── gold/                       # Analytics layer
│       ├── obt_bookings.sql        # One Big Table
│       ├── fct_bookings.sql        # Fact table
│       └── ephemeral/              # Temporary CTEs
├── macros/                         # Reusable SQL functions
│   ├── multiply.sql                # Math calculations
│   ├── tag.sql                     # Price categorization
│   ├── trimmer.sql                 # String utilities
│   └── generate_schema_name.sql    # Dynamic schema naming
├── snapshots/                      # SCD Type 2 configurations
│   ├── dim_bookings.yml
│   ├── dim_hosts.yml
│   └── dim_listings.yml
├── tests/                          # Data quality tests
└── seeds/                          # Static reference data
```

---

## 🚀 Getting Started

### Prerequisites
- **Snowflake Account** with ACCOUNTADMIN role
- **Python 3.12+** with pip
- **Git** for version control

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/susithr/Airbnb_Snowflake_DBT_Project.git
   cd aws_dbt_snowflake_project
   ```

2. **Create virtual environment**
   ```bash
   python -m venv .venv
   .venv\Scripts\activate  # Windows
   source .venv/bin/activate  # Linux/Mac
   ```

3. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   ```
   
   Core packages:
   - dbt-core>=1.11.2
   - dbt-snowflake>=1.11.0
   - sqlfmt>=0.0.3

4. **Configure Snowflake connection**
   
   Create `~/.dbt/profiles.yml`:
   ```yaml
   aws_dbt_snowflake_project:
     target: dev
     outputs:
       dev:
         type: snowflake
         account: <your-account-id>
         user: <your-username>
         password: <your-password>
         role: ACCOUNTADMIN
         database: AIRBNB
         schema: dbt_dev
         warehouse: COMPUTE_WH
         threads: 4
   ```

5. **Load source data to Snowflake**
   ```sql
   -- Create staging tables and load CSVs
   CREATE SCHEMA AIRBNB.STAGING;
   -- Upload: bookings.csv, hosts.csv, listings.csv
   ```

---

## 🔧 Usage

### Test Connection
```bash
cd aws_dbt_snowflake_project
dbt debug
```

### Run Models by Layer
```bash
dbt run --select bronze.*   # Raw data layer
dbt run --select silver.*   # Cleaned data layer
dbt run --select gold.*     # Analytics layer
dbt run --select tag:incremental  # Incremental models only
```

### Run All Models + Tests + Snapshots
```bash
dbt build
```

### Run Tests
```bash
dbt test
```

### Generate & View Documentation
```bash
dbt docs generate
dbt docs serve  # Open http://localhost:8000
```

### Snapshots (Historical Tracking)
```bash
dbt snapshot
```

---

## 🎯 Key Features

### 1. Incremental Loading
Only new/changed data is processed on subsequent runs:
```sql
{{ config(materialized='incremental') }}
{% if is_incremental() %}
    WHERE CREATED_AT > (SELECT MAX(CREATED_AT) FROM {{ this }})
{% endif %}
```
**Benefit**: Reduces compute cost and runtime on large datasets

### 2. Custom Macros
Reusable SQL logic across all models:
- `tag()` — Categorizes prices: low/medium/high
- `trimmer()` — Removes whitespace and converts to uppercase
- `multiply()` — Performs rounding calculations
```sql
{{ multiply('NIGHTS_BOOKED', 'BOOKING_AMOUNT', 2) }}
```

### 3. Dynamic SQL with Jinja
One Big Table (OBT) uses config-driven joins for maintainability:
```jinja
{% set configs = [ {table, columns, alias, join_condition} ] %}
SELECT {% for config in configs %}...{% endfor %}
FROM ...
{% for config in configs %}LEFT JOIN...{% endfor %}
```

### 4. Slowly-Changing Dimensions (SCD Type 2)
Snapshots track historical changes with validity dates:
```
dim_hosts:
  host_id | is_superhost | dbt_valid_from | dbt_valid_to
  1       | false        | 2024-01-01     | 2024-07-08
  1       | true         | 2024-07-08     | 9999-12-31
```
**Use case**: Point-in-time analysis and audit trails

### 5. Automated Data Quality
- Unique key constraints
- Not-null validations
- Referential integrity tests
- Custom business rule tests

### 6. Organized Schemas
Automatic layer-based separation:
```
AIRBNB.BRONZE.*  → Raw data
AIRBNB.SILVER.*  → Cleaned data
AIRBNB.GOLD.*    → Analytics-ready tables
```

---

## 📈 Data Quality & Testing

### Testing Strategy
- Source data validation (not_null, unique, relationships)
- Business logic validation (price ranges, status values)
- Data freshness checks
- Custom singular tests for complex rules

### Data Lineage
dbt automatically tracks:
- Which models depend on which sources
- Downstream impacts of upstream changes
- Complete source-to-consumption flow
- Dependencies visible in DAG (Directed Acyclic Graph)

---

## 🔐 Security & Best Practices

### Credentials Management
- ✅ Use environment variables for sensitive data
- ✅ Never commit `profiles.yml` with credentials
- ✅ Use Snowflake roles for access control
- ❌ Don't hardcode passwords in code

### Code Quality
- SQL formatting with sqlfmt
- Version control with Git
- Code reviews before merging
- Comprehensive documentation

### Performance Optimization
- Incremental models reduce full-table scans
- Ephemeral models eliminate unnecessary intermediate tables
- Strategic clustering keys in Snowflake
- Efficient join ordering in macros

---

## 📚 Learning Resources

- [dbt Documentation](https://docs.getdbt.com/)
- [Snowflake Best Practices](https://docs.snowflake.com/)
- [dbt Guides & Tutorials](https://docs.getdbt.com/guides)
- [Medallion Architecture](https://www.databricks.com/en-us/solutions/data-lakehouse/medallion-architecture)

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/YourFeature`
3. Commit changes: `git commit -m 'Add YourFeature'`
4. Push to branch: `git push origin feature/YourFeature`
5. Open a Pull Request

---

## 🐛 Troubleshooting

### Connection Issues
- Verify Snowflake credentials in `profiles.yml`
- Check warehouse is running: `SHOW WAREHOUSES;`
- Test connectivity: `dbt debug`

### Compilation Errors
- Run `dbt debug` to identify issues
- Verify model dependencies: `dbt docs generate`
- Check Jinja syntax in macros

### Incremental Load Issues
- Full refresh to rebuild: `dbt run --full-refresh`
- Verify source data timestamps
- Check `is_incremental()` logic

---

## 📝 License

This project is part of a data engineering portfolio demonstration.

---

## 👤 Author

**Airbnb Data Engineering Pipeline**
- Technologies: Snowflake, dbt, SQL, Jinja, Git
- Portfolio Project demonstrating modern data stack best practices

---

## 📊 Future Enhancements

- [ ] CI/CD pipeline with dbt Cloud
- [ ] Data quality dashboards
- [ ] BI tool integration (Tableau/Power BI)
- [ ] Advanced monitoring and alerting
- [ ] Data masking for PII
- [ ] Expanded test coverage
- [ ] Performance benchmarking

---

**Last Updated**: July 2024
