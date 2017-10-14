VERSION := 0.0.1
APP_NAME := kodicast
COMMIT := $(shell git rev-parse HEAD)
BUILD_TIME := $(shell date -u +%FT%T)
BRANCH := $(shell git rev-parse --abbrev-ref HEAD)

sync:
	cd src/$(APP_NAME); glide install

update:
	cd src/$(APP_NAME); glide up

deps:
	go get github.com/aktau/github-release
	go get -u github.com/axw/gocov/gocov
	go get -u github.com/laher/gols/cmd/...
	go get -u github.com/Masterminds/glide
	go get -u github.com/alecthomas/gometalinter
	go get -u github.com/mjibson/esc
	bin/gometalinter --install --update
	go get -t $(APP_NAME)/... # install test packages


clean:
	rm -f $(APP_NAME)
	rm -rf pkg
	rm -rf bin
	find src/* -maxdepth 0 ! -name '$(APP_NAME)' -type d | xargs rm -rf
	rm -rf src/$(APP_NAME)/vendor/
	 
lint:
	bin/gometalinter --fast --disable=gotype --disable=gosimple --disable=ineffassign --disable=dupl --disable=gas --cyclo-over=30 --deadline=60s --exclude $(shell pwd)/src/$(APP_NAME)/vendor src/$(APP_NAME)/...
	find src/$(APP_NAME) -not -path "./src/$(APP_NAME)/vendor/*" -name '*.go' | xargs gofmt -w -s

test: lint cover
	go test -v -race $(shell go-ls $(APP_NAME)/...)

cover:
	gocov test $(shell go-ls $(APP_NAME)/...) | gocov report

editor:
	go get -u -v github.com/nsf/gocode
	go get -u -v github.com/rogpeppe/godef
	go get -u -v github.com/golang/lint/golint
	go get -u -v github.com/lukehoban/go-outline
	go get -u -v sourcegraph.com/sqs/goreturns
	go get -u -v golang.org/x/tools/cmd/gorename
	go get -u -v github.com/tpng/gopkgs
	go get -u -v github.com/newhook/go-symbols
	go get -u -v golang.org/x/tools/cmd/guru

build:
	env GOOS=linux GOARCH=arm go build --ldflags '-w -X main.version=$(VERSION) -X main.commitHash=${COMMIT} -X main.branch=${BRANCH} -X main.buildTime=${BUILD_TIME}' -o $(APP_NAME)-Linux-armv7l $(APP_NAME)/cmd/$(APP_NAME)
	env GOOS=linux GOARCH=arm64 go build --ldflags '-w -X main.version=$(VERSION) -X main.commitHash=${COMMIT} -X main.branch=${BRANCH} -X main.buildTime=${BUILD_TIME}' -o $(APP_NAME)-Linux-aarch64 $(APP_NAME)/cmd/$(APP_NAME)
	env GOOS=linux GOARCH=amd64 go build --ldflags '-s -w -X main.version=$(VERSION) -X main.commitHash=${COMMIT} -X main.branch=${BRANCH} -X main.buildTime=${BUILD_TIME}' -o $(APP_NAME)-Linux-x86_64 $(APP_NAME)/cmd/$(APP_NAME)

install:
	sudo mv $(APP_NAME)-`uname -s`-`uname -m` /usr/local/bin/$(APP_NAME)

upload:
	bin/github-release upload \
		--user dz0ny \
		--repo $(APP_NAME) \
		--tag "v$(VERSION)" \
		--name "$(APP_NAME)-Linux-armv6l" \
		--file $(APP_NAME)-Linux-armv7l

all: deps sync build test