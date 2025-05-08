
USE [master]
GO

CREATE DATABASE [ClientDataMTIOTC_ss] ON
(  NAME     = N'ClientData'
 , FILENAME = N'M:\Data\ClientData_ss.mdf' )
AS SNAPSHOT OF [ClientDataMTIOTC]
GO


USE [master]
GO

/****** Object:  Database [MTIOTC]    Script Date: 7/29/2024 11:16:48 AM ******/
CREATE DATABASE [MTIOTC_ss] ON
(  NAME     = N'USFRET_Data'
 , FILENAME = N'M:\Data\USFRET_Data_ss.MDF' )
AS SNAPSHOT OF [MTIOTC]
GO

