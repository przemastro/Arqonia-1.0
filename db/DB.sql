USE [master]
GO
/****** Object:  Database [Astro]    Script Date: 27.11.2016 12:45:40 ******/
CREATE DATABASE [Astro]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'Astro', FILENAME = N'c:\Program Files\Microsoft SQL Server\MSSQL11.SQLEXPRESS\MSSQL\DATA\Astro.mdf' , SIZE = 2114560KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB )
 LOG ON 
( NAME = N'Astro_log', FILENAME = N'c:\Program Files\Microsoft SQL Server\MSSQL11.SQLEXPRESS\MSSQL\DATA\Astro_log.ldf' , SIZE = 2895104KB , MAXSIZE = 2048GB , FILEGROWTH = 10%)
GO
ALTER DATABASE [Astro] SET COMPATIBILITY_LEVEL = 110
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [Astro].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [Astro] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [Astro] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [Astro] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [Astro] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [Astro] SET ARITHABORT OFF 
GO
ALTER DATABASE [Astro] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [Astro] SET AUTO_CREATE_STATISTICS ON 
GO
ALTER DATABASE [Astro] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [Astro] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [Astro] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [Astro] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [Astro] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [Astro] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [Astro] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [Astro] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [Astro] SET  DISABLE_BROKER 
GO
ALTER DATABASE [Astro] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [Astro] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [Astro] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [Astro] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [Astro] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [Astro] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [Astro] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [Astro] SET RECOVERY SIMPLE 
GO
ALTER DATABASE [Astro] SET  MULTI_USER 
GO
ALTER DATABASE [Astro] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [Astro] SET DB_CHAINING OFF 
GO
ALTER DATABASE [Astro] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [Astro] SET TARGET_RECOVERY_TIME = 0 SECONDS 
GO
USE [Astro]
GO
/****** Object:  Schema [bi]    Script Date: 27.11.2016 12:45:41 ******/
CREATE SCHEMA [bi]
GO
/****** Object:  Schema [data]    Script Date: 27.11.2016 12:45:41 ******/
CREATE SCHEMA [data]
GO
/****** Object:  Schema [dic]    Script Date: 27.11.2016 12:45:41 ******/
CREATE SCHEMA [dic]
GO
/****** Object:  Schema [log]    Script Date: 27.11.2016 12:45:41 ******/
CREATE SCHEMA [log]
GO
/****** Object:  Schema [stg]    Script Date: 27.11.2016 12:45:41 ******/
CREATE SCHEMA [stg]
GO
/****** Object:  Schema [test]    Script Date: 27.11.2016 12:45:41 ******/
CREATE SCHEMA [test]
GO
/****** Object:  Schema [util]    Script Date: 27.11.2016 12:45:41 ******/
CREATE SCHEMA [util]
GO
/****** Object:  StoredProcedure [bi].[observationsDelta]    Script Date: 27.11.2016 12:45:41 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO


CREATE PROCEDURE [bi].[observationsDelta]
  
   @observationId varchar(50) = NULL
  
AS
BEGIN

   SET NOCOUNT ON;


--set id
   Declare @i int
   Declare @query nvarchar(max)
   Declare @deltaColumn varchar(50)
   Declare @stagingColumn varchar(50)
   Declare @photometryTable varchar (100)
   Declare @deltaColumnId nvarchar(max)
   Declare @ProcName varchar(100) = '[bi].[observationsDelta]'
   Declare @ProcMessage varchar(100)
   Declare @status varchar(10)
   Declare @active int


   set @ProcMessage = 'EXEC ' + @ProcName + ' ,@observationId=' + coalesce(convert(varchar(50),@observationId),'NULL')
   Insert INTO [log].[log](CreateDate, LogCategory, LogObject, Message, ObservationId) values(getDate(), 'PROC.BEGIN', @ProcName, @ProcMessage, @observationId)
   



--uPhotometry table
 set @ProcMessage = 'Populate bi.uPhotometry table'
 Insert INTO [log].[log](CreateDate, LogCategory, LogObject, Message, ObservationId) values(getDate(), NULL, @ProcName, @ProcMessage, @observationId)
   
 set @deltaColumn = (select DeltaColumnId from util.metadataComparison where id=1)
 set @photometryTable = (select PhotometryTable from util.metadataComparison where id=1)
 set @query = ('select top 1 @deltaColumnId='+@deltaColumn +' from '+@photometryTable+' alias order by '+ @deltaColumn +' desc')
 
 print @query
 
 exec sp_executesql @query, @Params = N'@deltaColumnId varchar(50) output', @deltaColumnId = @deltaColumnId output
 
 if ((@deltaColumnId) = null)
   begin
   set @i = 1
   end
 else
   begin
   set @i = (@deltaColumnId) + 1
   end


 Declare @uPhotometry varchar(50)
 DECLARE insert_cursor CURSOR FOR (select uPhotometry from stg.stagingObservations where Active=1 except select uPhotometry from bi.uPhotometry)

 OPEN insert_cursor
 FETCH NEXT FROM insert_cursor into @uPhotometry

 WHILE @@FETCH_STATUS=0
   BEGIN
   Insert into bi.uPhotometry (uPhotometryId, uPhotometry) SELECT @i, @uPhotometry
   FETCH NEXT FROM insert_cursor into @uPhotometry
   set @i=@i+1
   END
 close insert_cursor
 Deallocate insert_cursor
 

--vPhotometry table
 set @ProcMessage = 'Populate bi.vPhotometry table'
 Insert INTO [log].[log](CreateDate, LogCategory, LogObject, Message, ObservationId) values(getDate(), NULL, @ProcName, @ProcMessage, @observationId)
   
 set @deltaColumn = (select DeltaColumnId from util.metadataComparison where id=2)
 set @photometryTable = (select PhotometryTable from util.metadataComparison where id=2)
 set @query = ('select top 1 @deltaColumnId='+@deltaColumn +' from '+@photometryTable+' alias order by '+ @deltaColumn +' desc')
 
 print @query
 
 exec sp_executesql @query, @Params = N'@deltaColumnId varchar(50) output', @deltaColumnId = @deltaColumnId output
 
 if ((@deltaColumnId) = null)
   begin
   set @i = 1
   end
 else
   begin
   set @i = (@deltaColumnId) + 1
   end


 Declare @vPhotometry varchar(50)
 DECLARE insert_cursor CURSOR FOR (select vPhotometry from stg.stagingObservations where Active=1 except select vPhotometry from bi.vPhotometry)

 OPEN insert_cursor
 FETCH NEXT FROM insert_cursor into @vPhotometry

 WHILE @@FETCH_STATUS=0
   BEGIN
   Insert into bi.vPhotometry (vPhotometryId, vPhotometry) SELECT @i, @vPhotometry
   FETCH NEXT FROM insert_cursor into @vPhotometry
   set @i=@i+1
   END
 close insert_cursor
 Deallocate insert_cursor



 --bPhotometry table
 set @ProcMessage = 'Populate bi.bPhotometry table'
 Insert INTO [log].[log](CreateDate, LogCategory, LogObject, Message, ObservationId) values(getDate(), NULL, @ProcName, @ProcMessage, @observationId)
   
 set @deltaColumn = (select DeltaColumnId from util.metadataComparison where id=3)
 set @photometryTable = (select PhotometryTable from util.metadataComparison where id=3)
 set @query = ('select top 1 @deltaColumnId='+@deltaColumn +' from '+@photometryTable+' alias order by '+ @deltaColumn +' desc')
 
 print @query
 
 exec sp_executesql @query, @Params = N'@deltaColumnId varchar(50) output', @deltaColumnId = @deltaColumnId output
 
 if ((@deltaColumnId) = null)
   begin
   set @i = 1
   end
 else
   begin
   set @i = (@deltaColumnId) + 1
   end


 Declare @bPhotometry varchar(50)
 DECLARE insert_cursor CURSOR FOR (select bPhotometry from stg.stagingObservations where Active=1 except select bPhotometry from bi.bPhotometry)

 OPEN insert_cursor
 FETCH NEXT FROM insert_cursor into @bPhotometry

 WHILE @@FETCH_STATUS=0
   BEGIN
   Insert into bi.bPhotometry (bPhotometryId, bPhotometry) SELECT @i, @bPhotometry
   FETCH NEXT FROM insert_cursor into @bPhotometry
   set @i=@i+1
   END
 close insert_cursor
 Deallocate insert_cursor


 --rPhotometry table
 set @ProcMessage = 'Populate bi.rPhotometry table'
 Insert INTO [log].[log](CreateDate, LogCategory, LogObject, Message, ObservationId) values(getDate(), NULL, @ProcName, @ProcMessage, @observationId)
   
 set @deltaColumn = (select DeltaColumnId from util.metadataComparison where id=4)
 set @photometryTable = (select PhotometryTable from util.metadataComparison where id=4)
 set @query = ('select top 1 @deltaColumnId='+@deltaColumn +' from '+@photometryTable+' alias order by '+ @deltaColumn +' desc')
 
 print @query
 
 exec sp_executesql @query, @Params = N'@deltaColumnId varchar(50) output', @deltaColumnId = @deltaColumnId output
 
 if ((@deltaColumnId) = null)
   begin
   set @i = 1
   end
 else
   begin
   set @i = (@deltaColumnId) + 1
   end


 Declare @rPhotometry varchar(50)
 DECLARE insert_cursor CURSOR FOR (select rPhotometry from stg.stagingObservations where Active=1 except select rPhotometry from bi.rPhotometry)

 OPEN insert_cursor
 FETCH NEXT FROM insert_cursor into @rPhotometry

 WHILE @@FETCH_STATUS=0
   BEGIN
   Insert into bi.rPhotometry (rPhotometryId, rPhotometry) SELECT @i, @rPhotometry
   FETCH NEXT FROM insert_cursor into @rPhotometry
   set @i=@i+1
   END
 close insert_cursor
 Deallocate insert_cursor


 --iPhotometry table
 set @ProcMessage = 'Populate bi.iPhotometry table'
 Insert INTO [log].[log](CreateDate, LogCategory, LogObject, Message, ObservationId) values(getDate(), NULL, @ProcName, @ProcMessage, @observationId)
   
 set @deltaColumn = (select DeltaColumnId from util.metadataComparison where id=5)
 set @photometryTable = (select PhotometryTable from util.metadataComparison where id=5)
 set @query = ('select top 1 @deltaColumnId='+@deltaColumn +' from '+@photometryTable+' alias order by '+ @deltaColumn +' desc')
 
 print @query
 
 exec sp_executesql @query, @Params = N'@deltaColumnId varchar(50) output', @deltaColumnId = @deltaColumnId output
 
 if ((@deltaColumnId) = null)
   begin
   set @i = 1
   end
 else
   begin
   set @i = (@deltaColumnId) + 1
   end


 Declare @iPhotometry varchar(50)
 DECLARE insert_cursor CURSOR FOR (select iPhotometry from stg.stagingObservations where Active=1 except select iPhotometry from bi.iPhotometry)

 OPEN insert_cursor
 FETCH NEXT FROM insert_cursor into @iPhotometry

 WHILE @@FETCH_STATUS=0
   BEGIN
   Insert into bi.iPhotometry (iPhotometryId, iPhotometry) SELECT @i, @iPhotometry
   FETCH NEXT FROM insert_cursor into @iPhotometry
   set @i=@i+1
   END
 close insert_cursor
 Deallocate insert_cursor

 
--uPhotometryTime table
 set @ProcMessage = 'Populate bi.uPhotometryTime table'
 Insert INTO [log].[log](CreateDate, LogCategory, LogObject, Message, ObservationId) values(getDate(), NULL, @ProcName, @ProcMessage, @observationId)
   

 set @deltaColumn = (select DeltaColumnId from util.metadataComparison where id=6)
 set @photometryTable = (select PhotometryTable from util.metadataComparison where id=6)
 set @query = ('select top 1 @deltaColumnId='+@deltaColumn +' from '+@photometryTable+' alias order by '+ @deltaColumn +' desc')
 
 print @query
 
 exec sp_executesql @query, @Params = N'@deltaColumnId varchar(50) output', @deltaColumnId = @deltaColumnId output
 
 if ((@deltaColumnId) = null)
   begin
   set @i = 1
   end
 else
   begin
   set @i = (@deltaColumnId) + 1
   end


 Declare @uPhotometryTime varchar(50)
 DECLARE insert_cursor CURSOR FOR (select uPhotometryTime from stg.stagingObservations where Active=1 except select uPhotometryTime from bi.uPhotometryTime)

 OPEN insert_cursor
 FETCH NEXT FROM insert_cursor into @uPhotometryTime

 WHILE @@FETCH_STATUS=0
   BEGIN
   Insert into bi.uPhotometryTime (uPhotometryTimeId, uPhotometryTime) SELECT @i, @uPhotometryTime
   FETCH NEXT FROM insert_cursor into @uPhotometryTime
   set @i=@i+1
   END
 close insert_cursor
 Deallocate insert_cursor


 --vPhotometryTime table
 set @ProcMessage = 'Populate bi.vPhotometryTime table'
 Insert INTO [log].[log](CreateDate, LogCategory, LogObject, Message, ObservationId) values(getDate(), NULL, @ProcName, @ProcMessage, @observationId)
   
 set @deltaColumn = (select DeltaColumnId from util.metadataComparison where id=7)
 set @photometryTable = (select PhotometryTable from util.metadataComparison where id=7)
 set @query = ('select top 1 @deltaColumnId='+@deltaColumn +' from '+@photometryTable+' alias order by '+ @deltaColumn +' desc')
 
 print @query
 
 exec sp_executesql @query, @Params = N'@deltaColumnId varchar(50) output', @deltaColumnId = @deltaColumnId output
 
 if ((@deltaColumnId) = null)
   begin
   set @i = 1
   end
 else
   begin
   set @i = (@deltaColumnId) + 1
   end


 Declare @vPhotometryTime varchar(50)
 DECLARE insert_cursor CURSOR FOR (select vPhotometryTime from stg.stagingObservations where Active=1 except select vPhotometryTime from bi.vPhotometryTime)

 OPEN insert_cursor
 FETCH NEXT FROM insert_cursor into @vPhotometryTime

 WHILE @@FETCH_STATUS=0
   BEGIN
   Insert into bi.vPhotometryTime (vPhotometryTimeId, vPhotometryTime) SELECT @i, @vPhotometryTime
   FETCH NEXT FROM insert_cursor into @vPhotometryTime
   set @i=@i+1
   END
 close insert_cursor
 Deallocate insert_cursor


 --bPhotometryTime table
 set @ProcMessage = 'Populate bi.bPhotometryTime table'
 Insert INTO [log].[log](CreateDate, LogCategory, LogObject, Message, ObservationId) values(getDate(), NULL, @ProcName, @ProcMessage, @observationId)
   
 set @deltaColumn = (select DeltaColumnId from util.metadataComparison where id=8)
 set @photometryTable = (select PhotometryTable from util.metadataComparison where id=8)
 set @query = ('select top 1 @deltaColumnId='+@deltaColumn +' from '+@photometryTable+' alias order by '+ @deltaColumn +' desc')
 
 print @query
 
 exec sp_executesql @query, @Params = N'@deltaColumnId varchar(50) output', @deltaColumnId = @deltaColumnId output
 
 if ((@deltaColumnId) = null)
   begin
   set @i = 1
   end
 else
   begin
   set @i = (@deltaColumnId) + 1
   end


 Declare @bPhotometryTime varchar(50)
 DECLARE insert_cursor CURSOR FOR (select bPhotometryTime from stg.stagingObservations where Active=1 except select bPhotometryTime from bi.bPhotometryTime)

 OPEN insert_cursor
 FETCH NEXT FROM insert_cursor into @bPhotometryTime

 WHILE @@FETCH_STATUS=0
   BEGIN
   Insert into bi.bPhotometryTime (bPhotometryTimeId, bPhotometryTime) SELECT @i, @bPhotometryTime
   FETCH NEXT FROM insert_cursor into @bPhotometryTime
   set @i=@i+1
   END
 close insert_cursor
 Deallocate insert_cursor


 --rPhotometryTime table
 set @ProcMessage = 'Populate bi.rPhotometryTime table'
 Insert INTO [log].[log](CreateDate, LogCategory, LogObject, Message, ObservationId) values(getDate(), NULL, @ProcName, @ProcMessage, @observationId)
   
 set @deltaColumn = (select DeltaColumnId from util.metadataComparison where id=9)
 set @photometryTable = (select PhotometryTable from util.metadataComparison where id=9)
 set @query = ('select top 1 @deltaColumnId='+@deltaColumn +' from '+@photometryTable+' alias order by '+ @deltaColumn +' desc')
 
 print @query
 
 exec sp_executesql @query, @Params = N'@deltaColumnId varchar(50) output', @deltaColumnId = @deltaColumnId output
 
 if ((@deltaColumnId) = null)
   begin
   set @i = 1
   end
 else
   begin
   set @i = (@deltaColumnId) + 1
   end


 Declare @rPhotometryTime varchar(50)
 DECLARE insert_cursor CURSOR FOR (select rPhotometryTime from stg.stagingObservations where Active=1 except select rPhotometryTime from bi.rPhotometryTime)

 OPEN insert_cursor
 FETCH NEXT FROM insert_cursor into @rPhotometryTime

 WHILE @@FETCH_STATUS=0
   BEGIN
   Insert into bi.rPhotometryTime (rPhotometryTimeId, rPhotometryTime) SELECT @i, @rPhotometryTime
   FETCH NEXT FROM insert_cursor into @rPhotometryTime
   set @i=@i+1
   END
 close insert_cursor
 Deallocate insert_cursor


 --iPhotometryTime table
 set @ProcMessage = 'Populate bi.iPhotometryTime table'
 Insert INTO [log].[log](CreateDate, LogCategory, LogObject, Message, ObservationId) values(getDate(), NULL, @ProcName, @ProcMessage, @observationId)
   
 set @deltaColumn = (select DeltaColumnId from util.metadataComparison where id=10)
 set @photometryTable = (select PhotometryTable from util.metadataComparison where id=10)
 set @query = ('select top 1 @deltaColumnId='+@deltaColumn +' from '+@photometryTable+' alias order by '+ @deltaColumn +' desc')
 
 print @query
 
 exec sp_executesql @query, @Params = N'@deltaColumnId varchar(50) output', @deltaColumnId = @deltaColumnId output
 
 if ((@deltaColumnId) = null)
   begin
   set @i = 1
   end
 else
   begin
   set @i = (@deltaColumnId) + 1
   end


 Declare @iPhotometryTime varchar(50)
 DECLARE insert_cursor CURSOR FOR (select iPhotometryTime from stg.stagingObservations where Active=1 except select iPhotometryTime from bi.iPhotometryTime)

 OPEN insert_cursor
 FETCH NEXT FROM insert_cursor into @iPhotometryTime

 WHILE @@FETCH_STATUS=0
   BEGIN
   Insert into bi.iPhotometryTime (iPhotometryTimeId, iPhotometryTime) SELECT @i, @iPhotometryTime
   FETCH NEXT FROM insert_cursor into @iPhotometryTime
   set @i=@i+1
   END
 close insert_cursor
 Deallocate insert_cursor


--bi.observations table population
 set @ProcMessage = 'Populate bi.observations table'
 Insert INTO [log].[log](CreateDate, LogCategory, LogObject, Message, ObservationId) values(getDate(), NULL, @ProcName, @ProcMessage, @observationId)
   
 --firstly delete updated records
 delete ob from bi.observations ob join stg.stagingObservations so on so.id=ob.id where ob.id=@observationId and so.status='new'


 insert into bi.observations select so.id, so.RowId, so.ObjectName, so.ObjectType, so.StartDate, so.EndDate, uph.uPhotometryId, upht.uPhotometryTimeId,
                                     vph.vPhotometryId, vpht.vPhotometryTimeId, bph.bPhotometryId, bpht.bPhotometryTimeId,
									 rph.rPhotometryId, rpht.rPhotometryTimeId, iph.iPhotometryId, ipht.iPhotometryTimeId, so.Verified, so.OwnerId
 from stg.stagingObservations so
                               left join bi.uPhotometry uph on uph.uPhotometry=so.uPhotometry
                               left join bi.vPhotometry vph on vph.vPhotometry=so.vPhotometry
                               left join bi.bPhotometry bph on bph.bPhotometry=so.bPhotometry
							   left join bi.rPhotometry rph on rph.rPhotometry=so.rPhotometry
							   left join bi.iPhotometry iph on iph.iPhotometry=so.iPhotometry
                               left join bi.uPhotometryTime upht on upht.uPhotometryTime=so.uPhotometryTime
                               left join bi.vPhotometryTime vpht on vpht.vPhotometryTime=so.vPhotometryTime
                               left join bi.bPhotometryTime bpht on bpht.bPhotometryTime=so.bPhotometryTime
                               left join bi.rPhotometryTime rpht on rpht.rPhotometryTime=so.rPhotometryTime
                               left join bi.iPhotometryTime ipht on ipht.iPhotometryTime=so.iPhotometryTime
                               where so.id=@observationId and status='new' and active=1


--delete inactive records from delta
 set @query = ('set @status = (select distinct(status) from stg.stagingObservations where id='+@observationId+')')
 print @query
 exec sp_executesql @query, @Params = N'@status varchar(50) output', @status = @status output

 set @query = ('set @active = (select distinct(active) from stg.stagingObservations where id='+@observationId+')')
 print @query
 exec sp_executesql @query, @Params = N'@active varchar(50) output', @active = @active output

 print @active
 print @status

  if((@status='deleted') and (@active=1))
     begin
	 set @ProcMessage = 'Delete inactive rows from bi.observations table'
     Insert INTO [log].[log](CreateDate, LogCategory, LogObject, Message, ObservationId) values(getDate(), NULL, @ProcName, @ProcMessage, @observationId)
     delete from bi.observations where id=@observationId
	 update stg.stagingObservations set active=0 where id=@observationId
	 end

--update stg.stagingObservations table
 set @ProcMessage = 'Update stg.stagingObservations table'
 Insert INTO [log].[log](CreateDate, LogCategory, LogObject, Message, ObservationId, LastLoad) values(getDate(), NULL, @ProcName, @ProcMessage, @observationId, null)
      
 update stg.stagingObservations set status='old' where id=@observationId

--calculate BV Difference
 set @ProcMessage = 'Calculate BV difference of average values'
 Insert INTO [log].[log](CreateDate, LogCategory, LogObject, Message, ObservationId, LastLoad) values(getDate(), NULL, @ProcName, @ProcMessage, @observationId, null)

  if(((select top 1 bPhotometryId from bi.observations where id=@observationId) IS NULL) or ((select top 1 vPhotometryId from bi.observations where id=@observationId) is null))
    begin
	print 'NO BV HR-Diagram processing for observation = '+@observationId
	delete from bi.bvDiagram
    insert into bi.bvDiagram select cast((avg(cast(cast(rtrim(ltrim(bp.bPhotometry)) as varchar(10)) as decimal(18,10))) - avg(cast(cast(rtrim(ltrim(vp.vPhotometry)) as varchar(10)) as decimal(18,10)))) as varchar) as 'BVDifference', bp.ObjectName
    from bi.bPhotometrySorted bp 
	join bi.vPhotometrySorted vp on vp.ObjectName=bp.ObjectName
	join bi.observations ob on bp.ObjectName=ob.ObjectName
	where ob.ObjectType='Star' and ob.Verified=1
    group by bp.ObjectName
	end
  else
	begin
    delete from bi.bvDiagram
    insert into bi.bvDiagram select cast((avg(cast(cast(rtrim(ltrim(bp.bPhotometry)) as varchar(10)) as decimal(18,10))) - avg(cast(cast(rtrim(ltrim(vp.vPhotometry)) as varchar(10)) as decimal(18,10)))) as varchar) as 'BVDifference', bp.ObjectName
    from bi.bPhotometrySorted bp 
	join bi.vPhotometrySorted vp on vp.ObjectName=bp.ObjectName
	join bi.observations ob on bp.ObjectName=ob.ObjectName
	where ob.ObjectType='Star' and ob.Verified=1
    group by bp.ObjectName
	end

--calculate UB Difference
 set @ProcMessage = 'Calculate UB difference of average values'
 Insert INTO [log].[log](CreateDate, LogCategory, LogObject, Message, ObservationId, LastLoad) values(getDate(), NULL, @ProcName, @ProcMessage, @observationId, null)

  if(((select top 1 uPhotometryId from bi.observations where id=@observationId) IS NULL) or ((select top 1 bPhotometryId from bi.observations where id=@observationId) is null))
    begin
	print 'NO UB HR-Diagram processing for observation = '+@observationId
	delete from bi.ubDiagram
    insert into bi.ubDiagram select cast((avg(cast(cast(rtrim(ltrim(bp.uPhotometry)) as varchar(10)) as decimal(18,10))) - avg(cast(cast(rtrim(ltrim(vp.bPhotometry)) as varchar(10)) as decimal(18,10)))) as varchar) as 'UBDifference', bp.ObjectName
    from bi.uPhotometrySorted bp 
	join bi.bPhotometrySorted vp on vp.ObjectName=bp.ObjectName
	join bi.observations ob on bp.ObjectName=ob.ObjectName
	where ob.ObjectType='Star' and ob.Verified=1
    group by bp.ObjectName
	end
  else
	begin
    delete from bi.ubDiagram
    insert into bi.ubDiagram select cast((avg(cast(cast(rtrim(ltrim(bp.uPhotometry)) as varchar(10)) as decimal(18,10))) - avg(cast(cast(rtrim(ltrim(vp.bPhotometry)) as varchar(10)) as decimal(18,10)))) as varchar) as 'UBDifference', bp.ObjectName
    from bi.uPhotometrySorted bp 
	join bi.bPhotometrySorted vp on vp.ObjectName=bp.ObjectName
	join bi.observations ob on bp.ObjectName=ob.ObjectName
	where ob.ObjectType='Star' and ob.Verified=1
    group by bp.ObjectName
	end


--calculate VI Difference
 set @ProcMessage = 'Calculate VI difference of average values'
 Insert INTO [log].[log](CreateDate, LogCategory, LogObject, Message, ObservationId, LastLoad) values(getDate(), NULL, @ProcName, @ProcMessage, @observationId, null)

  if(((select top 1 vPhotometryId from bi.observations where id=@observationId) IS NULL) or ((select top 1 iPhotometryId from bi.observations where id=@observationId) is null))
    begin
	print 'NO VI HR-Diagram processing for observation = '+@observationId
	delete from bi.viDiagram
    insert into bi.viDiagram select cast((avg(cast(cast(rtrim(ltrim(bp.vPhotometry)) as varchar(10)) as decimal(18,10))) - avg(cast(cast(rtrim(ltrim(vp.iPhotometry)) as varchar(10)) as decimal(18,10)))) as varchar) as 'VIDifference', bp.ObjectName
    from bi.vPhotometrySorted bp 
	join bi.iPhotometrySorted vp on vp.ObjectName=bp.ObjectName
	join bi.observations ob on bp.ObjectName=ob.ObjectName
	where ob.ObjectType='Star' and ob.Verified=1
    group by bp.ObjectName
	end
  else
	begin
    delete from bi.viDiagram
    insert into bi.viDiagram select cast((avg(cast(cast(rtrim(ltrim(bp.vPhotometry)) as varchar(10)) as decimal(18,10))) - avg(cast(cast(rtrim(ltrim(vp.iPhotometry)) as varchar(10)) as decimal(18,10)))) as varchar) as 'VIDifference', bp.ObjectName
    from bi.vPhotometrySorted bp 
	join bi.iPhotometrySorted vp on vp.ObjectName=bp.ObjectName
	join bi.observations ob on bp.ObjectName=ob.ObjectName
	where ob.ObjectType='Star' and ob.Verified=1
    group by bp.ObjectName
	end

--calculate RI Difference
 set @ProcMessage = 'Calculate RI difference of average values'
 Insert INTO [log].[log](CreateDate, LogCategory, LogObject, Message, ObservationId, LastLoad) values(getDate(), NULL, @ProcName, @ProcMessage, @observationId, null)

  if(((select top 1 rPhotometryId from bi.observations where id=@observationId) IS NULL) or ((select top 1 iPhotometryId from bi.observations where id=@observationId) is null))
    begin
	print 'NO RI HR-Diagram processing for observation = '+@observationId
	delete from bi.riDiagram
    insert into bi.riDiagram select cast((avg(cast(cast(rtrim(ltrim(bp.rPhotometry)) as varchar(10)) as decimal(18,10))) - avg(cast(cast(rtrim(ltrim(vp.iPhotometry)) as varchar(10)) as decimal(18,10)))) as varchar) as 'RIDifference', bp.ObjectName
    from bi.rPhotometrySorted bp 
	join bi.iPhotometrySorted vp on vp.ObjectName=bp.ObjectName
	join bi.observations ob on bp.ObjectName=ob.ObjectName
	where ob.ObjectType='Star' and ob.Verified=1
    group by bp.ObjectName
	end
  else
	begin
    delete from bi.riDiagram
    insert into bi.riDiagram select cast((avg(cast(cast(rtrim(ltrim(bp.rPhotometry)) as varchar(10)) as decimal(18,10))) - avg(cast(cast(rtrim(ltrim(vp.iPhotometry)) as varchar(10)) as decimal(18,10)))) as varchar) as 'RIDifference', bp.ObjectName
    from bi.rPhotometrySorted bp 
	join bi.iPhotometrySorted vp on vp.ObjectName=bp.ObjectName
	join bi.observations ob on bp.ObjectName=ob.ObjectName
	where ob.ObjectType='Star' and ob.Verified=1
    group by bp.ObjectName
	end

 set @ProcMessage = 'Completed'
 Update [log].[log] set LastLoad=0
 Insert INTO [log].[log](CreateDate, LogCategory, LogObject, Message, ObservationId, LastLoad) values(getDate(), 'PROC.END', @ProcName, @ProcMessage, @observationId, 1)
 

  
 select * from stg.stagingObservations
 select * from bi.observations
END







GO
/****** Object:  StoredProcedure [bi].[observationsDeltaPersonalized]    Script Date: 27.11.2016 12:45:41 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO


CREATE PROCEDURE [bi].[observationsDeltaPersonalized]
  
   @observationId varchar(50) = NULL
  
AS
BEGIN

   SET NOCOUNT ON;


--set id
   Declare @i int
   Declare @query nvarchar(max)
   Declare @deltaColumn varchar(50)
   Declare @stagingColumn varchar(50)
   Declare @photometryTable varchar (100)
   Declare @deltaColumnId nvarchar(max)
   Declare @ProcName varchar(100) = '[bi].[observationsDeltaPersonalized]'
   Declare @ProcMessage varchar(100)
   Declare @status varchar(10)
   Declare @active int


   set @ProcMessage = 'EXEC ' + @ProcName + ' ,@observationId=' + coalesce(convert(varchar(50),@observationId),'NULL')
   Insert INTO [log].[log](CreateDate, LogCategory, LogObject, Message, ObservationId) values(getDate(), 'PROC.BEGIN', @ProcName, @ProcMessage, @observationId)
   



--uPhotometry table
 set @ProcMessage = 'Populate bi.uPhotometry table'
 Insert INTO [log].[log](CreateDate, LogCategory, LogObject, Message, ObservationId) values(getDate(), NULL, @ProcName, @ProcMessage, @observationId)
   
 set @deltaColumn = (select DeltaColumnId from util.metadataComparison where id=1)
 set @photometryTable = (select PhotometryTable from util.metadataComparison where id=1)
 set @query = ('select top 1 @deltaColumnId='+@deltaColumn +' from '+@photometryTable+' alias order by '+ @deltaColumn +' desc')
 
 print @query
 
 exec sp_executesql @query, @Params = N'@deltaColumnId varchar(50) output', @deltaColumnId = @deltaColumnId output
 
 if ((@deltaColumnId) = null)
   begin
   set @i = 1
   end
 else
   begin
   set @i = (@deltaColumnId) + 1
   end


 Declare @uPhotometry varchar(50)
 DECLARE insert_cursor CURSOR FOR (select uPhotometry from stg.stagingObservations where Active=1 except select uPhotometry from bi.uPhotometry)

 OPEN insert_cursor
 FETCH NEXT FROM insert_cursor into @uPhotometry

 WHILE @@FETCH_STATUS=0
   BEGIN
   Insert into bi.uPhotometry (uPhotometryId, uPhotometry) SELECT @i, @uPhotometry
   FETCH NEXT FROM insert_cursor into @uPhotometry
   set @i=@i+1
   END
 close insert_cursor
 Deallocate insert_cursor
 

--vPhotometry table
 set @ProcMessage = 'Populate bi.vPhotometry table'
 Insert INTO [log].[log](CreateDate, LogCategory, LogObject, Message, ObservationId) values(getDate(), NULL, @ProcName, @ProcMessage, @observationId)
   
 set @deltaColumn = (select DeltaColumnId from util.metadataComparison where id=2)
 set @photometryTable = (select PhotometryTable from util.metadataComparison where id=2)
 set @query = ('select top 1 @deltaColumnId='+@deltaColumn +' from '+@photometryTable+' alias order by '+ @deltaColumn +' desc')
 
 print @query
 
 exec sp_executesql @query, @Params = N'@deltaColumnId varchar(50) output', @deltaColumnId = @deltaColumnId output
 
 if ((@deltaColumnId) = null)
   begin
   set @i = 1
   end
 else
   begin
   set @i = (@deltaColumnId) + 1
   end


 Declare @vPhotometry varchar(50)
 DECLARE insert_cursor CURSOR FOR (select vPhotometry from stg.stagingObservations where Active=1 except select vPhotometry from bi.vPhotometry)

 OPEN insert_cursor
 FETCH NEXT FROM insert_cursor into @vPhotometry

 WHILE @@FETCH_STATUS=0
   BEGIN
   Insert into bi.vPhotometry (vPhotometryId, vPhotometry) SELECT @i, @vPhotometry
   FETCH NEXT FROM insert_cursor into @vPhotometry
   set @i=@i+1
   END
 close insert_cursor
 Deallocate insert_cursor



 --bPhotometry table
 set @ProcMessage = 'Populate bi.bPhotometry table'
 Insert INTO [log].[log](CreateDate, LogCategory, LogObject, Message, ObservationId) values(getDate(), NULL, @ProcName, @ProcMessage, @observationId)
   
 set @deltaColumn = (select DeltaColumnId from util.metadataComparison where id=3)
 set @photometryTable = (select PhotometryTable from util.metadataComparison where id=3)
 set @query = ('select top 1 @deltaColumnId='+@deltaColumn +' from '+@photometryTable+' alias order by '+ @deltaColumn +' desc')
 
 print @query
 
 exec sp_executesql @query, @Params = N'@deltaColumnId varchar(50) output', @deltaColumnId = @deltaColumnId output
 
 if ((@deltaColumnId) = null)
   begin
   set @i = 1
   end
 else
   begin
   set @i = (@deltaColumnId) + 1
   end


 Declare @bPhotometry varchar(50)
 DECLARE insert_cursor CURSOR FOR (select bPhotometry from stg.stagingObservations where Active=1 except select bPhotometry from bi.bPhotometry)

 OPEN insert_cursor
 FETCH NEXT FROM insert_cursor into @bPhotometry

 WHILE @@FETCH_STATUS=0
   BEGIN
   Insert into bi.bPhotometry (bPhotometryId, bPhotometry) SELECT @i, @bPhotometry
   FETCH NEXT FROM insert_cursor into @bPhotometry
   set @i=@i+1
   END
 close insert_cursor
 Deallocate insert_cursor


 --rPhotometry table
 set @ProcMessage = 'Populate bi.rPhotometry table'
 Insert INTO [log].[log](CreateDate, LogCategory, LogObject, Message, ObservationId) values(getDate(), NULL, @ProcName, @ProcMessage, @observationId)
   
 set @deltaColumn = (select DeltaColumnId from util.metadataComparison where id=4)
 set @photometryTable = (select PhotometryTable from util.metadataComparison where id=4)
 set @query = ('select top 1 @deltaColumnId='+@deltaColumn +' from '+@photometryTable+' alias order by '+ @deltaColumn +' desc')
 
 print @query
 
 exec sp_executesql @query, @Params = N'@deltaColumnId varchar(50) output', @deltaColumnId = @deltaColumnId output
 
 if ((@deltaColumnId) = null)
   begin
   set @i = 1
   end
 else
   begin
   set @i = (@deltaColumnId) + 1
   end


 Declare @rPhotometry varchar(50)
 DECLARE insert_cursor CURSOR FOR (select rPhotometry from stg.stagingObservations where Active=1 except select rPhotometry from bi.rPhotometry)

 OPEN insert_cursor
 FETCH NEXT FROM insert_cursor into @rPhotometry

 WHILE @@FETCH_STATUS=0
   BEGIN
   Insert into bi.rPhotometry (rPhotometryId, rPhotometry) SELECT @i, @rPhotometry
   FETCH NEXT FROM insert_cursor into @rPhotometry
   set @i=@i+1
   END
 close insert_cursor
 Deallocate insert_cursor


 --iPhotometry table
 set @ProcMessage = 'Populate bi.iPhotometry table'
 Insert INTO [log].[log](CreateDate, LogCategory, LogObject, Message, ObservationId) values(getDate(), NULL, @ProcName, @ProcMessage, @observationId)
   
 set @deltaColumn = (select DeltaColumnId from util.metadataComparison where id=5)
 set @photometryTable = (select PhotometryTable from util.metadataComparison where id=5)
 set @query = ('select top 1 @deltaColumnId='+@deltaColumn +' from '+@photometryTable+' alias order by '+ @deltaColumn +' desc')
 
 print @query
 
 exec sp_executesql @query, @Params = N'@deltaColumnId varchar(50) output', @deltaColumnId = @deltaColumnId output
 
 if ((@deltaColumnId) = null)
   begin
   set @i = 1
   end
 else
   begin
   set @i = (@deltaColumnId) + 1
   end


 Declare @iPhotometry varchar(50)
 DECLARE insert_cursor CURSOR FOR (select iPhotometry from stg.stagingObservations where Active=1 except select iPhotometry from bi.iPhotometry)

 OPEN insert_cursor
 FETCH NEXT FROM insert_cursor into @iPhotometry

 WHILE @@FETCH_STATUS=0
   BEGIN
   Insert into bi.iPhotometry (iPhotometryId, iPhotometry) SELECT @i, @iPhotometry
   FETCH NEXT FROM insert_cursor into @iPhotometry
   set @i=@i+1
   END
 close insert_cursor
 Deallocate insert_cursor

 
--uPhotometryTime table
 set @ProcMessage = 'Populate bi.uPhotometryTime table'
 Insert INTO [log].[log](CreateDate, LogCategory, LogObject, Message, ObservationId) values(getDate(), NULL, @ProcName, @ProcMessage, @observationId)
   

 set @deltaColumn = (select DeltaColumnId from util.metadataComparison where id=6)
 set @photometryTable = (select PhotometryTable from util.metadataComparison where id=6)
 set @query = ('select top 1 @deltaColumnId='+@deltaColumn +' from '+@photometryTable+' alias order by '+ @deltaColumn +' desc')
 
 print @query
 
 exec sp_executesql @query, @Params = N'@deltaColumnId varchar(50) output', @deltaColumnId = @deltaColumnId output
 
 if ((@deltaColumnId) = null)
   begin
   set @i = 1
   end
 else
   begin
   set @i = (@deltaColumnId) + 1
   end


 Declare @uPhotometryTime varchar(50)
 DECLARE insert_cursor CURSOR FOR (select uPhotometryTime from stg.stagingObservations where Active=1 except select uPhotometryTime from bi.uPhotometryTime)

 OPEN insert_cursor
 FETCH NEXT FROM insert_cursor into @uPhotometryTime

 WHILE @@FETCH_STATUS=0
   BEGIN
   Insert into bi.uPhotometryTime (uPhotometryTimeId, uPhotometryTime) SELECT @i, @uPhotometryTime
   FETCH NEXT FROM insert_cursor into @uPhotometryTime
   set @i=@i+1
   END
 close insert_cursor
 Deallocate insert_cursor


 --vPhotometryTime table
 set @ProcMessage = 'Populate bi.vPhotometryTime table'
 Insert INTO [log].[log](CreateDate, LogCategory, LogObject, Message, ObservationId) values(getDate(), NULL, @ProcName, @ProcMessage, @observationId)
   
 set @deltaColumn = (select DeltaColumnId from util.metadataComparison where id=7)
 set @photometryTable = (select PhotometryTable from util.metadataComparison where id=7)
 set @query = ('select top 1 @deltaColumnId='+@deltaColumn +' from '+@photometryTable+' alias order by '+ @deltaColumn +' desc')
 
 print @query
 
 exec sp_executesql @query, @Params = N'@deltaColumnId varchar(50) output', @deltaColumnId = @deltaColumnId output
 
 if ((@deltaColumnId) = null)
   begin
   set @i = 1
   end
 else
   begin
   set @i = (@deltaColumnId) + 1
   end


 Declare @vPhotometryTime varchar(50)
 DECLARE insert_cursor CURSOR FOR (select vPhotometryTime from stg.stagingObservations where Active=1 except select vPhotometryTime from bi.vPhotometryTime)

 OPEN insert_cursor
 FETCH NEXT FROM insert_cursor into @vPhotometryTime

 WHILE @@FETCH_STATUS=0
   BEGIN
   Insert into bi.vPhotometryTime (vPhotometryTimeId, vPhotometryTime) SELECT @i, @vPhotometryTime
   FETCH NEXT FROM insert_cursor into @vPhotometryTime
   set @i=@i+1
   END
 close insert_cursor
 Deallocate insert_cursor


 --bPhotometryTime table
 set @ProcMessage = 'Populate bi.bPhotometryTime table'
 Insert INTO [log].[log](CreateDate, LogCategory, LogObject, Message, ObservationId) values(getDate(), NULL, @ProcName, @ProcMessage, @observationId)
   
 set @deltaColumn = (select DeltaColumnId from util.metadataComparison where id=8)
 set @photometryTable = (select PhotometryTable from util.metadataComparison where id=8)
 set @query = ('select top 1 @deltaColumnId='+@deltaColumn +' from '+@photometryTable+' alias order by '+ @deltaColumn +' desc')
 
 print @query
 
 exec sp_executesql @query, @Params = N'@deltaColumnId varchar(50) output', @deltaColumnId = @deltaColumnId output
 
 if ((@deltaColumnId) = null)
   begin
   set @i = 1
   end
 else
   begin
   set @i = (@deltaColumnId) + 1
   end


 Declare @bPhotometryTime varchar(50)
 DECLARE insert_cursor CURSOR FOR (select bPhotometryTime from stg.stagingObservations where Active=1 except select bPhotometryTime from bi.bPhotometryTime)

 OPEN insert_cursor
 FETCH NEXT FROM insert_cursor into @bPhotometryTime

 WHILE @@FETCH_STATUS=0
   BEGIN
   Insert into bi.bPhotometryTime (bPhotometryTimeId, bPhotometryTime) SELECT @i, @bPhotometryTime
   FETCH NEXT FROM insert_cursor into @bPhotometryTime
   set @i=@i+1
   END
 close insert_cursor
 Deallocate insert_cursor


 --rPhotometryTime table
 set @ProcMessage = 'Populate bi.rPhotometryTime table'
 Insert INTO [log].[log](CreateDate, LogCategory, LogObject, Message, ObservationId) values(getDate(), NULL, @ProcName, @ProcMessage, @observationId)
   
 set @deltaColumn = (select DeltaColumnId from util.metadataComparison where id=9)
 set @photometryTable = (select PhotometryTable from util.metadataComparison where id=9)
 set @query = ('select top 1 @deltaColumnId='+@deltaColumn +' from '+@photometryTable+' alias order by '+ @deltaColumn +' desc')
 
 print @query
 
 exec sp_executesql @query, @Params = N'@deltaColumnId varchar(50) output', @deltaColumnId = @deltaColumnId output
 
 if ((@deltaColumnId) = null)
   begin
   set @i = 1
   end
 else
   begin
   set @i = (@deltaColumnId) + 1
   end


 Declare @rPhotometryTime varchar(50)
 DECLARE insert_cursor CURSOR FOR (select rPhotometryTime from stg.stagingObservations where Active=1 except select rPhotometryTime from bi.rPhotometryTime)

 OPEN insert_cursor
 FETCH NEXT FROM insert_cursor into @rPhotometryTime

 WHILE @@FETCH_STATUS=0
   BEGIN
   Insert into bi.rPhotometryTime (rPhotometryTimeId, rPhotometryTime) SELECT @i, @rPhotometryTime
   FETCH NEXT FROM insert_cursor into @rPhotometryTime
   set @i=@i+1
   END
 close insert_cursor
 Deallocate insert_cursor


 --iPhotometryTime table
 set @ProcMessage = 'Populate bi.iPhotometryTime table'
 Insert INTO [log].[log](CreateDate, LogCategory, LogObject, Message, ObservationId) values(getDate(), NULL, @ProcName, @ProcMessage, @observationId)
   
 set @deltaColumn = (select DeltaColumnId from util.metadataComparison where id=10)
 set @photometryTable = (select PhotometryTable from util.metadataComparison where id=10)
 set @query = ('select top 1 @deltaColumnId='+@deltaColumn +' from '+@photometryTable+' alias order by '+ @deltaColumn +' desc')
 
 print @query
 
 exec sp_executesql @query, @Params = N'@deltaColumnId varchar(50) output', @deltaColumnId = @deltaColumnId output
 
 if ((@deltaColumnId) = null)
   begin
   set @i = 1
   end
 else
   begin
   set @i = (@deltaColumnId) + 1
   end


 Declare @iPhotometryTime varchar(50)
 DECLARE insert_cursor CURSOR FOR (select iPhotometryTime from stg.stagingObservations where Active=1 except select iPhotometryTime from bi.iPhotometryTime)

 OPEN insert_cursor
 FETCH NEXT FROM insert_cursor into @iPhotometryTime

 WHILE @@FETCH_STATUS=0
   BEGIN
   Insert into bi.iPhotometryTime (iPhotometryTimeId, iPhotometryTime) SELECT @i, @iPhotometryTime
   FETCH NEXT FROM insert_cursor into @iPhotometryTime
   set @i=@i+1
   END
 close insert_cursor
 Deallocate insert_cursor


--bi.observations table population
 set @ProcMessage = 'Populate bi.observations table'
 Insert INTO [log].[log](CreateDate, LogCategory, LogObject, Message, ObservationId) values(getDate(), NULL, @ProcName, @ProcMessage, @observationId)
   
 --firstly delete updated records
 delete ob from bi.observations ob join stg.stagingObservations so on so.id=ob.id where ob.id=@observationId and so.status='new'


 insert into bi.observations select so.id, so.RowId, so.ObjectName, so.ObjectType, so.StartDate, so.EndDate, uph.uPhotometryId, upht.uPhotometryTimeId,
                                     vph.vPhotometryId, vpht.vPhotometryTimeId, bph.bPhotometryId, bpht.bPhotometryTimeId,
									 rph.rPhotometryId, rpht.rPhotometryTimeId, iph.iPhotometryId, ipht.iPhotometryTimeId, so.Verified, so.OwnerId
 from stg.stagingObservations so
                               left join bi.uPhotometry uph on uph.uPhotometry=so.uPhotometry
                               left join bi.vPhotometry vph on vph.vPhotometry=so.vPhotometry
                               left join bi.bPhotometry bph on bph.bPhotometry=so.bPhotometry
							   left join bi.rPhotometry rph on rph.rPhotometry=so.rPhotometry
							   left join bi.iPhotometry iph on iph.iPhotometry=so.iPhotometry
                               left join bi.uPhotometryTime upht on upht.uPhotometryTime=so.uPhotometryTime
                               left join bi.vPhotometryTime vpht on vpht.vPhotometryTime=so.vPhotometryTime
                               left join bi.bPhotometryTime bpht on bpht.bPhotometryTime=so.bPhotometryTime
                               left join bi.rPhotometryTime rpht on rpht.rPhotometryTime=so.rPhotometryTime
                               left join bi.iPhotometryTime ipht on ipht.iPhotometryTime=so.iPhotometryTime
                               where so.id=@observationId and status='new' and active=1


--delete inactive records from delta
 set @query = ('set @status = (select distinct(status) from stg.stagingObservations where id='+@observationId+')')
 print @query
 exec sp_executesql @query, @Params = N'@status varchar(50) output', @status = @status output

 set @query = ('set @active = (select distinct(active) from stg.stagingObservations where id='+@observationId+')')
 print @query
 exec sp_executesql @query, @Params = N'@active varchar(50) output', @active = @active output

 print @active
 print @status

  if((@status='deleted') and (@active=1))
     begin
	 set @ProcMessage = 'Delete inactive rows from bi.observations table'
     Insert INTO [log].[log](CreateDate, LogCategory, LogObject, Message, ObservationId) values(getDate(), NULL, @ProcName, @ProcMessage, @observationId)
     delete from bi.observations where id=@observationId
	 update stg.stagingObservations set active=0 where id=@observationId
	 end

--update stg.stagingObservations table
 set @ProcMessage = 'Update stg.stagingObservations table'
 Insert INTO [log].[log](CreateDate, LogCategory, LogObject, Message, ObservationId, LastLoad) values(getDate(), NULL, @ProcName, @ProcMessage, @observationId, null)
      
 update stg.stagingObservations set status='old' where id=@observationId

--calculate BV Difference
 set @ProcMessage = 'Calculate BV difference of personalized average values'
 Insert INTO [log].[log](CreateDate, LogCategory, LogObject, Message, ObservationId, LastLoad) values(getDate(), NULL, @ProcName, @ProcMessage, @observationId, null)

  if(((select top 1 bPhotometryId from bi.observations where id=@observationId) IS NULL) or ((select top 1 vPhotometryId from bi.observations where id=@observationId) is null))
    begin
	print 'NO BV HR-Diagram processing for observation = '+@observationId
	delete from bi.bvDiagramPersonalized
    insert into bi.bvDiagramPersonalized select cast((avg(cast(cast(rtrim(ltrim(bp.bPhotometry)) as varchar(10)) as decimal(18,10))) - avg(cast(cast(rtrim(ltrim(vp.vPhotometry)) as varchar(10)) as decimal(18,10)))) as varchar) as 'BVDifference', bp.ObjectName, ob.OwnerId
    from bi.bPhotometrySorted bp 
	join bi.vPhotometrySorted vp on vp.ObjectName=bp.ObjectName
	join bi.observations ob on bp.ObjectName=ob.ObjectName
	where ob.ObjectType='Star' and ob.Verified=1
    group by bp.ObjectName, ob.OwnerId
	end
  else
	begin
    delete from bi.bvDiagramPersonalized
    insert into bi.bvDiagramPersonalized select cast((avg(cast(cast(rtrim(ltrim(bp.bPhotometry)) as varchar(10)) as decimal(18,10))) - avg(cast(cast(rtrim(ltrim(vp.vPhotometry)) as varchar(10)) as decimal(18,10)))) as varchar) as 'BVDifference', bp.ObjectName, ob.OwnerId
    from bi.bPhotometrySorted bp 
	join bi.vPhotometrySorted vp on vp.ObjectName=bp.ObjectName
	join bi.observations ob on bp.ObjectName=ob.ObjectName
	where ob.ObjectType='Star' and ob.Verified=1
    group by bp.ObjectName, ob.OwnerId
	end

  set @ProcMessage = 'Calculate BV difference of global average values'
  Insert INTO [log].[log](CreateDate, LogCategory, LogObject, Message, ObservationId, LastLoad) values(getDate(), NULL, @ProcName, @ProcMessage, @observationId, null)

  if(((select top 1 bPhotometryId from bi.observations where id=@observationId) IS NULL) or ((select top 1 vPhotometryId from bi.observations where id=@observationId) is null))
    begin
	print 'NO BV HR-Diagram processing for observation = '+@observationId
	delete from bi.bvDiagram
    insert into bi.bvDiagram select cast((avg(cast(cast(rtrim(ltrim(bp.bPhotometry)) as varchar(10)) as decimal(18,10))) - avg(cast(cast(rtrim(ltrim(vp.vPhotometry)) as varchar(10)) as decimal(18,10)))) as varchar) as 'BVDifference', bp.ObjectName
    from bi.bPhotometrySorted bp 
	join bi.vPhotometrySorted vp on vp.ObjectName=bp.ObjectName
	join bi.observations ob on bp.ObjectName=ob.ObjectName
	where ob.ObjectType='Star' and ob.Verified=1
    group by bp.ObjectName
	end
  else
	begin
    delete from bi.bvDiagram
    insert into bi.bvDiagram select cast((avg(cast(cast(rtrim(ltrim(bp.bPhotometry)) as varchar(10)) as decimal(18,10))) - avg(cast(cast(rtrim(ltrim(vp.vPhotometry)) as varchar(10)) as decimal(18,10)))) as varchar) as 'BVDifference', bp.ObjectName
    from bi.bPhotometrySorted bp 
	join bi.vPhotometrySorted vp on vp.ObjectName=bp.ObjectName
	join bi.observations ob on bp.ObjectName=ob.ObjectName
	where ob.ObjectType='Star' and ob.Verified=1
    group by bp.ObjectName
	end

--calculate UB Difference
 set @ProcMessage = 'Calculate UB difference of personalized average values'
 Insert INTO [log].[log](CreateDate, LogCategory, LogObject, Message, ObservationId, LastLoad) values(getDate(), NULL, @ProcName, @ProcMessage, @observationId, null)

  if(((select top 1 uPhotometryId from bi.observations where id=@observationId) IS NULL) or ((select top 1 bPhotometryId from bi.observations where id=@observationId) is null))
    begin
	print 'NO UB HR-Diagram processing for observation = '+@observationId
	delete from bi.ubDiagramPersonalized
    insert into bi.ubDiagramPersonalized select cast((avg(cast(cast(rtrim(ltrim(bp.uPhotometry)) as varchar(10)) as decimal(18,10))) - avg(cast(cast(rtrim(ltrim(vp.bPhotometry)) as varchar(10)) as decimal(18,10)))) as varchar) as 'UBDifference', bp.ObjectName, ob.OwnerId
    from bi.uPhotometrySorted bp 
	join bi.bPhotometrySorted vp on vp.ObjectName=bp.ObjectName
	join bi.observations ob on bp.ObjectName=ob.ObjectName
	where ob.ObjectType='Star' and ob.Verified=1
    group by bp.ObjectName, ob.OwnerId
	end
  else
	begin
    delete from bi.ubDiagramPersonalized
    insert into bi.ubDiagramPersonalized select cast((avg(cast(cast(rtrim(ltrim(bp.uPhotometry)) as varchar(10)) as decimal(18,10))) - avg(cast(cast(rtrim(ltrim(vp.bPhotometry)) as varchar(10)) as decimal(18,10)))) as varchar) as 'UBDifference', bp.ObjectName, ob.OwnerId
    from bi.uPhotometrySorted bp 
	join bi.bPhotometrySorted vp on vp.ObjectName=bp.ObjectName
	join bi.observations ob on bp.ObjectName=ob.ObjectName
	where ob.ObjectType='Star' and ob.Verified=1
    group by bp.ObjectName, ob.OwnerId
	end

 set @ProcMessage = 'Calculate UB difference of global average values'
 Insert INTO [log].[log](CreateDate, LogCategory, LogObject, Message, ObservationId, LastLoad) values(getDate(), NULL, @ProcName, @ProcMessage, @observationId, null)


  if(((select top 1 uPhotometryId from bi.observations where id=@observationId) IS NULL) or ((select top 1 bPhotometryId from bi.observations where id=@observationId) is null))
    begin
	print 'NO UB HR-Diagram processing for observation = '+@observationId
	delete from bi.ubDiagram
    insert into bi.ubDiagram select cast((avg(cast(cast(rtrim(ltrim(bp.uPhotometry)) as varchar(10)) as decimal(18,10))) - avg(cast(cast(rtrim(ltrim(vp.bPhotometry)) as varchar(10)) as decimal(18,10)))) as varchar) as 'UBDifference', bp.ObjectName
    from bi.uPhotometrySorted bp 
	join bi.bPhotometrySorted vp on vp.ObjectName=bp.ObjectName
	join bi.observations ob on bp.ObjectName=ob.ObjectName
	where ob.ObjectType='Star' and ob.Verified=1
    group by bp.ObjectName
	end
  else
	begin
    delete from bi.ubDiagram
    insert into bi.ubDiagram select cast((avg(cast(cast(rtrim(ltrim(bp.uPhotometry)) as varchar(10)) as decimal(18,10))) - avg(cast(cast(rtrim(ltrim(vp.bPhotometry)) as varchar(10)) as decimal(18,10)))) as varchar) as 'UBDifference', bp.ObjectName
    from bi.uPhotometrySorted bp 
	join bi.bPhotometrySorted vp on vp.ObjectName=bp.ObjectName
	join bi.observations ob on bp.ObjectName=ob.ObjectName
	where ob.ObjectType='Star' and ob.Verified=1
    group by bp.ObjectName
	end


--calculate VI Difference
 set @ProcMessage = 'Calculate VI difference of personalized average values'
 Insert INTO [log].[log](CreateDate, LogCategory, LogObject, Message, ObservationId, LastLoad) values(getDate(), NULL, @ProcName, @ProcMessage, @observationId, null)

  if(((select top 1 vPhotometryId from bi.observations where id=@observationId) IS NULL) or ((select top 1 iPhotometryId from bi.observations where id=@observationId) is null))
    begin
	print 'NO VI HR-Diagram processing for observation = '+@observationId
	delete from bi.viDiagramPersonalized
    insert into bi.viDiagramPersonalized select cast((avg(cast(cast(rtrim(ltrim(bp.vPhotometry)) as varchar(10)) as decimal(18,10))) - avg(cast(cast(rtrim(ltrim(vp.iPhotometry)) as varchar(10)) as decimal(18,10)))) as varchar) as 'VIDifference', bp.ObjectName, ob.OwnerId
    from bi.vPhotometrySorted bp 
	join bi.iPhotometrySorted vp on vp.ObjectName=bp.ObjectName
	join bi.observations ob on bp.ObjectName=ob.ObjectName
	where ob.ObjectType='Star' and ob.Verified=1
    group by bp.ObjectName, ob.OwnerId
	end
  else
	begin
    delete from bi.viDiagramPersonalized
    insert into bi.viDiagramPersonalized select cast((avg(cast(cast(rtrim(ltrim(bp.vPhotometry)) as varchar(10)) as decimal(18,10))) - avg(cast(cast(rtrim(ltrim(vp.iPhotometry)) as varchar(10)) as decimal(18,10)))) as varchar) as 'VIDifference', bp.ObjectName, ob.OwnerId
    from bi.vPhotometrySorted bp 
	join bi.iPhotometrySorted vp on vp.ObjectName=bp.ObjectName
	join bi.observations ob on bp.ObjectName=ob.ObjectName
	where ob.ObjectType='Star' and ob.Verified=1
    group by bp.ObjectName, ob.OwnerId
	end

 set @ProcMessage = 'Calculate VI difference of global average values'
 Insert INTO [log].[log](CreateDate, LogCategory, LogObject, Message, ObservationId, LastLoad) values(getDate(), NULL, @ProcName, @ProcMessage, @observationId, null)

  if(((select top 1 vPhotometryId from bi.observations where id=@observationId) IS NULL) or ((select top 1 iPhotometryId from bi.observations where id=@observationId) is null))
    begin
	print 'NO VI HR-Diagram processing for observation = '+@observationId
	delete from bi.viDiagram
    insert into bi.viDiagram select cast((avg(cast(cast(rtrim(ltrim(bp.vPhotometry)) as varchar(10)) as decimal(18,10))) - avg(cast(cast(rtrim(ltrim(vp.iPhotometry)) as varchar(10)) as decimal(18,10)))) as varchar) as 'VIDifference', bp.ObjectName
    from bi.vPhotometrySorted bp 
	join bi.iPhotometrySorted vp on vp.ObjectName=bp.ObjectName
	join bi.observations ob on bp.ObjectName=ob.ObjectName
	where ob.ObjectType='Star' and ob.Verified=1
    group by bp.ObjectName
	end
  else
	begin
    delete from bi.viDiagram
    insert into bi.viDiagram select cast((avg(cast(cast(rtrim(ltrim(bp.vPhotometry)) as varchar(10)) as decimal(18,10))) - avg(cast(cast(rtrim(ltrim(vp.iPhotometry)) as varchar(10)) as decimal(18,10)))) as varchar) as 'VIDifference', bp.ObjectName
    from bi.vPhotometrySorted bp 
	join bi.iPhotometrySorted vp on vp.ObjectName=bp.ObjectName
	join bi.observations ob on bp.ObjectName=ob.ObjectName
	where ob.ObjectType='Star' and ob.Verified=1
    group by bp.ObjectName
	end

--calculate RI Difference
 set @ProcMessage = 'Calculate RI difference of personalized average values'
 Insert INTO [log].[log](CreateDate, LogCategory, LogObject, Message, ObservationId, LastLoad) values(getDate(), NULL, @ProcName, @ProcMessage, @observationId, null)

  if(((select top 1 rPhotometryId from bi.observations where id=@observationId) IS NULL) or ((select top 1 iPhotometryId from bi.observations where id=@observationId) is null))
    begin
	print 'NO RI HR-Diagram processing for observation = '+@observationId
	delete from bi.riDiagramPersonalized
    insert into bi.riDiagramPersonalized select cast((avg(cast(cast(rtrim(ltrim(bp.rPhotometry)) as varchar(10)) as decimal(18,10))) - avg(cast(cast(rtrim(ltrim(vp.iPhotometry)) as varchar(10)) as decimal(18,10)))) as varchar) as 'RIDifference', bp.ObjectName, ob.OwnerId
    from bi.rPhotometrySorted bp 
	join bi.iPhotometrySorted vp on vp.ObjectName=bp.ObjectName
	join bi.observations ob on bp.ObjectName=ob.ObjectName
	where ob.ObjectType='Star' and ob.Verified=1
    group by bp.ObjectName, ob.OwnerId
	end
  else
	begin
    delete from bi.riDiagramPersonalized
    insert into bi.riDiagramPersonalized select cast((avg(cast(cast(rtrim(ltrim(bp.rPhotometry)) as varchar(10)) as decimal(18,10))) - avg(cast(cast(rtrim(ltrim(vp.iPhotometry)) as varchar(10)) as decimal(18,10)))) as varchar) as 'RIDifference', bp.ObjectName, ob.OwnerId
    from bi.rPhotometrySorted bp 
	join bi.iPhotometrySorted vp on vp.ObjectName=bp.ObjectName
	join bi.observations ob on bp.ObjectName=ob.ObjectName
	where ob.ObjectType='Star' and ob.Verified=1
    group by bp.ObjectName, ob.OwnerId
	end

 set @ProcMessage = 'Calculate RI difference of global average values'
 Insert INTO [log].[log](CreateDate, LogCategory, LogObject, Message, ObservationId, LastLoad) values(getDate(), NULL, @ProcName, @ProcMessage, @observationId, null)

  if(((select top 1 rPhotometryId from bi.observations where id=@observationId) IS NULL) or ((select top 1 iPhotometryId from bi.observations where id=@observationId) is null))
    begin
	print 'NO RI HR-Diagram processing for observation = '+@observationId
	delete from bi.riDiagram
    insert into bi.riDiagram select cast((avg(cast(cast(rtrim(ltrim(bp.rPhotometry)) as varchar(10)) as decimal(18,10))) - avg(cast(cast(rtrim(ltrim(vp.iPhotometry)) as varchar(10)) as decimal(18,10)))) as varchar) as 'RIDifference', bp.ObjectName
    from bi.rPhotometrySorted bp 
	join bi.iPhotometrySorted vp on vp.ObjectName=bp.ObjectName
	join bi.observations ob on bp.ObjectName=ob.ObjectName
	where ob.ObjectType='Star' and ob.Verified=1
    group by bp.ObjectName
	end
  else
	begin
    delete from bi.riDiagram
    insert into bi.riDiagram select cast((avg(cast(cast(rtrim(ltrim(bp.rPhotometry)) as varchar(10)) as decimal(18,10))) - avg(cast(cast(rtrim(ltrim(vp.iPhotometry)) as varchar(10)) as decimal(18,10)))) as varchar) as 'RIDifference', bp.ObjectName
    from bi.rPhotometrySorted bp 
	join bi.iPhotometrySorted vp on vp.ObjectName=bp.ObjectName
	join bi.observations ob on bp.ObjectName=ob.ObjectName
	where ob.ObjectType='Star' and ob.Verified=1
    group by bp.ObjectName
	end

 set @ProcMessage = 'Completed'
 Update [log].[log] set LastLoad=0
 Insert INTO [log].[log](CreateDate, LogCategory, LogObject, Message, ObservationId, LastLoad) values(getDate(), 'PROC.END', @ProcName, @ProcMessage, @observationId, 1)
 

  
 select * from stg.stagingObservations
 select * from bi.observations
END



GO
/****** Object:  StoredProcedure [data].[insertTestData]    Script Date: 27.11.2016 12:45:41 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE [data].[insertTestData]
  
   @observationId varchar(50) = NULL,
   @active bit = 1,
   @status varchar(20) = 'new', 
   @starName varchar(50) = NULL,
   @startDate varchar(50) = NULL,
   @endDate varchar(50) = NULL 

  
AS
BEGIN

   SET NOCOUNT ON;

   Declare @ProcName varchar(100) = '[data].[insertTestData]'
   Declare @ProcMessage varchar(100)



   set @ProcMessage = 'EXEC ' + @ProcName + ' ,@observationId=' + coalesce(convert(varchar(50),@observationId),'NULL') +
                                            ' ,@active=' + coalesce(convert(varchar(50),@active),'NULL') +
											' ,@status=' + coalesce(convert(varchar(50),@status),'NULL') +
											' ,@starName=' + coalesce(convert(varchar(50),@starName),'NULL') +
											' ,@startDate=' + coalesce(convert(varchar(50),@startDate),'NULL') +
											' ,@endDate=' + coalesce(convert(varchar(50),@endDate),'NULL')
   Insert INTO [log].[log](CreateDate, LogCategory, LogObject, Message, ObservationId) values(getDate(), 'PROC.BEGIN', @ProcName, @ProcMessage, @observationId)
   

   Declare @uPhotometryTime varchar(50), @uPhotometry varchar(50), @vPhotometryTime varchar(50), @vPhotometry varchar(50), @bPhotometryTime varchar(50), @bPhotometry varchar(50)
   Declare @rowId int = 1

   DECLARE insert_cursor CURSOR FOR
   SELECT [Column 0], [Column 1], [Column 2], [Column 3], [Column 4], [Column 5] from [data].[TestData]

   OPEN insert_cursor
   FETCH NEXT FROM insert_cursor into @uPhotometryTime,@uPhotometry,@vPhotometryTime,@vPhotometry,@bPhotometryTime,@bPhotometry

   WHILE @@FETCH_STATUS=0
      BEGIN

      Insert into stg.stagingObservations (id, RowId, StarName, StartDate, EndDate, uPhotometry, uPhotometryTime, vPhotometry, vPhotometryTime, bPhotometry, bPhotometryTime, Status, Active)
      SELECT @observationId, @rowId, @starName, @startDate, @endDate, @uPhotometry, @uPhotometryTime, @vPhotometry, @vPhotometryTime, @bPhotometry, @bPhotometryTime, @status, @active

      FETCH NEXT FROM insert_cursor into @uPhotometryTime, @uPhotometry, @vPhotometryTime, @vPhotometry, @bPhotometryTime, @bPhotometry
      set @rowId=@rowId+1
      END
   close insert_cursor
   Deallocate insert_cursor

   set @ProcMessage = 'Test Data insert completed'
   Insert INTO [log].[log](CreateDate, LogCategory, LogObject, Message, ObservationId) values(getDate(), 'PROC.END', @ProcName, @ProcMessage, @observationId)
   

END






GO
/****** Object:  StoredProcedure [test].[observationsComparison]    Script Date: 27.11.2016 12:45:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [test].[observationsComparison]

   @observationId varchar(50) = NULL,
   @reportMode varchar(10) = 'N',
   @stagingTable varchar(50) = NULL,
   @deltaTable varchar(50) = NULL
  
AS
BEGIN


   SET NOCOUNT ON;
  
   Declare @query nvarchar(max)
   Declare @ProcName varchar(100) = '[test].[observationsComparison]'
   Declare @ProcMessage varchar(100)

   Declare @xmlCountsReport nvarchar(max) = ''
   Declare @xmlResult nvarchar(max) = ''
   Declare @xmlVarTime nvarchar(max)
   Declare @xmlComparison nvarchar(max)
  
   --Start procedure and log
   set @ProcMessage = 'EXEC ' + @ProcName + ' ,@observationId=' + coalesce(convert(varchar(50),@observationId),'NULL') + 
                                            ' ,@stagingTable=' + coalesce(convert(varchar(50),@stagingTable),'NULL') +
											' ,@deltaTable=' + coalesce(convert(varchar(50),@deltaTable),'NULL')
   Insert INTO [log].[log](CreateDate, LogCategory, LogObject, Message, ObservationId) values(getDate(), 'PROC.BEGIN', @ProcName, @ProcMessage, @observationId)
  

      
    --create temp table with values from Metadata dor specific .stg Table
    IF OBJECT_ID(N'tempdb.dbo.#tableStgDelta') is NULL

       CREATE TABLE #tableStgDelta (
          Id INT IDENTITY(1,1),
          DeltaColumn varchar(255),
          PhotometryTable varchar(255),
          DeltaColumnId varchar(255),
          StagingColumn varchar(8000),
          DataTypeConversion varchar(1000),
          NullValuesConversion varchar(100),
		  JoinHint varchar(100)
          )   


       insert into #tableStgDelta(DeltaColumn, PhotometryTable, DeltaColumnId, StagingColumn, DataTypeConversion, NullValuesConversion, JoinHint)
       select mcom.DeltaColumn, mcom.PhotometryTable, DeltaColumnId, mcom.StagingColumn, mcom.DataTypeConversion, mcom.NullValuesConversion, mcom.JoinHint from util.metadataComparison mcom
	   join util.metadataCounts mcnt on mcom.MetadataCountsId=mcnt.id
       where StagingTable=@stagingTable


      
    if(@reportMode='N')
       begin
       select * from #tableStgDelta
       end     

    --create query for dynamic execution
    Declare @deltaQuery nvarchar(max) = ''  --FCT
    Declare @deltaQuery2 nvarchar(max) = '' --FCT
    Declare @STGQuery nvarchar(max) = ''      --STG
    Declare @i int; set @i=1;
    Declare @dataTypeConversionValue varchar(800)
    Declare @nullValuesConversion varchar(100)
	Declare @joinHint varchar(50)
   
   set @ProcMessage = 'Begin loop for observationId='+@observationId
   Insert INTO [log].[log](CreateDate, LogCategory, LogObject, Message, ObservationId) values(getDate(), 'LOOP.BEGIN', @ProcName, @ProcMessage, @observationId)

    while @i <= (select count(1) from #tableStgDelta)
       begin
       set @dataTypeConversionValue = (select DataTypeConversion from #tableStgDelta where id=@i)
       set @nullValuesConversion = (select nullValuesConversion from #tableStgDelta where id=@i)
	   set @joinHint = (select joinHint from #tableStgDelta where id=@i)

       if(@i>1)
          begin
             set @deltaQuery = 'alias'+(convert(varchar(2),@i,2))+'.'+ (select DeltaColumn from #tableStgDelta where id=@i) +', '+ @deltaQuery
             set @deltaQuery2 = ' '+@joinHint+' ' + (select PhotometryTable from #tableStgDelta where id=@i) + ' alias'+(convert(varchar(2),@i,2)) + ' on ' +
                                  'fct.' +(select DeltaColumnId from #tableStgDelta where id=@i) + '=' + 'alias'+(convert(varchar(2),@i,2))+'.'+(select DeltaColumnId from #tableStgDelta where id=@i)
                                  + @deltaQuery2                       
             set @STGQuery = '(case when ISNULL(ltrim(rtrim('+(select StagingColumn from #tableStgDelta where id=@i)+')), '''')='''' Then '+@nullValuesConversion+' else '+ (@dataTypeConversionValue)+ ' end) as '''+(select StagingColumn from #tableStgDelta where id=@i) +''', '+ @STGQuery
          set @i=@i+1         
          end
       else     
          begin
             set @deltaQuery = 'alias'+(convert(varchar(2),@i,2))+'.'+ (select DeltaColumn from #tableStgDelta where id=@i) + @deltaQuery
             set @deltaQuery2 = ' '+@joinHint+' ' + (select PhotometryTable from #tableStgDelta where id=@i) + ' alias'+(convert(varchar(2),@i,2)) + ' on ' +
                                  'fct.' +(select DeltaColumnId from #tableStgDelta where id=@i) + '=' + 'alias'+(convert(varchar(2),@i,2))+'.'+(select DeltaColumnId from #tableStgDelta where id=@i)
                                  + @deltaQuery2                       
             set @STGQuery = '(case when ISNULL(ltrim(rtrim('+(select StagingColumn from #tableStgDelta where id=@i)+')), '''')='''' Then '+@nullValuesConversion+' else '+ (@dataTypeConversionValue)+ ' end) as '''+(select StagingColumn from #tableStgDelta where id=@i) +''''+ @STGQuery
          set @i=@i+1         
          end
       end;

    --Final queries
    set @deltaQuery = 'select RowId,' + @deltaQuery + ' from ' + @deltaTable + ' fct with (NOLOCK)'
    set @STGQuery = 'select RowId,' + @STGQuery + ' from ' + @stagingTable + ' with (NOLOCK) where Id='+cast(@observationId as varchar(100));
    
    Declare @deltaQueryFinal nvarchar(max)
    set @deltaQueryFinal = @deltaQuery + ' ' + @deltaQuery2 + ' where Id='+cast(@observationId as varchar(100));
   

    print @STGQuery
    print @deltaQueryFinal
	
   
    Declare @deltaQueryLastFinal nvarchar(max)
    Declare @var int

    if(@reportMode = 'N')
       begin
       exec sp_executesql @STGQuery           
       exec sp_executesql @deltaQueryFinal  

       set @deltaQueryLastFinal = @STGQuery + ' except ' + @deltaQueryFinal

       exec sp_executesql @deltaQueryLastFinal
       end
    else
       begin
       set @deltaQueryFinal = 'select @var=count(1) from (' + @STGQuery + ' except ' + @deltaQueryFinal +') b'     
       exec sp_executesql @deltaQueryLastFinal, @Params = N'@var varchar(50) output', @var = @var output
       select @observationId as 'ObservationId', @var as 'Staging - Delta Difference'
	 
	   set @query = 'select @xmlVarTime=getDate()'
	   exec sp_executesql @query, @Params = N'@xmlVarTime varchar(50) output', @xmlVarTime = @xmlVarTime output 
	  
       set @xmlComparison = ISNULL(CONVERT(varchar(50),@var),'No Difference')
	   print @xmlComparison
	   --XML report
       set @xmlCountsReport =
	   '<Entry name="Counts">
	      <Log>
		     <LogLine>
			    <Rule>Comparison</Rule>
				<ExecutionResult>'+@xmlComparison+'</ExecutionResult>
				<ObservationId>'+@observationId+'</ObservationId>
				<Time>'+@xmlVarTime+'</Time>
             </LogLine>
          </Log>
	   </Entry>'  
       set @xmlResult = '<Result xmlns:xsi="http://www.w3.org/2001/SMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">'+@xmlCountsReport+'</Result>'


   	   if(@xmlComparison = 'No Difference')
	     begin
		 insert into [util].[testStatus](observationId, testType, CreateDate, PostLoadingStatus, PostLoadingDetail) values(@observationId, 'Comparison',  getdate(), 'PASS', @xmlResult)
		 end
       else
	     begin
		 insert into [util].[testStatus](observationId, testType, CreateDate, PostLoadingStatus, PostLoadingDetail) values(@observationId, 'Comparison',  getdate(), 'FAIL', @xmlResult)
		 end   
       end

	  set @ProcMessage = 'Loop ended for observationId='+@observationId
      Insert INTO [log].[log](CreateDate, LogCategory, LogObject, Message, ObservationId) values(getDate(), 'LOOP.END', @ProcName, @ProcMessage, @observationId)

   --End procedure and log
   set @ProcMessage = 'Testing of quality completed'
   Insert INTO [log].[log](CreateDate, LogCategory, LogObject, Message, ObservationId) values(getDate(), 'PROC.END', @ProcName, @ProcMessage, @observationId)
  
  IF OBJECT_ID(N'tempdb.dbo.#tableStgDelta') is not NULL drop table #tableStgDelta
      
END   




GO
/****** Object:  StoredProcedure [test].[observationsCounts]    Script Date: 27.11.2016 12:45:41 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE [test].[observationsCounts]
  
   @observationId varchar(50) = NULL,
   @stagingTable varchar(50) = NULL,
   @deltaTable varchar(50) = NULL
  
AS
BEGIN

   SET NOCOUNT ON;

   Declare @ProcName varchar(100) = '[test].[observationsCounts]'
   Declare @ProcMessage varchar(100)
   Declare @query2 nvarchar(max) = ''
   Declare @query nvarchar(max)
   Declare @stg nvarchar(max)
   Declare @bi nvarchar(max)
   Declare @stgbi nvarchar(max)

   Declare @i int = 1
   Declare @length int

   Declare @xmlStg nvarchar(max)
   Declare @xmlBi nvarchar(max)
   Declare @xmlStgBi nvarchar(max)
   Declare @xmlStgTime nvarchar(max)
   Declare @xmlBiTime nvarchar(max)
   Declare @xmlStgBiTime nvarchar(max)

   Declare @xmlCountsReport nvarchar(max) = ''
   Declare @xmlResult nvarchar(max) = ''

   Declare @delimiter varchar(10) = ','

   --Start procedure and log
   set @ProcMessage = 'Start testing of counts'
   Insert INTO [log].[log](CreateDate, LogCategory, LogObject, Message) values(getDate(), 'PROC.BEGIN', @ProcName, @ProcMessage)

   --This is magic for splitting observationId's
   IF OBJECT_ID(N'#observationIds') IS NULL
      CREATE TABLE #observationIds (
	     Id INT IDENTITY(1, 1),
		 Observation varchar(255)
	  )

   ;with cte as
   (
      select 0 a, 1 b
	  union all
	  select b, CHARINDEX(@delimiter, @observationId, b) + len(@delimiter)
	  from cte where b>a
   )
   Insert into #observationIds select substring(@observationId, a,
      case when b>len(@delimiter)
	     Then b-a-len(@delimiter)
		 else len(@observationId)-a+1 end) value
   from cte where a>0

   --calculate number of records for while loop
   set @query = 'select @length=count(1) from #observationIds'
   exec sp_executesql @query, @Params = N'@length int output', @length = @length output




while @i<=@length
   begin

   --lets use @i run   
   set @query = 'select @observationId=Observation from #observationIds where id = '+cast(@i as varchar(20))
   exec sp_executesql @query, @Params = N'@observationId varchar(50) output', @observationId = @observationId output

   set @ProcMessage = 'EXEC ' + @ProcName + ' ,@observationId=' + coalesce(convert(varchar(50),@observationId),'NULL') + 
                                            ' ,@stagingTable=' + coalesce(convert(varchar(50),@stagingTable),'NULL') +
											' ,@deltaTable=' + coalesce(convert(varchar(50),@deltaTable),'NULL')
   Insert INTO [log].[log](CreateDate, LogCategory, LogObject, Message, ObservationId) values(getDate(), 'LOOP.BEGIN', @ProcName, @ProcMessage, @observationId)

   if(@observationId = NULL)
      begin
	  set @query2 = 'select NULL, '+@stagingTable+', ' +@deltaTable
	  end
   else
      begin
	  --select count for stg
	  set @query = 'select @stg=count(distinct rowId) from '+@stagingTable+' with (NOLOCK) where ID='+@observationId
	  exec sp_executesql @query, @Params = N'@stg varchar(50) output', @stg = @stg output  
	  
	  set @xmlStg = @stg
	  set @query = 'select @xmlStgTime=getDate()'
	  exec sp_executesql @query, @Params = N'@xmlStgTime varchar(50) output', @xmlStgTime = @xmlStgTime output  



	  --select count for bi
	  set @query = 'select @bi=count(distinct rowId) from '+@deltaTable+' with (NOLOCK) where ID='+@observationId
	  exec sp_executesql @query, @Params = N'@bi varchar(50) output', @bi = @bi output  

	  set @xmlBi = @bi
	  set @query = 'select @xmlBiTime=getDate()'
	  exec sp_executesql @query, @Params = N'@xmlBiTime varchar(50) output', @xmlBiTime = @xmlBiTime output 
      
	  --calculat Stg-Delta difference
	  if (@stg!=@bi)
	     begin
	     set @stgbi = cast((cast(@stg as int) - cast(@bi as int)) as varchar)

		 set @xmlStgBi = @stgbi
	     set @query = 'select @xmlStgBiTime=getDate()'
	     exec sp_executesql @query, @Params = N'@xmlStgBiTime varchar(50) output', @xmlStgBiTime = @xmlStgBiTime output 
		 end
      else
	     begin
		 set @stgbi = '''OK'''

		 set @xmlStgBi = '''OK'''
	     set @query = 'select @xmlStgBiTime=getDate()'
	     exec sp_executesql @query, @Params = N'@xmlStgBiTime varchar(50) output', @xmlStgBiTime = @xmlStgBiTime output 
		 end

	  --final population
	  if(@i=1)
	     begin
	     set @query2 = 'select cast('+@observationId+' as varchar) as ObservationId, cast('+@stg+' as varchar) as StagingCount, cast('+@bi+' as varchar) as DeltaCount, cast('+@stgbi+' as varchar) as StgDeltaDifference'
		 end
      else if (@i<=@length)
	     begin
		 set @query2 = 'select cast('+@observationId+' as varchar) as ObservationId, cast('+@stg+' as varchar) as StagingCount, cast('+@bi+' as varchar) as DeltaCount, cast('+@stgbi+' as varchar) as StgDeltaDifference union all '+@query2		 
		 end


	  --XML report
	  set @xmlCountsReport =
	  '<Entry name="Counts">
	      <Log>
		     <LogLine>
			    <Rule>Counts</Rule>
				<ExecutionResult>'+@xmlStg+'</ExecutionResult>
				<ObservationId>'+@observationId+'</ObservationId>
				<Time>'+@xmlStgTime+'</Time>
             </LogLine>
			 <LogLine>
			    <Rule>Counts</Rule>
				<ExecutionResult>'+@xmlBi+'</ExecutionResult>
				<ObservationId>'+@observationId+'</ObservationId>
				<Time>'+@xmlBiTime+'</Time>
             </LogLine>
	         <LogLine>
			    <Rule>Counts</Rule>
				<ExecutionResult>'+@xmlStgBi+'</ExecutionResult>
				<ObservationId>'+@observationId+'</ObservationId>
				<Time>'+@xmlStgBiTime+'</Time>
             </LogLine>
          </Log>
	  </Entry>'	     

	  set @xmlResult = '<Result xmlns:xsi="http://www.w3.org/2001/SMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">'+@xmlCountsReport+'</Result>'

	  print @xmlResult

	  if(@stgbi = '''OK''')
	     begin
		 insert into [util].[testStatus](observationId, testType, CreateDate, PostLoadingStatus, PostLoadingDetail) values(@observationId, 'Counts',  getdate(), 'PASS', @xmlResult)
		 end
      else
	     begin
		 insert into [util].[testStatus](observationId, testType, CreateDate, PostLoadingStatus, PostLoadingDetail) values(@observationId, 'Counts',  getdate(), 'FAIL', @xmlResult)
		 end

	  set @stg = '0'
	  set @bi = '0'
	  set @i=@i+1
	  end

	  
	  set @ProcMessage = 'EXEC ' + @ProcName + ' ,@observationId=' + coalesce(convert(varchar(50),@observationId),'NULL') + 
                                            ' ,@stagingTable=' + coalesce(convert(varchar(50),@stagingTable),'NULL') +
											' ,@deltaTable=' + coalesce(convert(varchar(50),@deltaTable),'NULL')
      Insert INTO [log].[log](CreateDate, LogCategory, LogObject, Message, ObservationId) values(getDate(), 'LOOP.END', @ProcName, @ProcMessage, @observationId)
   end


   exec sp_executesql @query2

   set @ProcMessage = 'Testing of counts completed'
   Insert INTO [log].[log](CreateDate, LogCategory, LogObject, Message) values(getDate(), 'PROC.END', @ProcName, @ProcMessage)

   IF OBJECT_ID(N'#observationIds') is not NULL drop table #observationIds

END







GO
/****** Object:  Table [bi].[bPhotometry]    Script Date: 27.11.2016 12:45:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [bi].[bPhotometry](
	[bPhotometryId] [bigint] NOT NULL,
	[bPhotometry] [varchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[bPhotometryId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [bi].[bPhotometryTime]    Script Date: 27.11.2016 12:45:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [bi].[bPhotometryTime](
	[bPhotometryTimeId] [bigint] NOT NULL,
	[bPhotometryTime] [varchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[bPhotometryTimeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [bi].[bvDiagram]    Script Date: 27.11.2016 12:45:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [bi].[bvDiagram](
	[BVDifference] [varchar](50) NULL,
	[ObjectName] [varchar](50) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [bi].[bvDiagramPersonalized]    Script Date: 27.11.2016 12:45:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [bi].[bvDiagramPersonalized](
	[BVDifference] [varchar](50) NULL,
	[ObjectName] [varchar](50) NULL,
	[OwnerId] [int] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [bi].[iPhotometry]    Script Date: 27.11.2016 12:45:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [bi].[iPhotometry](
	[iPhotometryId] [bigint] NOT NULL,
	[iPhotometry] [varchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[iPhotometryId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [bi].[iPhotometryTime]    Script Date: 27.11.2016 12:45:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [bi].[iPhotometryTime](
	[iPhotometryTimeId] [bigint] NOT NULL,
	[iPhotometryTime] [varchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[iPhotometryTimeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [bi].[observations]    Script Date: 27.11.2016 12:45:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [bi].[observations](
	[ID] [int] NOT NULL,
	[RowId] [bigint] NULL,
	[ObjectName] [varchar](50) NULL,
	[ObjectType] [varchar](50) NULL,
	[StartDate] [datetime] NULL,
	[EndDate] [datetime] NULL,
	[uPhotometryId] [bigint] NULL,
	[uPhotometryTimeId] [bigint] NULL,
	[vPhotometryId] [bigint] NULL,
	[vPhotometryTimeId] [bigint] NULL,
	[bPhotometryId] [bigint] NULL,
	[bPhotometryTimeId] [bigint] NULL,
	[rPhotometryId] [bigint] NULL,
	[rPhotometryTimeId] [bigint] NULL,
	[iPhotometryId] [bigint] NULL,
	[iPhotometryTimeId] [bigint] NULL,
	[Verified] [bit] NULL,
	[OwnerId] [bigint] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [bi].[riDiagram]    Script Date: 27.11.2016 12:45:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [bi].[riDiagram](
	[RIDifference] [varchar](50) NULL,
	[ObjectName] [varchar](50) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [bi].[riDiagramPersonalized]    Script Date: 27.11.2016 12:45:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [bi].[riDiagramPersonalized](
	[RIDifference] [varchar](50) NULL,
	[ObjectName] [varchar](50) NULL,
	[OwnerId] [int] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [bi].[rPhotometry]    Script Date: 27.11.2016 12:45:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [bi].[rPhotometry](
	[rPhotometryId] [bigint] NOT NULL,
	[rPhotometry] [varchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[rPhotometryId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [bi].[rPhotometryTime]    Script Date: 27.11.2016 12:45:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [bi].[rPhotometryTime](
	[rPhotometryTimeId] [bigint] NOT NULL,
	[rPhotometryTime] [varchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[rPhotometryTimeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [bi].[ubDiagram]    Script Date: 27.11.2016 12:45:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [bi].[ubDiagram](
	[UBDifference] [varchar](50) NULL,
	[ObjectName] [varchar](50) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [bi].[ubDiagramPersonalized]    Script Date: 27.11.2016 12:45:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [bi].[ubDiagramPersonalized](
	[UBDifference] [varchar](50) NULL,
	[ObjectName] [varchar](50) NULL,
	[OwnerId] [int] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [bi].[uPhotometry]    Script Date: 27.11.2016 12:45:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [bi].[uPhotometry](
	[uPhotometryId] [bigint] NOT NULL,
	[uPhotometry] [varchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[uPhotometryId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [bi].[uPhotometryTime]    Script Date: 27.11.2016 12:45:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [bi].[uPhotometryTime](
	[uPhotometryTimeId] [bigint] NOT NULL,
	[uPhotometryTime] [varchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[uPhotometryTimeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [bi].[viDiagram]    Script Date: 27.11.2016 12:45:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [bi].[viDiagram](
	[VIDifference] [varchar](50) NULL,
	[ObjectName] [varchar](50) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [bi].[viDiagramPersonalized]    Script Date: 27.11.2016 12:45:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [bi].[viDiagramPersonalized](
	[VIDifference] [varchar](50) NULL,
	[ObjectName] [varchar](50) NULL,
	[OwnerId] [int] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [bi].[vPhotometry]    Script Date: 27.11.2016 12:45:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [bi].[vPhotometry](
	[vPhotometryId] [bigint] NOT NULL,
	[vPhotometry] [varchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[vPhotometryId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [bi].[vPhotometryTime]    Script Date: 27.11.2016 12:45:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [bi].[vPhotometryTime](
	[vPhotometryTimeId] [bigint] NOT NULL,
	[vPhotometryTime] [varchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[vPhotometryTimeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [data].[Comets]    Script Date: 27.11.2016 12:45:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [data].[Comets](
	[Number] [varchar](10) NULL,
	[OrbitType] [varchar](1) NULL,
	[Designation] [varchar](7) NULL,
	[P_Year] [varchar](10) NULL,
	[P_Month] [varchar](10) NULL,
	[P_Day] [varchar](7) NULL,
	[P_Distance] [varchar](15) NULL,
	[e] [varchar](14) NULL,
	[Perihelion] [varchar](12) NULL,
	[Longitude] [varchar](12) NULL,
	[Inclination] [varchar](12) NULL,
	[E_Year] [varchar](10) NULL,
	[E_Month] [varchar](10) NULL,
	[E_Day] [varchar](10) NULL,
	[Abs_Mag] [varchar](5) NULL,
	[Name] [varchar](56) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [data].[fileNames]    Script Date: 27.11.2016 12:45:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [data].[fileNames](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[ObservationId] [int] NOT NULL,
	[FileName] [varchar](100) NULL,
	[FileType] [varchar](100) NULL,
	[FileSize] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [data].[GC]    Script Date: 27.11.2016 12:45:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [data].[GC](
	[GlonJ2000] [varchar](12) NULL,
	[GlatJ2000] [varchar](12) NULL,
	[RAJ2000] [varchar](14) NULL,
	[DEJ2000] [varchar](14) NULL,
	[GC] [int] NULL,
	[Vmag] [varchar](7) NULL,
	[SpType] [varchar](4) NULL,
	[RA1950] [varchar](12) NULL,
	[EpRA] [varchar](5) NULL,
	[pmRA] [varchar](11) NULL,
	[DE1950] [varchar](12) NULL,
	[EpDE] [varchar](5) NULL,
	[pmDE] [varchar](9) NULL,
	[Remark] [varchar](1) NULL,
	[DM] [varchar](13) NULL,
	[GLON] [varchar](10) NULL,
	[GLAT] [varchar](10) NULL,
	[HD] [int] NULL,
	[m_HD] [varchar](10) NULL,
	[e_RA] [varchar](9) NULL,
	[e_pmRA] [varchar](7) NULL,
	[e_DE] [varchar](9) NULL,
	[e_pmDE] [varchar](7) NULL,
	[RA_icrs] [varchar](12) NULL,
	[DE_icrs] [varchar](12) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [data].[HD]    Script Date: 27.11.2016 12:45:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [data].[HD](
	[GlonJ1900] [varchar](8) NULL,
	[GlatJ1900] [varchar](8) NULL,
	[RAJ2000] [varchar](12) NULL,
	[DEJ2000] [varchar](12) NULL,
	[HD] [int] NULL,
	[DM] [varchar](12) NULL,
	[RAB1900] [varchar](7) NULL,
	[DEB1900] [varchar](6) NULL,
	[q_Ptm] [varchar](10) NULL,
	[Ptm] [varchar](7) NULL,
	[n_Ptm] [varchar](1) NULL,
	[q_Ptg] [varchar](10) NULL,
	[Ptg] [varchar](7) NULL,
	[n_Ptg] [varchar](1) NULL,
	[SpT] [varchar](3) NULL,
	[Int] [varchar](2) NULL,
	[Rem] [varchar](1) NULL,
	[RA_icrs] [varchar](10) NULL,
	[DE_icrs] [varchar](9) NULL,
	[Tycho2] [varchar](5) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [data].[HD_NAME]    Script Date: 27.11.2016 12:45:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [data].[HD_NAME](
	[HD] [int] NULL,
	[BFD] [varchar](20) NULL,
	[NAME] [varchar](50) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [data].[HIP]    Script Date: 27.11.2016 12:45:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [data].[HIP](
	[GlonJ2000] [varchar](12) NULL,
	[GlatJ2000] [varchar](12) NULL,
	[RAJ2000] [varchar](16) NULL,
	[DEJ2000] [varchar](16) NULL,
	[HIP] [int] NULL,
	[n_HIP] [varchar](1) NULL,
	[Sn] [varchar](10) NULL,
	[So] [varchar](10) NULL,
	[Nc] [varchar](10) NULL,
	[RArad] [varchar](20) NULL,
	[e_RArad] [varchar](8) NULL,
	[DErad] [varchar](20) NULL,
	[e_DErad] [varchar](8) NULL,
	[Plx] [varchar](9) NULL,
	[e_Plx] [varchar](8) NULL,
	[pmRA] [varchar](10) NULL,
	[e_pmRA] [varchar](8) NULL,
	[pmDE] [varchar](10) NULL,
	[e_pmDE] [varchar](8) NULL,
	[Ntr] [varchar](10) NULL,
	[F2] [varchar](7) NULL,
	[F1] [varchar](10) NULL,
	[var] [varchar](7) NULL,
	[Hpmag] [varchar](11) NULL,
	[e_Hpmag] [varchar](11) NULL,
	[sHp] [varchar](9) NULL,
	[VA] [varchar](10) NULL,
	[B_V] [varchar](9) NULL,
	[e_B_V] [varchar](9) NULL,
	[V_I] [varchar](9) NULL,
	[HIP1] [varchar](4) NULL,
	[Phot] [varchar](4) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [data].[HR]    Script Date: 27.11.2016 12:45:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [data].[HR](
	[GlonJ2000] [varchar](12) NULL,
	[GlatJ2000] [varchar](12) NULL,
	[RAJ2000] [varchar](12) NULL,
	[DEJ2000] [varchar](12) NULL,
	[HR] [int] NULL,
	[Name] [varchar](10) NULL,
	[DM] [varchar](11) NULL,
	[HD] [int] NULL,
	[SAO] [varchar](10) NULL,
	[FK5] [varchar](10) NULL,
	[IRflag] [varchar](1) NULL,
	[r_IRflag] [varchar](1) NULL,
	[Multiple] [varchar](1) NULL,
	[ADS] [varchar](5) NULL,
	[ADScomp] [varchar](2) NULL,
	[VarID] [varchar](9) NULL,
	[RAJ2000_original] [varchar](10) NULL,
	[DEJ2000_original] [varchar](9) NULL,
	[GLON] [varchar](8) NULL,
	[GLAT] [varchar](8) NULL,
	[Vmag] [varchar](7) NULL,
	[n_Vmag] [varchar](1) NULL,
	[u_Vmag] [varchar](1) NULL,
	[B_V] [varchar](7) NULL,
	[u_B_V] [varchar](1) NULL,
	[U_B] [varchar](7) NULL,
	[u_U_B] [varchar](1) NULL,
	[R_I] [varchar](7) NULL,
	[n_R_I] [varchar](1) NULL,
	[SpType] [varchar](20) NULL,
	[n_SpType] [varchar](1) NULL,
	[pmRA] [varchar](9) NULL,
	[pmDE] [varchar](9) NULL,
	[n_Parallax] [varchar](1) NULL,
	[Parallax] [varchar](9) NULL,
	[RadVel] [varchar](10) NULL,
	[n_RadVel] [varchar](4) NULL,
	[l_RotVel] [varchar](2) NULL,
	[RotVel] [varchar](10) NULL,
	[u_RotVel] [varchar](1) NULL,
	[Dmag] [varchar](5) NULL,
	[Sep] [varchar](7) NULL,
	[MultID] [varchar](4) NULL,
	[MultCnt] [varchar](10) NULL,
	[NoteFlag] [varchar](10) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [data].[images]    Script Date: 27.11.2016 12:45:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [data].[images](
	[ID] [bigint] NOT NULL,
	[ImageId] [bigint] NOT NULL,
	[OwnerId] [int] NULL,
	[FileExtensionId] [int] NULL,
	[SessionId] [bigint] NULL,
	[ConversionTypeId] [int] NULL,
	[ImageTypeId] [int] NULL,
	[ObjectName] [varchar](200) NULL,
	[FolderName] [varchar](100) NULL,
	[ProcessingType] [varchar](100) NULL,
	[UploadTime] [varchar](100) NULL,
	[ActiveFlag] [bit] NULL,
PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [data].[MPC]    Script Date: 27.11.2016 12:45:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [data].[MPC](
	[Number] [varchar](10) NULL,
	[H] [varchar](7) NULL,
	[G] [varchar](7) NULL,
	[Epoch] [varchar](5) NULL,
	[M] [varchar](14) NULL,
	[Perihelion] [varchar](14) NULL,
	[Node] [varchar](14) NULL,
	[Inclination] [varchar](14) NULL,
	[e] [varchar](16) NULL,
	[n] [varchar](19) NULL,
	[a] [varchar](18) NULL,
	[U] [varchar](10) NULL,
	[Reference] [varchar](9) NULL,
	[Obs] [varchar](10) NULL,
	[Opp] [varchar](10) NULL,
	[Arc] [varchar](10) NULL,
	[rms] [varchar](6) NULL,
	[Perts] [varchar](10) NULL,
	[Name] [varchar](30) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [data].[SAO]    Script Date: 27.11.2016 12:45:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [data].[SAO](
	[GlonJ1950] [varchar](12) NULL,
	[GlatJ1950] [varchar](12) NULL,
	[RAJ2000] [varchar](14) NULL,
	[DEJ2000] [varchar](14) NULL,
	[SAO] [int] NULL,
	[delFlag] [varchar](1) NULL,
	[RAB1950] [varchar](12) NULL,
	[pmRA] [varchar](11) NULL,
	[e_pmRA] [varchar](10) NULL,
	[RA2mf] [varchar](1) NULL,
	[RA2s] [varchar](9) NULL,
	[e_RA2s] [varchar](10) NULL,
	[EpRA2] [varchar](7) NULL,
	[DEB1950] [varchar](12) NULL,
	[pmDE] [varchar](9) NULL,
	[e_pmDE] [varchar](10) NULL,
	[DE2mf] [varchar](1) NULL,
	[DE2s] [varchar](7) NULL,
	[e_DE2s] [varchar](10) NULL,
	[EpDE2] [varchar](7) NULL,
	[e_Pos] [varchar](10) NULL,
	[Pmag] [varchar](5) NULL,
	[Vmag] [varchar](5) NULL,
	[SpType] [varchar](3) NULL,
	[r_Vmag] [varchar](10) NULL,
	[r_Num] [varchar](10) NULL,
	[r_Pmag] [varchar](10) NULL,
	[r_pmRA] [varchar](10) NULL,
	[r_SpType] [varchar](10) NULL,
	[Rem] [varchar](10) NULL,
	[a_Vmag] [varchar](10) NULL,
	[a_Pmag] [varchar](10) NULL,
	[r_Cat] [varchar](10) NULL,
	[CatNum] [varchar](10) NULL,
	[DM] [varchar](13) NULL,
	[HD] [int] NULL,
	[m_HD] [varchar](10) NULL,
	[GC] [varchar](5) NULL,
	[RA2000] [varchar](12) NULL,
	[pmRA2000] [varchar](11) NULL,
	[DE2000] [varchar](12) NULL,
	[pmDE2000] [varchar](9) NULL,
	[RA_icrs] [varchar](12) NULL,
	[DE_icrs] [varchar](12) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [data].[subscribeList]    Script Date: 27.11.2016 12:45:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [data].[subscribeList](
	[Email] [varchar](200) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [data].[TYC2]    Script Date: 27.11.2016 12:45:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [data].[TYC2](
	[GlonJ2000] [varchar](12) NULL,
	[GlatJ2000] [varchar](12) NULL,
	[RAJ2000] [varchar](16) NULL,
	[DEJ2000] [varchar](16) NULL,
	[TYC1] [int] NULL,
	[TYC2] [int] NULL,
	[TYC3] [int] NULL,
	[pflag] [varchar](10) NULL,
	[RAmdeg] [varchar](20) NULL,
	[DEmdeg] [varchar](20) NULL,
	[pmRA] [varchar](8) NULL,
	[pmDE] [varchar](8) NULL,
	[e_RAmdeg] [varchar](10) NULL,
	[e_DEmdeg] [varchar](10) NULL,
	[e_pmRA] [varchar](5) NULL,
	[e_pmDE] [varchar](5) NULL,
	[EpRAm] [varchar](9) NULL,
	[EpDEm] [varchar](9) NULL,
	[Num] [varchar](10) NULL,
	[q_RAmdeg] [varchar](5) NULL,
	[q_DEmdeg] [varchar](5) NULL,
	[q_pmRA] [varchar](5) NULL,
	[q_pmDE] [varchar](5) NULL,
	[BTmag] [varchar](9) NULL,
	[e_BTmag] [varchar](9) NULL,
	[VTmag] [varchar](9) NULL,
	[e_VTmag] [varchar](9) NULL,
	[prox] [varchar](10) NULL,
	[TYC] [varchar](1) NULL,
	[HIP] [int] NULL,
	[CCDM] [varchar](10) NULL,
	[RAdeg] [varchar](20) NULL,
	[DEdeg] [varchar](20) NULL,
	[EpRA-1990] [varchar](7) NULL,
	[EpDE-1990] [varchar](7) NULL,
	[e_RAdeg] [varchar](6) NULL,
	[e_DEdeg] [varchar](6) NULL,
	[posflg] [varchar](10) NULL,
	[corr] [varchar](5) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [data].[TYC2_HD]    Script Date: 27.11.2016 12:45:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [data].[TYC2_HD](
	[TYC1] [int] NULL,
	[TYC2] [int] NULL,
	[TYC3] [int] NULL,
	[HD] [int] NULL
) ON [PRIMARY]

GO
/****** Object:  Table [data].[users]    Script Date: 27.11.2016 12:45:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [data].[users](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [varchar](100) NULL,
	[Email] [varchar](100) NULL,
	[Password] [varchar](500) NULL,
	[ActiveFlag] [bit] NULL,
	[ActiveCode] [varchar](max) NULL,
	[SessionID] [bigint] NULL,
	[ActiveDate] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[Email] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[HIP]    Script Date: 27.11.2016 12:45:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[HIP](
	[Column 0] [varchar](50) NULL,
	[Column 1] [varchar](50) NULL,
	[Column 2] [varchar](50) NULL,
	[Column 3] [varchar](50) NULL,
	[Column 4] [varchar](50) NULL,
	[Column 5] [varchar](50) NULL,
	[Column 6] [varchar](50) NULL,
	[Column 7] [varchar](50) NULL,
	[Column 8] [varchar](50) NULL,
	[Column 9] [varchar](50) NULL,
	[Column 10] [varchar](50) NULL,
	[Column 11] [varchar](50) NULL,
	[Column 12] [varchar](50) NULL,
	[Column 13] [varchar](50) NULL,
	[Column 14] [varchar](50) NULL,
	[Column 15] [varchar](50) NULL,
	[Column 16] [varchar](50) NULL,
	[Column 17] [varchar](50) NULL,
	[Column 18] [varchar](50) NULL,
	[Column 19] [varchar](50) NULL,
	[Column 20] [varchar](50) NULL,
	[Column 21] [varchar](50) NULL,
	[Column 22] [varchar](50) NULL,
	[Column 23] [varchar](50) NULL,
	[Column 24] [varchar](50) NULL,
	[Column 25] [varchar](50) NULL,
	[Column 26] [varchar](50) NULL,
	[Column 27] [varchar](50) NULL,
	[Column 28] [varchar](50) NULL,
	[Column 29] [varchar](50) NULL,
	[Column 30] [varchar](50) NULL,
	[Column 31] [varchar](50) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[HR]    Script Date: 27.11.2016 12:45:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[HR](
	[Column 0] [varchar](50) NULL,
	[Column 1] [varchar](50) NULL,
	[Column 2] [varchar](50) NULL,
	[Column 3] [varchar](50) NULL,
	[Column 4] [varchar](50) NULL,
	[Column 5] [varchar](50) NULL,
	[Column 6] [varchar](50) NULL,
	[Column 7] [varchar](50) NULL,
	[Column 8] [varchar](50) NULL,
	[Column 9] [varchar](50) NULL,
	[Column 10] [varchar](50) NULL,
	[Column 11] [varchar](50) NULL,
	[Column 12] [varchar](50) NULL,
	[Column 13] [varchar](50) NULL,
	[Column 14] [varchar](50) NULL,
	[Column 15] [varchar](50) NULL,
	[Column 16] [varchar](50) NULL,
	[Column 17] [varchar](50) NULL,
	[Column 18] [varchar](50) NULL,
	[Column 19] [varchar](50) NULL,
	[Column 20] [varchar](50) NULL,
	[Column 21] [varchar](50) NULL,
	[Column 22] [varchar](50) NULL,
	[Column 23] [varchar](50) NULL,
	[Column 24] [varchar](50) NULL,
	[Column 25] [varchar](50) NULL,
	[Column 26] [varchar](50) NULL,
	[Column 27] [varchar](50) NULL,
	[Column 28] [varchar](50) NULL,
	[Column 29] [varchar](50) NULL,
	[Column 30] [varchar](50) NULL,
	[Column 31] [varchar](50) NULL,
	[Column 32] [varchar](50) NULL,
	[Column 33] [varchar](50) NULL,
	[Column 34] [varchar](50) NULL,
	[Column 35] [varchar](50) NULL,
	[Column 36] [varchar](50) NULL,
	[Column 37] [varchar](50) NULL,
	[Column 38] [varchar](50) NULL,
	[Column 39] [varchar](50) NULL,
	[Column 40] [varchar](50) NULL,
	[Column 41] [varchar](50) NULL,
	[Column 42] [varchar](50) NULL,
	[Column 43] [varchar](50) NULL,
	[Column 44] [varchar](50) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[TYC2]    Script Date: 27.11.2016 12:45:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TYC2](
	[Column 0] [varchar](50) NULL,
	[Column 1] [varchar](50) NULL,
	[Column 2] [varchar](50) NULL,
	[Column 3] [varchar](50) NULL,
	[Column 4] [varchar](50) NULL,
	[Column 5] [varchar](50) NULL,
	[Column 6] [varchar](50) NULL,
	[Column 7] [varchar](50) NULL,
	[Column 8] [varchar](50) NULL,
	[Column 9] [varchar](50) NULL,
	[Column 10] [varchar](50) NULL,
	[Column 11] [varchar](50) NULL,
	[Column 12] [varchar](50) NULL,
	[Column 13] [varchar](50) NULL,
	[Column 14] [varchar](50) NULL,
	[Column 15] [varchar](50) NULL,
	[Column 16] [varchar](50) NULL,
	[Column 17] [varchar](50) NULL,
	[Column 18] [varchar](50) NULL,
	[Column 19] [varchar](50) NULL,
	[Column 20] [varchar](50) NULL,
	[Column 21] [varchar](50) NULL,
	[Column 22] [varchar](50) NULL,
	[Column 23] [varchar](50) NULL,
	[Column 24] [varchar](50) NULL,
	[Column 25] [varchar](50) NULL,
	[Column 26] [varchar](50) NULL,
	[Column 27] [varchar](50) NULL,
	[Column 28] [varchar](50) NULL,
	[Column 29] [varchar](50) NULL,
	[Column 30] [varchar](50) NULL,
	[Column 31] [varchar](50) NULL,
	[Column 32] [varchar](50) NULL,
	[Column 33] [varchar](50) NULL,
	[Column 34] [varchar](50) NULL,
	[Column 35] [varchar](50) NULL,
	[Column 36] [varchar](50) NULL,
	[Column 37] [varchar](50) NULL,
	[Column 38] [varchar](50) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dic].[ConversionTypes]    Script Date: 27.11.2016 12:45:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dic].[ConversionTypes](
	[ConversionTypeId] [int] NOT NULL,
	[ConversionType] [varchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[ConversionTypeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dic].[FileExtensions]    Script Date: 27.11.2016 12:45:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dic].[FileExtensions](
	[FileExtensionId] [int] NOT NULL,
	[FileExtension] [varchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[FileExtensionId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dic].[ImageTypes]    Script Date: 27.11.2016 12:45:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dic].[ImageTypes](
	[ImageTypeId] [int] NOT NULL,
	[ImageType] [varchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[ImageTypeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [log].[log]    Script Date: 27.11.2016 12:45:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [log].[log](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[CreateDate] [datetime] NULL,
	[LogCategory] [varchar](50) NULL,
	[LogObject] [varchar](50) NULL,
	[Message] [varchar](200) NULL,
	[ObservationId] [varchar](20) NULL,
	[LastLoad] [bit] NULL,
PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [stg].[stagingObservations]    Script Date: 27.11.2016 12:45:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [stg].[stagingObservations](
	[ID] [bigint] NULL,
	[RowId] [bigint] NOT NULL,
	[ObjectName] [varchar](50) NULL,
	[ObjectType] [varchar](50) NULL,
	[StartDate] [varchar](50) NULL,
	[EndDate] [varchar](50) NULL,
	[uPhotometry] [decimal](18, 5) NULL,
	[uPhotometryTime] [decimal](18, 5) NULL,
	[vPhotometry] [decimal](18, 5) NULL,
	[vPhotometryTime] [decimal](18, 5) NULL,
	[bPhotometry] [decimal](18, 5) NULL,
	[bPhotometryTime] [decimal](18, 5) NULL,
	[rPhotometry] [decimal](18, 5) NULL,
	[rPhotometryTime] [decimal](18, 5) NULL,
	[iPhotometry] [decimal](18, 5) NULL,
	[iPhotometryTime] [decimal](18, 5) NULL,
	[Status] [varchar](50) NULL,
	[Active] [bit] NULL,
	[Verified] [bit] NULL,
	[OwnerId] [bigint] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [test].[testStatus]    Script Date: 27.11.2016 12:45:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [test].[testStatus](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[ObservationId] [int] NULL,
	[TestType] [varchar](50) NULL,
	[CreateDate] [datetime] NULL,
	[PostLoadingStatus] [varchar](50) NULL,
	[PostLoadingDetail] [xml] NULL,
PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [util].[metadataComparison]    Script Date: 27.11.2016 12:45:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [util].[metadataComparison](
	[ID] [int] NOT NULL,
	[MetadataCountsId] [int] NOT NULL,
	[StagingColumn] [varchar](50) NULL,
	[DeltaColumn] [varchar](50) NULL,
	[DeltaColumnId] [varchar](50) NULL,
	[PhotometryTable] [varchar](50) NULL,
	[DataTypeConversion] [varchar](1000) NULL,
	[NullValuesConversion] [varchar](100) NULL,
	[JoinHint] [varchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [util].[metadataCounts]    Script Date: 27.11.2016 12:45:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [util].[metadataCounts](
	[ID] [int] NOT NULL,
	[StagingTable] [varchar](50) NULL,
	[DeltaTable] [varchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [util].[testStatus]    Script Date: 27.11.2016 12:45:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [util].[testStatus](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[ObservationId] [int] NULL,
	[TestType] [varchar](50) NULL,
	[CreateDate] [datetime] NULL,
	[PostLoadingStatus] [varchar](50) NULL,
	[PostLoadingDetail] [xml] NULL,
PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  View [bi].[bPhotometrySorted]    Script Date: 27.11.2016 12:45:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





CREATE view [bi].[bPhotometrySorted] as
SELECT        TOP (100) PERCENT bi.observations.ID, bi.observations.RowId, bi.observations.ObjectName, bi.observations.StartDate, bi.observations.EndDate, bi.bPhotometry.bPhotometry, 
                         bi.bPhotometryTime.bPhotometryTime, bi.observations.OwnerId
FROM            bi.bPhotometry INNER JOIN
                         bi.observations ON bi.bPhotometry.bPhotometryId = bi.observations.bPhotometryId INNER JOIN
                         bi.bPhotometryTime ON bi.observations.bPhotometryTimeId = bi.bPhotometryTime.bPhotometryTimeId
where bi.observations.Verified=1
ORDER BY bi.observations.ID, bi.observations.RowId, bi.observations.StartDate











GO
/****** Object:  View [bi].[bPhotometrySortedPersonalized]    Script Date: 27.11.2016 12:45:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






CREATE view [bi].[bPhotometrySortedPersonalized] as
SELECT        TOP (100) PERCENT bi.observations.ID, bi.observations.RowId, bi.observations.ObjectName, bi.observations.StartDate, bi.observations.EndDate, bi.bPhotometry.bPhotometry, 
                         bi.bPhotometryTime.bPhotometryTime, bi.observations.OwnerId
FROM            bi.bPhotometry INNER JOIN
                         bi.observations ON bi.bPhotometry.bPhotometryId = bi.observations.bPhotometryId INNER JOIN
                         bi.bPhotometryTime ON bi.observations.bPhotometryTimeId = bi.bPhotometryTime.bPhotometryTimeId
ORDER BY bi.observations.ID, bi.observations.RowId, bi.observations.StartDate












GO
/****** Object:  View [bi].[bvDiagramAvg]    Script Date: 27.11.2016 12:45:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






create view [bi].[bvDiagramAvg] as        
select * from bi.bvDiagram









GO
/****** Object:  View [bi].[bvDiagramAvgPersonalized]    Script Date: 27.11.2016 12:45:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO







create view [bi].[bvDiagramAvgPersonalized] as        
select * from bi.bvDiagramPersonalized










GO
/****** Object:  View [bi].[iPhotometrySorted]    Script Date: 27.11.2016 12:45:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





CREATE view [bi].[iPhotometrySorted] as
SELECT        TOP (100) PERCENT bi.observations.ID, bi.observations.RowId, bi.observations.ObjectName, bi.observations.StartDate, bi.observations.EndDate, bi.iPhotometry.iPhotometry, 
                         bi.iPhotometryTime.iPhotometryTime, bi.observations.OwnerId
FROM            bi.iPhotometry INNER JOIN
                         bi.observations ON bi.iPhotometry.iPhotometryId = bi.observations.iPhotometryId INNER JOIN
                         bi.iPhotometryTime ON bi.observations.iPhotometryTimeId = bi.iPhotometryTime.iPhotometryTimeId
where bi.observations.Verified=1
ORDER BY bi.observations.ID, bi.observations.RowId, bi.observations.StartDate











GO
/****** Object:  View [bi].[iPhotometrySortedPersonalized]    Script Date: 27.11.2016 12:45:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






CREATE view [bi].[iPhotometrySortedPersonalized] as
SELECT        TOP (100) PERCENT bi.observations.ID, bi.observations.RowId, bi.observations.ObjectName, bi.observations.StartDate, bi.observations.EndDate, bi.iPhotometry.iPhotometry, 
                         bi.iPhotometryTime.iPhotometryTime, bi.observations.OwnerId
FROM            bi.iPhotometry INNER JOIN
                         bi.observations ON bi.iPhotometry.iPhotometryId = bi.observations.iPhotometryId INNER JOIN
                         bi.iPhotometryTime ON bi.observations.iPhotometryTimeId = bi.iPhotometryTime.iPhotometryTimeId
ORDER BY bi.observations.ID, bi.observations.RowId, bi.observations.StartDate












GO
/****** Object:  View [bi].[observationsSorted]    Script Date: 27.11.2016 12:45:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





CREATE view [bi].[observationsSorted] as (
SELECT        TOP (100) PERCENT ID, RowId, ObjectName, StartDate, EndDate, OwnerId
FROM            bi.observations
where bi.observations.Verified=1
ORDER BY ID, RowId, StartDate)











GO
/****** Object:  View [bi].[observationsSortedPersonalized]    Script Date: 27.11.2016 12:45:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO








CREATE view [bi].[observationsSortedPersonalized] as (
SELECT        TOP (100) PERCENT ID, RowId, ObjectName, ObjectType, StartDate, EndDate, OwnerId, Verified
FROM            bi.observations
ORDER BY ID, RowId, StartDate)














GO
/****** Object:  View [bi].[riDiagramAvg]    Script Date: 27.11.2016 12:45:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






create view [bi].[riDiagramAvg] as        
select * from bi.riDiagram









GO
/****** Object:  View [bi].[riDiagramAvgPersonalized]    Script Date: 27.11.2016 12:45:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO







create view [bi].[riDiagramAvgPersonalized] as        
select * from bi.riDiagramPersonalized










GO
/****** Object:  View [bi].[rPhotometrySorted]    Script Date: 27.11.2016 12:45:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





CREATE view [bi].[rPhotometrySorted] as
SELECT        TOP (100) PERCENT bi.observations.ID, bi.observations.RowId, bi.observations.ObjectName, bi.observations.StartDate, bi.observations.EndDate, bi.rPhotometry.rPhotometry, 
                         bi.rPhotometryTime.rPhotometryTime, bi.observations.OwnerId
FROM            bi.rPhotometry INNER JOIN
                         bi.observations ON bi.rPhotometry.rPhotometryId = bi.observations.rPhotometryId INNER JOIN
                         bi.rPhotometryTime ON bi.observations.rPhotometryTimeId = bi.rPhotometryTime.rPhotometryTimeId
where bi.observations.Verified=1
ORDER BY bi.observations.ID, bi.observations.RowId, bi.observations.StartDate











GO
/****** Object:  View [bi].[rPhotometrySortedPersonalized]    Script Date: 27.11.2016 12:45:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






CREATE view [bi].[rPhotometrySortedPersonalized] as
SELECT        TOP (100) PERCENT bi.observations.ID, bi.observations.RowId, bi.observations.ObjectName, bi.observations.StartDate, bi.observations.EndDate, bi.rPhotometry.rPhotometry, 
                         bi.rPhotometryTime.rPhotometryTime, bi.observations.OwnerId
FROM            bi.rPhotometry INNER JOIN
                         bi.observations ON bi.rPhotometry.rPhotometryId = bi.observations.rPhotometryId INNER JOIN
                         bi.rPhotometryTime ON bi.observations.rPhotometryTimeId = bi.rPhotometryTime.rPhotometryTimeId
ORDER BY bi.observations.ID, bi.observations.RowId, bi.observations.StartDate












GO
/****** Object:  View [bi].[ubDiagramAvg]    Script Date: 27.11.2016 12:45:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






create view [bi].[ubDiagramAvg] as        
select * from bi.ubDiagram









GO
/****** Object:  View [bi].[ubDiagramAvgPersonalized]    Script Date: 27.11.2016 12:45:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO







create view [bi].[ubDiagramAvgPersonalized] as        
select * from bi.ubDiagramPersonalized










GO
/****** Object:  View [bi].[uPhotometrySorted]    Script Date: 27.11.2016 12:45:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





CREATE view [bi].[uPhotometrySorted] as
SELECT        TOP (100) PERCENT bi.observations.ID, bi.observations.RowId, bi.observations.ObjectName, bi.observations.StartDate, bi.observations.EndDate, bi.uPhotometry.uPhotometry, 
                         bi.uPhotometryTime.uPhotometryTime, bi.observations.OwnerId
FROM            bi.uPhotometry INNER JOIN
                         bi.observations ON bi.uPhotometry.uPhotometryId = bi.observations.uPhotometryId INNER JOIN
                         bi.uPhotometryTime ON bi.observations.uPhotometryTimeId = bi.uPhotometryTime.uPhotometryTimeId
where bi.observations.Verified=1
ORDER BY bi.observations.ID, bi.observations.RowId, bi.observations.StartDate











GO
/****** Object:  View [bi].[uPhotometrySortedPersonalized]    Script Date: 27.11.2016 12:45:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






CREATE view [bi].[uPhotometrySortedPersonalized] as
SELECT        TOP (100) PERCENT bi.observations.ID, bi.observations.RowId, bi.observations.ObjectName, bi.observations.StartDate, bi.observations.EndDate, bi.uPhotometry.uPhotometry, 
                         bi.uPhotometryTime.uPhotometryTime, bi.observations.OwnerId
FROM            bi.uPhotometry INNER JOIN
                         bi.observations ON bi.uPhotometry.uPhotometryId = bi.observations.uPhotometryId INNER JOIN
                         bi.uPhotometryTime ON bi.observations.uPhotometryTimeId = bi.uPhotometryTime.uPhotometryTimeId
ORDER BY bi.observations.ID, bi.observations.RowId, bi.observations.StartDate












GO
/****** Object:  View [bi].[viDiagramAvg]    Script Date: 27.11.2016 12:45:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






create view [bi].[viDiagramAvg] as        
select * from bi.viDiagram









GO
/****** Object:  View [bi].[viDiagramAvgPersonalized]    Script Date: 27.11.2016 12:45:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO







create view [bi].[viDiagramAvgPersonalized] as        
select * from bi.viDiagramPersonalized










GO
/****** Object:  View [bi].[vPhotometrySorted]    Script Date: 27.11.2016 12:45:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





CREATE view [bi].[vPhotometrySorted] as
SELECT        TOP (100) PERCENT bi.observations.ID, bi.observations.RowId, bi.observations.ObjectName, bi.observations.StartDate, bi.observations.EndDate, bi.vPhotometry.vPhotometry, 
                         bi.vPhotometryTime.vPhotometryTime, bi.observations.OwnerId
FROM            bi.vPhotometry INNER JOIN
                         bi.observations ON bi.vPhotometry.vPhotometryId = bi.observations.vPhotometryId INNER JOIN
                         bi.vPhotometryTime ON bi.observations.vPhotometryTimeId = bi.vPhotometryTime.vPhotometryTimeId
where bi.observations.Verified=1
ORDER BY bi.observations.ID, bi.observations.RowId, bi.observations.StartDate









GO
/****** Object:  View [bi].[vPhotometrySortedPersonalized]    Script Date: 27.11.2016 12:45:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






CREATE view [bi].[vPhotometrySortedPersonalized] as
SELECT        TOP (100) PERCENT bi.observations.ID, bi.observations.RowId, bi.observations.ObjectName, bi.observations.StartDate, bi.observations.EndDate, bi.vPhotometry.vPhotometry, 
                         bi.vPhotometryTime.vPhotometryTime, bi.observations.OwnerId
FROM            bi.vPhotometry INNER JOIN
                         bi.observations ON bi.vPhotometry.vPhotometryId = bi.observations.vPhotometryId INNER JOIN
                         bi.vPhotometryTime ON bi.observations.vPhotometryTimeId = bi.vPhotometryTime.vPhotometryTimeId
ORDER BY bi.observations.ID, bi.observations.RowId, bi.observations.StartDate










GO
/****** Object:  Index [ClusteredIndex-20161009-163040]    Script Date: 27.11.2016 12:45:41 ******/
CREATE CLUSTERED INDEX [ClusteredIndex-20161009-163040] ON [data].[HIP]
(
	[HIP] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [ClusteredIndex-20160915-184950]    Script Date: 27.11.2016 12:45:41 ******/
CREATE CLUSTERED INDEX [ClusteredIndex-20160915-184950] ON [data].[SAO]
(
	[HD] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [NonClusteredIndex-20160915-215141]    Script Date: 27.11.2016 12:45:41 ******/
CREATE NONCLUSTERED INDEX [NonClusteredIndex-20160915-215141] ON [data].[GC]
(
	[HD] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [NonClusteredIndex-20160915-195251]    Script Date: 27.11.2016 12:45:41 ******/
CREATE NONCLUSTERED INDEX [NonClusteredIndex-20160915-195251] ON [data].[HD]
(
	[HD] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [NonClusteredIndex-20160915-215207]    Script Date: 27.11.2016 12:45:41 ******/
CREATE NONCLUSTERED INDEX [NonClusteredIndex-20160915-215207] ON [data].[HD_NAME]
(
	[HD] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [NonClusteredIndex-20160915-215236]    Script Date: 27.11.2016 12:45:41 ******/
CREATE NONCLUSTERED INDEX [NonClusteredIndex-20160915-215236] ON [data].[HR]
(
	[HD] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [NonClusteredIndex-20160915-195354]    Script Date: 27.11.2016 12:45:41 ******/
CREATE NONCLUSTERED INDEX [NonClusteredIndex-20160915-195354] ON [data].[TYC2_HD]
(
	[HD] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
USE [master]
GO
ALTER DATABASE [Astro] SET  READ_WRITE 
GO
