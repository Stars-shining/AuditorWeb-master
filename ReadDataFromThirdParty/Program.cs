using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Net;
using System.Net.Security;
using System.IO;
using System.Security.Cryptography.X509Certificates;

namespace ReadDataFromThirdParty
{
    class Program
    {
        static void Main(string[] args)
        {
            ReadTokenData();
        }

        static void ReadTokenData() 
        {
            string url = "https://authtest.ictr.com.cn//service/api/Account/Login_API?UserName=zhanghong&Password=123456&ModuleCode=apmanager&Expires=31536000";
            var data = new
            {
                UserName = "zhanghong",
                Password = "123456",
                ModuleCode = "apmanager",
                Expires = 31536000
            };
            string result = GetUrlContent("POST", url);
        }

        private static string GetUrlContent(string method, string url)
        {
            HttpWebRequest httpRequest = null;
            HttpWebResponse httpResponse = null;
            string bodys = string.Empty;
            if (url.Contains("https://"))
            {
                ServicePointManager.ServerCertificateValidationCallback = new RemoteCertificateValidationCallback(CheckValidationResult);
                httpRequest = (HttpWebRequest)WebRequest.CreateDefault(new Uri(url));
            }
            else
            {
                httpRequest = (HttpWebRequest)WebRequest.Create(url);
            }
            httpRequest.Method = method;
            httpRequest.Headers.Add("token", "2ede7aee7ed6458b8a6124c93b5ad84b");
            if (0 < bodys.Length)
            {
                byte[] data = Encoding.UTF8.GetBytes(bodys);
                using (Stream stream = httpRequest.GetRequestStream())
                {
                    stream.Write(data, 0, data.Length);
                }
            }
            try
            {
                httpResponse = (HttpWebResponse)httpRequest.GetResponse();
            }
            catch (WebException ex)
            {
                httpResponse = (HttpWebResponse)ex.Response;
            }

            Stream st = httpResponse.GetResponseStream();
            StreamReader reader = new StreamReader(st, Encoding.GetEncoding("utf-8"));
            bodys = reader.ReadToEnd();
            return bodys;
        }

        public static bool CheckValidationResult(object sender, X509Certificate certificate, X509Chain chain, SslPolicyErrors errors)
        {
            return true;
        }

    }
}
