using Uno;
using Uno.Data.Xml;
using Fuse;
using Uno.Collections;
using Fuse.Controls;
using Fuse.Navigation;
using Fuse.Elements;
using Uno.Net.Http;

public partial class HttpXmlView 
{
    private const string _xmlExampleUrl = "http://s3-eu-west-1.amazonaws.com/fuselibs-testing/test-data.xml";

	void OnActive(object sender, object args)
	{
		ClearAll();
		GetXmlAsync();
	}

    void ClearAll()
    {
        SourceText.Value = string.Empty;
        XmlSection.Visibility = Visibility.Collapsed;
        LoadingMessage.Visibility = Visibility.Visible;
        ErrorMessage.Visibility = Visibility.Collapsed;
        SuccessValidation.Visibility = Visibility.Collapsed;
        InvalidResultContainer.Visibility = Visibility.Collapsed;
        FailedValidation.Visibility = Visibility.Collapsed;
        InvalidResultContainer.Children.Clear();
    }

    void GetXmlAsync()
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
        XmlSection.Visibility = Visibility.Visible;
        ErrorMessage.Visibility = Visibility.Collapsed;
        LoadingMessage.Visibility = Visibility.Collapsed;

        var responseString = request.GetResponseContentString();
        SourceText.Value = FixTabsDisplayingIssue(responseString);
        var xmlDocument = XmlDocument.Load(responseString);

        if (xmlDocument != null)
        {
            ValidateResult(xmlDocument);
        }
        else
        {
            ShowError("Unable to parse xml");
        }
    }

    void OnErrorHappened(HttpMessageHandlerRequest request, string message)
    {
        LoadingMessage.Visibility = Visibility.Collapsed;
        ShowError(message);
    }

    void ShowError(string errorMsg)
    {
        XmlSection.Visibility = Visibility.Collapsed;
        ErrorMessage.Visibility = Visibility.Visible;
        ErrorMessage.Value = string.Format("Error: {0}", errorMsg);
    }

    string FixTabsDisplayingIssue(string str)
    {
        return str.Replace("\t", "    ");
    }

    void ValidateResult(XmlDocument xmlDocument)
    {
        var errorList = new List<ResultItem>();
        var rootXmlNode = xmlDocument.DocumentElement.FirstChild;
        ValidateNodesCount(rootXmlNode, errorList);
        ValidateFirstChild(rootXmlNode, errorList);
        ValidateLastChild(rootXmlNode, errorList);

        if (errorList.Count > 0)
        {
            SuccessValidation.Visibility = Visibility.Collapsed;
            FailedValidation.Visibility = Visibility.Visible;
            InvalidResultContainer.Visibility = Visibility.Visible;
            foreach (var error in errorList)
            {
                InvalidResultContainer.Children.Add(error);
            }
        }
        else
        {
            SuccessValidation.Visibility = Visibility.Visible;
            FailedValidation.Visibility = Visibility.Collapsed;
            InvalidResultContainer.Visibility = Visibility.Collapsed;
        }
    }

    void ValidateNodesCount(XmlLinkedNode rootXmlNode, List<ResultItem> errorList)
    {
        if (rootXmlNode.Children.Count != 5)
        {
            errorList.Add(new ResultItem("Invalid number of 'food' nodes", rootXmlNode.Children.Count.ToString(), "5"));
        }
    }

    void ValidateFirstChild(XmlLinkedNode rootXmlNode, List<ResultItem> errorList)
    {
        if (rootXmlNode.FirstChild != null)
        {
            if (GetXmlNodeChildValue(rootXmlNode.FirstChild, "name") != "Belgian Waffles")
            {
                errorList.Add(new ResultItem("Invalid 'name' value for the first food child", GetXmlNodeChildValue(rootXmlNode.FirstChild, "name"), "Belgian Waffles"));
            }

            if (GetXmlNodeChildValue(rootXmlNode.FirstChild, "price") != "$5.95")
            {
                errorList.Add(new ResultItem("Invalid 'price' value for the first food child", GetXmlNodeChildValue(rootXmlNode.FirstChild, "price"), "$5.95"));
            }

            if (GetXmlNodeChildValue(rootXmlNode.FirstChild, "description") != "Two of our famous Belgian Waffles with plenty of real maple syrup")
            {
                errorList.Add(new ResultItem("Invalid 'description' value for the first food child", GetXmlNodeChildValue(rootXmlNode.FirstChild, "description"), "Two of our famous Belgian Waffles with plenty of real maple syrup"));
            }
        }
    }

    void ValidateLastChild(XmlLinkedNode rootXmlNode, List<ResultItem> errorList)
    {
        if (rootXmlNode.LastChild != null)
        {
            if (GetXmlNodeChildValue(rootXmlNode.LastChild, "name") != "Homestyle Breakfast")
            {
                errorList.Add(new ResultItem("Invalid 'name' value for the last food child", GetXmlNodeChildValue(rootXmlNode.LastChild, "name"), "Belgian Waffles"));
            }

            if (GetXmlNodeChildValue(rootXmlNode.LastChild, "price") != "$6.95")
            {
                errorList.Add(new ResultItem("Invalid 'price' value for the last food child", GetXmlNodeChildValue(rootXmlNode.LastChild, "price"), "$5.95"));
            }

            if (GetXmlNodeChildValue(rootXmlNode.LastChild, "calories") != "950")
            {
                errorList.Add(new ResultItem("Invalid 'calories' value for the last food child", GetXmlNodeChildValue(rootXmlNode.LastChild, "calories"), "950"));
            }

            if (GetXmlNodeAttributeValue(rootXmlNode.LastChild, "id") != "food5")
            {
                errorList.Add(new ResultItem("Invalid 'id' value for the last food child", GetXmlNodeAttributeValue(rootXmlNode.LastChild, "id"), "food5"));
            }
        }
    }

    string GetXmlNodeChildValue(XmlLinkedNode node, string childName)
    {
        try
        {
            return node.FindByName(childName).FirstChild.Value.AsString();
        }
        catch (Exception ex)
        { }
        return "";
    }

    string GetXmlNodeAttributeValue(XmlLinkedNode node, string attributeName)
    {
        try
        {
            return node.Attributes[attributeName].Value.AsString();
        }
        catch (Exception ex)
        { }
        return "";
    }
}
