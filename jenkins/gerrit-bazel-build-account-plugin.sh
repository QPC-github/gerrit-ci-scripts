#!/bin/bash -e

git checkout -f gerrit/{branch}
rm -rf plugins/account
git read-tree -u --prefix=plugins/account origin/{branch}

if [ -f plugins/account/external_plugin_deps.bzl ]
then
  cp -f plugins/account/external_plugin_deps.bzl plugins/
fi

TARGETS=$(echo "plugins/account:account" | sed -e 's/account/account/g')
TEST_TARGET=$(grep -2 junit_tests plugins/account/BUILD | grep -o 'name = "[^"]*"' | cut -d '"' -f 2)

. set-java.sh 8

pushd plugins/account
npm install bower
./node_modules/bower/bin/bower install
cp -Rf bower_components/jquery/dist/*js src/main/resources/static/js/.
cp -Rf bower_components/bootstrap/dist/js/*js src/main/resources/static/js/.
cp -Rf bower_components/bootstrap/dist/css/*css src/main/resources/static/css/.
cp -Rf bower_components/angular/*js src/main/resources/static/js/.
popd

bazelisk version
bazelisk build --spawn_strategy=standalone --genrule_strategy=standalone $TARGETS

if [ "$TEST_TARGET" != "" ]
then
    bazelisk test --test_env DOCKER_HOST=$DOCKER_HOST plugins/account:$TEST_TARGET
fi

for JAR in $(find bazel-bin/plugins/account -name account*.jar)
do
    PLUGIN_VERSION=$(git describe  --always origin/{branch})
    echo -e "Implementation-Version: $PLUGIN_VERSION" > MANIFEST.MF
    jar ufm $JAR MANIFEST.MF && rm MANIFEST.MF
    DEST_JAR=bazel-bin/plugins/account/$(basename $JAR)
    [ "$JAR" -ef "$DEST_JAR" ] || mv $JAR $DEST_JAR
    echo "$PLUGIN_VERSION" > bazel-bin/plugins/account/$(basename $JAR-version)
done
