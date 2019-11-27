unit:
	go test -v --race $(shell go list ./... | grep -v /vendor/)

staticcheck:
	megacheck $(shell go list ./... | grep -v /vendor/)

safesql:
	safesql https://github.com/ScottAI/microservices-search

benchmark:
	go test -benchmem -benchtime=20s -bench=. github.com/ScottAI/microservices-search/handlers | tee bench.txt
	if [ -a old_bench.txt ]; then \
  	benchcmp -tolerance=5.0 old_bench.txt bench.txt; \
	fi;
	
	if [ $$? -eq 0 ]; then \
		mv bench.txt old_bench.txt; \
	fi;

build_linux:
	CGO_ENABLED=0 GOOS=linux go build -o ./search .

build_docker:
	docker build -t wkdljl/search .

start_stack:
	docker-compose up -d

run: start_stack
	go run main.go
	docker-compose stop

integration: start_stack
	cd features && MYSQL_CONNECTION="root:password@tcp(${DOCKER_IP}:3306)/kittens" godog ./
	docker-compose stop
	docker-compose rm -f

test: unit benchmark staticcheck safesql integration

circleintegration:
	docker build -t circletemp -f ./IntegrationDockerfile .	
	docker-compose up -d
	docker run --network chapter11servicessearch_default -w /go/src/github.com/ScottAI/microservices-search/features -e "MYSQL_CONNECTION=root:password@tcp(mysql:3306)/kittens" circletemp godog ./
	docker-compose stop
	docker-compose rm -f


