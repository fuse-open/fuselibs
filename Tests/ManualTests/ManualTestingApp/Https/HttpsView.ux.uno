using Uno;
using Uno.Data.Xml;
using Fuse;
using Uno.Collections;
using Fuse.Controls;
using Fuse.Navigation;
using Fuse.Elements;
using Uno.Net.Http;

public partial class HttpsView 
{
    private const string _xmlExampleUrl = "https://s3-eu-west-1.amazonaws.com/fuselibs-testing/test-data.html";

    public HttpsView()
    {
        InitializeUX();

        if defined(WebGL)
        {
			SkipSection.Visibility = Visibility.Visible;
        }
        else
        {
			TestSection.Visibility = Visibility.Visible;
        }
    }

    void OnActive(object sender, object args)
    {
		ClearAll();
		GetPageAsync();
    }

    void ClearAll()
    {
        LoadingMessage.Visibility = Visibility.Visible;
        ErrorMessage.Visibility = Visibility.Collapsed;
        SuccessValidation.Visibility = Visibility.Collapsed;
        FailedValidation.Visibility = Visibility.Collapsed;
    }

    void GetPageAsync()
    {
        var httpMessageHandler = new HttpMessageHandler();
        var request = httpMessageHandler.CreateRequest("GET", _xmlExampleUrl);

        request.Done += OnDownloadDone;
        request.Error += OnErrorHappened;
        request.SetResponseType(HttpResponseType.String);
        request.SendAsync();
    }

    void OnDownloadDone(HttpMessageHandlerRequest request)
    {
        LoadingMessage.Visibility = Visibility.Collapsed;

        var responseString = request.GetResponseContentString();
        ValidateResult(responseString);
    }

    void OnErrorHappened(HttpMessageHandlerRequest request, string message)
    {
        LoadingMessage.Visibility = Visibility.Collapsed;
        ShowError(message);
    }

    void ShowError(string errorMsg)
    {
        ErrorMessage.Visibility = Visibility.Visible;
        ErrorMessage.Value = string.Format("Error: {0}", errorMsg);
    }

    void ValidateResult(string htmlString)
    {
        var isValid = htmlString.IndexOf("World") >= 0;
        if (isValid)
        {
            SuccessValidation.Visibility = Visibility.Visible;
            FailedValidation.Visibility = Visibility.Collapsed;
        }
        else
        {
            SuccessValidation.Visibility = Visibility.Collapsed;
            FailedValidation.Visibility = Visibility.Visible;
        }
    }
}
