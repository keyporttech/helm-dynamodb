# Copyright 2020 Keyporttech Inc.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#     http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

REGISTRY=registry.keyporttech.com:30243
DOCKERHUB_REGISTRY="keyporttech"
CHART=dynamodb
VERSION = $(shell yq r Chart.yaml 'version')
RELEASED_VERSION = $(shell helm repo add keyporttech https://keyporttech.github.io/helm-charts/ && helm show chart keyporttech/dynamodb | yq - read 'version')
REGISTRY_TAG=${REGISTRY}/${CHART}:${VERSION}
CWD = $(shell pwd)

lint:
	@echo "linting..."
	helm lint
	helm template test ./
	ct lint --validate-maintainers=false --charts .

ifeq ($(VERSION),$(RELEASED_VERSION))
	echo "$(VERSION) must be > $(RELEASED_VERSION). Please bump chart version."
	exit 1
endif

.PHONY: lint

test:
	@echo "testing..."
	docker run -v ~/.kube:/root/.kube -v `pwd`:/charts/$(CHART) registry.keyporttech.com:30243/chart-testing:0.1.3 bash -c "git clone git@github.com:keyporttech/helm-charts.git; cp -rf /charts/$(CHART) helm-charts/charts; cd helm-charts; ct lint-and-install;"
	@echo "OK"
.PHONY: test

build: lint test

.PHONY: build

publish-local-registry:
	REGISTRY_TAG=${REGISTRY}/${CHART}:${VERSION}
	@echo "publishing to ${REGISTRY_TAG}"
	HELM_EXPERIMENTAL_OCI=1 helm chart save ./ ${REGISTRY_TAG}
	# helm chart export  ${REGISTRY_TAG}
	HELM_EXPERIMENTAL_OCI=1 helm chart push ${REGISTRY_TAG}
	@echo "OK"
.PHONY: publish-local-registry

publish-public-repository:
	#docker run -e GITHUB_TOKEN=${GITHUB_TOKEN} -v `pwd`:/charts/$(CHART) registry.keyporttech.com:30243/chart-testing:0.1.4 bash -cx " \
	#	echo $GITHUB_TOKEN; \
	helm package .;
	curl -o releaseChart.sh https://raw.githubusercontent.com/keyporttech/helm-charts/master/scripts/releaseChart.sh; \
	chmod +x releaseChart.sh; \
	./releaseChart.sh $(CHART) $(VERSION) .;
.PHONY: publish-public-repository

deploy: publish-local-registry publish-public-repository
	git remote add upstream https://github.com/keyporttech/helm-$(CHART).git
	git push upstream master
.PHONY:deploy
