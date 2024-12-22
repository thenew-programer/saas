# Set python version as a build-time argument
ARG PYTHON_VERSION=3.12-slim-bullseye
FROM python:${PYTHON_VERSION}

# Create a venv
RUN python -m venv /opt/venv

# Set the virtual env as the current location
ENV PATH=/opt/venv/bin:$PATH

# upgrade pip
RUN pip install --upgrade pip

# Set Python-related environment variables
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# Install os dependencies for our docker image
RUN apt-get update && apt-get install -y \
	# for postgres
	libpq-dev \
	# for Pillow
	libjpeg-dev \
	# for cairoSVG
	libcairo2 \
	# others
	gcc \
	&& rm -rf /var/lib/apt/lists/*

# Create the code directory
RUN mkdir -p /code

# Set the working dir
WORKDIR /code

# Copy the requirements file into the container
COPY requirements.txt /tmp/requirements.txt

# Copy the source code into the code directory
COPY ./src /code

# Install project dependencies
RUN pip install -r /tmp/requirements.txt

ARG DJANGO_SECRET_KEY
ENV DJANGO_SECRET_KEY=${DJANGO_SECRET_KEY}

ARG DJANGO_DEBUG=0
ENV DJANGO_DEBUG=${DJANGO_DEBUG}

# database isn't available during build
# run any other commands that do not need the database
# such as:
# RUN python manage.py vendor_pull
# RUN python manage.py collectstatic --noinput

# set the project name
ARG PROJECT_NAME=saas

# create a bash script that will run the project
RUN printf "#!/bin/bash\n" > ./paracord_runner.sh && \
	printf "RUN_PORT=\"\${PORT:-8000}\"\n\n" >> ./paracord_runner.sh && \
	printf "python manage.py migrate --no-input\n" >> ./paracord_runner.sh && \
	printf "gunicorn ${PROJECT_NAME}.wsgi:application --bind \"0.0.0.0\$RUN_PORT\"\n" >> ./paracord_runner.sh \

# make the script exec
RUN chmod +x ./paracord_runner.sh

# Clean up cache to reduce image size
RUN apt-get remove --purge -y \
	&& apt-get autoremove -y \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

# run the project via the script when the container starts
CMD ./paracord_runner.sh
