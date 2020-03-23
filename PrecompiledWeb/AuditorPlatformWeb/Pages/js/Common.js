//获取url中的参数
function getUrlParam(name) {
    var reg = new RegExp("(^|&)" + name + "=([^&]*)(&|$)"); //构造一个含有目标参数的正则表达式对象
    var r = window.location.search.substr(1).match(reg);  //匹配目标参数
    if (r != null) return unescape(r[2]); return null; //返回参数值
}
function jsonDateFormatCN(jsonDate) {//json日期格式转换为正常格式
    try {
        var date = new Date(parseInt(jsonDate.replace("/Date(", "").replace(")/", ""), 10));
        var month = date.getMonth() + 1 < 10 ? "0" + (date.getMonth() + 1) : date.getMonth() + 1;
        var day = date.getDate() < 10 ? "0" + date.getDate() : date.getDate();
        var hours = date.getHours();
        var minutes = date.getMinutes();
        var seconds = date.getSeconds();
        var milliseconds = date.getMilliseconds();
        if (date.getFullYear() <= 1) {
            return "";
        }
        else {
            return date.getFullYear() + "年" + month + "月" + day + "日";
        }
    } catch (ex) {
        return "";
    }
}
function jsonDateFormat(jsonDate) {//json日期格式转换为正常格式
    try {
        var date = new Date(parseInt(jsonDate.replace("/Date(", "").replace(")/", ""), 10));
        var month = date.getMonth() + 1 < 10 ? "0" + (date.getMonth() + 1) : date.getMonth() + 1;
        var day = date.getDate() < 10 ? "0" + date.getDate() : date.getDate();
        var hours = date.getHours();
        var minutes = date.getMinutes();
        var seconds = date.getSeconds();
        var milliseconds = date.getMilliseconds();
        if (date.getFullYear() <= 1) {
            return "";
        }
        else {
            return date.getFullYear() + "-" + month + "-" + day;
        }
    } catch (ex) {
        return "";
    }
}
function jsonDateTimeFormat(jsonDateTime) {//json日期格式转换为正常格式
    try {
        var date = new Date(parseInt(jsonDateTime.replace("/Date(", "").replace(")/", ""), 10));
        var month = date.getMonth() + 1 < 10 ? "0" + (date.getMonth() + 1) : date.getMonth() + 1;
        var day = date.getDate() < 10 ? "0" + date.getDate() : date.getDate();
        var hours = date.getHours() < 10 ? "0" + date.getHours() : date.getHours();
        var minutes = date.getMinutes() < 10 ? "0" + date.getMinutes() : date.getMinutes();
        var seconds = date.getSeconds() < 10 ? "0" + date.getSeconds() : date.getSeconds();
        var milliseconds = date.getMilliseconds();
        return date.getFullYear() + "-" + month + "-" + day + " " + hours + ":" + minutes + ":" + seconds;
    } catch (ex) {
        return "";
    }
}
function jsonDateTimeFormatWithoutSeconds(jsonDateTime) {//json日期格式转换为正常格式
    try {
        var date = new Date(parseInt(jsonDateTime.replace("/Date(", "").replace(")/", ""), 10));
        var month = date.getMonth() + 1 < 10 ? "0" + (date.getMonth() + 1) : date.getMonth() + 1;
        var day = date.getDate() < 10 ? "0" + date.getDate() : date.getDate();
        var hours = date.getHours() < 10 ? "0" + date.getHours() : date.getHours();
        var minutes = date.getMinutes() < 10 ? "0" + date.getMinutes() : date.getMinutes();
        return date.getFullYear() + "-" + month + "-" + day + " " + hours + ":" + minutes;
    } catch (ex) {
        return "";
    }
}
function ConvertJSONDateToJSDate(jsondate) {
    var date = new Date(parseInt(jsondate.replace("/Date(", "").replace(")/", ""), 10));
    return date;
}
function ArrayToString(arrObj) {
    var str = "";
    $.each(arrObj, function (i, item) {
        str = str + "， " + item.Name;
    });
    str = str.replace(/(^，)|(，$)/g, '')
    return str;
}

function GetCurrentPageName() {
    var url = window.location.pathname;
    var parts = url.split('/');
    var fileName = parts[parts.length - 1];
    return fileName;
}

function GetPageNaviItems() {
    var naviItemsJson = "{\n\
    \"allitem\": [\"index.asp\"],\n\
    \"newitem\": [\n\
        \"AddProjectInfo.asp\",\n\
        \"AddProjectCondition.asp\"\n\
    ],\n\
    \"queryitem\": [\n\
        \"ProjectSchedule_Auto.asp\",\n\
        \"Query_monitoring.asp\",\n\
        \"Query_Effect.asp\"\n\
    ],\n\
    \"basedataitem\": [\"BaseDataSearch.asp\"],\n\
    \"dbitem\": [\"UploadList.asp\",\"Audience_Data.asp\",\"Excuted_Data.asp\",\"Feedback_Data.asp\"],\n\
    \"timeitem\": [\"TimeResource.asp\"],\n\
    \"roleitem\": [\"UserManager.asp\"],\n\
    \"listitem\": [\n\
        \"ProjectList.asp\",\n\
        \"ViewProjectInfo.asp\",\n\
        \"ViewProjectCondition.asp\",\n\
        \"Solutions.asp\",\n\
        \"Schedule.asp\",\n\
        \"Excuted.asp\",\n\
        \"Feedback_Details.asp\",\n\
        \"ViewProjectSchedule.asp\"\n\
    ]}";
    return naviItemsJson;
}

var Download = function (url, data, method) {
    if (url && data) {
        data = typeof data == 'string' ? data : $.param(data);
        var inputs = '';
        $.each(data.split('&'), function () {
            var pair = this.split('=');
            inputs += '<input type="hidden" name="' + pair[0] + '" value="' + pair[1] + '" />';
        });
        $('<form action="' + url + '" method="' + (method || 'post') + '">' + inputs + '</form>')
.appendTo('body').submit().remove();
    };
};

// 对Date的扩展，将 Date 转化为指定格式的String 
// 月(M)、日(d)、小时(h)、分(m)、秒(s)、季度(q) 可以用 1-2 个占位符， 
// 年(y)可以用 1-4 个占位符，毫秒(S)只能用 1 个占位符(是 1-3 位的数字) 
// 例子： 
// (new Date()).Format("yyyy-MM-dd hh:mm:ss.S") ==> 2006-07-02 08:09:04.423 
// (new Date()).Format("yyyy-M-d h:m:s.S")      ==> 2006-7-2 8:9:4.18 
Date.prototype.Format = function (fmt) { //author: meizz 
    var o = {
        "M+": this.getMonth() + 1,                 //月份 
        "d+": this.getDate(),                    //日 
        "h+": this.getHours(),                   //小时 
        "m+": this.getMinutes(),                 //分 
        "s+": this.getSeconds(),                 //秒 
        "q+": Math.floor((this.getMonth() + 3) / 3), //季度 
        "S": this.getMilliseconds()             //毫秒 
    };
    if (/(y+)/.test(fmt))
        fmt = fmt.replace(RegExp.$1, (this.getFullYear() + "").substr(4 - RegExp.$1.length));
    for (var k in o)
        if (new RegExp("(" + k + ")").test(fmt))
            fmt = fmt.replace(RegExp.$1, (RegExp.$1.length == 1) ? (o[k]) : (("00" + o[k]).substr(("" + o[k]).length)));
    return fmt;
}
function PrefixInteger(num, n) {
    return (Array(n).join(0) + num).slice(-n);
}

function JSONLength(obj) {
    var size = 0, key;
    for (key in obj) {
        if (obj.hasOwnProperty(key)) size++;
    }
    return size;
}

function PreViewPhotoBase(imgSrc, title) {
    window.open(imgSrc, title);
}

function PreViewPhoto(imgSrc, title) {
    var json = "{\
  \"title\": \"" + title + "\", \
  \"data\": [   \
    {\
      \"alt\": \"" + title + "\",\
      \"pid\": 0, \
      \"src\": \"" + imgSrc + "\", \
      \"thumb\": \"\" \
    }\
  ]\
}";
    layer.photos({
        photos: $.parseJSON(json)
        , anim: 5
        , closeBtn: 2
    });
}

function PreViewPhotos(relatedID, title, data) {
    var json = "{\
  \"title\": \"" + title + "\", \
  \"id\": " + relatedID + ", \
  \"data\": [   ";

    var pics = new Array();
    $.each(data, function (i, item) {
        var pid = item.ID;
        var pictitle = item.FileName;
        var url = item.RelevantPath;
        var thumbUrl = item.ThumbRelevantPath;
        var fileType = item.FileType;
        var str = "{\
                    \"alt\": \"" + pictitle + "\",\
                    \"pid\": " + pid + ", \
                    \"src\": \"" + url + "\", \
                    \"thumb\": \"" + thumbUrl + "\" \
                }";

        pics.push(str);
    });
    json += pics.join(',');
    json += "]}";

    layer.photos({
        photos: $.parseJSON(json)
        , anim: 5
        , closeBtn: 2
    });
}

function ShowQuestionFiles(relatedID, typeID) {
    if (relatedID == 'null') {
        relatedID = "-1";
    }
    var url = "../Logic/QuestionnaireAudit.ashx";
    var date = new Date();
    $.ajax({
        url: url,
        data: {
            type: 5,
            Date: date,
            relatedID: relatedID,
            typeID: typeID
        },
        dataType: "json",
        type: "GET",
        traditional: true,
        success: function (data) {
            PreViewPhotos(relatedID, "", data);
        },
        error: function (e) {

        }
    });
}

function ShowQuestionFiles(relatedID, typeID, tempCode) {
    if (relatedID == 'null') {
        relatedID = "-1";
    }
    var url = "../Logic/QuestionnaireAudit.ashx";
    var date = new Date();
    $.ajax({
        url: url,
        data: {
            type: 5,
            Date: date,
            relatedID: relatedID,
            typeID: typeID,
            tempCode: tempCode
        },
        dataType: "json",
        type: "GET",
        traditional: true,
        success: function (data) {
            PreViewPhotos(relatedID, "", data);
        },
        error: function (e) {

        }
    });
}

function ShowFilesWithList(answerID, typeID, tempCode) {
    $('#fileWindowList').empty();
    LoadFiles(answerID, typeID, tempCode);
    layer.open({
        type: 1,
        shade: 0.8,
        skin: 'layui-layer-rim',
        area: ['70%', '70%'],
        shadeClose: true,
        title: false, //不显示标题
        content: $('#fileWindow'), //捕获的元素，注意：最好该指定的元素要存放在body最外层，否则可能被其它的相对元素所影响
        end: function () {
            //LoadData();
        }
    });
}

String.prototype.replaceAll = function (s1, s2) {
    return this.replace(new RegExp(s1, "gm"), s2);
}

function ReplaceNULL(text, char) {
    if (text == null) {
        text = char;
    }
    return text;
}

function RedirectToPreviousQuestion(currentResultID,currentQuestionID) {
    var url = "../Logic/Questionnaire.ashx";
    var date = new Date();
    $.getJSON(url, { type: "17", date: date, currentQuestionID: currentQuestionID }, function (data) {
        var prevQuestionID = data.PrevQuestionID;
        var prevQuestionTypeID = data.PrevQuestionTypeID;
        var type = "Q" + prevQuestionTypeID + ".htm?ID=" + prevQuestionID + "&ResultID=" + currentResultID;
        var url = "QuestionnaireUpload" + type;
        if (prevQuestionTypeID == "-1") {
            url = "QuestionnaireUploadStart.htm?resultID=" + currentResultID + "&st=2";
        }
        window.location.href = url;
    });
}

function RedirectToNextQuestion(currentResultID, currentQuestionnaireID, currentQuestionID) {
    var url = "../Logic/Questionnaire.ashx";
    var date = new Date();
    $.getJSON(url, { type: "15", date: date, currentResultID:currentResultID, currentQuestionnaireID: currentQuestionnaireID, currentQuestionID: currentQuestionID }, function (data) {
        var nextQuestionID = data.NextQuestionID;
        var nextQuestionTypeID = data.NextQuestionTypeID;
        var type = "Q" + nextQuestionTypeID + ".htm?ID=" + nextQuestionID + "&ResultID=" + currentResultID;
        var url = "QuestionnaireUpload" + type;
        if (nextQuestionTypeID == "-1") {
            url = "QuestionnaireUploadStart.htm?resultID=" + currentResultID + "&st=3";
        }
        window.location.href = url;
    });
}

function RedirectToNextQuestionDirectly(resultID) {
    var url = "../Logic/QuestionnaireDelivery.ashx";
    var date = new Date();
    $.getJSON(url, { type: "9", date: date, resultID: resultID }, function (data) {
        var item = data[0];
        RedirectToNextQuestionDirectlyOpenWindow(resultID, item.QuestionnaireID, item.CurrentQuestionID, item.QuestionnaireName, item.ClientName);
    });
}

function RedirectToNextQuestionDirectlyOpenWindow(currentResultID, currentQuestionnaireID, currentQuestionID, questionnaireName, clientName) {
    var url = "../Logic/Questionnaire.ashx";
    var date = new Date();
    $.getJSON(url, { type: "15", date: date, currentQuestionnaireID: currentQuestionnaireID, currentQuestionID: currentQuestionID }, function (data) {
        var nextQuestionID = data.NextQuestionID;
        var nextQuestionTypeID = data.NextQuestionTypeID;
        var type = "Q" + nextQuestionTypeID + ".htm?ID=" + nextQuestionID + "&ResultID=" + currentResultID;
        var questionUrl = "QuestionnaireUpload" + type;
        var title = "问卷录入：" + questionnaireName + " - " + clientName;
        var area = ['1070px', '95%'];
        layer.open({
            type: 2,
            title: title,
            shadeClose: false,
            area: area,
            offset: "auto",
            content: questionUrl,
            shade: 0.6
        });
    });
}

String.prototype.Trim = function () {
    return this.replace(/(^\s*)|(\s*$)/g, "");
}
String.prototype.LTrim = function () {
    return this.replace(/(^\s*)/g, "");
}
String.prototype.RTrim = function () {
    return this.replace(/(\s*$)/g, "");
}

function DownloadFile(url, id, filetype) {
    if (filetype == "1") {
        //图片
        DownloadPic(id);
    }
    else {
        window.open(url, "_parent");
    }
}

function DownloadPic(id) {
    var form = $("<form>"); //定义一个form表单
    form.attr("style", "display:none");
    form.attr("target", "");
    form.attr("method", "post");
    form.attr("action", "../Logic/Upload.ashx?type=5");
    var input1 = $("<input>");
    input1.attr("type", "hidden");
    input1.attr("name", "date");
    input1.attr("value", (new Date()).getMilliseconds());
    var input2 = $("<input>");
    input2.attr("type", "hidden");
    input2.attr("name", "id");
    input2.attr("value", id);
    $("body").append(form); //将表单放置在web中
    form.append(input1);
    form.append(input2);
    form.submit(); //提交下载 
}

function DeleteFile(fileID, callback) {
    layer.confirm('您确定要删除该文件吗？', {
        btn: ['确定', '取消']
    }, function (index) {
        layer.close(index);
        var date = new Date();
        var url = '../Logic/Upload.ashx';
        $.ajax({
            url: url,
            data: {
                Type: 4,
                Date: date,
                FileID: fileID
            },
            dataType: "json",
            type: "POST",
            traditional: true,
            success: function (data) {
                if (data == "1") {
                    layer.alert("删除成功！", function (index) {
                        layer.close(index);
                        callback();
                    });
                }
            }
        });
    });
}


//加密方法。没有过滤首尾空格，即没有trim.  
//加密可以加密N次，对应解密N次就可以获取明文  
function encodeBase64(mingwen, times) {
    var code = "";
    var num = 1;
    if (typeof times == 'undefined' || times == null || times == "") {
        num = 1;
    } else {
        var vt = times + "";
        num = parseInt(vt);
    }

    if (typeof mingwen == 'undefined' || mingwen == null || mingwen == "") {

    } else {
        $.base64.utf8encode = true;
        code = mingwen;
        for (var i = 0; i < num; i++) {
            code = $.base64.encode(code);
        }
    }
    return code;
}


//解密方法。没有过滤首尾空格，即没有trim  
//加密可以加密N次，对应解密N次就可以获取明文  
function decodeBase64(mi, times) {
    var mingwen = "";
    var num = 1;
    if (typeof times == 'undefined' || times == null || times == "") {
        num = 1;
    } else {
        var vt = times + "";
        num = parseInt(vt);
    }


    if (typeof mi == 'undefined' || mi == null || mi == "") {

    } else {
        $.base64.utf8encode = true;
        mingwen = mi;
        for (var i = 0; i < num; i++) {
            mingwen = $.base64.decode(mingwen);
        }
    }
    return mingwen;
}


function LoadCurrentProjectLeft() {
    var date = new Date();
    var url = '../Logic/UserMenu.ashx';

    $.ajax({
        url: url,
        data: {
            Type: 1,
            Date: date,
            IsInProject: true
        },
        dataType: "text",
        type: "GET",
        traditional: true,
        success: function (data) {
            $("#CommonLeft").load(data, function () {
                $("#CommonLeft").find(".layui-this").removeClass("layui-this");
                var filename = window.location.href;
                filename = filename.substr(filename.lastIndexOf('/') + 1, filename.lastIndexOf('.htm') - filename.lastIndexOf('/') + 3);
                $("#CommonLeft").find("a").each(function (i, item) {
                    var href = $(item).attr("href");
                    if (href.indexOf(filename) >= 0) {
                        var parent = $(item).parent();
                        if (parent.is("li")) {
                            parent.addClass("layui-this");
                        }
                        else {
                            parent.parent().parent().addClass("layui-this");
                        }
                    }

                });

            });

            
        },
        error: function () {
        }
    });
}

function LoadCurrentLeft() {
    var date = new Date();
    var url = '../Logic/UserMenu.ashx';

    $.ajax({
        url: url,
        data: {
            Type: 1,
            Date: date,
            IsInProject: false
        },
        dataType: "text",
        type: "GET",
        traditional: true,
        success: function (data) {
            $("#CommonLeft").load(data, function () {
                $("#CommonLeft").find(".layui-this").removeClass("layui-this");
                var filename = window.location.href;
                filename = filename.substr(filename.lastIndexOf('/') + 1, filename.lastIndexOf('.htm') - filename.lastIndexOf('/') + 3);
                $("#CommonLeft").find("a").each(function (i, item) {
                    var href = $(item).attr("href");
                    if (href.indexOf(filename) >= 0) {
                        var parent = $(item).parent();
                        if (parent.is("li")) {
                            parent.addClass("layui-this");
                        }
                        else {
                            parent.parent().parent().addClass("layui-this");
                        }
                    }

                });

            });
        },
        error: function () {
        }
    });
}

function InitPeriod(ddlPeriodObj) {
    var toDate = new Date();
    var lastThreeDays = new Date();
    var lastOneWeek = new Date();
    var lastOneMonth = new Date();
    var lastThreeMonth = new Date();
    var lastSixMonth = new Date();
    var lastOneYear = new Date();
    var lastThreeYear = new Date();

    //added by diego at 2016-11-11
    var tomorrow = new Date();
    var nextSevenDays = new Date();

    lastThreeDays.setDate(toDate.getDate() - 2);
    lastOneWeek.setDate(toDate.getDate() - 6);
    lastOneMonth.setMonth(toDate.getMonth() - 1);
    lastOneMonth.setDate(lastOneMonth.getDate() + 1);
    lastThreeMonth.setMonth(toDate.getMonth() - 3);
    lastThreeMonth.setDate(lastThreeMonth.getDate() + 1);
    lastSixMonth.setMonth(toDate.getMonth() - 6);
    lastSixMonth.setDate(lastSixMonth.getDate() + 1);
    lastOneYear.setFullYear(toDate.getFullYear() - 1);
    lastOneYear.setDate(lastOneYear.getDate() + 1);
    lastThreeYear.setFullYear(toDate.getFullYear() - 3);
    lastThreeYear.setDate(lastThreeYear.getDate() + 1);

    tomorrow.setDate(toDate.getDate() + 1);
    nextSevenDays.setDate(toDate.getDate() + 7);


    var strlastThreeDays = GetPeriodString(lastThreeDays, toDate);
    var strlastOneWeek = GetPeriodString(lastOneWeek, toDate);
    var strlastOneMonth = GetPeriodString(lastOneMonth, toDate);
    var strlastThreeMonth = GetPeriodString(lastThreeMonth, toDate);
    var strlastSixMonth = GetPeriodString(lastSixMonth, toDate);
    var strlastOneYear = GetPeriodString(lastOneYear, toDate);
    var strlastThreeYear = GetPeriodString(lastThreeYear, toDate);

    var strNextSevenDays = GetPeriodString(tomorrow, nextSevenDays);

    ddlPeriodObj.empty();
    ddlPeriodObj.append("<option value='-999'>不限</option>");
    //ddlPeriodObj.append("<option value='" + strNextSevenDays + "'>未来一周</option>");
    ddlPeriodObj.append("<option value='" + strlastThreeDays + "'>最近三天</option>");
    ddlPeriodObj.append("<option value='" + strlastOneWeek + "'>最近一周</option>");
    ddlPeriodObj.append("<option value='" + strlastOneMonth + "'>最近一个月</option>");
    ddlPeriodObj.append("<option value='" + strlastThreeMonth + "'>最近三个月</option>");
    ddlPeriodObj.append("<option value='" + strlastSixMonth + "'>最近六个月</option>");
    ddlPeriodObj.append("<option value='" + strlastOneYear + "'>最近一年</option>");
    ddlPeriodObj.append("<option value='" + strlastThreeYear + "'>最近三年</option>");
//    ddlPeriodObj.append("<option value='-1'>自定义日期</option>");
    ddlPeriodObj.get(0).selectedIndex = 0;
}

function GetPeriodString(fromDate, toDate) {
    var period = fromDate.getFullYear() + "-" + (fromDate.getMonth() + 1) + "-" + fromDate.getDate() + "|" + toDate.getFullYear() + "-" + (toDate.getMonth() + 1) + "-" + toDate.getDate();
    return period;
}


$.ajaxSettings.async = false;
var userID = 0;
var userName = "";
var userType = 0;
LoadLoginUser();
$.ajaxSettings.async = true;
function LoadLoginUser() {
    var date = new Date();
    var url = '../Logic/Users.ashx';
    $.ajax({
        type: "get",
        url: url,
        data: { "type": "3", "date": date },
        success: function (data) {
            userID = data.ID;
            userName = data.UserName;
            userType = data.UserType;
            var clientID_V = data.ClientID;
            var projectID_V = data.ProjectID;
            if (data.ID <= 0) {
                if (clientID_V > 0) {
                    window.location = "VLogin.htm?p=" + projectID_V;
                }
                else {
                    var oldUserType = data.OldUserType;
                    var loginPage = "Login.htm";
                    if (oldUserType == 9) {
                        loginPage = "CLogin.htm";
                        var groupID = data.OldGroupID;
                        if (groupID > 0) {
                            loginPage = "CLogin.htm?g=" + groupID;
                            window.location = loginPage;
                            return;
                        }
                    }
                    var returnUrl = document.URL;
                    var returnProjectID = getUrlParam("returnProjectID");
                    if (returnProjectID != "" && returnProjectID != null) {
                        window.location = loginPage + "?returnProjectID=" + returnProjectID + "&returnUrl=" + escape(returnUrl);
                    }
                    else {
                        var url = loginPage + "?returnUrl=" + escape(returnUrl);
                        window.location = url;
                    }
                }
            }
        }
    });
}

function ResetPwd(userID) {
    layer.confirm('您确定要重置当前用户的登录密码吗？', {
        btn: ['确定', '取消']
    }, function (index) {

        var date = new Date();
        var url = '../Logic/Users.ashx';
        $.ajax({
            url: url,
            data: {
                Type: 13,
                Date: date,
                id: userID
            },
            dataType: "text",
            type: "POST",
            traditional: true,
            success: function (data) {
                layer.alert("密码已重置回初始密码：" + data + "，请通知该账号及时修改密码，防止账号被盗用。");
                layer.close(index);
            },
            error: function () {
                layer.close(index);
            }
        });

    });
}

function GetBusinessConfigValues(ddlConfig, itemdesc) {
    ddlConfig.empty();
    ddlConfig.append("<option value=''>请选择</option>");
    var date = new Date();
    var url = '../Logic/BusinessConfiguration.ashx';
    $.ajax({
        url: url,
        data: {
            Type: 1,
            Date: date,
            name: itemdesc
        },
        dataType: "json",
        type: "GET",
        traditional: true,
        success: function (data) {
            $.each(data, function (i, item) {
                ddlConfig.append("<option value='" + item.ID + "'>" + item.Name + "</option>");
            });
        },
        error: function () {
        }
    });
}

function toDecimal(x, bit) {
    var f = parseFloat(x);
    if (isNaN(f)) {
        return x;
    }
    if (bit > 0) {
        var m = Math.pow(10, bit);
        f = Math.round(x * m) / m;
    }
    return f;
}

function IEVersion() {
    var userAgent = navigator.userAgent; //取得浏览器的userAgent字符串  
    var isIE = userAgent.indexOf("compatible") > -1 && userAgent.indexOf("MSIE") > -1; //判断是否IE<11浏览器  
    var isEdge = userAgent.indexOf("Edge") > -1 && !isIE; //判断是否IE的Edge浏览器  
    var isIE11 = userAgent.indexOf('Trident') > -1 && userAgent.indexOf("rv:11.0") > -1;
    if (isIE) {
        var reIE = new RegExp("MSIE (\\d+\\.\\d+);");
        reIE.test(userAgent);
        var fIEVersion = parseFloat(RegExp["$1"]);
        if (fIEVersion == 7) {
            return 7;
        } else if (fIEVersion == 8) {
            return 8;
        } else if (fIEVersion == 9) {
            return 9;
        } else if (fIEVersion == 10) {
            return 10;
        } else {
            return 6; //IE版本<=7
        }
    } else if (isEdge) {
        return 'edge'; //edge
    } else if (isIE11) {
        return 11; //IE11  
    } else {
        return -1; //不是ie浏览器
    }
}