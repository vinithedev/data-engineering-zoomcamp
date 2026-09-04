## Model deployment
[Tutorial](https://cloud.google.com/bigquery-ml/docs/export-model-tutorial)
### Steps
- gcloud auth login

- bq --project_id analog-artifact-377402 extract -m nytaxi.tip_model gs://kestra-zoomcamp-vini-demo-20260818/tip_model

- mkdir D:\data-engineering\data-engineering-zoomcamp\data-warehouse\tmp\model

- gsutil cp -r gs://kestra-zoomcamp-vini-demo-20260818/tip_model D:\data-engineering\data-engineering-zoomcamp\data-warehouse\tmp\model

- mkdir D:\data-engineering\data-engineering-zoomcamp\data-warehouse\serving_dir\tip_model\1

- xcopy D:\data-engineering\data-engineering-zoomcamp\data-warehouse\tmp\model\tip_model\* D:\data-engineering\data-engineering-zoomcamp\data-warehouse\serving_dir\tip_model\1 /E /I

- docker pull tensorflow/serving

- docker run -p 8501:8501 --mount type=bind,source=`pwd`/serving_dir/tip_model,target=/models/tip_model -e MODEL_NAME=tip_model -t tensorflow/serving &

- curl -d '{"instances": [{"passenger_count":1, "trip_distance":12.2, "PULocationID":"193", "DOLocationID":"264", "payment_type":"2","fare_amount":20.4,"tolls_amount":0.0}]}' -X POST http://localhost:8501/v1/models/tip_model:predict

- http://localhost:8501/v1/models/tip_model