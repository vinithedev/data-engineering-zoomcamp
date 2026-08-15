# image
FROM python:3.13.11-slim

# copy from another docker image
COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/

# work directory
WORKDIR /code

# Add PATH so we don't have to "uv run" every time
ENV PATH="/code/.venv/bin:$PATH"

# copy multiple files from host to docker ./
COPY pyproject.toml .python-version uv.lock ./

# install dependencies from uv.lock
RUN uv sync --locked

# install dependencies
# RUN pip install pandas pyarrow

# copy from host sys pipeline.py to docker image ./
COPY ingest_data.py .

# runs bash command
ENTRYPOINT ["python", "ingest_data.py"]