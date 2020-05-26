#!/bin/sh

if [ "${CLASSPATH}" != "" ] ;then
    exec java -cp "${CLASSPATH}:@JAR@" org.antlr.Tool "$@"
else
    exec java -cp "@JAR@" org.antlr.Tool "$@"
fi
