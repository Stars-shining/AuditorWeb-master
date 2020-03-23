using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.IO;
using APLibrary;
using APLibrary.Utility;
using System.Diagnostics;
using System.Drawing;

namespace ReadImageFromICTR
{
    class Program
    {
        static void Main(string[] args)
        {
            Process.GetCurrentProcess().PriorityClass = ProcessPriorityClass.RealTime;

            while (File.Exists("D:\\stop11.txt"))
            {
                System.Threading.Thread.Sleep(1000);
            }

            if (args == null || args.Length < 15) 
            {
                return;
            }

            string tempfilePath = DecodeBase64(args[0]);
            string physicalPath = DecodeBase64(args[1]);
            string vituralPath = DecodeBase64(args[2]);
            int projectID = DecodeBase64(args[3]).ToInt(0);
            int resultID = DecodeBase64(args[4]).ToInt(0);
            int questionID = DecodeBase64(args[5]).ToInt(0);
            int answerID = DecodeBase64(args[6]).ToInt(0);
            string fromDate = DecodeBase64(args[7]);
            string clientCode = DecodeBase64(args[8]);
            string formatFileName = DecodeBase64(args[9]);
            int fileType = DecodeBase64(args[10]).ToInt(0);
            string watermark = DecodeBase64(args[11]);
            int typeID = DecodeBase64(args[12]).ToInt(0);
            int userID = DecodeBase64(args[13]).ToInt(0);
            string imageUrl = DecodeBase64(args[14]);

            SaveImageModel model = new SaveImageModel();
            model.tempfilePath = tempfilePath;
            model.physicalPath = physicalPath;
            model.vituralPath = vituralPath;
            model.projectID = projectID;
            model.resultID = resultID;
            model.questionID = questionID;
            model.answerID = answerID;
            model.fromDate = fromDate;
            model.clientCode = clientCode;
            model.formatFileName = formatFileName;
            model.fileType = fileType;
            model.watermark = watermark;
            model.typeID = typeID;
            model.userID = userID;
            model.imageUrl = imageUrl;

            SaveImageWorker worker = new SaveImageWorker(model);
            worker.SaveResultImageFileInstance();
        }

        public static string DecodeBase64(string mi)
        {
            string mingwen = "";
            if (string.IsNullOrEmpty(mi) == false)
            {
                byte[] inArray = Convert.FromBase64String(mi);
                mingwen = System.Text.Encoding.UTF8.GetString(inArray);
            }
            return mingwen;
        }


    }
}

