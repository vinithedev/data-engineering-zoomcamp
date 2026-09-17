## Bash

##### Create api key env variable, so we don't expose it in a file (terminal session)
```bash
export GEMINI_API_KEY="your-api-key-here"
echo $GEMINI_API_KEY
```

#### Change prompt

##### current session
```bash
PS1="> ";
```

##### default
```bash
[ -f ~/.bashrc ] && rm ~/.bashrc; # delete prompt file if exists
echo 'PS1="> "' > ~/.bashrc; # create and write a new one
```

##### Reset (current session)
```bash
PS1='\[\033[32m\]\u@\h \[\033[33m\]\w\[\033[0m\]\n$ ';
```

##### Reset (default)
```bash
[ -f ~/.bashrc ] && rm ~/.bashrc;
```

#### Docker

##### Test if docker is installed correctly
```bash
docker
docker run hello-world
docker run ubuntu
```

##### Access docker container terminal (stateless)
```bash
docker run -it ubuntu
```

##### Update packages
```bash
apt update
```

##### Install python3
```bash
apt install python3
```

##### Check python3 version
```bash
python3 -V
```

##### Exit docker
```bash
exit
```

##### Run specific python docker image
```bash
docker run -it python:3.13.11
```

##### Run smaller python docker image
```bash
docker run -it python:3.13.11-slim
```

##### Overwrite entrypoint
```bash
docker run -it --entrypoint=bash python:3.13.11-slim
```

##### Create file and write to it
```bash
echo 123 > file
```

##### Show all docker images
```bash
docker ps -a
```

##### Show all docker images' ids
```bash
docker ps -aq
```

##### Remove all docker images
```bash
docker rm `docker ps -aq`
or
docker rm $(docker ps -aq)
```

##### Create directory
```bash
mkdir test
```

##### Create files
```bash
touch file1.txt file2.txt file3.txt
```

##### Write to file
```bash
echo "Hello from host" > file1.txt
```

##### Print content of a file
```bash
cat file1.txt
```

##### Get current path
```bash
pwd
```

##### Include ./test content to ./app/test when running docker
```bash
docker run -it --entrypoint=bash -v "$(pwd -W)/test:/app/test" python:3.13.11-slim # Windows
docker run -it --entrypoint=bash -v $(pwd)/test:/app/test python:3.13.11-slim # Linux
```

##### Build and run Dockerfile
```bash
docker build -t test:pandas . # test = base image name, pandas = tag
docker run -it --entrypoint=bash --rm test:pandas # --rm makes it stateless
docker run -it --rm test:pandas # run and executes dockerfile's entrypoint
```

##### Start postgres
```bash
docker run -it --rm \
  -e POSTGRES_USER="root" \
  -e POSTGRES_PASSWORD="root" \
  -e POSTGRES_DB="ny_taxi" \
  -v ny_taxi_postgres_data:/var/lib/postgresql \
  -p 5432:5432 \
  postgres:18
```

##### Add pgcli as a dev dependency so that it won't go to production
```bash
uv add --dev pgcli
```

##### Access database with pgcli
```bash
uv run pgcli -h localhost -p 5432 -u root -d ny_taxi
```

##### List all tables
```bash
\dt
```

##### Install jupyter
```bash
uv add --dev jupyter
```

##### Start jupyter
```bash
uv run jupyter notebook
```

##### Convert jupyter notebook to file
```bash
uv run jupyter nbconvert --to=script notebook.ipynb
```

##### Run ingest_data specifying params
```bash
uv run python ingest_data.py \
  --pg-user=root \
  --pg-pass=root \
  --pg-host=localhost \
  --pg-port=5432 \
  --pg-db=ny_taxi \
  --target-table=yellow_taxi_trips_2021_1 \
  --year=2021 \
  --month=1 \
  --chunksize=100000
```

##### Build taxi ingest
```bash
docker build -t taxi_ingest:v001 .
```

##### Create docker network
```bash
docker network create pg-network
```

##### Start postgres on specific network
```bash
docker run -it --rm \
  -e POSTGRES_USER="root" \
  -e POSTGRES_PASSWORD="root" \
  -e POSTGRES_DB="ny_taxi" \
  -v ny_taxi_postgres_data:/var/lib/postgresql \
  -p 5432:5432 \
  --network=pg-network \
  --name pgdatabase \
  postgres:18
```

##### Run taxi ingest
```bash
docker run -it --rm \
  --network=pg-network \
  taxi_ingest:v001 \
  --pg-user=root \
  --pg-pass=root \
  --pg-host=pgdatabase \
  --pg-port=5432 \
  --pg-db=ny_taxi \
  --target-table=yellow_taxi_trips_2021_1 \
  --chunksize=100000
```

##### Start pgadmin
```bash
docker run -it \
  -e PGADMIN_DEFAULT_EMAIL="admin@admin.com" \
  -e PGADMIN_DEFAULT_PASSWORD="root" \
  -v pgadmin_data:/var/lib/pgadmin \
  -p 8085:80 \
  --network=pg-network \
  --name pgadmin \
  dpage/pgadmin4
```

##### Build docker-compose
```bash
docker-compose up
```

##### Show docker networks
```bash
docker network ls
```

##### Run taxi ingest to pipeline_default
```bash
docker run -it --rm \
  --network=pipeline_default \
  taxi_ingest:v001 \
  --pg-user=root \
  --pg-pass=root \
  --pg-host=pgdatabase \
  --pg-port=5432 \
  --pg-db=ny_taxi \
  --target-table=yellow_taxi_trips_2021_1 \
  --chunksize=100000
```

## Python

##### Print variable
```python
print(f"Files in {current_dir}:")
```

##### Get current path
```python
from pathlib import Path

current_dir = Path.cwd()
print(f"current_dir={current_dir}")
```

##### Get current file name
```python
from pathlib import Path

current_file = Path(__file__).name
print(f"current_file={current_file}")
```

##### List items in a directory
```python
from pathlib import Path

current_dir = Path.cwd()

for filepath in current_dir.iterdir():
    print(f"  - {filepath.name}")
```

##### Check if a path is a file (not a folder)
```python
if filepath.is_file():
    print(f"{filepath.name} is a file")
```

##### Read a file's contents
```python
content = filepath.read_text(encoding='utf-8')
print(f"Content: {content}")
```

##### Get params
```python
import sys

print('arguments', sys.argv)
print('First', sys.argv[1])

> python pipeline.py 12
arguments ['pipeline.py', '12']
First 12
```

##### DataFrame
```python
import pandas as pd

df = pd.DataFrame({"A": [1, 2], "B": [3, 4]})
print(df.head())

> python pipeline.py
   A  B
0  1  3
1  2  4
```

##### DataFrame: naming columns and adding more data
```python
import sys
import pandas as pd

month = int(sys.argv[1])

df = pd.DataFrame({"day": [1, 2], "num_passengers": [3, 4]})
df['month'] = month
print(df.head())

> python pipeline.py 12
arguments ['pipeline.py', '12']
   day  num_passengers  month
0    1               3     12
1    2               4     12
```

##### Initialize uv
```bash
uv init --python 3.13
uv python install 3.13

>Python: Select Interpreter
Select "uv run which python" path
```

##### Print python path
```bash
which python
uv run which python
```

##### Install uv dependencies
```bash
uv add pandas pyarrow
```

##### Create parquet file
```python
df.to_parquet(f"output_{month}.parquet")
```

##### Create schema and table but do not insert
```python
df.head(0).to_sql(name='yellow_taxi_data', con=engine, if_exists='replace')
```

## dbt
```
- dbt Packages are similar to python libraries
- dbt hub: https://hub.getdbt.com/
- utils: SQL logic: https://hub.getdbt.com/dbt-labs/dbt_utils/latest/
- project evaluator: test your project and give a score: https://hub.getdbt.com/dbt-labs/dbt_project_evaluator/latest/
- codegen: helps generate yml files: https://hub.getdbt.com/dbt-labs/codegen/latest/
- audit helper: useful for refactoring: https://hub.getdbt.com/dbt-labs/audit_helper/latest/
- expectations: testing: https://hub.getdbt.com/metaplane/dbt_expectations/latest/
```

##### How to install a package
In the project directory, add a file named ```packages.yml``` and specify package name and version like so:
```yml
packages:
  - package: dbt-labs/dbt_utils
    version: 1.3.3
```
```bash
> dbt deps
```

##### How to use a dbt package macro
```sql
select
    {{ dbt_utils.generate_surrogate_key([
        'vendor_id',
        'pickup_datetime',
        'pickup_location_id',
        'payment_type'
    ]) }} as trip_id
from trips_unioned
```

##### Initialize a dbt project and create directory structure (Only need to run once at the beginning)
```bash
> dbt init
```

##### Check if our profiles are valid according to the database we're working on
```bash
> dbt debug
```

##### Ingest all .csv files that are in seeds folder
```bash
> dbt seed
```

##### Take a snapshot and compare
```bash
> dbt snapshot
```

##### Check how up-to-date our source tables are
```bash
> dbt source freshness
```

##### Generate catalog.json
```bash
> dbt docs generate
```

##### Browse local docs website (not needed in dbt cloud)
```bash
> dbt docs serve
```

##### Remove files specified in dbt_project.yml
```yml
# Delete "target" and "dbt_packages" folders
clean-targets:
  - "target"
  - "dbt_packages"
```
```bash
> dbt clean
```

##### Compile and store our code at ./target/compiled (useful to spot errors at zero cost)
```bash
> dbt compile
```

##### Materialize all models in our project
```bash
> dbt run
```

##### Run all tests in our project
```bash
> dbt test
```

##### Build project
```bash
> dbt build
```

##### Resume 'build' from where it left off after fixing errors, rather than restarting from scratch and wasting resources.
```bash
> dbt retry
```

##### Display an overview of all commands
```bash
> dbt --help
or
> dbt -h
```

##### Check dbt version
```bash
> dbt --version
or
> dbt -v
```

##### If there's an incremental model in our project, drop all and upload again from scratch, instead of adding data incrementally
```bash
> dbt run --full-refresh
```

##### Strict Run: let it fail on any warning
```bash
> dbt run --fail-fast
```

##### Specify a target. By default, dbt targets 'dev'
```bash
> dbt test -t prod
```

##### Run a single model
```bash
> dbt run -s stg_green_tripdata
or
> dbt run --select stg_green_tripdata
```

##### Run a single model + all ancestors (upstream)
```bash
> dbt run -s +int_trips_unioned
```

##### Run a single model + all descendants (downstream)
```bash
> dbt run -s int_trips_unioned+
```

##### Run a single model + everything upstream and downstream
```bash
> dbt run -s +int_trips_unioned+
```

##### Run every model inside a directory
```bash
> dbt run -s models/intermediate
```

##### Run all models with a specific tag
```bash
> dbt run -s tag:mytesttag
```

##### Run all models that are new files
```bash
> dbt run -s state:new
```

##### Run all models that have changed
```bash
> dbt run -s state:modified
```

