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

VERSION := $(shell dpkg-parsechangelog | awk '/^Version:/ { print $$2 }')
UPSTREAM_VERSION := $(shell echo "$(VERSION)" | sed -e 's,-[^-]*$$,,')

BUILD_ROOT := $(CURDIR)/build
SOURCE_DIR := $(BUILD_ROOT)/dwarf-$(UPSTREAM_VERSION)

ORIG := dwarf_$(UPSTREAM_VERSION).orig.tar.gz

help:
	@echo "You need to specify a build rule"

$(BUILD_ROOT)/$(ORIG):
	install -d $(BUILD_ROOT)
	wget -O $(BUILD_ROOT)/$(ORIG) \
	    https://github.com/juergh/dwarf/archive/v$(UPSTREAM_VERSION).tar.gz
	touch $@

$(SOURCE_DIR)/debian/changelog: $(BUILD_ROOT)/$(ORIG)
	tar -C $(BUILD_ROOT) -xzvf $(BUILD_ROOT)/$(ORIG)
	cp -aR debian $(SOURCE_DIR)
	touch $@

source: $(SOURCE_DIR)/debian/changelog

clean:
	@find . \( -name '*~' \) -type f -print | xargs rm -f
	@rm -rf $(BUILD_ROOT)

deb: $(SOURCE_DIR)/debian/changelog
	cd $(SOURCE_DIR) && \
	    debian/rules debian/control && \
	    dpkg-buildpackage -us -uc

src: $(SOURCE_DIR)/debian/changelog
	cd $(SOURCE_DIR) && \
	    debian/rules debian/control && \
	    dpkg-buildpackage -uc -us -S -sa

#ppa:
#	cd $(BUILD_ROOT) && dput ppa:juergh/dwarf $(CHANGES)
