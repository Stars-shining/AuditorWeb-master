delete from BusinessConfiguration where ItemDesc='ProjectStatus'
insert into BusinessConfiguration (ItemKey,ItemValue,ItemDesc)
select 1,'已创建','ProjectStatus' union
select 2,'执行中','ProjectStatus' union
select 3,'已执行','ProjectStatus'

delete from BusinessConfiguration where ItemDesc='QuestionnaireStatus'
insert into BusinessConfiguration (ItemKey,ItemValue,ItemDesc)
select 1,'已创建','QuestionnaireStatus' union
select 2,'执行中','QuestionnaireStatus' union
select 3,'已执行','QuestionnaireStatus'

delete from BusinessConfiguration where ItemDesc='ProjectType'
insert into BusinessConfiguration (ItemKey,ItemValue,ItemDesc)
select 1,'金融服务','ProjectType' union
select 2,'汽车销售','ProjectType' union
select 3,'地产销售','ProjectType' union
select 4,'餐饮服务','ProjectType'


delete from BusinessConfiguration where ItemDesc='QuestionType'
insert into BusinessConfiguration (ItemKey,ItemValue,ItemDesc)
select 1,'是非题','QuestionType' union
select 2,'单选题','QuestionType' union
select 3,'多选题','QuestionType' union
select 4,'填空题','QuestionType' union
select 5,'矩阵单选题','QuestionType' union
select 6,'矩阵多选题','QuestionType' union
select 7,'段落','QuestionType' union
select 8,'上传题','QuestionType'


delete from BusinessConfiguration where ItemDesc='CountType'
insert into BusinessConfiguration (ItemKey,ItemValue,ItemDesc)
select 1,'正确得分','CountType' union
select 2,'错误扣分','CountType' union
select 3,'全部正确得分','CountType' union
select 4,'选项分总和','CountType' union
select 5,'不得分不扣分','CountType' union
select 6,'选项叠加扣分','CountType' union
select 7,'等于选项分','CountType'


delete from dbo.APUserRole
insert into dbo.APUserRole (ID,FirstPage,Name,MenuPage, ProjectMenuPage)
select 1,'ProjectList.htm','总控','CommonLeftMasterUser.htm','CommonProjectLeftMasterUser.htm' union
select 2,'ProjectList.htm','区控','CommonLeftAreaUser.htm','CommonProjectLeftAreaUser.htm' union
select 3,'ProjectList.htm','执行督导','CommonLeftCityUser.htm','CommonProjectLeftCityUser.htm' union
select 4,'ProjectList.htm','访问员','CommonLeftVisitor.htm','CommonProjectLeftVisitor.htm' union
select 5,'ProjectList.htm','质控督导','CommonLeftQCLeader.htm','CommonProjectLeftQCLeader.htm' union
select 6,'ProjectList.htm','质控员','CommonLeftQCUser.htm','CommonProjectLeftQCUser.htm' union
select 7,'ProjectList.htm','研究员','CommonLeft.htm','CommonProjectLeft.htm' union
select 8,'ProjectList.htm','系统管理员','CommonLeft.htm','CommonProjectLeft.htm' union
select 10,'ProjectList.htm','质管员','CommonLeft.htm','CommonProjectLeftQMUser.htm' union
select 9,'QuestionnaireCheckListClient.htm','客户',NULL,'CommonProjectLeftClient.htm'


delete from APUsers where LoginName='admin'
insert into APUsers (LoginName,UserName,Password,RoleID,CreateTime,CreateUserID)
select 'admin','系统管理员','123456',8,GETDATE(),1

delete from BusinessConfiguration where ItemDesc='FileType'
insert into BusinessConfiguration (ItemKey,ItemValue,ItemDesc)
select 1,'图片','FileType' union
select 2,'录音','FileType' union
select 3,'录像','FileType' union
select 4,'文档','FileType' union
select 5,'其他','FileType'

delete from DirectoryMapping where ID=1
insert into DirectoryMapping (ID,PhysicalPath,VituralPath,IsCurrent)
select 1,'D:\Workspace\核查系统\Upload\Files\','../Upload/Files/',1

delete from BusinessConfiguration where ItemDesc='ProjectFrequency'
insert into BusinessConfiguration (ItemKey,ItemValue,ItemDesc)
select 1,'每周','ProjectFrequency' union
select 2,'每月','ProjectFrequency' union
select 3,'每季度','ProjectFrequency' union
select 4,'每半年','ProjectFrequency' union
select 5,'每年','ProjectFrequency' 


delete from BusinessConfiguration where ItemDesc='AreaDivision'
insert into BusinessConfiguration (ItemKey,ItemValue,ItemDesc)
select 1,'华东地区','AreaDivision' union
select 2,'华北地区','AreaDivision' union
select 3,'华中地区','AreaDivision' union
select 4,'华南地区','AreaDivision' union
select 5,'西南地区','AreaDivision' union
select 6,'西北地区','AreaDivision' union
select 7,'东北地区','AreaDivision' union
select 8,'港澳台地区','AreaDivision'

update dbo.APCity set areaID=1 where Level=1 and Code like '3%'
update dbo.APCity set areaID=2 where Level=1 and Code like '1%'
update dbo.APCity set areaID=7 where Level=1 and Code like '2%'
update dbo.APCity set areaID=5 where Level=1 and Code like '5%'
update dbo.APCity set areaID=6 where Level=1 and Code like '6%'
update dbo.APCity set areaID=3 where Level=1 and Code in (410000,420000,430000)
update dbo.APCity set areaID=4 where Level=1 and Code in (440000,450000,460000)
update dbo.APCity set areaID=8 where Level=1 and Code like '8%' or Code like '7%' 
update dbo.APCity set bDirectCity=1 where Level=1 and Name like '%市'

delete from BusinessConfiguration where ItemDesc='QuestionnaireUploadStatus'
insert into BusinessConfiguration (ItemKey,ItemValue,ItemDesc)
select 0,'未录入','QuestionnaireUploadStatus' union
select 1,'录入完成','QuestionnaireUploadStatus' union 
select 2,'录入未完成','QuestionnaireUploadStatus' union
select 3,'退回待修改','QuestionnaireUploadStatus' union
select 4,'已提交审核','QuestionnaireUploadStatus'

delete from BusinessConfiguration where ItemDesc='QuestionnaireAuditStatus'
insert into BusinessConfiguration (ItemKey,ItemValue,ItemDesc)
select 0,'未审核','QuestionnaireAuditStatus' union
select 1,'审核通过','QuestionnaireAuditStatus' union 
select 2,'审核不通过','QuestionnaireAuditStatus' union
select 3,'未裁决','QuestionnaireAuditStatus'

delete from BusinessConfiguration where ItemDesc='QuestionnaireClientStatus'
insert into BusinessConfiguration (ItemKey,ItemValue,ItemDesc)
select 0,'未申诉','QuestionnaireClientStatus' union
select 1,'已提交申诉','QuestionnaireClientStatus' union
select 2,'审核通过','QuestionnaireClientStatus' union
select 3,'审核不通过','QuestionnaireClientStatus' union
select 4,'申诉已处理','QuestionnaireClientStatus' union
select 6,'申诉未裁决','QuestionnaireClientStatus' union
select 7,'无申诉内容','QuestionnaireClientStatus'

delete from BusinessConfiguration where ItemDesc='QuestionnaireStageStatus'
insert into BusinessConfiguration (ItemKey,ItemValue,ItemDesc,ItemOrder)
select 0,'未开始','QuestionnaireStageStatus',1 union
select 1,'录入中','QuestionnaireStageStatus',2 union 
select 2,'执行督导审核中','QuestionnaireStageStatus',3 union 
select 3,'区控审核中','QuestionnaireStageStatus',4 union 
select 4,'质控审核中','QuestionnaireStageStatus',5 union 
select 8,'质控督导审核中','QuestionnaireStageStatus',6 union 
select 5,'申诉中','QuestionnaireStageStatus',7 union 
select 6,'复审中','QuestionnaireStageStatus',8 union 
select 7,'完成','QuestionnaireStageStatus',9

delete from BusinessConfiguration where ItemDesc='PageStatus'
insert into BusinessConfiguration (ItemKey,ItemValue,ItemDesc)
select 0,'新增','PageStatus' union
select 1,'查看','PageStatus' union 
select 2,'编辑','PageStatus'

delete from BusinessConfiguration where ItemDesc='DocumentStatus'
insert into BusinessConfiguration (ItemKey,ItemValue,ItemDesc)
select 0,'正常','DocumentStatus' union
select 1,'删除','DocumentStatus'
          
delete from BusinessConfiguration where ItemDesc='QuestionnaireAuditType'
insert into BusinessConfiguration (ItemKey,ItemValue,ItemDesc)
select 1,'执行督导审核','QuestionnaireAuditType' union
select 2,'区控审核','QuestionnaireAuditType' union
select 3,'质控审核','QuestionnaireAuditType' union
select 6,'质控督导审核','QuestionnaireAuditType' union
select 7,'研究员审核','QuestionnaireAuditType' union
select 4,'客户审核','QuestionnaireAuditType' union
select 5,'质控督导复审','QuestionnaireAuditType'union
select 8,'终审裁决','QuestionnaireAuditType' 
          
delete from BusinessConfiguration where ItemDesc='UserStatus'
insert into BusinessConfiguration (ItemKey,ItemValue,ItemDesc)
select 0,'正常','UserStatus' union
select 1,'停用','UserStatus' union
select 2,'删除','UserStatus' 


delete from BusinessConfiguration where ItemDesc='ContactOnlineEmailServer'
insert into BusinessConfiguration (ItemKey,ItemValue,ItemDesc)
select 0,'210.77.136.200','ContactOnlineEmailServer'
delete from BusinessConfiguration where ItemDesc='ContactOnlineEmailServerPort'
insert into BusinessConfiguration (ItemKey,ItemValue,ItemDesc)
select 0,'465','ContactOnlineEmailServerPort'
delete from BusinessConfiguration where ItemDesc='ContactOnlineEmailUsername'
insert into BusinessConfiguration (ItemKey,ItemValue,ItemDesc)
select 0,'auditonline@ctrchina.cn','ContactOnlineEmailUsername'
delete from BusinessConfiguration where ItemDesc='ContactOnlineEmailPassword'
insert into BusinessConfiguration (ItemKey,ItemValue,ItemDesc)
select 0,'cr2017!@#','ContactOnlineEmailPassword'
delete from BusinessConfiguration where ItemDesc='ContactOnlineEmailDisplayName'
insert into BusinessConfiguration (ItemKey,ItemValue,ItemDesc)
select 0,'渠道核查在线管理平台','ContactOnlineEmailDisplayName'

delete from BusinessConfiguration where ItemDesc='MessageStatus'
insert into BusinessConfiguration (ItemKey,ItemValue,ItemDesc)
select 0,'未读','MessageStatus' union
select 1,'已读','MessageStatus'

delete from BusinessConfiguration where ItemDesc='MessageType'
insert into BusinessConfiguration (ItemKey,ItemValue,ItemDesc)
select 1,'建项通知','MessageType' union
select 2,'任务通知','MessageType' union
select 3,'审核任务','MessageType' union
select 4,'审核通知','MessageType' union
select 5,'申诉通知','MessageType' union
select 6,'申诉裁定','MessageType' union
select 7,'申诉关闭','MessageType' union
select 8,'删除通知','MessageType'


delete from BusinessConfiguration where ItemDesc='Sex'
insert into BusinessConfiguration (ItemKey,ItemValue,ItemDesc)
select 1,'男','Sex' union
select 2,'女','Sex'

delete from BusinessConfiguration where ItemDesc='Degree'
insert into BusinessConfiguration (ItemKey,ItemValue,ItemDesc)
select 1,'小学及以下','Degree' union
select 2,'初中','Degree' union
select 3,'高中','Degree' union
select 4,'大专','Degree' union
select 5,'本科','Degree' union
select 6,'硕士','Degree' union
select 7,'博士及以上','Degree'

delete from BusinessConfiguration where ItemDesc='HouseHold'
insert into BusinessConfiguration (ItemKey,ItemValue,ItemDesc)
select 1,'非农户口','HouseHold' union
select 2,'农业户口','HouseHold'

delete from BusinessConfiguration where ItemDesc='ProtocolType'
insert into BusinessConfiguration (ItemKey,ItemValue,ItemDesc)
select 1,'全职','ProtocolType' union
select 2,'兼职','ProtocolType'

delete from BusinessConfiguration where ItemDesc='DocumentType'
insert into BusinessConfiguration (ItemKey,ItemValue,ItemDesc)
select 1,'客户列表','DocumentType' union
select 2,'问卷模板','DocumentType' union
select 3,'执行上传','DocumentType' union
select 4,'审核上传','DocumentType' union
select 5,'客户上传','DocumentType' union
select 6,'用户上传','DocumentType' union
select 7,'执行全程录像','DocumentType' union
select 8,'上传执行计划','DocumentType' union
select 9,'上传第三方数据','DocumentType' union
select 10,'更新样本状态','DocumentType'

delete from BusinessConfiguration where ItemDesc='UploadType'
insert into BusinessConfiguration (ItemKey,ItemValue,ItemDesc)
select 1,'逐题录入','UploadType' union
select 2,'统一录入(弹窗式)','UploadType' union
select 3,'统一录入(无弹窗式)','UploadType' union
select 4,'无图片上传方式','UploadType'

delete from BusinessConfiguration where ItemDesc='QuestionAppealStatus'
insert into BusinessConfiguration (ItemKey,ItemValue,ItemDesc)
select 0,'未处理','QuestionAppealStatus' union
select 1,'已维持扣分','QuestionAppealStatus' union
select 2,'已还分','QuestionAppealStatus' union
select 3,'未裁决','QuestionAppealStatus'

delete from BusinessConfiguration where ItemDesc='Region'
insert into BusinessConfiguration (ItemKey,ItemValue,ItemDesc)
select 1,'汉族','Region' union
select 2,'蒙古族','Region' union
select 3,'回族','Region' union
select 4,'藏族','Region' union
select 5,'维吾尔族','Region' union
select 6,'苗族','Region' union
select 7,'彝族','Region' union
select 8,'壮族','Region' union
select 9,'布依族','Region' union
select 10,'朝鲜族','Region' union
select 11,'满族','Region' union
select 12,'侗族','Region' union
select 13,'瑶族','Region' union
select 14,'白族','Region' union
select 15,'土家族','Region' union
select 16,'哈尼族','Region' union
select 17,'哈萨克族','Region' union
select 18,'傣族','Region' union
select 19,'黎族','Region' union
select 20,'傈僳族','Region' union
select 21,'佤族','Region' union
select 22,'畲族','Region' union
select 23,'高山族','Region' union
select 24,'拉祜族','Region' union
select 25,'水族','Region' union
select 26,'东乡族','Region' union
select 27,'纳西族','Region' union
select 28,'景颇族','Region' union
select 29,'柯尔克孜族','Region' union
select 30,'土族','Region' union
select 31,'达斡尔族','Region' union
select 32,'仫佬族','Region' union
select 33,'羌族','Region' union
select 34,'布朗族','Region' union
select 35,'撒拉族','Region' union
select 36,'毛难族','Region' union
select 37,'仡佬族','Region' union
select 38,'锡伯族','Region' union
select 39,'阿昌族','Region' union
select 40,'普米族','Region' union
select 41,'塔吉克族','Region' union
select 42,'怒族','Region' union
select 43,'乌孜别克族','Region' union
select 44,'俄罗斯族','Region' union
select 45,'鄂温克族','Region' union
select 46,'崩龙族','Region' union
select 47,'保安族','Region' union
select 48,'裕固族','Region' union
select 49,'京族','Region' union
select 50,'塔塔尔族','Region' union
select 51,'独龙族','Region' union
select 52,'鄂伦春族','Region' union
select 53,'赫哲族','Region' union
select 54,'门巴族','Region' union
select 55,'珞巴族','Region' union
select 56,'基诺族','Region' union
select 57,'其他','Region' union
select 58,'外国血统','Region'

delete from BusinessConfiguration where ItemDesc='TrainingType'
insert into BusinessConfiguration (ItemKey,ItemValue,ItemDesc)
select 1,'访问员培训','TrainingType' union
select 2,'执行督导培训','TrainingType' union
select 3,'质控培训','TrainingType' 
