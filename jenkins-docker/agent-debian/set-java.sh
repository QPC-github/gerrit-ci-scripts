#!/bin/bash

if [ "$1" == "" ]
then
  echo "Set current Java version level"
  echo ""
  echo "Use: $0 <7|8>"
  exit 1
fi

export JAVA_HOME=/usr/lib/jvm/java-$1-openjdk-amd64
export PATH=$JAVA_HOME/bin:$JAVA_HOME/jre/bin:$PATH

echo "Java set to: $(which java)"

if [[ "$1" == "11" ]]
then
   # See Bazel Issue 3236 with Java 11 [https://github.com/bazelbuild/bazel/issues/3236]
   export BAZEL_OPTS="$BAZEL_OPTS --sandbox_tmpfs_path=/tmp"
fi

