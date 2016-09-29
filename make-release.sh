#!/bin/bash

set -e

if [[ $(git status -s) != "" ]]
then
    echo working directory is not clean
    exit 1
fi

if [[ $((git symbolic-ref -q HEAD || git name-rev --name-only --no-undefined --always HEAD ) | sed -e 's,.*/,,') != "master" ]]
then
    echo not on master branch
    exit 1
fi

version=$(perl -ne 'print "$1\n" if (/^\(defproject .* "(.*)-SNAPSHOT"/i)' project.clj)

if [[ $version = "" ]]
then
    echo project.clj does not define a -SNAPSHOT version
    exit 1
fi

perl -pi -e 's/^(\(defproject .* "\d+\.\d+\.\d+)-SNAPSHOT"/\1"/' project.clj

echo building version $version

lein clean
lein test

git tag $version

lein deploy # builds jar and uses nexus credentials from .lein/profiles.clj 

perl -pi -e 's/(\(defproject .* "\d+\.)(\d+)\.\d+"/$1 . ($2 + 1)  . ".0-SNAPSHOT\""/e' project.clj
version=$(perl -ne 'print "$1\n" if (/^\(defproject .* "(.*)-SNAPSHOT"/i)' project.clj)

git commit -m "Bump version number to $version-SNAPSHOT" project.clj
git push origin
