/* Task #1: get these two sets of parameters to perform consistently
sub-5-seconds, no matter which one is called first.

Try freeing the plan cache, then run Brent, then run Jon Skeet.

Then free the plan cache again, run Jon Skeet, then Brent.

Get both of them to run in <5 seconds, no matter which one is run first,
without using a recompile hint.
 */


/* Find comments left for Brent. Brent isn't that popular
of a user on Stack Overflow, so he wants to see all comments: */
EXEC usp_MostRecentCommentsForMe @UserId = 26837,
	@MinimumCommenterReputation = 0, @MinimumCommentScore = 0;

/* Find comments left for Jon Skeet. He's VERY popular,
so he only wants to see the best users & comments: */
EXEC usp_MostRecentCommentsForMe @UserId = 22656,
	@MinimumCommenterReputation = 10000, @MinimumCommentScore = 50;
GO



/* Task #2: after you've finished that, find at least 3 other
sets of parameters that might cause a problem for your newly
tuned stored procedure.

Find:
 * Outlier users
 * Outlier minimum reputations
 * Outlier minimum comment scores

Try putting them in memory first, and then run Brent and Jon Skeet.
Do they all still perform in under 5 seconds?
*/


/* Task #3: if you find new problems, can you tune your
stored procedure or indexes again, and still get everyone
to perform in <5 seconds? What changes do you need to make? */