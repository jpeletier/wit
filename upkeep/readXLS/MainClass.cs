using System;
using Excel;
using System.IO;
using System.Collections;

using ADODB;

using peletier.config;
using peletier.ADODBUtils;

namespace readXLS
{
	/// <summary>
	/// Summary description for Class1.
	/// </summary>
	class MainClass
	{
		/// <summary>
		/// The main entry point for the application.
		/// </summary>
		
		static string getCell(Worksheet ws,int row,int column)
		{
			Excel.Range rng=(Range)ws.Cells[row,column];
			object obj=rng.get_Value("".GetType());

			if (obj!=null)
				return obj.ToString();
			else
				return null;

		}
		
		[STAThread]
		static void Main(string[] args)
		{
			object m = System.Reflection.Missing.Value;
			Excel.Application app = new Excel.ApplicationClass();

			Hashtable subjectmap=new Hashtable();

			RecordsetClass rc=peletier.config.common.getOpenedRecordset("SELECT IDSubject, Subject FROM Subjects","Trivial",CursorTypeEnum.adOpenForwardOnly,LockTypeEnum.adLockOptimistic);
			ConnectionClass cn=(ConnectionClass) rc.ActiveConnection;

			while(!rc.EOF)
			{
				subjectmap.Add(rc.Fields["Subject"].Value.ToString(),rc.Fields["IDSubject"].Value);
				rc.MoveNext();
			}

			ADOTools.closeStuff(rc);

			DirectoryInfo fld=new DirectoryInfo("<redacted-path>");
			FileInfo[] files = fld.GetFiles("*.xls");

			string author;
			string question;
			string answer;
			string subject;


			int authorID;
			int subjectID;

			int row;
			
			foreach(FileInfo f in files)
			{
				Excel.Workbook wb = app.Workbooks.Open(f.FullName ,m,m,m,m,m,m,m,m,m,m,m,m,m,m);
				wb.SaveAs(f.FullName + ".txt",XlFileFormat.xlTextWindows,m,m,m,m,XlSaveAsAccessMode.xlExclusive,m,m,m,m,m);
			}
			
			app=null;
			GC.Collect();

		}
	}
}
