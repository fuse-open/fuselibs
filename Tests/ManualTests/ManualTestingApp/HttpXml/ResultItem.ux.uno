using Uno;
using Fuse;
using Fuse.Controls;

public partial class ResultItem
{
    public ResultItem()
    {
        InitializeUX();
    }

    public ResultItem(string fieldName, string expectedResult, string actualResult) : this()
    {
    	FieldName.Value = fieldName;
    	ExpectedResult.Value = expectedResult;
    	ActualResult.Value = actualResult;
    }
}
