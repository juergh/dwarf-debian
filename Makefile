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

RELEASE ?= $(shell lsb_release -cs)

DEB_VERSION = $(shell head -1 debian/changelog | awk '{print $$2}' | \
	tr -d '()' | sed 's/RELEASE/$(RELEASE)/')
DEB_NAME = dwarf_$(DEB_VERSION)

VERSION = $(shell echo $(DEB_VERSION) | awk -F- '{print $$1 }')

all: deb

build:
	rm -rf build || :
	mkdir build
ifeq ($(TGZ),)
	cd build && \
		wget -O dwarf_$(VERSION).orig.tar.gz \
		https://github.com/juergh/dwarf/archive/v$(VERSION).tar.gz && \
		tar -xzvf dwarf_$(VERSION).orig.tar.gz
else
	cd build && tar -xzvf ../$(TGZ)
endif
	cp -aR debian build/dwarf-$(VERSION)
	sed -i 's/RELEASE/$(RELEASE)/g' build/dwarf-$(VERSION)/debian/changelog

deb: build
	cd build/dwarf-$(VERSION) && debuild -uc -us

src: build
	cd build/dwarf-$(VERSION) && debuild -S -sa

ppa: src
	cd build && dput ppa:juergh/dwarf $(DEB_NAME)_source.changes

clean:
	@find . \( -name '*~' \) -type f -print | \
		xargs rm -f
	@rm -rf build || :

.PHONY: build
