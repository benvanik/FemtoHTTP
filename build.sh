#!/bin/bash

PROJECTNAME="FemtoHTTP"

# Release
xcodebuild -project $PROJECTNAME.xcodeproj/ -target $PROJECTNAME-iPhone -configuration Release -sdk iphonesimulator2.1
xcodebuild -project $PROJECTNAME.xcodeproj/ -target $PROJECTNAME-iPhone -configuration Release -sdk iphoneos2.1
xcodebuild -project $PROJECTNAME.xcodeproj/ -target $PROJECTNAME -configuration Release -sdk macosx10.5

# Documentation
xcodebuild -project $PROJECTNAME.xcodeproj/ -target Documentation -configuration Release -sdk macosx10.5

# Consolidate into a single folder
rm -rf Redist
mkdir Redist
mkdir Redist/Documentation
mkdir Redist/iPhone
mkdir Redist/iPhone/include
mkdir Redist/iPhone/include/$PROJECTNAME
mkdir Redist/iPhone/lib
mkdir Redist/MacOS

cp LICENSE Redist/

cp build/Release-iphoneos/$PROJECTNAME/* Redist/iPhone/include/$PROJECTNAME
cp build/Release-iphoneos/lib$PROJECTNAME-iphoneos.a Redist/iPhone/lib/
cp build/Release-iphonesimulator/lib$PROJECTNAME-iphonesimulator.a Redist/iPhone/lib/
cp -R build/Release/$PROJECTNAME.framework Redist/MacOS/
rm -Rf Redist/MacOS/$PROJECTNAME.framework/Versions/A/PrivateHeaders/*

cp -R Documentation/DoxygenDocs.docset/html/org.noxa.$PROJECTNAME.docset Redist/
cp -R Documentation/html/* Redist/Documentation/
rm -Rf Redist/Documentation/org.noxa.$PROJECTNAME.docset
