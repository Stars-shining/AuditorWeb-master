using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.IO;
using APLibrary.DataObject;
using System.Net;
using System.Drawing;
using System.Drawing.Imaging;

namespace APLibrary.Utility
{
    public class SaveImageWorker
    {
        public SaveImageModel model;
        public SaveImageWorker(SaveImageModel s)
        {
            model = s;
        }
        public void SaveResultImageFileInstance()
        {
            string tempfilePath = model.tempfilePath;
            string physicalPath = model.physicalPath;
            string vituralPath = model.vituralPath;
            int projectID = model.projectID;
            int resultID = model.resultID;
            int questionID = model.questionID;
            int answerID = model.answerID;
            string fromDate = model.fromDate;
            string clientCode = model.clientCode;
            string formatFileName = model.formatFileName;
            int fileType = model.fileType;
            string watermark = model.watermark;
            int typeID = model.typeID;
            int userID = model.userID;
            string imageUrl = model.imageUrl;


            DownloadFile(imageUrl, tempfilePath);
            formatFileName = FixedSpecialCharsInFileName(formatFileName);

            string diskFolderPath = physicalPath.TrimEnd('\\') + "\\" + projectID + "\\" + fromDate + "\\" + clientCode + "\\" + fileType + "\\";
            if (Directory.Exists(diskFolderPath) == false)
            {
                Directory.CreateDirectory(diskFolderPath);
            }
            string diskFilePath = diskFolderPath + formatFileName;
            diskFilePath = GetNewPathForDuplicates(diskFilePath);
            File.Copy(tempfilePath, diskFilePath, true);
            FileInfo file = new FileInfo(diskFilePath);
            long fileLength = file.Length;

            string webDirPath = vituralPath.TrimEnd('/') + "/" + projectID + "/" + fromDate + "/" + clientCode + "/" + fileType + "/";
            string fixedFileName = Path.GetFileName(diskFilePath);
            string webFilePath = webDirPath + fixedFileName;

            string thumbRelevantPath = string.Empty;
            string thumbPhysicalPath = string.Empty;
            string timeLength = string.Empty;
            string extension = Path.GetExtension(diskFilePath).ToLower();
            if (fileType == (int)Enums.FileType.图片)
            {
                if (fileLength > 0)
                {
                    if (string.IsNullOrEmpty(watermark) == false)
                    {
                        AddImageSignText(diskFilePath, diskFilePath, watermark, 7, 100, 12);
                    }

                    thumbRelevantPath = GetThumbPathForImageFile(webFilePath);
                    thumbPhysicalPath = GetThumbPathForImageFile(diskFilePath);
                    MakeThumbnail(diskFilePath, thumbPhysicalPath, Constants.ThumbnailWidth, Constants.ThumbnailHeight, "");
                }
            }

            string tempCode = resultID * 100 + " " + questionID * 100;

            DocumentFilesDO doc = new DocumentFilesDO();
            doc.FileName = formatFileName;
            doc.OriginalFileName = formatFileName;
            doc.TempCode = tempCode;
            doc.RelatedID = answerID;
            doc.ResultID = resultID;
            doc.TypeID = typeID;
            doc.FileSize = fileLength;
            doc.TimeLength = timeLength;
            doc.Status = (int)Enums.DocumentStatus.正常;
            doc.RelevantPath = webFilePath;
            doc.PhysicalPath = diskFilePath;
            doc.ThumbRelevantPath = thumbRelevantPath;
            doc.FileType = fileType;
            doc.UserID = userID;
            doc.InputDate = DateTime.Now;
            int docid = BusinessLogicBase.Default.Insert(doc);
        }

        public string GetThumbPathForImageFile(string path)
        {
            string pathWithoutExtension = path.Substring(0, path.LastIndexOf('.'));
            string extension = path.Substring(path.LastIndexOf('.'));
            string thumbPath = string.Format("{0}_{1}{2}", pathWithoutExtension, "thumb", extension);
            return thumbPath;
        }

        public void AddImageSignText(string imgPath, string filename, string watermarkText, int watermarkStatus, int quality, int fontsize, string fontname = "微软雅黑")
        {
            try
            {
                byte[] _ImageBytes = File.ReadAllBytes(imgPath);
                Image img = Image.FromStream(new System.IO.MemoryStream(_ImageBytes));

                int sizeTimes = img.Width / 150;
                fontsize = fontsize + sizeTimes * 2;

                Graphics g = Graphics.FromImage(img);
                Font drawFont = new Font(fontname, fontsize, FontStyle.Regular, GraphicsUnit.Pixel);
                SizeF crSize;
                crSize = g.MeasureString(watermarkText, drawFont);

                float xpos = 0;
                float ypos = 0;

                switch (watermarkStatus)
                {
                    case 1:
                        xpos = (float)img.Width * (float).01;
                        ypos = (float)img.Height * (float).01;
                        break;
                    case 2:
                        xpos = ((float)img.Width * (float).50) - (crSize.Width / 2);
                        ypos = (float)img.Height * (float).01;
                        break;
                    case 3:
                        xpos = ((float)img.Width * (float).99) - crSize.Width;
                        ypos = (float)img.Height * (float).01;
                        break;
                    case 4:
                        xpos = (float)img.Width * (float).01;
                        ypos = ((float)img.Height * (float).50) - (crSize.Height / 2);
                        break;
                    case 5:
                        xpos = ((float)img.Width * (float).50) - (crSize.Width / 2);
                        ypos = ((float)img.Height * (float).50) - (crSize.Height / 2);
                        break;
                    case 6:
                        xpos = ((float)img.Width * (float).99) - crSize.Width;
                        ypos = ((float)img.Height * (float).50) - (crSize.Height / 2);
                        break;
                    case 7:
                        xpos = (float)img.Width * (float).01;
                        ypos = ((float)img.Height * (float).99) - crSize.Height;
                        break;
                    case 8:
                        xpos = ((float)img.Width * (float).50) - (crSize.Width / 2);
                        ypos = ((float)img.Height * (float).99) - crSize.Height;
                        break;
                    case 9:
                        xpos = ((float)img.Width * (float).99) - crSize.Width;
                        ypos = ((float)img.Height * (float).99) - crSize.Height;
                        break;
                }

                g.DrawString(watermarkText, drawFont, new SolidBrush(Color.Black), xpos + 1, ypos + 1);
                g.DrawString(watermarkText, drawFont, new SolidBrush(Color.White), xpos, ypos);

                ImageCodecInfo[] codecs = ImageCodecInfo.GetImageEncoders();
                ImageCodecInfo ici = null;
                foreach (ImageCodecInfo codec in codecs)
                {
                    if (codec.MimeType.IndexOf("jpeg") > -1)
                        ici = codec;
                }
                EncoderParameters encoderParams = new EncoderParameters();
                long[] qualityParam = new long[1];
                if (quality < 0 || quality > 100)
                    quality = 80;

                qualityParam[0] = quality;

                EncoderParameter encoderParam = new EncoderParameter(System.Drawing.Imaging.Encoder.Quality, qualityParam);
                encoderParams.Param[0] = encoderParam;

                if (ici != null)
                    img.Save(filename, ici, encoderParams);
                else
                    img.Save(filename);

                g.Dispose();
                img.Dispose();
            }
            catch { }
        }

        /// <summary>
        /// 生成缩略图
        /// </summary>
        /// <param name="originalImagePath">源图路径（物理路径）</param>
        /// <param name="thumbnailPath">缩略图路径（物理路径）</param>
        /// <param name="width">缩略图宽度</param>
        /// <param name="height">缩略图高度</param>
        /// <param name="mode">生成缩略图的方式</param>    
        public void MakeThumbnail(string originalImagePath, string thumbnailPath, int width, int height, string mode)
        {
            Image originalImage = Image.FromFile(originalImagePath);

            int towidth = width;
            int toheight = height;

            int x = 0;
            int y = 0;
            int ow = originalImage.Width;
            int oh = originalImage.Height;

            if (string.IsNullOrEmpty(mode))
            {
                if (ow > oh)
                {
                    mode = "W";
                }
                else
                {
                    mode = "H";
                }
            }

            switch (mode)
            {
                case "HW"://指定高宽缩放（可能变形）                
                    break;
                case "W"://指定宽，高按比例                    
                    toheight = originalImage.Height * width / originalImage.Width;
                    break;
                case "H"://指定高，宽按比例
                    towidth = originalImage.Width * height / originalImage.Height;
                    break;
                case "Cut"://指定高宽裁减（不变形）                
                    if ((double)originalImage.Width / (double)originalImage.Height > (double)towidth / (double)toheight)
                    {
                        oh = originalImage.Height;
                        ow = originalImage.Height * towidth / toheight;
                        y = 0;
                        x = (originalImage.Width - ow) / 2;
                    }
                    else
                    {
                        ow = originalImage.Width;
                        oh = originalImage.Width * height / towidth;
                        x = 0;
                        y = (originalImage.Height - oh) / 2;
                    }
                    break;
                default:
                    break;
            }

            //新建一个bmp图片
            Image bitmap = new System.Drawing.Bitmap(towidth, toheight);
            //新建一个画板
            Graphics g = System.Drawing.Graphics.FromImage(bitmap);
            try
            {
                //设置高质量插值法
                g.InterpolationMode = System.Drawing.Drawing2D.InterpolationMode.High;

                //设置高质量,低速度呈现平滑程度
                g.SmoothingMode = System.Drawing.Drawing2D.SmoothingMode.HighQuality;

                //清空画布并以透明背景色填充
                g.Clear(Color.Transparent);

                //在指定位置并且按指定大小绘制原图片的指定部分
                g.DrawImage(originalImage, new Rectangle(0, 0, towidth, toheight),
                    new Rectangle(x, y, ow, oh),
                    GraphicsUnit.Pixel);

                //以jpg格式保存缩略图
                bitmap.Save(thumbnailPath, System.Drawing.Imaging.ImageFormat.Jpeg);
            }
            catch (System.Exception e)
            {
                throw e;
            }
            finally
            {
                originalImage.Dispose();
                bitmap.Dispose();
                g.Dispose();
            }
        }

        /// <summary>
        /// Generates a new path for duplicate filenames.
        /// </summary>
        /// <param name="path">The path.</param>
        /// <returns></returns>
        public string GetNewPathForDuplicates(string path)
        {
            string directory = Path.GetDirectoryName(path);
            string filename = Path.GetFileNameWithoutExtension(path);
            string extension = Path.GetExtension(path);
            int counter = 1;
            string newFullPath = path;
            while (System.IO.File.Exists(newFullPath))
            {
                string newFilename = string.Format("{0}({1}){2}", filename, counter, extension);
                newFullPath = Path.Combine(directory, newFilename);
                counter++;
            }
            return newFullPath;
        }

        public string FixedSpecialCharsInFileName(string fileName)
        {
            string result = fileName;
            string invalid = new string(Path.GetInvalidFileNameChars()) + new string(Path.GetInvalidPathChars());
            foreach (char c in invalid)
            {
                result = result.Replace(c.ToString(), "");
            }
            return result;
        }

        public void DownloadFile(string url, string filePath)
        {
            int attempt = 5;
            while (File.Exists(filePath) == false && attempt > 0)
            {
                try
                {
                    DownloadFileInstance(url, filePath);
                }
                catch { }
            }
        }

        public void DownloadFileInstance(string url, string filePath)
        {
            Uri downUri = new Uri(url);
            HttpWebRequest hwr = (HttpWebRequest)WebRequest.Create(downUri);
            using (Stream stream = hwr.GetResponse().GetResponseStream())
            {
                using (FileStream fs = new FileStream(filePath, FileMode.Create))
                {
                    byte[] bytes = new byte[1024];
                    int n = 1;
                    while (n > 0)
                    {
                        n = stream.Read(bytes, 0, 1024);
                        fs.Write(bytes, 0, n);
                    }
                }
            }
        }
    }

    public class SaveImageModel
    {
        public string tempfilePath;
        public string physicalPath;
        public string vituralPath;
        public int projectID;
        public int resultID;
        public int questionID;
        public int answerID;
        public string fromDate;
        public string clientCode;
        public string formatFileName;
        public int fileType;
        public string watermark;
        public int typeID;
        public int userID;
        public string imageUrl;
    }
}
