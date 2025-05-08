/*
Try these different parameters. If one goes in first, how do the 
others perform? It’s going to be tough to get one plan to work 
well for all of ’em:
*/
EXEC RecentPostsByLocation @Location = N'Germany';
EXEC RecentPostsByLocation @Location = N'Iceland';
EXEC RecentPostsByLocation @Location = N'Hafnarfjordur, Iceland';

/* 
For the sake of this lab, let’s say:

* Recompile hints are off-limits because the queries are run on a 
  frequent scheduled basis
* We can’t change the indexes – we can’t add more indexes, and we 
  can’t remove indexes because they’re all needed for other queries
*/