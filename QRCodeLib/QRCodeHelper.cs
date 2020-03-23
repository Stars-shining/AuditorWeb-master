using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Drawing;
using ThoughtWorks.QRCode.Codec;

namespace QRCodeLib
{
    public static class QRCodeHelper
    {
        /// <summary>
        /// 创建二维码
        /// </summary>
        /// <param name="content"></param>
        /// <param name="size"></param>
        /// <returns></returns>
        public static Bitmap Create(string content)
        {
            try
            {
                //var options = new QrCodeEncodingOptions
                //{
                //    DisableECI = true,
                //    CharacterSet = "UTF-8",
                //    Width = size,
                //    Height = size,
                //    Margin = 0,
                //    ErrorCorrection = ErrorCorrectionLevel.H

                //};
                //var writer = new BarcodeWriter();
                //writer.Format = BarcodeFormat.QR_CODE;
                //writer.Options = options;
                //var bmp = writer.Write(content);
                //return bmp;

                QRCodeEncoder qRCodeEncoder = new QRCodeEncoder();
                qRCodeEncoder.QRCodeEncodeMode = QRCodeEncoder.ENCODE_MODE.BYTE;//设置二维码编码格式 
                qRCodeEncoder.QRCodeScale = 4;//设置编码测量度             
                qRCodeEncoder.QRCodeVersion = 7;//设置编码版本   
                qRCodeEncoder.QRCodeErrorCorrect = QRCodeEncoder.ERROR_CORRECTION.M;//设置错误校验 

                Bitmap image = qRCodeEncoder.Encode(content);
                return image;
            }
            catch (Exception ex)
            {
                return null;
            }
        }

        /// <summary>
        /// 获取本地图片
        /// </summary>
        /// <param name="fileName"></param>
        /// <returns></returns>
        private static Bitmap GetLocalLog(string fileName)
        {
            Bitmap newBmp = new Bitmap(fileName);
            //Bitmap bmp = new Bitmap(newBmp);
            return newBmp;
        }
        /// <summary>
        /// 生成带logo二维码
        /// </summary>
        /// <returns></returns>
        public static Bitmap CreateQRCodeWithLogo(string content, string logopath)
        {
            //生成二维码
            Bitmap qrcode = Create(content);

            //生成logo
            Bitmap logo = GetLocalLog(logopath);
            ImageUtility util = new ImageUtility();
            Bitmap finalImage = util.MergeQrImg(qrcode, logo);
            return finalImage;
        }

    }
}
