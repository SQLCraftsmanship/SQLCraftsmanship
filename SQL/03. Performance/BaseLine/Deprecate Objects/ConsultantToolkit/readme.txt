SQL Server Checkup

Run this app from your desktop, and it will:

* Connect to the SQL Server of your choice
* Run a series of low-priority diagnostic queries (takes 5-15 minutes)
* Put that data into a spreadsheet and a series of files
* Zip them together into one file

For full documentation, visit: https://sqlservercheckup.com/


HOW TO USE IT:

Open a command prompt in the folder where you unzipped it, and run:


Windows authentication:
SQLServerCheckup.exe --datasource MyServerName

SQL Server authentication:
SQLServerCheckup.exe --datasource MyServerName --userid MyUserName --password MyPassword

Azure SQL DB:
SQLServerCheckup.exe --datasource MyServerName --userdb MyDatabaseName --userid MyUserName --password MyPassword

If you use tricky characters in your server name, user name, or password, like
quotation marks or spaces, you'll need to surround it with double quotes. For
example, if my password is @#!, I might want to use "@#!".

You don't have to run this on the SQL Server itself - you can run it from any
desktop or laptop with at least .NET 4.5.2.

SQL Server 2008 and newer are supported. If you have databases with older
compatibility levels, you'll see errors as SQLServerCheckup runs - that's okay,
and we may still be able to get enough diagnostic data to perform our analysis.

By default, it runs a subset of diagnostic queries - enough to get us a good
start. If you want to run a more in-depth analysis, add --deepdive to the
command line, but it can take 15-45 minutes depending on the number of
databases, server horsepower, other active running queries, etc. 



WHEN IT FINISHES:

Go into the Output folder, grab the zip file, and send that to us. We will
start reading the diagnostic data and making our assessments.




WHAT QUERIES IT RUNS:

To see the queries, go into the \Resources\SQLServerCheckup folder. They are a
collection of industry-standard open source scripts that check for things like
missing backups, corrupt databases, misconfigured memory, and more.

They are very lightweight: they don't start traces with Profiler or Extended
Events. They're designed to capture diagnostic data quickly with a minimum of
overhead.

Nervous about what data is getting gathered? No problem: run it against a test
or development server first. After it finishes, look in the Output folder and
you can see the output.