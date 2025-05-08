/* view connections */
SELECT * FROM pg_stat_activity;

/*-— Kill connections*/
SELECT
    pg_terminate_backend(pid)
FROM
    pg_stat_activity
WHERE
    -- don't kill my own connection!
    pid != pg_backend_pid()
    -- don't kill the connections to other databases
    AND datname = 'XXXX';

/* kill a specific connection */     
select pg_terminate_backend(XXXX)
