# Copyright (c) 2014 Hewlett-Packard Development Company, L.P.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied.
# See the License for the specific language governing permissions and
# limitations under the License.

DISTRO ?= $(shell lsb_release -is | tr '[:upper:]' '[:lower:]')
RELEASE ?= $(shell lsb_release -cs | tr '[:upper:]' '[:lower:]')

VERSION := $(shell dpkg-parsechangelog | awk '/^Version:/ { print $$2 }')
UPSTREAM_VERSION := $(shell echo "$(VERSION)" | sed -e 's,-[^-]*$$,,')

BUILD_ROOT := $(CURDIR)/build

SOURCE_DIR = $(BUILD_ROOT)/dwarf-$(UPSTREAM_VERSION)
ORIG = dwarf_$(UPSTREAM_VERSION).orig.tar.gz

help:
	@echo "You need to specify a build rule"

$(BUILD_ROOT)/$(ORIG):
	install -d $(BUILD_ROOT)
	wget -O $(BUILD_ROOT)/$(ORIG) \
	    https://github.com/juergh/dwarf/archive/v$(UPSTREAM_VERSION).tar.gz

$(SOURCE_DIR)/debian/control: $(BUILD_ROOT)/$(ORIG)
	# Unpack the source
	tar -C $(BUILD_ROOT) -xzvf $(BUILD_ROOT)/$(ORIG)
	cp -aR debian $(SOURCE_DIR)

	# Create the control file
	cat $(SOURCE_DIR)/debian/control.d/$(DISTRO) > \
	    $(SOURCE_DIR)/debian/control

	# Fix the changelog
	sed -i "s/RELEASE/$(RELEASE)/g" $(SOURCE_DIR)/debian/changelog

	# Distro-specific cleanups
	if [ "$(DISTRO)" = "ubuntu" ] ; then \
	    rm -f $(SOURCE_DIR)debian/dwarf.init ; \
	fi

	@echo "DISTRO = $(DISTRO)"
	@echo "RELEASE = $(RELEASE)"

source: $(SOURCE_DIR)/debian/control

clean:
	@find . \( -name '*~' \) -type f -print | xargs rm -f
	@rm -rf $(SOURCE_DIR)

deepclean: clean
	@rm -rf $(BUILD_ROOT)

deb: source
	cd $(SOURCE_DIR) && dpkg-buildpackage -us -uc

src: source
	cd $(SOURCE_DIR) && dpkg-buildpackage -uc -us -S -sa

tot: UPSTREAM_VERSION := $(shell date +'%Y%m%d')
tot:
	install -d $(BUILD_ROOT)
	rm -rf $(SOURCE_DIR)

	wget -O $(BUILD_ROOT)/dwarf.tar.gz \
	    https://github.com/juergh/dwarf/archive/master.tar.gz
	tar -C $(BUILD_ROOT) -xzvf $(BUILD_ROOT)/dwarf.tar.gz
	rm $(BUILD_ROOT)/dwarf.tar.gz
	mv $(BUILD_ROOT)/dwarf-master $(SOURCE_DIR)

	tar -C $(BUILD_ROOT) -czvf $(BUILD_ROOT)/$(ORIG) $(SOURCE_DIR)
	cp -aR debian $(SOURCE_DIR)

	# Create the control file
	cat $(SOURCE_DIR)/debian/control.d/$(DISTRO) > \
	    $(SOURCE_DIR)/debian/control

	# Create a dummy changelog
	( echo 'dwarf ($(UPSTREAM_VERSION)-1) UNRELEASED; urgency=low' ; \
	  echo ; \
	  echo '  * top-of-tree' ; \
	  echo ; \
	  echo ' -- ${DEBFULLNAME} <${DEBEMAIL}>  $(shell date -R)' \
	) > $(SOURCE_DIR)/debian/changelog

	cd $(SOURCE_DIR) && dpkg-buildpackage -us -uc
