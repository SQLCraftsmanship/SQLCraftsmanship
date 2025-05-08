/*
Through the course of the, uh, course, we’ve been gradually 
layering on more ways that you can detect and prevent 
parameter sniffing performance problems. 

Now, it’s your final lab. No running workload this time: 
you’re going to take the query plans and parameter sets 
that you’ve been gathering so far, and actually get to 
work fixing the problems.

I will leave it up to you to decide:

* Which compatibility level you want to use (140 or 150)
* Which features you want enabled (like memory grant feedback, 
  columnstore indexes on 2017 to enable new features)

Here’s the setup I’m going to use on SQL Server 2019 – 
I’m going to stick with 2017 compat level so that I can 
teach more of you how things will look on your systems today:
*/



USE StackOverflow;
GO
/* I'm sticking with 2017 compat level to teach more folks relevant stuff: */
ALTER DATABASE CURRENT SET COMPATIBILITY_LEVEL = 140;
GO
ALTER DATABASE SCOPED CONFIGURATION SET LAST_QUERY_PLAN_STATS = ON;
GO
ALTER DATABASE [StackOverflow] SET QUERY_STORE = ON
GO
ALTER DATABASE [StackOverflow] SET QUERY_STORE (OPERATION_MODE = READ_WRITE, 
DATA_FLUSH_INTERVAL_SECONDS = 60, INTERVAL_LENGTH_MINUTES = 1, QUERY_CAPTURE_MODE = AUTO)
GO

/*
Then, we’re going to try fixing as many queries as we can by:

* Taking their outlier parameters that we’ve gathered
* Taking the query plans we’ve seen in production 
  (like spill problems)
* Deciding whether we can fix it with one good query plan, 
  or if we need multiple
* If we need multiple plans, figuring out the appropriate 
  method to use given the parameter varieties and their 
  execution frequencies
* Changing the queries & indexes to be less parameter sensitive
* Trying the new versions of the queries to see what their 
  new worst-case scenarios are

All of that work above will add up to 30-60 minutes per query, 
easily. Because of that, this lab is a bit of a gift that keeps 
on giving: you can spend hours or days working through a variety 
of queries to improve them. I don’t expect you to solve all of 
the queries in the time you have – just pick the ones you think 
are having the biggest problems, and work through from there. 

Let’s do this!
*/