replace view ${TdBenchDb}.DBQLogV_sum as
-- This query produces one row from DBQLogTbl data for each ParentQueryID (i.e. query)
-- Columns  without prefix represent data for the entire query
-- Columns starting with PC_  represents data from the Primary Cluster
-- Columns starting with CC_  represents data from the Compute Cluster
--
-- List of columns valid as of Lake release 20.00.13.43. 
-- WARNING: Column definitions ARE NOT dynamic across releases like other DBQL/Resuage views
--
SELECT parentqueryid 			                   AS ParentQueryID
--	'PQID='||(cast(parentqueryid as char(22)))                                AS ParentQueryID
       -- This format is used so ParentQueryID can be copied into Excel without losing trailing digits
       -- This is to overcome an Excel issue with numbers larger than 15 digits
-- CLusters involved in query processing            
      ,MAX(CASE WHEN CLUSTER_TYPE =  'pog' THEN ql.NumOfActiveAMPs   ELSE NULL END) AS PC_ActiveAMPs            
      ,MAX(CASE WHEN CLUSTER_TYPE <> 'pog' THEN ql.NumOfActiveAMPs   ELSE  0 END)   AS CC_ActiveAMPs  
      ,MAX(CASE WHEN CLUSTER_TYPE =  'pog' THEN ql.ComputeWorkerUsed ELSE NULL END) AS ComputeWorkerUsed
--
-- 'pog' literal MUST be lower case
      ,MAX(CASE WHEN (SUBSTRING(ql.PATH_COMPONENT_ID FROM 1 FOR 3) (NAMED CLUSTER_TYPE)) = 'pog'
                THEN STRTOK(ql.PATH_COMPONENT_ID,'_',01)
                ELSE NULL 
                 END)                                                            AS Primary_ID
      ,MAX(CASE WHEN CLUSTER_TYPE <> 'pog'
                THEN STRTOK(PATH_COMPONENT_ID,'_',04)
                ELSE NULL
                 END)                                                            AS Compute_ID
      ,MAX(CASE WHEN CLUSTER_TYPE <> 'pog'
                THEN STRTOK(PATH_COMPONENT_ID,'_',02)
                ELSE NULL
                 END)                                                            AS ComputeGroupUniqName
      ,MAX(CASE WHEN CLUSTER_TYPE <> 'pog'
                THEN STRTOK(PATH_COMPONENT_ID,'_',03)
                ELSE NULL
                 END)                                                            AS ComputeProfileUniqName
--
      ,COUNT(*)                                                                  AS DBQL_ROW_CNT
--
      ,cast(ql.PATH_YEAR as char(4)) as PATH_YEAR
      ,cast(ql.PATH_MONTH as char(2)) as PATH_MONTH
      ,cast(ql.PATH_DAY as char(2)) as PATH_DAY
      ,cast(ql.PATH_HOUR as char(2)) as PATH_HOUR
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.PATH_MINUTE                    ELSE NULL END) AS PATH_MINUTE
--
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.ProcID                           ELSE NULL END) AS ProcID
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.CollectTimeStamp                 ELSE NULL END) AS CollectTimeStamp
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.UserName                         ELSE NULL END) AS UserName
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.DefaultDatabase                  ELSE NULL END) AS DefaultDatabase      
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.AcctString                       ELSE NULL END) AS AcctString
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.ExpandAcctString                 ELSE NULL END) AS ExpandAcctString
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.SessionID                        ELSE NULL END) AS SessionID
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.LogicalHostID                    ELSE NULL END) AS LogicalHostID
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.RequestNum                       ELSE NULL END) AS RequestNum
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.InternalRequestNum               ELSE NULL END) AS InternalRequestNum
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.LogonDateTime                    ELSE NULL END) AS LogonDateTime
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.AcctStringTime                   ELSE NULL END) AS AcctStringTime
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.AcctStringHour                   ELSE NULL END) AS AcctStringHour
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.AcctStringDate                   ELSE NULL END) AS AcctStringDate
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.LogonSource                      ELSE NULL END) AS LogonSource
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN TRIM(ql.AppID)                      ELSE NULL END) AS AppID
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN TRIM(ql.ClientID)                   ELSE NULL END) AS ClientID
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN TRIM(ql.ClientAddr)                 ELSE NULL END) AS ClientAddr
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.QueryBand                        ELSE NULL END) AS QueryBand
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.ProfileID                        ELSE NULL END) AS ProfileID
--
--  Query Timings
--
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.DelayTime                        ELSE NULL END) AS DelayTime
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.StartTime                        ELSE NULL END) AS StartTime
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.FirstStepTime                    ELSE NULL END) AS FirstStepTime
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.FirstRespTime                    ELSE NULL END) AS FirstRespTime
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.TotalFirstRespTime               ELSE NULL END) AS TotalFirstRespTime
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.LastRespTime                     ELSE NULL END) AS LastRespTime
--
/*  optimizer gets confused on column references below and assumes something needs to be grouped
      ,((FirstRespTime - StartTime)     HOUR(4) TO SECOND)                              AS ElapsedTime
      ,((FirstStepTime - StartTime)     HOUR(4) TO SECOND)                              AS ParseTime
      ,((FirstRespTime - FirstStepTime) HOUR(4) TO SECOND)                              AS DBMSTime
--
      ,CAST((EXTRACT(HOUR   FROM ElapsedTime)*3600
            +EXTRACT(MINUTE FROM ElapsedTime)*60
            +EXTRACT(SECOND FROM ElapsedTime)) as DECIMAL(8,2))                             AS ElapsedTimeSecs  
      ,CAST((EXTRACT(HOUR   FROM ParseTime)*3600
            +EXTRACT(MINUTE FROM ParseTime)*60
            +EXTRACT(SECOND FROM ParseTime)) as DECIMAL(8,2))                               AS ParseTimeSecs              
      ,CAST((EXTRACT(HOUR   FROM DBMSTime)*3600
            +EXTRACT(MINUTE FROM DBMSTime)*60
            +EXTRACT(SECOND FROM DBMSTime)) as DECIMAL(8,2))                                AS DBMSTimeSecs  
--        
      ,MIN(CASE WHEN  CLUSTER_TYPE <> 'pog' THEN ql.StartTime                       ELSE NULL END) AS CC_StartTime
      ,MAX(CASE WHEN  CLUSTER_TYPE <> 'pog' THEN ql.FirstRespTime                   ELSE NULL END) AS CC_FirstRespTime
      ,((CC_FirstRespTime - CC_StartTime)      HOUR(4) TO SECOND)                               AS CC_ElapsedTime
--
*/
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.LastStateChange                  ELSE NULL END) AS LastStateChange
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' 
                 AND  ql.QueryText LIKE 'EXPLAIN%' THEN 'EXPLAIN'                   ELSE NULL END) AS StatementExplain
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.StatementGroup                   ELSE NULL END) AS StatementGroup
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.StatementType                    ELSE NULL END) AS StatementType
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.ErrorCode                        ELSE NULL END) AS ErrorCode
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.ErrorText                        ELSE NULL END) AS ErrorText
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.QueryText                        ELSE NULL END) AS QueryText
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.WarningOnly                      ELSE NULL END) AS WarningOnly
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.AbortFlag                        ELSE NULL END) AS AbortFlag
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.CacheFlag                        ELSE NULL END) AS CacheFlag
--
-- query plan details, totaled and broken out by cluster
--
      ,SUM(ql.NumSteps)                                                                            AS NumSteps
      ,MAX(CASE WHEN CLUSTER_TYPE =  'pog' THEN ql.NumSteps ELSE NULL END)                         AS PC_NumSteps
      ,SUM(CASE WHEN CLUSTER_TYPE <> 'pog' THEN ql.NumSteps ELSE NULL END)                         AS CC_NumSteps
--
      ,SUM(ql.NumStepswPar)                                                                        AS NumStepswPar
      ,MAX(CASE WHEN CLUSTER_TYPE =  'pog' THEN ql.NumStepswPar ELSE NULL END)                     AS PC_NumStepswPar
      ,SUM(CASE WHEN CLUSTER_TYPE <> 'pog' THEN ql.NumStepswPar ELSE NULL END)                     AS CC_NumStepswPar
--
      ,MAX(ql.MaxStepsInPar)                                                                       AS MaxStepsInPar
--
      ,SUM(ql.NumJoinSteps)                                                                        AS NumJoinSteps
      ,MAX(CASE WHEN CLUSTER_TYPE =  'pog' THEN ql.NumJoinSteps ELSE NULL END)                     AS PC_NumJoinSteps
      ,SUM(CASE WHEN CLUSTER_TYPE <> 'pog' THEN ql.NumJoinSteps ELSE NULL END)                     AS CC_NumJoinSteps
--
      ,SUM(ql.NumSumSteps)                                                                         AS NumSumSteps
      ,MAX(CASE WHEN CLUSTER_TYPE =  'pog' THEN ql.NumSumSteps ELSE NULL END)                      AS PC_NumSumSteps
      ,SUM(CASE WHEN CLUSTER_TYPE <> 'pog' THEN ql.NumSumSteps ELSE NULL END)                      AS CC_NumSumSteps
--
-- query result details 
--
      ,MAX(CASE WHEN CLUSTER_TYPE =  'pog' THEN ql.NumResultRows ELSE NULL END)                    AS NumResultRows
--
-- query resource consumption details, , totaled and broken out by cluster 
--
      ,SUM(CAST(ql.AMPCPUTime AS DECIMAL(11,2)))                                                    AS AMPCPUTime
      ,MAX(CASE WHEN CLUSTER_TYPE =  'pog' THEN CAST(ql.AMPCPUTime as decimal(11,2)) ELSE NULL END) AS PC_AMPCPUTime
      ,SUM(CASE WHEN CLUSTER_TYPE <> 'pog' THEN CAST(ql.AMPCPUTime as decimal(11,2)) ELSE NULL END) AS CC_AMPCPUTime
--
      ,MAX(CASE WHEN CLUSTER_TYPE =  'pog' THEN ql.NumOfActiveAMPs ELSE NULL END)                   AS PC_NumOfActiveAMPs
      ,MAX(CASE WHEN CLUSTER_TYPE =  'pog' THEN CAST(ql.MaxAMPCPUTime as decimal(11,2)) ELSE 0 END) AS PC_MaxAMPCPUTime
      ,PC_AMPCPUTIME/NULLIFZERO(PC_NumOfActiveAMPs)                                              AS PC_AvgAMPCPUTime
      ,PC_AvgAMPCPUTime/NULLIFZERO(PC_MaxAMPCPUTime)                                             AS PC_Parallelism
 --
      ,MAX(CASE WHEN CLUSTER_TYPE <> 'pog' THEN ql.NumOfActiveAMPs ELSE  0 END)                     AS CC_NumOfActiveAMPs
      ,MAX(CASE WHEN CLUSTER_TYPE <> 'pog' THEN CAST(ql.MaxAMPCPUTime as decimal(11,2)) ELSE 0 END) AS CC_MaxAMPCPUTime
      ,CC_AMPCPUTIME/NULLIFZERO(CC_NumOfActiveAMPs)                                              AS CC_AvgAMPCPUTime
      ,CC_AvgAMPCPUTime/NULLIFZERO(CC_MaxAMPCPUTime)                                             AS CC_Parallelism
--
      ,MAX(CASE WHEN CLUSTER_TYPE =  'pog' THEN CAST(ql.ParserCPUTime as decimal(11,2)) ELSE 0 END) AS PC_ParserCPUTime
      ,SUM(CASE WHEN CLUSTER_TYPE <> 'pog' THEN CAST(ql.ParserCPUTime as decimal(11,2)) ELSE 0 END) AS CC_ParserCPUTime
      ,SUM(ql.ParserCPUTime)                                                                     AS  ParserCPUTime
 --
      ,SUM(ql.TotalIOCount)                                                                        AS TotalIOCount
      ,MAX(CASE WHEN CLUSTER_TYPE =  'pog' THEN ql.TotalIOCount ELSE NULL END)                     AS PC_TotalIOCount
      ,SUM(CASE WHEN CLUSTER_TYPE <> 'pog' THEN ql.TotalIOCount ELSE NULL END)                     AS CC_TotalIOCount
--
      ,SUM(ql.ReqIOKB)                                                                            AS ReqIOKB
      ,MAX(CASE WHEN CLUSTER_TYPE =  'pog' THEN ql.ReqIOKB ELSE NULL END)                          AS PC_ReqIOKB
      ,SUM(CASE WHEN CLUSTER_TYPE <> 'pog' THEN ql.ReqIOKB ELSE NULL END)                          AS CC_ReqIOKB
--
      ,SUM(ql.ReqPhysIO)                                                                           AS ReqPhysIO
      ,MAX(CASE WHEN CLUSTER_TYPE =  'pog' THEN ql.ReqPhysIO ELSE NULL END)                        AS PC_ReqPhysIO
      ,SUM(CASE WHEN CLUSTER_TYPE <> 'pog' THEN ql.ReqPhysIO ELSE NULL END)                        AS CC_ReqPhysIO
--
      ,SUM(ql.ReqPhysIOKB)                                                                         AS ReqPhysIOKB
      ,MAX(CASE WHEN CLUSTER_TYPE =  'pog' THEN ql.ReqPhysIOKB ELSE NULL END)                      AS PC_ReqPhysIOKB
      ,SUM(CASE WHEN CLUSTER_TYPE <> 'pog' THEN ql.ReqPhysIOKB ELSE NULL END)                      AS CC_ReqPhysIOKB
--
      ,SUM(ql.SpoolUsage)                                                                          AS SpoolUsage 
      ,MAX(CASE WHEN CLUSTER_TYPE =  'pog' THEN ql.SpoolUsage ELSE NULL END)                       AS PC_SpoolUsage 
      ,SUM(CASE WHEN CLUSTER_TYPE <> 'pog' THEN ql.SpoolUsage ELSE NULL END)                       AS CC_SpoolUsage 
--
      ,SUM(ql.NosPhysWriteIO)                                                                      AS NosPhysWriteIO
      ,SUM(ql.NosPhysWriteIOKB)                                                                    AS NosPhysWriteIOKB
      ,SUM(ql.NosCacheReadIO)                                                                      AS NosCacheReadIO
      ,SUM(ql.NosCacheReadIOKB)                                                                    AS NosCacheReadIOKB
      ,SUM(ql.NosPhysDataReadIO)                                                                   AS NosPhysDataReadIO
      ,SUM(ql.NosPhysDataReadIOKB)                                                                 AS NosPhysDataReadIOKB
      ,SUM(ql.NosPrefetchReadIO)                                                                   AS NosPrefetchReadIO
      ,SUM(ql.NosPrefetchReadIOKB)                                                                 AS NosPrefetchReadIOKB
      ,SUM(ql.NosFilesWritten)                                                                     AS NosFilesWritten
      ,SUM(ql.NosFilesDeleted)                                                                     AS NosFilesDeleted
      ,SUM(ql.NosDeleteIO)                                                                         AS NosDeleteIO
      ,SUM(ql.NosDeleteIOKB)                                                                       AS NosDeleteIOKB
      ,SUM(ql.NosNumDeleteSuccess)                                                                 AS NosNumDeleteSuccess
      ,SUM(ql.NosNumDeleteFailure)                                                                 AS NosNumDeleteFailure
--
      ,SUM(ql.NosRecordsReturned)                                                                  AS NosRecordsReturned
      ,SUM(ql.NosRecordsSkipped)                                                                   AS NosRecordsSkipped
      ,SUM(ql.NosPhysReadIO)                                                                       AS NosPhysReadIO
      ,SUM(ql.NosPhysReadIOKB)                                                                     AS NosPhysReadIOKB
      ,SUM(ql.NosRecordsReturnedKB)                                                                AS NosRecordsReturnedKB
      ,SUM(ql.NosTotalIOWaitTime)                                                                  AS NosTotalIOWaitTime
      ,SUM(ql.NosMaxIOWaitTime)                                                                    AS NosMaxIOWaitTime
      ,SUM(ql.NosCPUTime)                                                                          AS NosCPUTime
      ,SUM(ql.NosTables)                                                                           AS NosTables
      ,SUM(ql.NosFiles)                                                                            AS NosFiles
      ,SUM(ql.NosFilesSkipped)                                                                     AS NosFilesSkipped
--
--NosSp Columns capture OFS Spool values
--
      ,SUM(ql.NosSpCIsReturned)                                                                    AS NosSpCIsReturned
      ,SUM(ql.NosSpCIsReturnedKB)                                                                  AS NosSpCIsReturnedKB
      ,SUM(ql.NosSpDBChunksReturned)                                                               AS NosSpDBChunksReturned
      ,SUM(ql.NosSpDBChunksReturnedKB)                                                             AS NosSpDBChunksReturnedKB
      ,SUM(ql.NosSpDBsReturned)                                                                    AS NosSpDBsReturned
      ,SUM(ql.NosSpDBsReturnedKB)                                                                  AS NosSpDBsReturnedKB
      ,SUM(ql.NosSpBlksFSGAcqs)                                                                    AS NosSpBlksFSGAcqs
      ,SUM(ql.NosSpBlksFSGAcqsKB)                                                                  AS NosSpBlksFSGAcqsKB
      ,SUM(ql.NosSpTablesRead)                                                                     AS NosSpTablesRead
      ,SUM(ql.NosSpCPUTime)                                                                        AS NosSpCPUTime
      ,SUM(ql.NosSpMaxIOWaitTime)                                                                  AS NosSpMaxIOWaitTime
      ,SUM(ql.NosSpTotalIOWaitTime)                                                                AS NosSpTotalIOWaitTime
      ,SUM(ql.NosSpTablesWritten)                                                                  AS NosSpTablesWritten
      ,SUM(ql.NosSpCIsWritten)                                                                     AS NosSpCIsWritten
      ,SUM(ql.NosSpCIsWrittenKB)                                                                   AS NosSpCIsWrittenKB
      ,SUM(ql.NosSpDBChunksWritten)                                                                AS NosSpDBChunksWritten
      ,SUM(ql.NosSpDBChunksWrittenKB)                                                              AS NosSpDBChunksWrittenKB
      ,SUM(ql.NosSpDBsWritten)                                                                     AS NosSpDBsWritten
      ,SUM(ql.NosSpDBsWrittenKB)                                                                   AS NosSpDBsWrittenKB
--
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.MaxCPUAmpNumber                  ELSE NULL END) AS MaxCPUAmpNumber
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.MinAmpCPUTime                    ELSE NULL END) AS MinAmpCPUTime
--   
      ,MAX(ql.MaxAMPIO)                                                                        AS MaxAmpIO
      ,MAX(CASE WHEN CLUSTER_TYPE =  'pog' THEN ql.MaxAMPIO ELSE NULL END)                     AS PC_MaxAMPIO
      ,MAX(CASE WHEN CLUSTER_TYPE <> 'pog' THEN ql.MaxAMPIO ELSE NULL END)                     AS CC_MaxAMPIO
  --    
      --,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.MaxAmpIO                         ELSE NULL END) AS MaxAmpIO
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.MaxIOAmpNumber                   ELSE NULL END) AS MaxIOAmpNumber
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.MinAmpIO                         ELSE NULL END) AS MinAmpIO
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.UtilityByteCount                 ELSE NULL END) AS UtilityByteCount
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.UtilityRowCount                  ELSE NULL END) AS UtilityRowCount
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.WDID                             ELSE NULL END) AS WDID
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.OpEnvID                          ELSE NULL END) AS OpEnvID
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.SysConID                         ELSE NULL END) AS SysConID
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.LSN                              ELSE NULL END) AS LSN
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.NoClassification                 ELSE NULL END) AS NoClassification
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.WDOverride                       ELSE NULL END) AS WDOverride
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.ResponseTimeMet                  ELSE NULL END) AS ResponseTimeMet
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.ExceptionValue                   ELSE NULL END) AS ExceptionValue
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.FinalWDID                        ELSE NULL END) AS FinalWDID
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.TDWMEstMaxRows                   ELSE NULL END) AS TDWMEstMaxRows
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.TDWMEstLastRows                  ELSE NULL END) AS TDWMEstLastRows
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.TDWMEstTotalTime                 ELSE NULL END) AS TDWMEstTotalTime
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.TDWMAllAmpFlag                   ELSE NULL END) AS TDWMAllAmpFlag
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.TDWMConfLevelUsed                ELSE NULL END) AS TDWMConfLevelUsed
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.TDWMRuleID                       ELSE NULL END) AS TDWMRuleID
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.UserID                           ELSE NULL END) AS UserID
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.ZoneId                           ELSE NULL END) AS ZoneId
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.AMPCPUTimeNorm                   ELSE NULL END) AS AMPCPUTimeNorm
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.ParserCPUTimeNorm                ELSE NULL END) AS ParserCPUTimeNorm
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.MaxAMPCPUTimeNorm                ELSE NULL END) AS MaxAMPCPUTimeNorm
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.MaxCPUAmpNumberNorm              ELSE NULL END) AS MaxCPUAmpNumberNorm
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.MinAmpCPUTimeNorm                ELSE NULL END) AS MinAmpCPUTimeNorm
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.EstResultRows                    ELSE NULL END) AS EstResultRows
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.EstProcTime                      ELSE NULL END) AS EstProcTime
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.EstMaxRowCount                   ELSE NULL END) AS EstMaxRowCount
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.ProxyUser                        ELSE NULL END) AS ProxyUser
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.ProxyRole                        ELSE NULL END) AS ProxyRole
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.SessionTemporalQualifier         ELSE NULL END) AS SessionTemporalQualifier
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.CalendarName                     ELSE NULL END) AS CalendarName
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.SessionWDID                      ELSE NULL END) AS SessionWDID
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.DataCollectAlg                   ELSE NULL END) AS DataCollectAlg
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.ParserExpReq                     ELSE NULL END) AS ParserExpReq
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.CallNestingLevel                 ELSE NULL END) AS CallNestingLevel
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.NumRequestCtx                    ELSE NULL END) AS NumRequestCtx
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.KeepFlag                         ELSE NULL END) AS KeepFlag
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.QueryRedriven                    ELSE NULL END) AS QueryRedriven
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.ReDriveKind                      ELSE NULL END) AS ReDriveKind
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.CPUDecayLevel                    ELSE NULL END) AS CPUDecayLevel
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.IODecayLevel                     ELSE NULL END) AS IODecayLevel
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.TacticalCPUException             ELSE NULL END) AS TacticalCPUException
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.TacticalIOException              ELSE NULL END) AS TacticalIOException
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.SeqRespTime                      ELSE NULL END) AS SeqRespTime
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.NumFragments                     ELSE NULL END) AS NumFragments
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.CheckpointNum                    ELSE NULL END) AS CheckpointNum
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.UnityTime                        ELSE NULL END) AS UnityTime
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.LockDelay                        ELSE NULL END) AS LockDelay
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.DisCPUTime                       ELSE NULL END) AS DisCPUTime
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.Statements                       ELSE NULL END) AS Statements
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.DisCPUTimeNorm                   ELSE NULL END) AS DisCPUTimeNorm
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.TxnMode                          ELSE NULL END) AS TxnMode
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.RequestMode                      ELSE NULL END) AS RequestMode
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.UtilityInfoAvailable             ELSE NULL END) AS UtilityInfoAvailable
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.UnitySQL                         ELSE NULL END) AS UnitySQL
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.ThrottleBypassed                 ELSE NULL END) AS ThrottleBypassed
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.DBQLStatus                       ELSE NULL END) AS DBQLStatus
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.IterationCount                   ELSE NULL END) AS IterationCount
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.VHLogicalIO                      ELSE NULL END) AS VHLogicalIO
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.VHPhysIO                         ELSE NULL END) AS VHPhysIO
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.VHLogicalIOKB                    ELSE NULL END) AS VHLogicalIOKB
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.VHPhysIOKB                       ELSE NULL END) AS VHPhysIOKB
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.TDWMEstMemUsage                  ELSE NULL END) AS TDWMEstMemUsage
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.MaxStepMemory                    ELSE NULL END) AS MaxStepMemory
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.TotalServerByteCount             ELSE NULL END) AS TotalServerByteCount
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.ProxyUserID                      ELSE NULL END) AS ProxyUserID
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.TxnUniq                          ELSE NULL END) AS TxnUniq
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.LockLevel                        ELSE NULL END) AS LockLevel
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.TTGranularity                    ELSE NULL END) AS TTGranularity
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.ProfileName                      ELSE NULL END) AS ProfileName
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.WDName                           ELSE NULL END) AS WDName
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.FlexThrottle                     ELSE NULL END) AS FlexThrottle
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.EstMaxStepTime                   ELSE NULL END) AS EstMaxStepTime
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.ParamQuery                       ELSE NULL END) AS ParamQuery
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.RemoteQuery                      ELSE NULL END) AS RemoteQuery
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.PersistentSpool                  ELSE NULL END) AS PersistentSpool
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.MinRespHoldTime                  ELSE NULL END) AS MinRespHoldTime
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.MaxOneMBRowSize                  ELSE NULL END) AS MaxOneMBRowSize
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.NumResultOneMBRows               ELSE NULL END) AS NumResultOneMBRows
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.MaxNumMapAMPs                    ELSE NULL END) AS MaxNumMapAMPs
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.MinNumMapAMPs                    ELSE NULL END) AS MinNumMapAMPs
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.SysDefNumMapAMPs                 ELSE NULL END) AS SysDefNumMapAMPs
--      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.FeatureUsage                   ELSE NULL END) AS FeatureUsage
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.ReqMaxSpool                      ELSE NULL END) AS ReqMaxSpool
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.NumAmpsImpacted                  ELSE NULL END) AS NumAmpsImpacted
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.UsedIota                         ELSE NULL END) AS UsedIota
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.OpEnvName                        ELSE NULL END) AS OpEnvName
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.SysConName                       ELSE NULL END) AS SysConName
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.FinalWDName                      ELSE NULL END) AS FinalWDName
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.SessionWDName                    ELSE NULL END) AS SessionWDName
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.MaxAmpsMapNo                     ELSE NULL END) AS MaxAmpsMapNo
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.AutoDBAData                      ELSE NULL END) AS AutoDBAData
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.UAFName                          ELSE NULL END) AS UAFName
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.UnityQueryType                   ELSE NULL END) AS UnityQueryType
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.TacticalRequest                  ELSE NULL END) AS TacticalRequest
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.DefaultDBCacheUsed               ELSE NULL END) AS DefaultDBCacheUsed
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.ReqAWTTime                       ELSE NULL END) AS ReqAWTTime
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.MaxReqAwtTime                    ELSE NULL END) AS MaxReqAwtTime
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.MaxReqAWTTimeAmpNum              ELSE NULL END) AS MaxReqAWTTimeAmpNum
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.MinReqAWTTime                    ELSE NULL END) AS MinReqAWTTime
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.UDFVMData                        ELSE NULL END) AS UDFVMData
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.UDFVMPeak                        ELSE NULL END) AS UDFVMPeak
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.TotalUDFMemUsage                 ELSE NULL END) AS TotalUDFMemUsage
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.MaxReqUDFMemUsage                ELSE NULL END) AS MaxReqUDFMemUsage
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.MaxReqUDFMemUsageAmpNum          ELSE NULL END) AS MaxReqUDFMemUsageAmpNum
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.PGRCTimeToGetPlan                ELSE NULL END) AS PGRCTimeToGetPlan
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.StepCacheHash                    ELSE NULL END) AS StepCacheHash
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.TDWMMSRCount                     ELSE NULL END) AS TDWMMSRCount
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.DeferTime                        ELSE NULL END) AS DeferTime
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.DeferRuleID                      ELSE NULL END) AS DeferRuleID
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.TDWMAdmissionTime                ELSE NULL END) AS TDWMAdmissionTime
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.StmtDMLRowCount                  ELSE NULL END) AS StmtDMLRowCount
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.UnityQueryForeignInfo            ELSE NULL END) AS UnityQueryForeignInfo
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.PGRCTgtPENum                     ELSE NULL END) AS PGRCTgtPENum
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.ReqLocSpoolUsage                 ELSE NULL END) AS ReqLocSpoolUsage
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.ReqPhysLocIO                     ELSE NULL END) AS ReqPhysLocIO
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.ReqPhysLocIOKB                   ELSE NULL END) AS ReqPhysLocIOKB
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.ReqPeakAmpPrvMem                 ELSE NULL END) AS ReqPeakAmpPrvMem
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.ReqPeakAmpPrvMemAmpNum           ELSE NULL END) AS ReqPeakAmpPrvMemAmpNum
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.ReqPeakAmpShrMem                 ELSE NULL END) AS ReqPeakAmpShrMem
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.ReqPeakAmpShrMemAmpNum           ELSE NULL END) AS ReqPeakAmpShrMemAmpNum
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.TDWMEstMemResLimit               ELSE NULL END) AS TDWMEstMemResLimit
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.MaxPSFWDID                       ELSE NULL END) AS MaxPSFWDID
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.MaxPSFWDIDAmpNum                 ELSE NULL END) AS MaxPSFWDIDAmpNum
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.HPTotalPipelines                 ELSE NULL END) AS HPTotalPipelines
      ,MAX(CASE WHEN  CLUSTER_TYPE = 'pog' THEN ql.HPMaxPipelines                   ELSE NULL END) AS HPMaxPipelines
--
  FROM TD_METRIC_SVC.DBQLOGV ql
--
-- use the path_xxxx columns to filter out DBQL rows using path filtering for performance
--
WHERE --PATH_YEAR = '2023'
   --AND PATH_MONTH = '03'
   --AND PATH_DAY   = '07'
--
--  use the following selection criteria to filter out primary and compute cluster DBQLogTbl rows not speifically related to a query.
--
   --AND
   (
        (CLUSTER_TYPE  = 'pog' AND ql.USERNAME NOT LIKE 'TDAAS%' AND ql.USERNAME <> 'TDWM') --Selects all query-related Primary Cluster rows
     OR (CLUSTER_TYPE <> 'pog' AND PARENTQUERYID <> QUERYID)                          --Selects all query-related Compute Cluster rows
       )
--
  GROUP BY ParentQueryID, PATH_YEAR, PATH_MONTH, PATH_DAY, PATH_HOUR;
