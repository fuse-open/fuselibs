using Uno;
using Fuse.Scripting;

namespace Fuse.Scripting
{
    class DiagnosticSubject
    {		
        IDisposable _diagnostic;
        public void ClearDiagnostic()
        {
            if (_diagnostic != null)
            {
                _diagnostic.Dispose();
                _diagnostic = null;
            }
        }
        public void SetDiagnostic(ScriptException se)
        {
            var d = new Diagnostic(DiagnosticType.UserError, se.Name, this, se.FileName, se.LineNumber, null, se);
            ClearDiagnostic();
            _diagnostic = Diagnostics.ReportTemporal(d);
        }
    }
}