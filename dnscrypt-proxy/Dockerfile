FROM docker.io/alpine/git AS source
ARG VERSION=master
WORKDIR /go/src
RUN git clone --depth=1 -b ${VERSION} https://github.com/DNSCrypt/dnscrypt-proxy.git .

FROM golang:1.17-alpine AS build
COPY --from=source /go/src /go/src
WORKDIR /go/src/dnscrypt-proxy
ENV CGO_ENABLED=0
RUN go mod download
RUN go build -ldflags '-extldflags "-static"' .

FROM alpine
COPY --from=build /go/src/dnscrypt-proxy/dnscrypt-proxy /dnscrypt-proxy
RUN apk -U upgrade --no-cache
RUN apk add --no-cache ca-certificates && mkdir -p /etc/dnscrypt-proxy/ /var/log/dnscrypt-proxy/
COPY dnscrypt-proxy.toml /etc/dnscrypt-proxy/dnscrypt-proxy.toml
RUN addgroup -S dnscrypt && adduser -S dnscrypt -G dnscrypt && chown dnscrypt:dnscrypt /var/log/dnscrypt-proxy/
USER dnscrypt
EXPOSE 5054/udp
EXPOSE 5054/tcp
VOLUME [ "/var/log/dnscrypt-proxy/" ]
VOLUME [ "/etc/dnscrypt-proxy/" ]
ENTRYPOINT [ "/dnscrypt-proxy", "-config", "/etc/dnscrypt-proxy/dnscrypt-proxy.toml" ]
