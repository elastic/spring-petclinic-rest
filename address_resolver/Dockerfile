FROM python:3.6-stretch

ENV PYTHONUNBUFFERED 1
ENV PYTHONDONTWRITEBYTECODE 1
ENV HOME /root
ENV DEBIAN_FRONTEND noninteractive
WORKDIR /usr/src/
RUN git clone https://github.com/emanuil-tolev/spring-petclinic.git
WORKDIR /usr/src/spring-petclinic/address_resolver/src
RUN pip install gunicorn json-logging-py
RUN pip install setuptools==45
RUN pip install --no-cache-dir -r requirements.txt

EXPOSE 5000
WORKDIR /opt/bot_server

ENTRYPOINT ["/usr/local/bin/gunicorn", "--config", "gunicorn.conf", "--log-config", "logging.conf", "-b", ":5000", "server:app"]