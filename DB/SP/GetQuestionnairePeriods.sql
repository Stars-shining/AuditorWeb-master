IF OBJECT_ID('dbo.GetQuestionnairePeriods', 'P') IS NULL EXEC('Create Procedure dbo.GetQuestionnairePeriods AS SELECT ''Not Implemented...'' ')
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE  [dbo].[GetQuestionnairePeriods]
	@ID int
AS
BEGIN
/*
declare @ID int
set @ID=5
*/

declare @QuestionnairePeriods table
(	
	FromDate datetime,
	ToDate datetime,
	Period nvarchar(50)
)
	declare @fromdate datetime
	declare @todate datetime
	declare @frequency int
	SET ROWCOUNT 1
	select @fromdate=FromDate,@todate=ToDate,@frequency=Frequency from APQuestionnaires where @ID=ID
	SET ROWCOUNT 0
	
	declare @period nvarchar(50)
	declare @tempFromDate datetime
	declare @tempToDate datetime
	set @tempFromDate=@fromdate
	if @frequency=1
	begin
		--per week
		while @tempFromDate<=@todate
		begin
			set @tempToDate=dateadd(day,8 - datepart(weekday,@tempFromDate),@tempFromDate)
			if @tempToDate<@todate
			begin
				set @period=CONVERT(varchar(100), @tempFromDate, 102) + '-' + CONVERT(varchar(100), @tempToDate, 102)
				insert into @QuestionnairePeriods
				select @tempFromDate,@tempToDate,@period
				set @tempFromDate=DATEADD(day,1,@tempToDate)
			end
			else
			begin
				set @period=CONVERT(varchar(100), @tempFromDate, 102) + '-' + CONVERT(varchar(100), @todate, 102)
				insert into @QuestionnairePeriods
				select @tempFromDate,@todate,@period
				set @tempFromDate=DATEADD(day,1,@todate)
			end
		end
	end	
	else if @frequency=2
	begin
		--per month
		while @tempFromDate<=@todate
		begin
			set @tempToDate=DATEADD(Day,-1,CONVERT(char(8),DATEADD(Month,1,@tempFromDate),120)+'1')
			if @tempToDate<@todate
			begin
				set @period=convert(varchar,DATEPART(year,@tempFromDate)) + '年' + convert(varchar,DATEPART(MONTH,@tempFromDate)) + '月'
				insert into @QuestionnairePeriods
				select @tempFromDate,@tempToDate,@period
				set @tempFromDate=DATEADD(day,1,@tempToDate)
			end
			else
			begin
				set @period=convert(varchar,DATEPART(year,@tempFromDate)) + '年' + convert(varchar,DATEPART(MONTH,@tempFromDate)) + '月'
				insert into @QuestionnairePeriods
				select @tempFromDate,@todate,@period
				set @tempFromDate=DATEADD(day,1,@todate)
			end
		end
	end	
	else if @frequency=3
	begin
		--per quater
		while @tempFromDate<=@todate
		begin
			set @tempToDate=DATEADD(Day,-1,CONVERT(char(8),DATEADD(Month,1+DATEPART(Quarter,@tempFromDate)*3-Month(@tempFromDate),@tempFromDate),120)+'1')
			if @tempToDate<@todate
			begin
				set @period=convert(varchar,DATEPART(year,@tempFromDate)) + '年' + convert(varchar,datepart(quarter,@tempFromDate)) + '季度'
				insert into @QuestionnairePeriods
				select @tempFromDate,@tempToDate,@period
				set @tempFromDate=DATEADD(day,1,@tempToDate)
			end
			else
			begin
				set @period=convert(varchar,DATEPART(year,@tempFromDate)) + '年' + convert(varchar,datepart(quarter,@tempFromDate)) + '季度'
				insert into @QuestionnairePeriods
				select @tempFromDate,@todate,@period
				set @tempFromDate=DATEADD(day,1,@todate)
			end
		end
	end	
	else if @frequency=4
	begin
		--per half year
		while @tempFromDate<=@todate
		begin
			set @tempToDate=case when DATEPART(month,@tempFromDate)<=6 then CONVERT(datetime,CONVERT(char(4),DATEPART(year,@tempFromDate))+'-06-30') 
																	   else CONVERT(datetime,CONVERT(char(4),DATEPART(year,@tempFromDate))+'-12-31') end
			if @tempToDate<@todate
			begin
				set @period=convert(varchar,DATEPART(year,@tempFromDate)) + '年' + (case when DATEPART(MONTH,@tempFromDate)<=6 then '上半年' else '下半年' end)
				insert into @QuestionnairePeriods
				select @tempFromDate,@tempToDate,@period
				set @tempFromDate=DATEADD(day,1,@tempToDate)
			end
			else
			begin
				set @period=convert(varchar,DATEPART(year,@tempFromDate)) + '年' + (case when DATEPART(MONTH,@tempFromDate)<=6 then '上半年' else '下半年' end)
				insert into @QuestionnairePeriods
				select @tempFromDate,@todate,@period
				set @tempFromDate=DATEADD(day,1,@todate)
			end
		end
	end	
	else if @frequency=5
	begin
		--per year
		while @tempFromDate<=@todate
		begin
			set @tempToDate=CONVERT(datetime,CONVERT(char(4),DATEPART(year,@tempFromDate))+'-12-31') 
			
			if @tempToDate<@todate
			begin
				set @period=convert(varchar,DATEPART(year,@tempFromDate)) + '年'
				insert into @QuestionnairePeriods
				select @tempFromDate,@tempToDate,@period
				set @tempFromDate=DATEADD(day,1,@tempToDate)
			end
			else
			begin
				set @period=convert(varchar,DATEPART(year,@tempFromDate)) + '年'
				insert into @QuestionnairePeriods
				select @tempFromDate,@todate,@period
				set @tempFromDate=DATEADD(day,1,@todate)
			end
		end
	end	
	
select  * from @QuestionnairePeriods order by FromDate

END