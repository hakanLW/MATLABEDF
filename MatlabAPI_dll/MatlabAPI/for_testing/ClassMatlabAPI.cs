/*
* MATLAB Compiler: 6.4 (R2017a)
* Date: Wed Feb 09 11:42:01 2022
* Arguments:
* "-B""macro_default""-W""dotnet:MatlabAPI_1_0_0,ClassMatlabAPI,4.0,private""-T""link:lib"
* "-d""C:\GIT\matlabapideveloper\MatlabAPI_dll\MatlabAPI\for_testing""-v""class{ClassMatla
* bAPI:C:\GIT\matlabapideveloper\ECGAnalysis.m}"
*/
using System;
using System.Reflection;
using System.IO;
using MathWorks.MATLAB.NET.Arrays;
using MathWorks.MATLAB.NET.Utility;

#if SHARED
[assembly: System.Reflection.AssemblyKeyFile(@"")]
#endif

namespace MatlabAPI_1_0_0
{

  /// <summary>
  /// The ClassMatlabAPI class provides a CLS compliant, MWArray interface to the MATLAB
  /// functions contained in the files:
  /// <newpara></newpara>
  /// C:\GIT\matlabapideveloper\ECGAnalysis.m
  /// </summary>
  /// <remarks>
  /// @Version 4.0
  /// </remarks>
  public class ClassMatlabAPI : IDisposable
  {
    #region Constructors

    /// <summary internal= "true">
    /// The static constructor instantiates and initializes the MATLAB Runtime instance.
    /// </summary>
    static ClassMatlabAPI()
    {
      if (MWMCR.MCRAppInitialized)
      {
        try
        {
          Assembly assembly= Assembly.GetExecutingAssembly();

          string ctfFilePath= assembly.Location;

          int lastDelimiter= ctfFilePath.LastIndexOf(@"\");

          ctfFilePath= ctfFilePath.Remove(lastDelimiter, (ctfFilePath.Length - lastDelimiter));

          string ctfFileName = "MatlabAPI_1_0_0.ctf";

          Stream embeddedCtfStream = null;

          String[] resourceStrings = assembly.GetManifestResourceNames();

          foreach (String name in resourceStrings)
          {
            if (name.Contains(ctfFileName))
            {
              embeddedCtfStream = assembly.GetManifestResourceStream(name);
              break;
            }
          }
          mcr= new MWMCR("",
                         ctfFilePath, embeddedCtfStream, true);
        }
        catch(Exception ex)
        {
          ex_ = new Exception("MWArray assembly failed to be initialized", ex);
        }
      }
      else
      {
        ex_ = new ApplicationException("MWArray assembly could not be initialized");
      }
    }


    /// <summary>
    /// Constructs a new instance of the ClassMatlabAPI class.
    /// </summary>
    public ClassMatlabAPI()
    {
      if(ex_ != null)
      {
        throw ex_;
      }
    }


    #endregion Constructors

    #region Finalize

    /// <summary internal= "true">
    /// Class destructor called by the CLR garbage collector.
    /// </summary>
    ~ClassMatlabAPI()
    {
      Dispose(false);
    }


    /// <summary>
    /// Frees the native resources associated with this object
    /// </summary>
    public void Dispose()
    {
      Dispose(true);

      GC.SuppressFinalize(this);
    }


    /// <summary internal= "true">
    /// Internal dispose function
    /// </summary>
    protected virtual void Dispose(bool disposing)
    {
      if (!disposed)
      {
        disposed= true;

        if (disposing)
        {
          // Free managed resources;
        }

        // Free native resources
      }
    }


    #endregion Finalize

    #region Methods

    /// <summary>
    /// Provides a single output, 0-input MWArrayinterface to the ECGAnalysis MATLAB
    /// function.
    /// </summary>
    /// <remarks>
    /// M-Documentation:
    /// Initialization
    /// </remarks>
    /// <returns>An MWArray containing the first output argument.</returns>
    ///
    public MWArray ECGAnalysis()
    {
      return mcr.EvaluateFunction("ECGAnalysis", new MWArray[]{});
    }


    /// <summary>
    /// Provides a single output, 1-input MWArrayinterface to the ECGAnalysis MATLAB
    /// function.
    /// </summary>
    /// <remarks>
    /// M-Documentation:
    /// Initialization
    /// </remarks>
    /// <param name="FileAdress">Input argument #1</param>
    /// <returns>An MWArray containing the first output argument.</returns>
    ///
    public MWArray ECGAnalysis(MWArray FileAdress)
    {
      return mcr.EvaluateFunction("ECGAnalysis", FileAdress);
    }


    /// <summary>
    /// Provides a single output, 2-input MWArrayinterface to the ECGAnalysis MATLAB
    /// function.
    /// </summary>
    /// <remarks>
    /// M-Documentation:
    /// Initialization
    /// </remarks>
    /// <param name="FileAdress">Input argument #1</param>
    /// <param name="JsonRequestPackets">Input argument #2</param>
    /// <returns>An MWArray containing the first output argument.</returns>
    ///
    public MWArray ECGAnalysis(MWArray FileAdress, MWArray JsonRequestPackets)
    {
      return mcr.EvaluateFunction("ECGAnalysis", FileAdress, JsonRequestPackets);
    }


    /// <summary>
    /// Provides the standard 0-input MWArray interface to the ECGAnalysis MATLAB
    /// function.
    /// </summary>
    /// <remarks>
    /// M-Documentation:
    /// Initialization
    /// </remarks>
    /// <param name="numArgsOut">The number of output arguments to return.</param>
    /// <returns>An Array of length "numArgsOut" containing the output
    /// arguments.</returns>
    ///
    public MWArray[] ECGAnalysis(int numArgsOut)
    {
      return mcr.EvaluateFunction(numArgsOut, "ECGAnalysis", new MWArray[]{});
    }


    /// <summary>
    /// Provides the standard 1-input MWArray interface to the ECGAnalysis MATLAB
    /// function.
    /// </summary>
    /// <remarks>
    /// M-Documentation:
    /// Initialization
    /// </remarks>
    /// <param name="numArgsOut">The number of output arguments to return.</param>
    /// <param name="FileAdress">Input argument #1</param>
    /// <returns>An Array of length "numArgsOut" containing the output
    /// arguments.</returns>
    ///
    public MWArray[] ECGAnalysis(int numArgsOut, MWArray FileAdress)
    {
      return mcr.EvaluateFunction(numArgsOut, "ECGAnalysis", FileAdress);
    }


    /// <summary>
    /// Provides the standard 2-input MWArray interface to the ECGAnalysis MATLAB
    /// function.
    /// </summary>
    /// <remarks>
    /// M-Documentation:
    /// Initialization
    /// </remarks>
    /// <param name="numArgsOut">The number of output arguments to return.</param>
    /// <param name="FileAdress">Input argument #1</param>
    /// <param name="JsonRequestPackets">Input argument #2</param>
    /// <returns>An Array of length "numArgsOut" containing the output
    /// arguments.</returns>
    ///
    public MWArray[] ECGAnalysis(int numArgsOut, MWArray FileAdress, MWArray 
                           JsonRequestPackets)
    {
      return mcr.EvaluateFunction(numArgsOut, "ECGAnalysis", FileAdress, JsonRequestPackets);
    }


    /// <summary>
    /// Provides an interface for the ECGAnalysis function in which the input and output
    /// arguments are specified as an array of MWArrays.
    /// </summary>
    /// <remarks>
    /// This method will allocate and return by reference the output argument
    /// array.<newpara></newpara>
    /// M-Documentation:
    /// Initialization
    /// </remarks>
    /// <param name="numArgsOut">The number of output arguments to return</param>
    /// <param name= "argsOut">Array of MWArray output arguments</param>
    /// <param name= "argsIn">Array of MWArray input arguments</param>
    ///
    public void ECGAnalysis(int numArgsOut, ref MWArray[] argsOut, MWArray[] argsIn)
    {
      mcr.EvaluateFunction("ECGAnalysis", numArgsOut, ref argsOut, argsIn);
    }



    /// <summary>
    /// This method will cause a MATLAB figure window to behave as a modal dialog box.
    /// The method will not return until all the figure windows associated with this
    /// component have been closed.
    /// </summary>
    /// <remarks>
    /// An application should only call this method when required to keep the
    /// MATLAB figure window from disappearing.  Other techniques, such as calling
    /// Console.ReadLine() from the application should be considered where
    /// possible.</remarks>
    ///
    public void WaitForFiguresToDie()
    {
      mcr.WaitForFiguresToDie();
    }



    #endregion Methods

    #region Class Members

    private static MWMCR mcr= null;

    private static Exception ex_= null;

    private bool disposed= false;

    #endregion Class Members
  }
}
