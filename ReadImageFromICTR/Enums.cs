using System;
using System.Collections.Generic;
using System.Collections.Specialized;

namespace APLibrary
{

    public class Enums
    {
        public enum QuestionCountType
        {
            正确得分 = 1,
            错误扣分 = 2,
            全部正确得分 = 3,
            选项分总和 = 4,
            不得分不扣分 = 5,
            选项叠加扣分 = 6,
            等于选项分 =7
        }

        public enum QuestionType
        {
            是非题 = 1,
            单选题 = 2,
            多选题 = 3,
            填空题 = 4,
            矩阵单选题 = 5,
            矩阵多选题 = 6,
            段落 = 7,
            上传题 = 8
        }

        public enum QuestionnaireStatus
        {
            已创建 = 1,
            执行中 = 2,
            已执行 = 3
        }

        public enum UserType
        {
            总控 = 1,
            区控 = 2,
            执行督导 = 3,
            访问员 = 4,
            质控督导 = 5,
            质控员 = 6,
            研究员 = 7,
            系统管理员 = 8,
            客户 = 9
        }

        public enum QuestionnaireUploadStatus
        {
            未录入 = 0,
            录入完成 = 1,
            录入未完成 = 2,
            录入待修改 = 3,
            已提交审核 = 4
        }

        public enum QuestionnaireAuditStatus
        {
            未审核 = 0,
            通过 = 1,
            不通过 = 2,
            未裁决 = 3
        }

        public enum QuestionnaireClientStatus
        {
            未申诉 = 0,
            已提交申诉 = 1,
            审核通过 = 2,
            审核不通过 = 3,
            申诉已处理 = 4,
            申诉未裁决 = 6,
            无申诉内容 = 7
        }

        public enum QuestionnaireStageStatus
        {
            未开始 = 0,
            录入中 = 1,
            执行督导审核中 = 2,
            区控审核中 = 3,
            质控审核中 = 4,
            质控督导审核中 = 8,
            申诉中 = 5,
            复审中 = 6,
            完成 = 7
        }

        public enum DocumentStatus 
        { 
            正常 = 0,
            删除 = 1
        }

        public enum DeleteStatus
        {
            正常 = 1,
            删除 = 0
        }

        public enum UserStatus
        {
            正常 = 0,
            停用 = 1,
            删除 = 2
        }

        public enum ClientStatus
        {
            正常 = 0,
            删除 = 1
        }

        public enum MessageStatus
        {
            未读 = 0,
            已读 = 1
        }

        public enum QuestionnaireAuditType
        {
            执行督导审核 = 1,
            区控审核 = 2,
            质控审核 = 3,
            客户审核 = 4,
            质控督导复审 = 5,
            质控督导审核 = 6,
            研究员审核 = 7,
            终审裁决 = 8
        }

        public enum MessageType
        {
            建项通知 = 1,
            任务通知 = 2,
            审核任务 = 3,
            审核通知 = 4,
            申诉通知 = 5,
            申诉裁定 = 6,
            申诉关闭 = 7,
            删除通知 = 8
        }

        public enum DocumentType
        {
            客户列表 = 1,
            问卷模板 = 2,
            执行上传 = 3,
            审核上传 = 4,
            客户上传 = 5,
            用户上传 = 6,
            执行全程录像 = 7,
            上传执行计划 = 8,
            上传第三方数据 = 9,
            更新样本状态 = 10
        }

        public enum FileType
        {
            图片 = 1,
            录音 = 2,
            录像 = 3,
            文档 = 4,
            其他 = 5
        }
    }
}
