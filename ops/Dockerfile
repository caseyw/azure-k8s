FROM golang:1.20.4-alpine AS builder
WORKDIR /app
COPY src/ .
RUN go mod download
RUN CGO_ENABLED=0 go build -ldflags="-w -s" -o app

FROM scratch
COPY --from=builder /app/app /app
EXPOSE 8090
ENTRYPOINT ["/app"]