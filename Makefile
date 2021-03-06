PYTHON?=python
PYTHON3?=python3
SETUPFLAGS=
PACKAGENAME=fastrlock
VERSION=$(shell python -c 'import re; f=open("setup.py"); print(re.search("VERSION\s*=\s*(.+)", f.read()).group(1).strip("\x27")); f.close()')

PYTHON_WITH_CYTHON=$(shell $(PYTHON)  -c 'import Cython.Compiler' >/dev/null 2>/dev/null && echo " --with-cython" || true)
PY3_WITH_CYTHON=$(shell $(PYTHON3) -c 'import Cython.Compiler' >/dev/null 2>/dev/null && echo " --with-cython" || true)

MANYLINUX_IMAGE_X86_64=quay.io/pypa/manylinux1_x86_64
MANYLINUX_IMAGE_686=quay.io/pypa/manylinux1_i686

.PHONY: all version inplace sdist build clean wheel_manylinux wheel

all: inplace


version:
	@echo $(VERSION)

inplace:
	$(PYTHON) setup.py $(SETUPFLAGS) build_ext -i $(PYTHON_WITH_CYTHON)

sdist:
	$(PYTHON) setup.py $(SETUPFLAGS) sdist $(PYTHON_WITH_CYTHON)

build:
	$(PYTHON) setup.py $(SETUPFLAGS) build $(PYTHON_WITH_CYTHON)

wheel:
	$(PYTHON) setup.py $(SETUPFLAGS) bdist_wheel $(PYTHON_WITH_CYTHON)

wheel_manylinux: wheel_manylinux64   # wheel_manylinux32

wheel_manylinux32 wheel_manylinux64: dist/$(PACKAGENAME)-$(VERSION).tar.gz
	time docker run --rm -t \
		-v $(shell pwd):/io \
		-e CFLAGS="-O3 -mtune=generic -pipe -fPIC" \
		-e LDFLAGS="$(LDFLAGS)" \
		-e LIBXML2_VERSION="$(MANYLINUX_LIBXML2_VERSION)" \
		-e LIBXSLT_VERSION="$(MANYLINUX_LIBXSLT_VERSION)" \
		$(if $(patsubst %32,,$@),$(MANYLINUX_IMAGE_X86_64),$(MANYLINUX_IMAGE_686)) \
		bash /io/tools/build-manylinux-wheels.sh /io/$<

clean:
	find . \( -name '*.o' -o -name '*.so' -o -name '*.py[cod]' -o -name '*.dll' \) -exec rm -f {} \;
	rm -rf build
