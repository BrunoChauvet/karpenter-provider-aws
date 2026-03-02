FROM public.ecr.aws/docker/library/golang:1.25.7

WORKDIR /work

COPY Makefile /work/
COPY hack/toolchain.sh /work/hack/toolchain.sh
RUN make toolchain && go clean -cache -modcache

COPY go.mod go.sum /work/
RUN mkdir -p -m 0600 ~/.ssh && ssh-keyscan github.com >> ~/.ssh/known_hosts
RUN --mount=type=ssh \
    git config --global url."git@github.com:".insteadOf "https://github.com/" && \
    GONOSUMDB="github.com/ROKT/*" GOPRIVATE="github.com/ROKT/*" go mod download
