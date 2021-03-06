FROM docker.io/alpine/git:latest AS source
ARG VERSION=master
WORKDIR /go/src
RUN git clone --depth=1 -b ${VERSION} https://github.com/DNSCrypt/dnscrypt-proxy.git .

FROM docker.io/library/golang:1.18-alpine AS build
COPY --from=source /go/src /go/src
WORKDIR /go/src/dnscrypt-proxy
RUN go mod download
RUN if [[ "`go env | grep "^GOARCH=" | sed 's:^GOARCH="\(.*\)"$:\1:'`" != "arm" ]]; then CGO_ENABLED=0 go build -buildvcs=false -ldflags '-w -s -buildid=' -trimpath -buildmode=pie .;else CGO_ENABLED=0 go build -buildvcs=false -ldflags '-w -s -buildid=' -trimpath .;fi

FROM docker.io/library/alpine:latest
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
