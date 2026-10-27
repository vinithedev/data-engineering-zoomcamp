import json

from kafka import KafkaConsumer
from kafka.serializer import Deserializer


class JsonDeserializer(Deserializer):
    def deserialize(self, topic, headers, data):
        return json.loads(data.decode('utf-8'))


server = 'localhost:9092'
topic_name = 'green-trips'

consumer = KafkaConsumer(
    topic_name,
    bootstrap_servers=[server],
    auto_offset_reset='earliest',
    group_id=None,
    value_deserializer=JsonDeserializer(),
    consumer_timeout_ms=5000,
)

total = 0
long_trips = 0

for message in consumer:
    trip = message.value
    total += 1
    if trip['trip_distance'] > 5.0:
        long_trips += 1

consumer.close()

print(f'read {total} trips')
print(f'trips with trip_distance > 5: {long_trips}')
