#!/bin/bash
set -euf

export PATH=${GOPATH}/bin:$PATH
pushd src/github.com/sylabs/${PKG_NAME}

# bootstrap go dependencies
go get -u github.com/golang/dep/cmd/dep

# Create a C and CPP compiler for singularity
cat > singularity-cc <<_EOF
#!/usr/bin/env bash
exec $CC -I${PREFIX}/include -L${PREFIX}/lib \$@
_EOF
chmod 755 singularity-cc

cat > singularity-cxx <<_EOF
#!/usr/bin/env bash
exec $CXX -I${PREFIX}/include -L${PREFIX}/lib \$@
_EOF
chmod 755 singularity-cxx

# configure
./mconfig \
  -p $PREFIX \
  -c "${PWD}/singularity-cc" \
  -x "${PWD}/singularity-cxx"

# build
pushd builddir
export CGO_CFLAGS="${CFLAGS}"
export CGO_CPPFLAGS="${CPPFLAGS} -I${PREFIX}/include"
export CGO_LDFLAGS="${LDFLAGS} -L${PREFIX}/lib"

export LD_LIBRARY_PATH=${PREFIX}/lib
make

# install
make install

# Fix SUID processes
find ${PREFIX}/libexec/singularity -type f -name '*-suid' -exec chmod u+s {} \;
