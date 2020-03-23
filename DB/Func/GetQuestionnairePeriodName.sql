IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GetQuestionnairePeriodName]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].GetQuestionnairePeriodName
GO
Create FUNCTION [dbo].GetQuestionnairePeriodName
(
	@FromDate datetime,
	@ToDate datetime,
	@QuestionnaireID int
)
returns nvarchar(50) AS
BEGIN
	declare  @period nvarchar(50)
	declare @frequency int
	select @frequency=Frequency from APQuestionnaires where ID=@QuestionnaireID
	
	if @frequency=1
	begin
		--per week
		set @period=CONVERT(varchar(100), @FromDate, 102) + '-' + CONVERT(varchar(100), @ToDate, 102)
	end	
	else if @frequency=2
	begin
		--per month
		set @period=convert(varchar,DATEPART(year,@FromDate)) + '年' + convert(varchar,DATEPART(MONTH,@FromDate)) + '月'
	end	
	else if @frequency=3
	begin
		--per quater
		set @period=convert(varchar,DATEPART(year,@FromDate)) + '年' + convert(varchar,datepart(quarter,@FromDate)) + '季度'
	end	
	else if @frequency=4
	begin
		--per half year
		set @period=convert(varchar,DATEPART(year,@FromDate)) + '年' + (case when DATEPART(MONTH,@FromDate)<=6 then '上半年' else '下半年' end)
	end	
	else if @frequency=5
	begin
		--per year
		set @period=convert(varchar,DATEPART(year,@FromDate)) + '年'
	end	
	return @period
END

