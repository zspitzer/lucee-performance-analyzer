# Lucee Performance Analyzer
Performance Analyzer plugin for Lucee, to be used in the Lucee admin.

By Zac Spitzer https://twitter.com/zackster/

![install count](https://www.forgebox.io/api/v1/entry/A345C8CB-04CC-4D2B-93D50471D5105D83/badges/downloads)

Supports Lucee 5.2.8.50 and later

## Features
- Summary of top variable Scoping problems
- Summary of slowest sql queries

## Building
The Build process uses [Apache Ant](https://ant.apache.org/) 

Simply run **ant** in the root directory to build the extension .lex file, which you can then manually install via the Lucee Administrator

## Hacking
Once installed, all the source cfml and js files can be found under the server or web context, depending where you installed it 

- web context: under the \WEB-INF\context\admin\plugin\PerformanceAnalyzer
- server: C:\lucee\tomcat\lucee-server\context\context\admin\plugin\PerformanceAnalyzer

Append debug=true to the url to enable debugging output

If the plugin doesn't appear, append alwaysnew=1 to the url

