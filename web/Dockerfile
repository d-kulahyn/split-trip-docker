FROM nginx

MAINTAINER DIMA KULAHYN <d.kulahyn@gmail.com>

RUN apt update

RUN apt-get install -y wget

RUN apt-get install apt-transport-https

RUN apt-get install -y nano

RUN apt-get install -y certbot

RUN apt install -y python3-certbot-nginx

COPY nginx.conf /etc/nginx/nginx.conf

COPY fastcgi.conf /etc/nginx/fastcgi.conf

COPY split_trip.conf /etc/nginx/conf.d/default.conf