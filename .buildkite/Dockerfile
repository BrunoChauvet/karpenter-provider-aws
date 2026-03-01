FROM public.ecr.aws/docker/library/golang:1.24.1

WORKDIR /work

COPY Makefile /work/
COPY hack/toolchain.sh /work/hack/toolchain.sh
RUN make toolchain && go clean -cache -modcache

COPY go.mod go.sum /work/
RUN go mod download
