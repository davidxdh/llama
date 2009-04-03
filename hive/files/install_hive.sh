#!/bin/sh
# Copyright 2009 Cloudera, inc.

usage() {
  echo "
usage: $0 <options>
  Required not-so-options:
     --cloudera-source-dir=DIR   path to cloudera distribution files
     --build-dir=DIR             path to hive/build/dist
     --prefix=PREFIX             path to install into

  Optional options:
     --doc-dir=DIR               path to install docs into [/usr/share/doc/hive]
     --lib-dir=DIR               path to install hive home [/usr/lib/hive]
     --installed-lib-dir=DIR     path where lib-dir will end up on target system
     --bin-dir=DIR               path to install bins [/usr/bin]
     --examples-dir=DIR          path to install examples [doc-dir/examples]
     ... [ see source for more similar options ]
  "
  exit 1
}

OPTS=$(getopt \
  -n $0 \
  -o '' \
  -l 'cloudera-source-dir:' \
  -l 'prefix:' \
  -l 'doc-dir:' \
  -l 'lib-dir:' \
  -l 'installed-lib-dir:' \
  -l 'bin-dir:' \
  -l 'examples-dir:' \
  -l 'python-dir:' \
  -l 'build-dir:' -- "$@")

if [ $? != 0 ] ; then
    usage
fi

eval set -- "$OPTS"
while true ; do
    case "$1" in
        --cloudera-source-dir)
        CLOUDERA_SOURCE_DIR=$2 ; shift 2
        ;;
        --prefix)
        PREFIX=$2 ; shift 2
        ;;
        --build-dir)
        BUILD_DIR=$2 ; shift 2
        ;;
        --doc-dir)
        DOC_DIR=$2 ; shift 2
        ;;
        --lib-dir)
        LIB_DIR=$2 ; shift 2
        ;;
        --installed-lib-dir)
        INSTALLED_LIB_DIR=$2 ; shift 2
        ;;
        --bin-dir)
        BIN_DIR=$2 ; shift 2
        ;;
        --examples-dir)
        EXAMPLES_DIR=$2 ; shift 2
        ;;
        --python-dir)
        PYTHON_DIR=$2 ; shift 2
        ;;
        --)
        shift ; break
        ;;
        *)
        echo "Unknown option: $1"
        usage
        exit 1
        ;;
    esac
done

for var in CLOUDERA_SOURCE_DIR PREFIX BUILD_DIR ; do
  if [ -z "$(eval "echo \$$var")" ]; then
    echo Missing param: $var
    usage
  fi
done

DOC_DIR=${DOC_DIR:-$PREFIX/usr/share/doc/hive}
LIB_DIR=${LIB_DIR:-$PREFIX/usr/lib/hive}
INSTALLED_LIB_DIR=${INSTALLED_LIB_DIR:-/usr/lib/hive}
EXAMPLES_DIR=${EXAMPLES_DIR:-$DOC_DIR/examples}
BIN_DIR=${BIN_DIR:-$PREFIX/usr/bin}
PYTHON_DIR=${PYTHON_DIR:-$LIB_DIR/lib/py}
CONF_DIR=/etc/hive
CONF_DIST_DIR=/etc/hive/conf.dist

# First we'll move everything into lib
install -d -m 0755 ${LIB_DIR}
(cd ${BUILD_DIR} && tar -cf - .)|(cd ${LIB_DIR} && tar -xf -)

# Move the "ext" directory top level in lib
mv ${LIB_DIR}/bin/ext ${LIB_DIR}
for thing in bin conf README.txt examples lib/py;
do
  rm -rf ${LIB_DIR}/$thing
done

install -d -m 0755 ${BIN_DIR}
for file in hive hive-config.sh
do
  cp $CLOUDERA_SOURCE_DIR/$file ${BIN_DIR}
done
hive_config=${BIN_DIR}/hive-config.sh
sed -i -e "s|@HIVE_HOME@|${INSTALLED_LIB_DIR}|" $hive_config
sed -i -e "s|@HIVE_CONF@|${CONF_DIR}/conf|" $hive_config


# Config
install -d -m 0755 ${PREFIX}${CONF_DIST_DIR}
(cd ${BUILD_DIR}/conf && tar -cf - .)|(cd ${PREFIX}${CONF_DIST_DIR} && tar -xf -)
cp $CLOUDERA_SOURCE_DIR/hive-site.xml ${PREFIX}${CONF_DIST_DIR}

# Docs
install -d -m 0755 ${DOC_DIR}
cp ${BUILD_DIR}/README.txt ${DOC_DIR}

# Examples
install -d -m 0755 ${EXAMPLES_DIR}
cp -a ${BUILD_DIR}/examples/* ${EXAMPLES_DIR}

# Python libs
install -d -m 0755 ${PYTHON_DIR}
(cd $BUILD_DIR/lib/py && tar cf - .) | (cd ${PYTHON_DIR} && tar xf -)
chmod 755 ${PYTHON_DIR}/hive_metastore/*-remote

# Dir for Metastore DB
install -d -m 1777 $PREFIX/var/lib/hive/metastore/
