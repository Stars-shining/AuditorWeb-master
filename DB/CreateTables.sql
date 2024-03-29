
--if you need create particular table please add your script in this file
--before you add your script please add your name before the code
--in order to simplify the administration process, please add all your create script in one place.


--create table by Diego
BEGIN TRANSACTION;
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[APUsers]') AND type in (N'U'))
BEGIN

CREATE TABLE [dbo].[APUsers](
[ID] [int] IDENTITY(1,1) NOT NULL,
[LoginName] nvarchar(50) NULL,
[UserName] nvarchar(50) NULL,
[Password] nvarchar(50) NULL,

[DateOfBirth] datetime NULL,
[Sex] int NULL,
[Address] nvarchar(500) NULL,
[Postcode] nvarchar(50) NULL,
[Email] nvarchar(50) NULL,
[MobilePhone] nvarchar(50) NULL,
[Telephone] nvarchar(50) NULL,
[PhotoPath] nvarchar(500) NULL,

[AreaID] int NULL,
[Province] nvarchar(50) NULL,
[City] nvarchar(50) NULL,
[District] nvarchar(50) NULL,

[Degree] int NULL,
[IDCardNumber] nvarchar(50) NULL,
[Region] int NULL,
[HouseHoldRegistration] int NULL,
[HouseHoldAddress] nvarchar(500) NULL,
[Department] nvarchar(50) NULL,
[Position] nvarchar(50) NULL,

[BankAccount] nvarchar(50) NULL,
[OpeningBankName] nvarchar(50) NULL,
[TrainingScore] decimal(38,18) NULL,
[TrainingTime] datetime NULL,
[TrainingComment] nvarchar(max) NULL,
[GroupID] int NULL,
[CompanyID] int NULL,
[EntryTime] datetime NULL,
[RoleID] int NULL,
[bHasProtocol] bit NULL,
[ProtocolType] int NULL,
[bHasExperience] bit NULL,

[CreateTime]  datetime NULL,
[CreateUserID] INT NULL,
[LastModifiedTime] datetime null,
[LastModifiedUserID] INT NULL,
[Status] int NULL,

[ProjectID] int NULL,
[ClientID] int NULL,

[LastLoginTime] datetime null,
[LastLoginIP] nvarchar(50) NULL,

[DeleteFlag] bit default 0 NULL,
[DeleteTime] datetime NULL,
 CONSTRAINT [PK_APUsers] PRIMARY KEY CLUSTERED 
(
 [ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

END
GO

RAISERROR (N'[dbo].[APUsers]: Create Batch: 1.....Done!', 10, 1) WITH NOWAIT; 
COMMIT;


BEGIN TRANSACTION;
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[APQuestionnaires]') AND type in (N'U'))
BEGIN

CREATE TABLE [dbo].[APQuestionnaires](
[ID] [int] IDENTITY(1,1) NOT NULL,
[Name] nvarchar(50) NULL,
[FromDate] datetime null,
[ToDate] datetime NULL,
[TotalScore] decimal(38,18) NULL,
[SampleNumber] int NULL,
[Frequency] int NULL,
[Description] nvarchar(max) NULL,
[ProjectID] int Null,

[CreateTime]  datetime NULL,
[CreateUserID] INT NULL,
[LastModifiedTime] datetime null,
[LastModifiedUserID] INT NULL,
[Status] int NULL,
[DeleteFlag] bit default 0 NULL,
[DeleteTime] datetime NULL,
[BAutoTickCorrectOption] bit NULL,
[BAutoRefreshPage] bit NULL,
[UploadType] int NULL,
 CONSTRAINT [PK_APQuestionnaires] PRIMARY KEY CLUSTERED 
(
 [ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO

RAISERROR (N'[dbo].[APQuestionnaires]: Create Batch: 1.....Done!', 10, 1) WITH NOWAIT; 
COMMIT;


BEGIN TRANSACTION;
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[APQuestions]') AND type in (N'U'))
BEGIN

CREATE TABLE [dbo].[APQuestions](
[ID] [int] IDENTITY(1,1) NOT NULL,
[Code] nvarchar(50) NULL,
[Title] nvarchar(max) NULL,
[ParentCode] nvarchar(50) NULL,
[TotalScore] decimal(38,18) NULL,
[CountType] int NULL,
[QuestionType] int NULL,
[bAllowImage] bit NULL,
[bAllowAudio] bit NULL,
[bAllowVideo] bit NULL,
[bMustImage] bit NULL,
[bMustAudio] bit NULL,
[bMustVideo] bit NULL,
[Description] nvarchar(max) NULL,

[QuestionnaireID] int Null,
[LinkQuestionID] int Null,
[LinkOptionID] int Null,

[bHidden] bit Null,

[CreateTime]  datetime NULL,
[CreateUserID] INT NULL,
[LastModifiedTime] datetime null,
[LastModifiedUserID] INT NULL,
[Status] int NULL,
 CONSTRAINT [PK_APQuestions] PRIMARY KEY CLUSTERED 
(
 [ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
RAISERROR (N'[dbo].[APQuestion]: Create Batch: 1.....Done!', 10, 1) WITH NOWAIT; 
COMMIT;


BEGIN TRANSACTION;
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[APOptions]') AND type in (N'U'))
BEGIN

CREATE TABLE [dbo].[APOptions](
[ID] [int] IDENTITY(1,1) NOT NULL,
[Title] nvarchar(max) NULL,
[Score] decimal(38,18) NULL,
[OptionImageID] int NULL,
[bMustImage] bit NULL,
[bAllowText] bit NULL,
[bCorrectOption] bit NULL,
[JumpQuestionCode] nvarchar(max) NULL,
[ShowQuestionCode] nvarchar(max) NULL,
[QuestionID] int Null,
 CONSTRAINT [PK_APOptions] PRIMARY KEY CLUSTERED 
(
 [ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
RAISERROR (N'[dbo].[APOptions]: Create Batch: 1.....Done!', 10, 1) WITH NOWAIT; 
COMMIT;


BEGIN TRANSACTION;
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[APAnswers]') AND type in (N'U'))
BEGIN

CREATE TABLE [dbo].[APAnswers](
[ID] [int] IDENTITY(1,1) NOT NULL,
[TotalScore] decimal(38,18) NULL,
[Description] nvarchar(max) NULL,
[ResultID] int Null,
[QuestionID] int Null,
[CreateTime]  datetime NULL,
[CreateUserID] INT NULL,
[LastModifiedTime] datetime null,
[LastModifiedUserID] INT NULL,
[Status] int NULL,
 CONSTRAINT [PK_APAnswers] PRIMARY KEY CLUSTERED 
(
 [ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO

IF EXISTS (SELECT * FROM SYSINDEXES WHERE NAME='NCI_APAnswers_QuestionID')
DROP INDEX APAnswers.NCI_APAnswers_QuestionID

CREATE NONCLUSTERED INDEX NCI_APAnswers_QuestionID
ON APAnswers(QuestionID)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

IF EXISTS (SELECT * FROM SYSINDEXES WHERE NAME='NCI_APAnswers_ResultID')
DROP INDEX APAnswers.NCI_APAnswers_ResultID

CREATE NONCLUSTERED INDEX NCI_APAnswers_ResultID
ON APAnswers(ResultID)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

GO

RAISERROR (N'[dbo].[APAnswers]: Create Batch: 1.....Done!', 10, 1) WITH NOWAIT; 
COMMIT;


BEGIN TRANSACTION;
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[APAnswerOptions]') AND type in (N'U'))
BEGIN

CREATE TABLE [dbo].[APAnswerOptions](
[ID] [int] IDENTITY(1,1) NOT NULL,
[OptionID] int NULL,
[OptionText] nvarchar(max) NULL,
[AnswerID] int Null,
 CONSTRAINT [PK_APAnswerOptions] PRIMARY KEY CLUSTERED 
(
 [ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO

IF EXISTS (SELECT * FROM SYSINDEXES WHERE NAME='NCI_APAnswerOptions_AnswerID')
DROP INDEX APAnswerOptions.NCI_APAnswerOptions_AnswerID

CREATE NONCLUSTERED INDEX NCI_APAnswerOptions_AnswerID
ON APAnswerOptions(AnswerID)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

GO

RAISERROR (N'[dbo].[APAnswerOptions]: Create Batch: 1.....Done!', 10, 1) WITH NOWAIT; 
COMMIT;


BEGIN TRANSACTION;
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[APAnswerAttachments]') AND type in (N'U'))
BEGIN

CREATE TABLE [dbo].[APAnswerAttachments](
[ID] [int] IDENTITY(1,1) NOT NULL,
[FileName] nvarchar(500) NULL,
[FileType] int NULL,
[FileSize] int NULL,

[FilePath_Relevant] nvarchar(500) NULL,
[FilePath_Disk] nvarchar(500) NULL,
[ThumbnailPath_Relevent] nvarchar(500) NULL,
[ThumbnailPath_Disk] nvarchar(500) NULL,

[Description] nvarchar(max) NULL,
[AnswerID] int NULL,

[CreateTime]  datetime NULL,
[CreateUserID] INT NULL,
[LastModifiedTime] datetime null,
[LastModifiedUserID] INT NULL,
[Status] int NULL,
 CONSTRAINT [PK_APAnswerAttachments] PRIMARY KEY CLUSTERED 
(
 [ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
RAISERROR (N'[dbo].[APAnswerAttachments]: Create Batch: 1.....Done!', 10, 1) WITH NOWAIT; 
COMMIT;


BEGIN TRANSACTION;
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[APProjects]') AND type in (N'U'))
BEGIN

CREATE TABLE [dbo].[APProjects](
[ID] [int] IDENTITY(1,1) NOT NULL,
[Name] nvarchar(500) NULL,
[TypeID] int NULL,
[Background] nvarchar(max) NULL,
[FromDate] datetime NULL,
[ToDate] datetime NULL,
[Description] nvarchar(max) NULL,
[SampleNumber] int NULL,
[Frequency] int NULL,
[CoreUserID] int NULL,	--研究员
[PrimaryApplyUserID] int NULL,--总控
[QCLeaderUserID] int NULL,--QC督导
[BHasAreaUser] bit NULL,
[BAutoAppeal] bit NULL,
[GroupID] int NULL,

[CreateTime]  datetime NULL,
[CreateUserID] INT NULL,
[LastModifiedTime] datetime null,
[LastModifiedUserID] INT NULL,
[Status] int NULL,

[UploadValidationType] int NULL,

[DeleteFlag] bit default 0 NULL,
[DeleteTime] datetime NULL,
 CONSTRAINT [PK_APProjects] PRIMARY KEY CLUSTERED 
(
 [ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
RAISERROR (N'[dbo].[APProjects]: Create Batch: 1.....Done!', 10, 1) WITH NOWAIT; 
COMMIT;


BEGIN TRANSACTION;
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[APUserMenu]') AND type in (N'U'))
BEGIN

CREATE TABLE [dbo].[APUserMenu](
[ID] [int] IDENTITY(1,1) NOT NULL,
[Name] nvarchar(500) NULL,
[Title] nvarchar(500) NULL,
[UserTypeID] int NULL,
[ParentID] int NULL,
[Description] nvarchar(max) NULL,
[Url] nvarchar(500) NULL,
 CONSTRAINT [PK_APUserMenu] PRIMARY KEY CLUSTERED 
(
 [ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
RAISERROR (N'[dbo].[APUserMenu]: Create Batch: 1.....Done!', 10, 1) WITH NOWAIT; 
COMMIT;

BEGIN TRANSACTION;
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[BusinessConfiguration]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[BusinessConfiguration](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[ItemKey] [int] NULL,
	[ItemValue] [nvarchar](500) NULL,
	[ItemDesc] [nvarchar](500) NULL,
	[ItemOrder] [int] NULL,
 CONSTRAINT [PK_BusinessConfiguration] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
RAISERROR (N'[dbo].[BusinessConfiguration]: Create Batch: 1.....Done!', 10, 1) WITH NOWAIT; 
COMMIT;

BEGIN TRANSACTION;
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DocumentFiles]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[DocumentFiles](
	[ID] [int] identity(1,1) NOT NULL,
	[FileName] [nvarchar](500) NULL,
	[FileSize] decimal(38,18) NULL,
	[TimeLength] nvarchar(255) NULL,
	[OriginalFileName] [nvarchar](500) NULL,
	[ThumbRelevantPath] [nvarchar](500) NULL,
	[RelevantPath] [nvarchar](500) NULL,
	[PhysicalPath] [nvarchar](500) NULL,
	[FileType] int NULL, -- Image, Document, Video, Audio
	[FromDate] datetime NULL,
	[ToDate] datetime NULL,
	[RelatedID] [int] NULL,
	[ResultID] [int] NULL,
	[TempCode] [nvarchar](500) NULL,
	[TypeID] [int] NULL,
	[InputDate] datetime NULL,
	[UserID] [int] NULL,
	[Status] [int] NULL,
	[BackupStatus] [int] NULL,
 CONSTRAINT [PK_DocumentFiles] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
RAISERROR (N'[dbo].[DocumentFiles]: Create Batch: 1.....Done!', 10, 1) WITH NOWAIT; 
COMMIT;

BEGIN TRANSACTION;
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DirectoryMapping]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[DirectoryMapping](
	[ID] [int] NOT NULL,
	[PhysicalPath] [nvarchar](500) NULL,
	[VituralPath] [nvarchar](500) NULL,
	[IsCurrent] bit NULL
 CONSTRAINT [PK_DirectoryMapping] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
RAISERROR (N'[dbo].[DirectoryMapping]: Create Batch: 1.....Done!', 10, 1) WITH NOWAIT; 
COMMIT;

BEGIN TRANSACTION;
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[APClients]') AND type in (N'U'))
BEGIN

CREATE TABLE [dbo].[APClients](
[ID] [int] IDENTITY(1,1) NOT NULL,
[Code] nvarchar(50) NULL,
[Name] nvarchar(50) NULL,
[Province] nvarchar(50) NULL,
[City] nvarchar(50) NULL,
[District] nvarchar(50) NULL,
[Address] nvarchar(500) NULL,
[LocationCodeX] nvarchar(50) NULL,
[LocationCodeY] nvarchar(50) NULL,
[OpeningTime] nvarchar(500) NULL,
[ParentID] int NULL,
[Description] nvarchar(max) NULL,

[Email]  nvarchar(50) NULL,
[PhoneNumber] nvarchar(50) NULL,
[Postcode] nvarchar(50) NULL,

[LevelID] int NULL,
[ProjectID] int NULL,

[CreateTime]  datetime NULL,
[CreateUserID] INT NULL,
[LastModifiedTime] datetime null,
[LastModifiedUserID] INT NULL,
[Status] int NULL,
 CONSTRAINT [PK_APClients] PRIMARY KEY CLUSTERED 
(
 [ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

END
GO

RAISERROR (N'[dbo].[APClients]: Create Batch: 1.....Done!', 10, 1) WITH NOWAIT; 
COMMIT;


BEGIN TRANSACTION;
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[APCity]') AND type in (N'U'))
BEGIN

CREATE TABLE [dbo].[APCity](
[ID] [int] IDENTITY(1,1) NOT NULL,
[Code] nvarchar(50) NULL,
[Name] nvarchar(50) NULL,
[Level] int NULL,
[AreaID] int NULL,
[bDirectCity] bit NULL,
 CONSTRAINT [PK_APCity] PRIMARY KEY CLUSTERED 
(
 [ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

END
GO

RAISERROR (N'[dbo].[APCity]: Create Batch: 1.....Done!', 10, 1) WITH NOWAIT; 
COMMIT;


BEGIN TRANSACTION;
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[APClientStructure]') AND type in (N'U'))
BEGIN

CREATE TABLE [dbo].[APClientStructure](
[ID] [int] IDENTITY(1,1) NOT NULL,
[LevelID] [int] NULL,
[Name] nvarchar(50) NULL,
[ProjectID] [int] NULL,
 CONSTRAINT [PK_APClientStructure] PRIMARY KEY CLUSTERED 
(
 [ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

END
GO

RAISERROR (N'[dbo].[APClientStructure]: Create Batch: 1.....Done!', 10, 1) WITH NOWAIT; 
COMMIT;


BEGIN TRANSACTION;
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[APQuestionnaireDelivery]') AND type in (N'U'))
BEGIN

CREATE TABLE [dbo].[APQuestionnaireDelivery](
[ID] [int] IDENTITY(1,1) NOT NULL,
[QuestionnaireID] int NULL,
[ClientID] int NULL,
[FromDate] datetime NULL,
[ToDate] datetime NULL,
[TypeID] int NULL,
[AcceptUserID] int NULL,
[SampleNumber] int NULL,
[ProjectID] int NULL,
[CreateTime] datetime NULL,
[CreateUserID] INT NULL,
 CONSTRAINT [PK_APQuestionnaireDelivery] PRIMARY KEY CLUSTERED 
(
 [ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
RAISERROR (N'[dbo].[APQuestionnaireDelivery]: Create Batch: 1.....Done!', 10, 1) WITH NOWAIT; 
COMMIT;


BEGIN TRANSACTION;
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[APUserRole]') AND type in (N'U'))
BEGIN

CREATE TABLE [dbo].[APUserRole](
[ID] [int] NOT NULL,
[Name] nvarchar(50) NULL,
[Level] [int] NULL,
[FirstPage] nvarchar(50) NULL,
[MenuPage] nvarchar(50) NULL,
[ProjectMenuPage] nvarchar(50) NULL,
 CONSTRAINT [PK_APUserRole] PRIMARY KEY CLUSTERED 
(
 [ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

END
GO

RAISERROR (N'[dbo].[APUserRole]: Create Batch: 1.....Done!', 10, 1) WITH NOWAIT; 
COMMIT;


BEGIN TRANSACTION;
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[APQuestionnaireDeliverySettings]') AND type in (N'U'))
BEGIN

CREATE TABLE [dbo].[APQuestionnaireDeliverySettings](
[ID] [int] IDENTITY(1,1) NOT NULL,
[AreaLevelID] [int] NULL,
[CityLevelID] [int] NULL,
[VisitLevelID] [int] NULL,
[QCLevelID] [int] NULL,
[ProjectID] [int] NULL,
 CONSTRAINT [PK_APQuestionnaireDeliverySettings] PRIMARY KEY CLUSTERED 
(
 [ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

END
GO

RAISERROR (N'[dbo].[APQuestionnaireDeliverySettings]: Create Batch: 1.....Done!', 10, 1) WITH NOWAIT; 
COMMIT;


BEGIN TRANSACTION;
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[APQuestionnaireResults]') AND type in (N'U'))
BEGIN

CREATE TABLE [dbo].[APQuestionnaireResults](
[ID] [int] IDENTITY(1,1) NOT NULL,
[DeliveryID] int NULL,
[QuestionnaireID] int NULL,
[ClientID] int NULL,
[ProjectID] int NULL,
[FromDate] datetime NULL,
[ToDate] datetime NULL,
[Score] decimal(38,18) NULL,

[VisitBeginTime]  datetime NULL,
[VisitEndTime] datetime NULL,
[VideoPath] nvarchar(500) NULL,
[VideoLength] nvarchar(50) NULL,
[Description] nvarchar(max) NULL,

[TimePeriodID] int NULL,--时间段，关联到时间段定义表
[TimeLength] int NULL,--访问时长，分钟为单位
[WeekNum] int NULL,--星期几

[OtherPlatformID] nvarchar(500) NULL,--其他平台ID编号

[LocationX] float NULL,--坐标X
[LocationY] float NULL,--坐标Y
[Address] nvarchar(500) NULL,--坐标地址

[QuestionnaireVersion] nvarchar(50) NULL,--问卷版本

[CurrentQuestionID] int NULL,
[CurrentProgress] decimal(38,18) NULL,
[UploadBeginTime] datetime NULL,
[UploadEndTime] datetime NULL,
[bOverTime] bit NULL,

[VisitUserUploadStatus] int NULL,
[VisitUserID] int NULL,
[CityUserAuditStatus] int NULL,
[CityUserAuditTime] datetime NULL,
[CityUserID] int NULL,

[AreaUserAuditStatus] int NULL,
[AreaUserAuditTime] datetime NULL,
[AreaUserID] int NULL,

[QCUserAuditStatus] int NULL,
[QCUserAuditTime] datetime NULL,
[QCUserID] int NULL,

[QCLeaderAuditStatusFirst] int NULL,
[QCLeaderAuditTimeFirst] datetime NULL,
[QCLeaderUserIDFirst] int NULL,

[ClientUserAuditStatus] int NULL,
[ClientUserAuditTime] datetime NULL,
[ClientUserID] int NULL,
[CurrentClientUserID] int NULL,

[QCLeaderAuditStatus] int NULL,
[QCLeaderAuditTime] datetime NULL,
[QCLeaderUserID] int NULL,

[LastModifiedTime] datetime null,
[LastModifiedUserID] INT NULL,
[Status] int NULL,
[ReAuditStatus] int NULL,

[LastAuditNote] nvarchar(max) NULL,
 CONSTRAINT [PK_APQuestionnaireResults] PRIMARY KEY CLUSTERED 
(
 [ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO

IF EXISTS (SELECT * FROM SYSINDEXES WHERE NAME='NCI_APQuestionnaireResults_QuestionnaireID')
DROP INDEX APQuestionnaireResults.NCI_APQuestionnaireResults_QuestionnaireID

CREATE NONCLUSTERED INDEX NCI_APQuestionnaireResults_QuestionnaireID
ON APQuestionnaireResults(QuestionnaireID)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

GO
RAISERROR (N'[dbo].[APQuestionnaireResults]: Create Batch: 1.....Done!', 10, 1) WITH NOWAIT; 
COMMIT;


BEGIN TRANSACTION;
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[APProjectTimePeriod]') AND type in (N'U'))
BEGIN

CREATE TABLE [dbo].APProjectTimePeriod(
[ID] [int] IDENTITY(1,1) NOT NULL,
[ProjectID] int NULL,
[TimeStart] time(7) NULL,
[TimeEnd] time(7) NULL,
[Title] nvarchar(50) NULL,
 CONSTRAINT [PK_APProjectTimePeriod] PRIMARY KEY CLUSTERED 
(
 [ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

END
GO

RAISERROR (N'[dbo].[APProjectTimePeriod]: Create Batch: 1.....Done!', 10, 1) WITH NOWAIT; 
COMMIT;


BEGIN TRANSACTION;
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[APAuditHistory]') AND type in (N'U'))
BEGIN

CREATE TABLE [dbo].[APAuditHistory](
[ID] [int] IDENTITY(1,1) NOT NULL,
[AuditUserID] [int] NULL,
[AuditStatus] [int] NULL,
[AuditTime] datetime NULL,
[AuditNotes] nvarchar(max) NULL,

[AuditResult] bit NULL,
[ReturnUserType] int NULL,
[ReturnUserID] int NULL,
[TypeID] [int] NULL,
[QuestionnaireResultID] [int] NULL,
[ClientID] [int] NULL,
[ProjectID] [int] NULL,
 CONSTRAINT [PK_APAuditHistory] PRIMARY KEY CLUSTERED 
(
 [ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

END
GO

RAISERROR (N'[dbo].[APAuditHistory]: Create Batch: 1.....Done!', 10, 1) WITH NOWAIT; 
COMMIT;


BEGIN TRANSACTION;
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[APQuestionAuditNotes]') AND type in (N'U'))
BEGIN

CREATE TABLE [dbo].[APQuestionAuditNotes](
[ID] [int] IDENTITY(1,1) NOT NULL,
[AuditNotes] nvarchar(max) NULL,
[AuditTypeID] [int] NULL, --3  访问员 执行督导 区控  4质控 5 客户 
[UserTypeID] [int] NULL,
[QuestionID] [int] NULL,
[ResultID] [int] NULL,
[CreateUserID] [int] NULL,
[CreateTime] datetime NULL,
 CONSTRAINT [PK_APQuestionAuditNotes] PRIMARY KEY CLUSTERED 
(
 [ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

END
GO

RAISERROR (N'[dbo].[APQuestionAuditNotes]: Create Batch: 1.....Done!', 10, 1) WITH NOWAIT; 
COMMIT;



BEGIN TRANSACTION;
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[APUserRole]') AND type in (N'U'))
BEGIN

CREATE TABLE [dbo].[APUserRole](
[ID] [int] NOT NULL,
[Name] nvarchar(50) NULL,
[FirstPage] nvarchar(500) NULL, 
[MenuPage] nvarchar(500) NULL, 
[ProjectMenuPage] nvarchar(500) NULL, 
 CONSTRAINT [PK_APUserRole] PRIMARY KEY CLUSTERED 
(
 [ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

END
GO

RAISERROR (N'[dbo].[APUserRole]: Create Batch: 1.....Done!', 10, 1) WITH NOWAIT; 
COMMIT;


BEGIN TRANSACTION;
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[APMessage]') AND type in (N'U'))
BEGIN

CREATE TABLE [dbo].[APMessage](
[ID] [int] IDENTITY(1,1) NOT NULL,
[Title] nvarchar(50) NULL,
[Content] nvarchar(max) NULL, 
[FromUserID] int NULL, 
[AcceptUserID] int NULL, 
[TypeID] int NULL,
[RelatedID] int NULL,
[RelatedUrl] nvarchar(500) NULL,
[ProjectID] int NULL,
[TemplateID] int NULL,
[CreateUserID] int NULL,
[CreateTime] datetime NULL,
[Status] int NULL,
 CONSTRAINT [PK_APMessage] PRIMARY KEY CLUSTERED 
(
 [ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

END
GO

RAISERROR (N'[dbo].[APMessage]: Create Batch: 1.....Done!', 10, 1) WITH NOWAIT; 
COMMIT;


BEGIN TRANSACTION;
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[APProjectUsers]') AND type in (N'U'))
BEGIN

CREATE TABLE [dbo].[APProjectUsers](
[ID] [int] IDENTITY(1,1) NOT NULL,
[UserID] [int] NULL,
[RoleID] [int] NULL, 
[ProjectID] [int] NULL, 
 CONSTRAINT [PK_APProjectUsers] PRIMARY KEY CLUSTERED 
(
 [ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

END
GO

RAISERROR (N'[dbo].[APProjectUsers]: Create Batch: 1.....Done!', 10, 1) WITH NOWAIT; 
COMMIT;


BEGIN TRANSACTION;
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[APAnswerEditHistory]') AND type in (N'U'))
BEGIN

CREATE TABLE [dbo].[APAnswerEditHistory](
[ID] [int] IDENTITY(1,1) NOT NULL,
[AnswerID] [int] NULL,
[EditNote] nvarchar(500) NULL,
[ScoreNote] nvarchar(500) NULL,
[ResultID] [int] NULL,
[StageStatusID] [int] NULL,
[UserID] [int] NULL,
[InputDate] [datetime] NULL,
 CONSTRAINT [PK_APAnswerEditHistory] PRIMARY KEY CLUSTERED 
(
 [ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

END
GO

RAISERROR (N'[dbo].[APAnswerEditHistory]: Create Batch: 1.....Done!', 10, 1) WITH NOWAIT; 
COMMIT;


BEGIN TRANSACTION;
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[APAppealAudit]') AND type in (N'U'))
BEGIN

CREATE TABLE [dbo].[APAppealAudit](
[ID] [int] IDENTITY(1,1) NOT NULL,
[ResultID] [int] NULL,
[QuestionID] [int] NULL,
[AppealStatus] [int] NULL,
[UserID] [int] NULL,
[InputDate] [datetime] NULL,
 CONSTRAINT [PK_APAppealAudit] PRIMARY KEY CLUSTERED 
(
 [ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

END
GO

RAISERROR (N'[dbo].[APAppealAudit]: Create Batch: 1.....Done!', 10, 1) WITH NOWAIT; 
COMMIT;


BEGIN TRANSACTION;
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[APAppealPeriod]') AND type in (N'U'))
BEGIN

CREATE TABLE [dbo].[APAppealPeriod](
[ID] [int] IDENTITY(1,1) NOT NULL,
[ProjectID] [int] NULL,
[QuestionnaireID] [int] NULL,
[FromDate] [datetime] NULL,
[ToDate] [datetime] NULL,
[CreateUserID] int NULL,
[CreateTime] datetime NULL,
 CONSTRAINT [PK_APAppealPeriod] PRIMARY KEY CLUSTERED 
(
 [ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

END
GO

RAISERROR (N'[dbo].[APAppealPeriod]: Create Batch: 1.....Done!', 10, 1) WITH NOWAIT; 
COMMIT;


BEGIN TRANSACTION;
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[APTraining]') AND type in (N'U'))
BEGIN

CREATE TABLE [dbo].[APTraining](
[ID] [int] IDENTITY(1,1) NOT NULL,
[ProjectID] [int] NULL,
[FromDate] [datetime] NULL,
[ToDate] [datetime] NULL,
[Title] nvarchar(500) NULL,
[Description] varchar(max) NULL,
[TypeID] int NULL,
[CreateUserID] int NULL,
[CreateTime] datetime NULL,
[LastModifiedUserID] int NULL,
[LastModifiedTime] datetime NULL,
 CONSTRAINT [PK_APTraining] PRIMARY KEY CLUSTERED 
(
 [ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

END
GO

RAISERROR (N'[dbo].[APTraining]: Create Batch: 1.....Done!', 10, 1) WITH NOWAIT; 
COMMIT;


BEGIN TRANSACTION;
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[APTrainingFiles]') AND type in (N'U'))
BEGIN

CREATE TABLE [dbo].[APTrainingFiles](
[ID] [int] IDENTITY(1,1) NOT NULL,
[TrainingID] [int] NULL,
[FileName] [nvarchar](500) NULL,
[FileSize] decimal(38,18) NULL,
[TimeLength] nvarchar(255) NULL,
[OriginalFileName] [nvarchar](500) NULL,
[ThumbRelevantPath] [nvarchar](500) NULL,
[RelevantPath] [nvarchar](500) NULL,
[PhysicalPath] [nvarchar](500) NULL,
[FileType] int NULL, -- Image, Document, Video, Audio
[FromDate] datetime NULL,
[ToDate] datetime NULL,
[RelatedID] [int] NULL,
[TempCode] [nvarchar](500) NULL,
[TypeID] [int] NULL,
[InputDate] datetime NULL,
[UserID] [int] NULL,
[Status] [int] NULL,
[BackupStatus] [int] NULL,
 CONSTRAINT [PK_APTrainingFiles] PRIMARY KEY CLUSTERED 
(
 [ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

END
GO

RAISERROR (N'[dbo].[APTrainingFiles]: Create Batch: 1.....Done!', 10, 1) WITH NOWAIT; 
COMMIT;
--end create by Diego