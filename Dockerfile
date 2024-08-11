FROM golang:1.16 AS build
RUN apt-get update && apt-get install --no-install-recommends -y make=4.3-4.1
WORKDIR /go/
COPY . .
WORKDIR /go/word-cloud-generator
RUN make

FROM alpine:3.20.2 AS product
COPY --from=build /go/word-cloud-generator/artifacts/linux/word-cloud-generator /opt/word-cloud-generator/
EXPOSE 8888
RUN apk --no-cache add bash=5.2.26-r0 libc6-compat=1.1.0-r4
WORKDIR /opt/word-cloud-generator/
RUN chmod +x word-cloud-generator \
&& export PATH="$/opt/word-cloud-generator:$PATH" 
CMD ["./word-cloud-generator"]
