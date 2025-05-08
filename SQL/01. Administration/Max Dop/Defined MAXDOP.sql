https://dba.stackexchange.com/questions/36522/maxdop-setting-algorithm-for-sql-server


DECLARE @CoreCount int;
DECLARE @NumaNodes int;

SET @CoreCount = (SELECT i.cpu_count from sys.dm_os_sys_info i);
SET @NumaNodes = (
    SELECT MAX(c.memory_node_id) + 1 
    FROM sys.dm_os_memory_clerks c 
    WHERE memory_node_id < 64
    );

IF @CoreCount > 4 /* If less than 5 cores, don't bother. */
BEGIN
    DECLARE @MaxDOP int;

    /* 3/4 of Total Cores in Machine */
    SET @MaxDOP = @CoreCount * 0.75; 

    /* if @MaxDOP is greater than the per NUMA node
       Core Count, set @MaxDOP = per NUMA node core count
    */
    IF @MaxDOP > (@CoreCount / @NumaNodes) 
        SET @MaxDOP = (@CoreCount / @NumaNodes) * 0.75;

    /*
        Reduce @MaxDOP to an even number 
    */
    SET @MaxDOP = @MaxDOP - (@MaxDOP % 2);

    /* Cap MAXDOP at 8, according to Microsoft */
    IF @MaxDOP > 8 SET @MaxDOP = 8;

    PRINT 'Suggested MAXDOP = ' + CAST(@MaxDOP as varchar(max));
END
ELSE
BEGIN
    PRINT 'Suggested MAXDOP = 0 since you have less than 4 cores total.';
    PRINT 'This is the default setting, you likely do not need to do';
    PRINT 'anything.';
END;



/*************************************************************************
Author          :   Dennis Winter (Thought: Adapted from a script from "Kin Shah")
Purpose         :   Recommend MaxDop settings for the server instance
Tested RDBMS    :   SQL Server 2008R2

**************************************************************************/
declare @hyperthreadingRatio bit
declare @logicalCPUs int
declare @HTEnabled int
declare @physicalCPU int
declare @SOCKET int
declare @logicalCPUPerNuma int
declare @NoOfNUMA int
declare @MaxDOP int

select @logicalCPUs = cpu_count -- [Logical CPU Count]
    ,@hyperthreadingRatio = hyperthread_ratio --  [Hyperthread Ratio]
    ,@physicalCPU = cpu_count / hyperthread_ratio -- [Physical CPU Count]
    ,@HTEnabled = case 
        when cpu_count > hyperthread_ratio
            then 1
        else 0
        end -- HTEnabled
from sys.dm_os_sys_info
option (recompile);

select @logicalCPUPerNuma = COUNT(parent_node_id) -- [NumberOfLogicalProcessorsPerNuma]
from sys.dm_os_schedulers
where [status] = 'VISIBLE ONLINE'
    and parent_node_id < 64
group by parent_node_id
option (recompile);

select @NoOfNUMA = count(distinct parent_node_id)
from sys.dm_os_schedulers -- find NO OF NUMA Nodes 
where [status] = 'VISIBLE ONLINE'
    and parent_node_id < 64

IF @NoOfNUMA > 1 AND @HTEnabled = 0
    SET @MaxDOP= @logicalCPUPerNuma 
ELSE IF  @NoOfNUMA > 1 AND @HTEnabled = 1
    SET @MaxDOP=round( @NoOfNUMA  / @physicalCPU *1.0,0)
ELSE IF @HTEnabled = 0
    SET @MaxDOP=@logicalCPUs
ELSE IF @HTEnabled = 1
    SET @MaxDOP=@physicalCPU

IF @MaxDOP > 10
    SET @MaxDOP=10
IF @MaxDOP = 0
    SET @MaxDOP=1

PRINT 'logicalCPUs : '         + CONVERT(VARCHAR, @logicalCPUs)
PRINT 'hyperthreadingRatio : ' + CONVERT(VARCHAR, @hyperthreadingRatio) 
PRINT 'physicalCPU : '         + CONVERT(VARCHAR, @physicalCPU) 
PRINT 'HTEnabled : '           + CONVERT(VARCHAR, @HTEnabled)
PRINT 'logicalCPUPerNuma : '   + CONVERT(VARCHAR, @logicalCPUPerNuma) 
PRINT 'NoOfNUMA : '            + CONVERT(VARCHAR, @NoOfNUMA)
PRINT '---------------------------'
Print 'MAXDOP setting should be : ' + CONVERT(VARCHAR, @MaxDOP)



select @@SERVERNAME,
SERVERPROPERTY('ComputerNamePhysicalNetBIOS'),
cpu_count, 
hyperthread_ratio, 
softnuma_configuration, 
softnuma_configuration_desc, 
socket_count, 
numa_node_count 
from 
sys.dm_os_sys_info
