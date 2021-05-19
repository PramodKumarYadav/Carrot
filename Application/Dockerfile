# Dockerfile References: https://docs.docker.com/engine/reference/builder/
FROM golang:latest

LABEL maintainer="Antonio Pretto <qwertoyo@gmail.com>"

WORKDIR /app

COPY go.mod go.sum ./

RUN go mod download

COPY . .

RUN go build -o main .

CMD ["./start.sh"]