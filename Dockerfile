FROM ubuntu:latest
COPY eg /usr/local/bin/eg
RUN chmod 0755 /usr/local/bin/eg
