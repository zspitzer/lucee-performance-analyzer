# Lucee Performance Analyzer
Performance Analyzer plugin for Lucee, to be used in the Lucee admin.

By Zac Spitzer https://twitter.com/zackster/

![extension install count](https://www.forgebox.io/api/v1/entry/A345C8CB-04CC-4D2B-93D50471D5105D83/badges/downloads)

[Forgebox](https://www.forgebox.io/view/A345C8CB-04CC-4D2B-93D50471D5105D83)

Supports Lucee 5.2.8.50 and later

## Install

### Lucee Administrator as an Admin Plugin / Extension

Install via Applications page in your Lucee Administrator. It's best to install under the Web Administrator, once [this bug/patch](https://luceeserver.atlassian.net/browse/LDEV-2791) against Lucee is merged, you will be able to install the plugin once at the Server level and then access the plugin from all web contexts. After installing the plugin restart Lucee to make the plugin accessible to your Lucee Server/Web Administrator. 

### Standalone Install  (new!)

Checkout the code into a folder and you can run it without having the Lucee Administrator enabled.

Just login with your Lucee Server Admin password, currently still requires debugging to be already enabled.

## Usage

You will need to enable debugging and configure a debug template in order to capture debug logs for this plugin to work. To enable debugging log into Lucee Administrator, click in the "Debugging" section on "Settings" and enable "Database Activity" with "Query Usage", "Exceptions", "Timer" and "Implicit variable Access". Then make sure to populate the debugging log by navigating/opening a cfml page with your browser, e.g. http://localhost:8888/index.cfm. After this you'll be able to see the collected information in the "Performance Analyzer" section in the Lucee Web Administrator of that web context. 

## Features
- Overall Analysis Report
- Filter by Path or URL
- Top variable Scoping problems Report
- Slowest SQL queries Report
- Slowest Templates / Functions Report
- Unused Templates Report
- Aggregate Aborts Report
- Aggregate Dumps Report
- Aggregate Exceptions Report
- Aggregate Timers Report
- Aggregate Traces Report
- Lucee Thread Report
- Memory Report by Application / Session
- All tables are sortable, just click any header

## Building
The Build process uses [Apache Ant](https://ant.apache.org/) 

Simply run **ant** in the root directory to build the extension .lex file, which you can then manually install via the Lucee Administrator

## Support

If you run into any issues, **please always describe your Lucee stack** (Java version, Lucee version, OS, webserver, tomcat/commandbox etc) and include any stacktraces if you encounter an exception.

Lucee doesn't yet support accessing plugins installed at the Server Admin plugins from the Web Admin, I have been working on a patch to enable this https://github.com/lucee/Lucee/pull/901 which was merged in with version 5.3.7.31

This plugin relies on the same backend API as the built in `Debugging - Logs` view in the Lucee Admin. If you don't see any logs there, this plugin won't have anything to report on. 

## Hacking
Once installed, all the source cfml and js files can be found under the server or web context, depending where you installed it 

- web context: under the \WEB-INF\context\admin\plugin\PerformanceAnalyzer
- server: C:\lucee\tomcat\lucee-server\context\context\admin\plugin\PerformanceAnalyzer

Append debug=true to the url to enable debugging output

If the plugin doesn't appear, append alwaysnew=1 to the url

Pull requests are welcome!

