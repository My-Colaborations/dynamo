# Dynamo Ada Generator

[![Build Status](https://img.shields.io/jenkins/s/http/jenkins.vacs.fr/Dynamo.svg)](http://jenkins.vacs.fr/job/Dynamo/)
[![Test Status](https://img.shields.io/jenkins/t/http/jenkins.vacs.fr/Dynamo.svg)](http://jenkins.vacs.fr/job/Dynamo/)
[![Download](https://img.shields.io/badge/download-0.8.0-brightgreen.svg)](http://download.vacs.fr/dynamo/dynamo-0.8.0.tar.gz)
[![License](http://img.shields.io/badge/license-APACHE2-blue.svg)](LICENSE)
![Commits](https://img.shields.io/github/commits-since/stcarrez/dynamo/0.8.0.svg)

This Ada05 application is a code generator used to generate
an Ada Web Application or database mappings from hibernate-like
XML description or UML models.  It provides various commands for the
generation of a web application which uses the Ada Web Application framework
(https://github.com/stcarrez/ada-awa/).

Build with the following commands:
```
   ./configure
   make
```
Install it with:
```
   make install
```
# Documentation

The Dynamo Ada Generator sources as well as a wiki documentation
is provided on:

   https://github.com/stcarrez/dynamo


# License

Dynamo integrates some files from the GNU Compiler Collection (5.2.0).
These files are used to read the GNAT project files (see src/gnat).
They are distributed under the GPL version 3 license.

The Dynamo core implementation is distributed under the Apache 2.0 license.

The Dynamo templates are distributed under the Apache 2.0 license.

The Dynamo generated code can be distributed under whatever license you like.