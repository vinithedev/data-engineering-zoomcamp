import json
from time import time

import pandas as pd
from kafka import KafkaProducer
from kafka.serializer import Serializer

URL = 'https://d37ci6vzurychx.cloudfront.net/trip-data/green_tripdata_2025-10.parquet'

COLUMNS = [
    'lpep_pickup_datetime',
    'lpep_dropoff_datetime',
    'PULocationID',
    'DOLocationID',
    'passenger_count',
    'trip_distance',
    'tip_amount',
    'total_amount',
]


class JsonSerializer(Serializer):
    def serialize(self, topic, headers, data):
        return json.dumps(data).encode('utf-8')


df = pd.read_parquet(URL, columns=COLUMNS)

# JSON has no datetime type: send them as 'YYYY-MM-DD HH:MM:SS' strings
for col in ['lpep_pickup_datetime', 'lpep_dropoff_datetime']:
    df[col] = df[col].dt.strftime('%Y-%m-%d %H:%M:%S')

# missing values would become NaN
df = df.astype(object).where(df.notna(), None)

records = df.to_dict(orient='records')

server = 'localhost:9092'
producer = KafkaProducer(
    bootstrap_servers=[server],
    value_serializer=JsonSerializer(),
)

topic_name = 'green-trips'

t0 = time()

for record in records:
    producer.send(topic_name, value=record)

producer.flush()

t1 = time()
print(f'sent {len(records)} rows')
print(f'took {(t1 - t0):.2f} seconds')
