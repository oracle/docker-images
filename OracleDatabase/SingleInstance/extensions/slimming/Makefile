
RPM_VERSION ?= 0.0.1

all: generate_rpm

setup_system: refresh_applin
	@echo "Setting up the required packages"

generate_rpm:
	@echo "Generating RPMs for ${RPM_VERSION}"
	sh buildscripts/buildsyslensrpm.sh ${RPM_VERSION} generic

generate_shep_rel_tar:
	@echo "Generating shepherd tar for ${RPM_VERSION}"
	sh buildscripts/buildshepherdrelease.sh ${RPM_VERSION}

pylint:
	@echo "Running pylint"
	python3 buildscripts/lint.py | tee test/pylint_result


# Applin
########

.PHONY: refresh_applin

# Read applin version from .applin_base
APPLIN_VERSION ?= $(shell grep -oE '^VERSION=[0-9]+\.[0-9]+\.[0-9]+' .applin_base | grep -oE '[0-9.]+')
APPLIN_VERSION_TRUNC=$(shell grep -oE '^[0-9]+\.[0-9]+' <<< $(APPLIN_VERSION))

refresh_applin: applin-${APPLIN_VERSION}.gz applin/${APPLIN_VERSION}
	tar xzf $< -C applin/${APPLIN_VERSION}

applin-.gz:
	@echo "Please specify proper applin version."
	@echo "Instructions:"
	@echo "    Add the line 'VERSION=x.y.z' to the .applin_base file."
	@echo "    Where x.y.z specifies the required version."
	@false

applin-%.gz:
	@echo "Getting package from OCIfactory: applin-${APPLIN_VERSION}.gz"
	curl --noproxy '*' -s -S -O https://artifactory.oci.oraclecorp.com/adbd-syslens-dev-rpm-local/applin/${APPLIN_VERSION_TRUNC}/${APPLIN_VERSION}/applin-${APPLIN_VERSION}.gz

applin/%: FORCE
	rm -rf $@
	mkdir -p $@

# Any target with FORCE as pre-requisite will have
# its recipe run every time.
FORCE: ;
