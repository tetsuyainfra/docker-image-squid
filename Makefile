DOCKER_NAME := squid
SQUID_FILES := squid/entrypoint.sh squid/Dockerfile

BUILD_STAMP=tmp/.docker_build_done

ALL := $(BUILD_STAMP)

ifdef BUILD_TIME_HTTP_PROXY
DOCKER_BUILD_ARGS += --build-arg HTTP_PROXY=$(BUILD_TIME_HTTP_PROXY)
endif


.PHONY: all clean  cache_clean build run

all: $(ALL)

clean:
	@echo "Cleaning the project..."
	docker image rm -f $(DOCKER_NAME):latest || true
	rm -f $(ALL)

cache_clean: clean
	docker buildx prune -f || true

build: $(BUILD_STAMP)

$(BUILD_STAMP): $(SQUID_FILES)
	@echo "Building the Docker image on localhost..."
	echo "$(SQUID_FILES)"
	docker build \
		--progress=plain \
		$(DOCKER_BUILD_ARGS) \
		-t $(DOCKER_NAME):latest squid 2>&1 | tee tmp/build.log
	touch $(BUILD_STAMP)

run: build
	@echo "Running the Docker container..."
	docker run --rm -it \
		-p 3128:3128 \
		-p 3142:3142 \
		--env CONTAINER_DEBUG="${CONTAINER_DEBUG}" \
		--env SQUID_HTTPS_USERS="${SQUID_HTTPS_USERS}" \
		--name $(DOCKER_NAME) \
		$(DOCKER_NAME):latest
