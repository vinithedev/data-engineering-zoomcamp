### Resources
```
https://github.com/DataTalksClub/data-engineering-zoomcamp/blob/main/cohorts/2026/05-data-platforms/homework.md
```

### Setup
```bash
> curl -LsSf https://getbruin.com/install/cli | sh
> bruin init zoomcamp my-pipeline
Configure .bruin.yml with a DuckDB connection
```

### 1. In a Bruin project, what are the required files/directories?
```
.bruin.yml and pipeline/ with pipeline.yml and assets/
```

### 2. You're building a pipeline that processes NYC taxi data organized by month based on ```pickup_datetime```. Which incremental strategy is best for processing a specific interval period by deleting and inserting data for that time period?
```
time_interval - incremental based on a time column
```

### 3. ...How do you override this when running the pipeline to only process yellow taxis?
```
> bruin run --var 'taxi_types=["yellow"]'
This will ignore default values for taxi_types and override them
```

### 4. You've modified the ```ingestion/trips.py``` asset and want to run it plus all downstream assets. Which command should you use?
```
> bruin run ingestion/trips.py --downstream
```

### 5. You want to ensure the ```pickup_datetime``` column in your trips table never has NULL values. Which quality check should you add to your asset definition?
```
name: not_null
```

### 6. After building your pipeline, you want to visualize the dependency graph between assets. Which Bruin command should you use?
```
bruin lineage
```

### 7. You're running a Bruin pipeline for the first time on a new DuckDB database. What flag should you use to ensure tables are created from scratch?
```
--full-refresh
```

