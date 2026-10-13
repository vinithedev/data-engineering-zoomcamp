#!/usr/bin/env python
# coding: utf-8

r"""
python 06_spark_sql_standalone.py \
    --input_green=../data/pq/green/*/* \
    --input_yellow=../data/pq/yellow/*/* \
    --output=../data/report-2020/

---------------------------------------

export SPARK_HOME='D:\data-engineering\data-engineering-zoomcamp\batch\.venv\Lib\site-packages\pyspark'
export PYSPARK_PYTHON="$(cygpath -w "$(which python)")"
export PYSPARK_DRIVER_PYTHON="$PYSPARK_PYTHON"
URL="spark://localhost:7077"

spark-submit.cmd \
    --master="${URL}" \
    --driver-java-options "-Djava.library.path=C:/tools/hadoop/bin" \
    --conf "spark.executor.extraJavaOptions=-Djava.library.path=C:/tools/hadoop/bin" \
    06_spark_sql_standalone.py \
    --input_green='../data/pq/green/*/*' \
    --input_yellow='../data/pq/yellow/*/*' \
    --output='../data/report-2020/'

--input_green=gs://dtc_data_lake_de-zoomcamp-nytaxi_vini/pq/green/2020/*/
--input_yellow=gs://dtc_data_lake_de-zoomcamp-nytaxi_vini/pq/yellow/2020/*/
--output=gs://dtc_data_lake_de-zoomcamp-nytaxi_vini/report-2020/

----------------------------
export CLOUDSDK_PYTHON="/c/Program Files (x86)/Google/Cloud SDK/google-cloud-sdk/platform/bundledpython/python.exe"

bq mk --location=US --dataset analog-artifact-377402:trips_data_all

gcloud dataproc clusters create de-zoomcamp-cluster --project=analog-artifact-377402 --region=us-east4 --single-node --master-machine-type=e2-standard-4 --master-boot-disk-type=pd-balanced --master-boot-disk-size=100GB --image-version=2.2-debian12 --max-idle=1h

gsutil cp 06_spark_sql_big_query.py gs://dtc_data_lake_de-zoomcamp-nytaxi_vini/code/06_spark_sql_big_query.py

gcloud dataproc jobs submit pyspark \
    --cluster=de-zoomcamp-cluster \
    --region=us-east4 \
    gs://dtc_data_lake_de-zoomcamp-nytaxi_vini/code/06_spark_sql_big_query.py \
    -- \
    --input_green=gs://dtc_data_lake_de-zoomcamp-nytaxi_vini/pq/green/2020/*/ \
    --input_yellow=gs://dtc_data_lake_de-zoomcamp-nytaxi_vini/pq/yellow/2020/*/ \
    --output=trips_data_all.reports-2020
"""

import argparse
import pyspark
from pyspark.sql import SparkSession
from pyspark.sql import types
from pyspark.sql import functions as F

parser = argparse.ArgumentParser()

parser.add_argument('--input_green', required=True)
parser.add_argument('--input_yellow', required=True)
parser.add_argument('--output', required=True)

args = parser.parse_args()

input_green = args.input_green
input_yellow = args.input_yellow
output = args.output

spark = SparkSession.builder \
    .appName('test') \
    .getOrCreate()

spark.conf.set('temporaryGcsBucket', 'dataproc-temp-us-east4-426824376748-bosgp7ui')

df_green = spark.read.parquet(input_green) # '../data/pq/green/*/*'

df_yellow = spark.read.parquet(input_yellow) # '../data/pq/yellow/*/*'

df_green = df_green \
    .withColumnRenamed('lpep_pickup_datetime', 'pickup_datetime') \
    .withColumnRenamed('lpep_dropoff_datetime', 'dropoff_datetime')

df_yellow = df_yellow \
    .withColumnRenamed('tpep_pickup_datetime', 'pickup_datetime') \
    .withColumnRenamed('tpep_dropoff_datetime', 'dropoff_datetime')

common_columns = []

yellow_columns = set(df_yellow.columns)

for col in df_green.columns:
    if col in yellow_columns:
        common_columns.append(col)

common_columns = ['VendorID',
    'pickup_datetime',
    'dropoff_datetime',
    'store_and_fwd_flag',
    'RatecodeID',
    'PULocationID',
    'DOLocationID',
    'passenger_count',
    'trip_distance',
    'fare_amount',
    'extra',
    'mta_tax',
    'tip_amount',
    'tolls_amount',
    'improvement_surcharge',
    'total_amount',
    'payment_type',
    'congestion_surcharge'
]

df_green_sel = df_green \
    .select(common_columns) \
    .withColumn('service_type', F.lit('green'))

df_yellow_sel = df_yellow \
    .select(common_columns) \
    .withColumn('service_type', F.lit('yellow'))

df_trips_data = df_green_sel.unionAll(df_yellow_sel)

df_trips_data.createOrReplaceTempView('trips_data')

df_result = spark.sql("""
SELECT
    -- Revenue grouping
    PULocationID AS revenue_zone,
    date_trunc('month', pickup_datetime) AS revenue_month,
    service_type,

    -- Revenue calculation
    SUM(fare_amount) AS revenue_monthly_fare,
    SUM(extra) AS revenue_monthly_extra,
    SUM(mta_tax) AS revenue_monthly_mta_tax,
    SUM(tip_amount) AS revenue_monthly_tip_amount,
    SUM(tolls_amount) AS revenue_monthly_tolls_amount,
    SUM(improvement_surcharge) AS revenue_monthly_improvement_surcharge,
    SUM(total_amount) AS revenue_monthly_total_amount,
    SUM(congestion_surcharge) AS revenue_monthly_congestion_surcharge,

    -- Additional calculations
    AVG(passenger_count) AS avg_monthly_passenger_count,
    AVG(trip_distance) AS avg_monthly_trip_distance
FROM
    trips_data
GROUP BY
    1, 2, 3
""")

# '../data/report/revenue/'
df_result.write.format('bigquery') \
    .option('table', output) \
    .mode('overwrite') \
    .save()
