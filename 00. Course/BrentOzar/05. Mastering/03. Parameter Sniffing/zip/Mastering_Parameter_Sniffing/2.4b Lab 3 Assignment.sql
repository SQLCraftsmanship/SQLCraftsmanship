/*
Now, it’s your turn: we’re going to run a workload in your lab
while sp_BlitzFirst collects data. You’ll query the plan cache
history in DBAtools.dbo.BlitzCache and BlitzWho, find queries 
whose plans are changing, and gather parameters & plans to use 
that will help you design a better plan tomorrow.

You don’t have to fix the parameter sniffing yet. Your goal 
here is just to start identifying problematic queries and 
collecting data about them. 

I can’t emphasize this enough: my goal with this lab is to give 
you a lot of different queries, many of which can have parameter 
sniffing issues, so that you’ve got a wide variety of challenges 
over time as you revisit this lab. Don’t think that there’s only 
“one answer” that you need to find – here, I’m just getting you 
used to surveying how big the landscape is. In the real world, 
you would focus on big runaway queries and queries users are 
complaining about.

Your goal is to use the BlitzCache, BlitzWho, and BlitzFirst tables to:

1. Identify the worst-performing query that you’d want to tune if 
   given the chance (and don’t worry about whether or not it has 
   parameter sniffing issues – almost everything in this lab does)

2. Gather at least 2 sets of parameters that are being used to 
   call it in production

3. Gather at least 2 different execution plans that are being 
   generated in production (estimated, or last actual, or mid-flight)

Then turn those into me in Slack. You can use PasteThePlan.com to 
share query plans.
*/