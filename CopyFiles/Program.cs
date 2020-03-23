using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.IO;
using System.Net;
using System.Data;
using System.Threading;

namespace CopyFiles
{
    class Program
    {
        public static string ServerUrl = "http://116.62.142.234:30008/";

        static void Main(string[] args)
        {
            while(true)
            {
                DataTable dt = DocumentManager.GetAllUnCopyFilesByFileType();
                if (dt != null && dt.Rows.Count > 0) 
                {
                    foreach (DataRow row in dt.Rows) 
                    {
                        string id = row["ID"].ToString();
                        int fileID = 0;
                        int.TryParse(id, out fileID);
                        string relevantPath = row["RelevantPath"].ToString();
                        string fileName = relevantPath.Substring(relevantPath.LastIndexOf('/') + 1);
                        string folderPath = relevantPath.Substring(0, relevantPath.LastIndexOf('/') + 1).Replace("../", "");
                        ListeningFiles(fileID, fileName, folderPath);
                    }
                }
                Thread.Sleep(1000 * 60 * 10);//等待10分钟
            }
        }

        private static void ListeningFiles(int id, string fileName, string folderPath)
        {
            string localFolder = folderPath.Replace("/", "\\");
            string clientPath = AppDomain.CurrentDomain.SetupInformation.ApplicationBase.TrimEnd('\\') + "\\" + localFolder;
            if (Directory.Exists(clientPath) == false)
            {
                Directory.CreateDirectory(clientPath);
            }
            string serverPath = ServerUrl + folderPath + fileName;
            string clientFilePath = clientPath + fileName;
            if (File.Exists(clientFilePath) == false)
            {
                CopyFile(serverPath, clientFilePath);

                //string tempFilePath = clientFilePath.Substring(0, clientFilePath.LastIndexOf('.')) + "_temp.mp4";
                //File.Move(clientFilePath, tempFilePath);
                //GetVideoConvertedPath(tempFilePath, clientFilePath);
                //File.Delete(tempFilePath);
                string updateSQL = "update DocumentFiles set BackupStatus=1 where ID=" + id;
                BusinessLogicBase.Default.Execute(updateSQL);
            }
            //else {
            //    string updateSQL = "update DocumentFiles set BackupStatus=1 where ID=" + id;
            //    BusinessLogicBase.Default.Execute(updateSQL);
            //}
        }

        private static string GetVideoConvertedPath(string sourceFile, string fixedFilePath)
        {
            try
            {
                string ffmpegfile = AppDomain.CurrentDomain.SetupInformation.ApplicationBase.TrimEnd('\\') + "\\ffmpeg.exe";
                if ((!System.IO.File.Exists(ffmpegfile)) || (!System.IO.File.Exists(sourceFile)))
                {
                    return "";
                }
                
                using (System.Diagnostics.Process ffmpeg = new System.Diagnostics.Process())
                {
                    String result;  // temp variable holding a string representation of our video's duration
                    StreamReader errorreader;  // StringWriter to hold output from ffmpeg

                    // we want to execute the process without opening a shell
                    ffmpeg.StartInfo.UseShellExecute = false;
                    //ffmpeg.StartInfo.ErrorDialog = false;
                    ffmpeg.StartInfo.WindowStyle = System.Diagnostics.ProcessWindowStyle.Hidden;
                    // redirect StandardError so we can parse it
                    // for some reason the output comes through over StandardError
                    ffmpeg.StartInfo.RedirectStandardError = true;

                    // set the file name of our process, including the full path
                    // (as well as quotes, as if you were calling it from the command-line)
                    ffmpeg.StartInfo.FileName = ffmpegfile;

                    // set the command-line arguments of our process, including full paths of any files
                    // (as well as quotes, as if you were passing these arguments on the command-line)
                    ffmpeg.StartInfo.Arguments = string.Format("-i \"{0}\" -c:v libx264 -preset ultrafast -crf 20 -acodec aac \"{1}\"", sourceFile, fixedFilePath);

                    // start the process
                    ffmpeg.Start();

                    // now that the process is started, we can redirect output to the StreamReader we defined
                    errorreader = ffmpeg.StandardError;

                    //wait until ffmpeg comes back
                    //ffmpeg.WaitForExit();

                    // read the output from ffmpeg, which for some reason is found in Process.StandardError
                    result = errorreader.ReadToEnd();

                    // a little convoluded, this string manipulation...
                    // working from the inside out, it:
                    // takes a substring of result, starting from the end of the "Duration: " label contained within,
                    // (execute "ffmpeg.exe -i somevideofile" on the command-line to verify for yourself that it is there)
                    // and going the full length of the timestamp

                    return fixedFilePath;
                }
            }
            catch
            {
                return "";
            }
        }

        private static void CopyFile(string serverPath, string clientFilePath)
        {
            try
            {
                using (FileStream fs = new FileStream(clientFilePath, FileMode.OpenOrCreate, FileAccess.ReadWrite, FileShare.None))
                {
                    long lastPosition = fs.Length;
                    if (lastPosition > 0)
                    {
                        //移动文件流中的当前指针
                        fs.Seek(lastPosition, SeekOrigin.Current);
                    }
                    HttpWebRequest request = WebRequest.Create(serverPath) as HttpWebRequest;
                    if (lastPosition > 0)
                    {
                        request.AddRange((int)lastPosition);
                    }
                    HttpWebResponse response = request.GetResponse() as HttpWebResponse;
                    Stream responseStream = response.GetResponseStream();
                    byte[] bArr = new byte[1024];
                    int size = responseStream.Read(bArr, 0, (int)bArr.Length);
                    while (size > 0)
                    {
                        fs.Write(bArr, 0, size);
                        size = responseStream.Read(bArr, 0, (int)bArr.Length);
                    }
                    fs.Close();
                    responseStream.Close();
                }
            }
            catch { }
        }
    }
}
