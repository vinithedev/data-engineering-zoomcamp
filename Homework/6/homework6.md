### Resources
```
https://github.com/DataTalksClub/data-engineering-zoomcamp/blob/main/cohorts/2026/06-batch/homework.md
```

### Setup
```bash
> curl -fL --create-dirs -o /d/data-engineering/data-engineering-zoomcamp/batch/data/raw/yellow/2025/11/yellow_tripdata_2025-11.parquet https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2025-11.parquet
```

### 1. Install Spark and PySpark. What's the spark.version output?
```
Run 06_01_homework.ipynb
Spark version: 4.2.0
```

### 2. ...What is the average size of the Parquet (ending with .parquet extension) Files that were created (in MB)? Select the answer which most closely matches.
```
Run 06_02_homework.ipynb
average: 24.4 MB
25 MB
```

### 3. How many taxi trips were there on the 15th of November?
```
Run 06_03_homework.ipynb
162604
162,604
```

### 4. What is the length of the longest trip in the dataset in hours?
```
Run 06_04_homework.ipynb
90.64666666666666
90.6
```

### 5. Spark's User Interface which shows the application's dashboard runs on which local port?
```
http://localhost:4040/jobs/
4040
```

### 6. Using the zone lookup data and the Yellow November 2025 data, what is the name of the LEAST frequent pickup location Zone?
```
Run 06_06_homework.ipynb

|Eltingville/Annad...|    1|
|Governor's Island...|    1|
|       Arden Heights|    1|

Arden Heights
```

