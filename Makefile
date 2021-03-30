#
# Makefile to generate specifications
#

.PHONY: clean all travis_targets json franca csv tests binary protobuf ocf c install deploy

all: clean json franca csv binary tests protobuf

# All targets that shall be built on each pull request for
# vehicle-signal-specification or vss-tools
# NOTE: c currently not built by travis - does not support latest vss
travis_targets: clean json franca binary csv tests deploy

DESTDIR?=/usr/local
TOOLSDIR?=./vss-tools
DEPLOYDIR?=./docs-gen/static/releases/nightly


json:
	${TOOLSDIR}/vspec2json.py -i:spec/VehicleSignalSpecification.id -I ./spec ./spec/VehicleSignalSpecification.vspec vss_rel_$$(cat VERSION).json

franca:
	${TOOLSDIR}/vspec2franca.py -v $$(cat VERSION) -i:spec/VehicleSignalSpecification.id -I ./spec ./spec/VehicleSignalSpecification.vspec vss_rel_$$(cat VERSION).fidl


csv:
	${TOOLSDIR}/vspec2csv.py -i:spec/VehicleSignalSpecification.id -I ./spec ./spec/VehicleSignalSpecification.vspec vss_rel_$$(cat VERSION).csv

tests:
	PYTHONPATH=${TOOLSDIR} pytest

binary:
	gcc -shared -o ${TOOLSDIR}/binary/binarytool.so -fPIC ${TOOLSDIR}/binary/binarytool.c
	${TOOLSDIR}/vspec2binary.py -i:./spec/VehicleSignalSpecification.id ./spec/VehicleSignalSpecification.vspec vss_rel_$$(cat VERSION).binary

protobuf:
	${TOOLSDIR}/contrib/vspec2protobuf.py -i:spec/VehicleSignalSpecification.id -I ./spec ./spec/VehicleSignalSpecification.vspec vss_rel_$$(cat VERSION).proto

ocf:
	${TOOLSDIR}/contrib/ocf/vspec2ocf.py -i PREFIX:spec/VehicleSignalSpecification.id:1 -I ./spec ./spec/VehicleSignalSpecification.vspec vss_rel_$$(cat VERSION).ocf.json

c:
	(cd ${TOOLSDIR}/vspec2c/; make )
	${TOOLSDIR}/vspec2c.py -i:./spec/VehicleSignalSpecification.id -I ./spec ./spec/VehicleSignalSpecification.vspec vss_rel_$$(cat VERSION).h vss_rel_$$(cat VERSION)_macro.h

clean:
	rm -f vss_rel_*
	(cd ${TOOLSDIR}/vspec2c/; make clean)

install:
	git submodule init
	git submodule update
	(cd ${TOOLSDIR}/; python3 setup.py install --install-scripts=${DESTDIR}/bin)
	$(MAKE) DESTDIR=${DESTDIR} -C ${TOOLSDIR}/vspec2c install
	install -d ${DESTDIR}/share/vss
	(cd spec; cp -r * ${DESTDIR}/share/vss)

deploy:
	if [ -d $(DEPLOYDIR) ]; then \
	  rm -f ${DEPLOYDIR}/vss_rel_*;\
	else \
	  mkdir -p ${DEPLOYDIR}; \
	fi;
	cp  vss_rel_* ${DEPLOYDIR}/
