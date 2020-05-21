#!/bin/bash -e

git remote add origin https://gerrit.googlesource.com/gerrit
git fetch origin
git checkout origin/{gerrit-branch}
git submodule update --init
rm -rf plugins/its-{name}
rm -rf plugins/its-base
git read-tree -u --prefix=plugins/its-{name} plugin/{branch}
git fetch --tags origin

# Try first the Gerrit-specific branch of its-base and then fallback to the one of the plugin
git read-tree -u --prefix=plugins/its-base base/{gerrit-branch} || git read-tree -u --prefix=plugins/its-base base/{branch}

rm -Rf bazel-bin

if [ -f plugins/its-{name}/external_plugin_deps.bzl ]
then
  cp -f plugins/its-{name}/external_plugin_deps.bzl plugins/
fi

TARGETS=$(echo "{targets}" | sed -e 's/its-{{name}}/its-{name}/g')

. set-java.sh 8

java -fullversion
bazelisk version
bazelisk build --spawn_strategy=standalone --genrule_strategy=standalone $TARGETS

echo 'Running tests...'
set +e
bazelisk test --test_env DOCKER_HOST=$DOCKER_HOST plugins/its-{name}/...
TEST_RES=$?
set -e
if [ $TEST_RES -eq 4 ]
then
    echo 'No tests found for its plugin (tell this to the plugin maintainers?).'
elif [ ! $TEST_RES -eq 0 ]
then
    echo 'Tests failed'
    exit 1
fi

for JAR in $(find bazel-bin/plugins/its-{name} -name its-{name}*.jar)
do
    PLUGIN_VERSION=$(git describe --always plugin/{branch})
    echo -e "Implementation-Version: $PLUGIN_VERSION" > MANIFEST.MF
    jar ufm $JAR MANIFEST.MF && rm MANIFEST.MF
    DEST_JAR=bazel-bin/plugins/its-{name}/$(basename $JAR)
    [ "$JAR" -ef "$DEST_JAR" ] || mv $JAR $DEST_JAR
    echo "$PLUGIN_VERSION" > bazel-bin/plugins/its-{name}/$(basename $JAR-version)
done
