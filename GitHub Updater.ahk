f_UpdateRoutine(VersionNumberDefStringIncludeScripts:="VN=",VersionNumberDefMainScript:="VNI=",vNumberOfBackups:=0,IniObjFlag:=-1)
{
	; facilitates all subfunctions for pulling updates from a public github repo.
	; before calling this function, make sure you have the following 


	; m(GitPageURLComponents,"`n",LocalValues)
	; add input verification: 
	; does gitpage connect successfully, 
	; does gitpage4 contain a valid path on the harddrive
	; 
	global GitPageURLComponents 
	global LocalValues
	
		;Date: 22 Mai 2021 10:57:45: an alternative way would be to use the ini-file
		;only for fetching file-urls, then check for missing files. all other files are
		;compared on a line-by-line basis to check if they match everywhere. you could
		;make this a "cutting edge"-feature (possibly search another git branch for this?
		;) and ask the user if they want to use experimental versions. Much more prone to
		;error,  but in theory possible.
	gui, destroy
	vFileCountToUpdate:=0
	ReturnPackage:=f_CheckForUpdates(GitPageURLComponents,LocalValues,VersionNumberDefMainScript,VersionNumberDefStringIncludeScripts)
	vFileCountToUpdate:=ReturnPackage[2].Count()
	if ReturnPackage[1]!=0
		vFileCountToUpdate++
		;tooltip, updating 	; insert f_PerformUpdate here
	if vFileCountToUpdate!=0 			; MainFile's VN doesn't match → update (insert assume-all function? Not necessary, as each file with unique name is also loggged by vn.)
		if f_Confirm_Question_Updater("Do you want to update?`nNew Version is available",LocalValues[1],LocalValues[2])
			f_PerformUpdate(ReturnPackage,GitPageURLComponents,LocalValues,IniObjFlag,vNumberOfBackups)
	else if (lIsDifferent=-1) 	; vn-identifier string not found
		if !vsdb
		{
			Notify().AddWindow("No update available",{Title:"Checking for updates.",TitleColor:"0xFFFFFF",Time:1200,Color:"0xFFFFFF",Background:"0x000000",TitleSize:10,Size:10,ShowDelay:0,Radius:15, Flash:1200,FlashColor:0x5555})
			UpdateCheck:=-1
			return UpdateCheck ; insert notify guis to tell no update is available
		}
	else if (lIsDifferent=0) 	; vn's match
		return
}

f_CheckForUpdates(GitPageURLComponents,LocalValues,VersionNumberDefStringIncludeScripts,VersionNumberDefMainScript:="VN=")
{
	; returns:
	;  0 - match
	;  1 - don't match
	; -1 - VersionNumberDefMainScript could not be found 
	;__________________________________________
	
	
	;__________________________________________
	;__________________________________________
	; Check main script against github instance
	;__________________________________________
	;__________________________________________
	; taken from https://www.autohotkey.com/docs/commands/URLDownloadToFile.htm#WHR example 3
	whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
	; https://raw.githubusercontent.com/Gewerd-Strauss/GeneralHealthBots.ahk/main/StayHydratedBot%20settingsGUI_16.05.2021.ahk
	url:="https://raw.githubusercontent.com/" GitPageURLComponents[1] "/" GitPageURLComponents[2] "/main/" GitPageURLComponents[3]""
	;m(url)
	whr.Open("GET","https://raw.githubusercontent.com/" GitPageURLComponents[1] "/" GitPageURLComponents[2] "/main/" GitPageURLComponents[3]"", true)
	whr.Send()
	; Using 'true' above and the call below allows the script to remain responsive.
	whr.WaitForResponse()
	ReadLine := strsplit(whr.ResponseText,"`r`n")
	vNumel:=ReadLine.length()
	loop, %vNumel%
		if Instr(ReadLine[A_Index],VersionNumberDefMainScript)
		{
			; if (substr(vNumel))
			vVNOnline:=ReadLine[A_Index]
			; m(vVNOnline,VN)
			;d:=SubStr(vVNOnline,1,1)
 			;if (d="") 	; this doesn't work, how do I get the fucking string of the thing? ffs. 
			;	MsgBox, hi
			vVNOnline:=StrReplace(vVNOnline," ")
			vVNOnline:=StrReplace(vVNOnline,VersionNumberDefMainScript,"")
			if (vVNOnline != LocalValues[2])		; vVNOnline is the github version, GitpageURLComponents1 is the local version, this needs to be switched
				VersionDifference_MainScript:=true
			Else
				VersionDifference_MainScript:=false
			break
		}
	Else
		VersionDifference_MainScript:=-1
	;MsgBox % vVNOnline "`n" LocalValues[2] "`nDifference:" VersionDifference_MainScript
	
	
	;________________________________________________
	;________________________________________________
	; Get Local include version Numbers (VNs)
	; write to common ini-file to query when uploaded
	;________________________________________________
	;________________________________________________
	
	
	
	OfflineVNs:=[]
	OfflineVNs["local"]:=[]
	OfflineVNs["local"]:=f_PullLocalVersionsFromIncludeFiles("GeneralHealthBots\includes",VersionNumberDefStringIncludeScripts)
	OfflineVNs["local"][A_ScriptName]:=LocalValues[2]	; this throws an error in the testfile, but won't do so in the actual file. 
	OfflineVNs["localend"]:=[]
	
	m(OfflineVNs)
	FolderOfVersioningFile:="FileVersions"
	SplitPath, A_ScriptName, A_ScriptNameNoExt
	f_WriteINI_FileVersions(OfflineVNs,"FileVersions " A_ScriptNameNoExt ,FolderOfVersioningFile)		; figure out how to write this array to the ini-file
	INiObj:=f_ReadINI_FileVersions("FileVersions " A_ScriptNameNoExt,FolderOfVersioningFile) ;; replace this with FileNameIniRead later once this is written out fully. 
	; now we have the VN's of all subscripts locally, and they are always updated to the ini-file itself. 
	
	; now we have: Function pulls vn's from local files, with OfflineVNs being an array of filename - vn created at start of mainscript
	; 
	
	;________________________________________________
	;________________________________________________
	; Get online include version Numbers (VNs) from the online ini.file ← this is important to go over the ini-file as we need to make 
	; sure we also catch the files that are new, but for those we cannot assemble the url-string yet, as we would be lacking the filenames. 
	; Hence, we need to read back the ini-file to get the names of the functions existing on github
	
	
	
	; for v, k in OfflineVNs.local
	; {
	; 	m(v)
	
	; wrap this code in a function OnlineVNs:=f_PullOnlineVersionsFromIniFile(GitPageURLComponents) ; returns OnlineVNs
	OnlineVNs:=f_PullOnlineVersionsFromIniFile(GitPageURLComponents)
	
	OnlineVNs.Remove("")
	FilesToDownload:=f_CompareVersions(OnlineVNs,OfflineVNs,GitPageURLComponents)
	
	
	ReturnPackage:=[]
	ReturnPackage:=[VersionDifference_MainScript,FilesToDownload]
		;Date: 21 Mai 2021 23:00:37: todo tomorrow:  1. verify that my filtering
		;function does indeed work correctly. 2. write the downloader-fn (which really is
		;just a https-request linked to a FileOpen/FileClose to properly edit all. Make
		;sure you have all necessary values passed.)
	
	return ReturnPackage
	
}

f_CompareVersions(OnlineVNs,OfflineVNs,GitPageURLComponents)
{ ; returns array of filenames to download. Files with version mismatch and files not existing on the local instance/ini-file are selected, and marked to be downloaded
	; 1. Check if vn's are equal
		; this doesn't work because files are not in the same order, hence if a new file is inserted one pattern will shift by 1 completely, resulting in permanent hits where there aren't any irl.
		; fix:
		; 1. Collect the Keys of the OFFLINE array in a separate array (which is non-associative)
		; 2. Loop through the keys of ONLINE arr and check if they exist in the new offline-key-array
		; 2.1 YES: compare the vn's of that key between both arrays and check if unequal → download
		; 2.2 NO:  key of an online-fn doesn't exist in the offline-fn, hence the function doesn't exist either. → download to file
		
	FilesToDownload:=[]
	Ind:=1
	k:=""
	OfflineFiles:=[]
	for k,v in OfflineVNs.local
		OfflineFiles[A_Index]:=k		; contains all keys of offline files: these files exist on the pc.
	for k, v in OnlineVNs			; loop through the keys of Online files to check if they exist within the offline files. 
	{
		HV:=HasVal(OfflineFiles,k)
		if HV!=0	; if HV!=0 OfflineFiles does have the key, hence the file exists. now compare the respective VNs
		{
			a:=OfflineVNs.local[k]
			b:=OnlineVNs[k]
			if !Instr(a,b)	; if a!=b the file VNs are unequal, hence download
			{
				FilesToDownload[Ind]:=k
				Ind++
			}
		}
		Else		; if HV=0, the file doesn't exist locally, hence add it. 
		{
			;m(HV,"doesn't exist, hence download directly")
			;m(k,"very much news","`nLocal:",a,LocalVN_current,"`nOnline:",b,VN_kOn)
			FilesToDownload[Ind]:=k
			Ind++
		}	
	}
	return FilesToDownload
}

f_PerformUpdate(ReturnPackage,GitPageURLComponents,LocalValues,IniObjFlag:=1,vNumberOfBackups:=0)
{

		;NEW PROCEDURE: 
		;0. Create Backup
		
		;1. Parse throught ReturnPackage[2]
		;1.1. Create dummy-values "FileNotReadFromGitPage"
		;1.2. attempt to read each file from gitpage into the respective variable.
			 ;The files that remain unchanged couldn't be downloaded for some reason
			 	;- faulty vn, faulty name f.e.
		;2. Assemble the respective url's and write them to an array DownloadURLs
		;3. Check if ReturnPackage[1]=1 ← download MainScript
		;4. pass that to f_downloadfiles, returning array (FileArray) of filenames (keys) and the entire files (vals)
		;5. pass that to f_writedownloads, which takes the FileArray and all paths ()
	
	; 0. Create Backup
	if vNumberOfBackups>0
	{
		ExcludedFolders:=["AHK-Studio Backup","PrivateMusic"]
		f_CreateBackup(vNumberOfBackups,ExcludedFolders)
	}
	; 1. Parse throught ReturnPackage[2]
	FilesReadFromGitPage:=[]
	for k,v in ReturnPackage[2]
		FilesReadFromGitPage[k]:="-1: File Not read from gitpage"
	GitPageURLComponents[5]:=LocalValues[3]
	FileTexts:=f_DownloadFilesFromGitPage(FilesReadFromGitPage,GitPageURLComponents,ReturnPackage)
	
	;ReturnPackage[2].Push(A_ScriptName)
	f_WriteFilesFromArray(ReturnPackage[2],FileTexts,GitPageURLComponents)
	f_NotifyUserOfUpdates()
	return ; VersionDifference_MainScript
} 

f_NotifyUserOfUpdates()
{
	m("remember to create the notifyuserofupdates_fn")
	;Date: 22 Mai 2021 13:34:03: todo: notify what has changed, where the old files
	;are, etc etc  1. Old files are dropped to 
}

f_WriteFilesFromArray(FileNames,FileTexts,GitPageURLComponents)
{
	global vsdb
	; m(FileNames)
	; m(GitPageURLComponents[5])
	; m(FileTexts)
	FilePathsLocal:=f_AssembleLocalFilePaths(FileNames,GitPageURLComponents[5]) ; this function assembles the local file path for the main script onto the filepath of m.ahk
	ErrorMsg:=[]
	Files:=[FileNames,FileTexts,FilePathsLocal,ErrorMsg]
	for k,v in FilePathsLocal
	{
		if FileTexts[k]!="404: Not Found"
		{
			if  vsdb ;!
			{
				If !FileExist(v)
					ErrorMsg.push(0)
				Else
					ErrorMsg.push(1)
				CurrFile:=FileOpen(v,"w") 	; this is a beatiful one-liner that wipes the entire file clean. This is necessary because we need to make sure our replacement isn't destroyed by left-over text from the file before.
				CurrFile:=FileOpen(v,"rw") 	; actually open the file to write the update to it.
				CurrFile.Write(FileTexts[k])
				CurrFile.Close()
			}
			;Files.push(FileExist)
		}
		else
		{
			ErrorMsg.push(-1)
			;m("File not found online: Reference exists, file itself does not")
		}
	}
	; and now we only have to write the files to the files, duh.
	if !vsdb
		m("f_writeFilesFromArray:`nremember to finish thee notify-msgs")
		
		f_FinishUp(GitPageURLComponents,Files)
}

f_FinishUp(GitpageURLComponents,Files)
{
	EMString:=f_AssembleErrorMessages(GitPageURLComponents,Files)
	m(EMString)
}

f_AssembleErrorMessages(GitPageURLComponents,Files)
{	; function assembles the various error-messages into one unified 
	NotifyArr:=[]
	LongStr:="`Error Messages:`n"
	for k,v in Files[4]
		if v=-1
		{
			str:= "`n" Files[1][k] ": A reference exists, but the file itself is not found at the repo. Please create an issue to notify the creator of a missing file or a superfluous reference"
			Longstr.=str

		}
	LongStr.="`n`nCreated Files:`n"
	for k,v in Files[4]
		if v=0
		{
			str:= "`n"""Files[1][k] """ was created"
			Longstr.=str
		}
	LongStr.="`n`nUpdated Files:`n"
	for k,v in Files[4]
		if v=1
		{
			str:= "`n"""Files[1][k] """ was updated"
			Longstr.=str
		}
	return Longstr
}


f_AssembleLocalFilePaths(FileNames,FileDirIncludes)
{
	FilePathsLocal:=[]
	for k,v in FileNames
	{
		CurrFilePath:=A_ScriptDir "\" FileDirIncludes FileNames[A_Index]
		CurrFilePath:=StrReplace(CurrFilePath,"/","\" )
		FilePathsLocal[A_Index]:=CurrFilePath
		Ind:=A_Index
	}
	return FilePathsLocal
}

f_DownloadFilesFromGitPage(FilesReadFromGitPage,GitPageURLComponents,ReturnPackage)
{
	DownloadURLs:=f_AssembleDownloadURLs(GitPageURLComponents,ReturnPackage)

	whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
	for k,v in DownloadURLs
	{
		whr.Open("GET",DownloadURLs[A_Index]"", true)
		whr.Send()	
		whr.WaitForResponse()
		FileNameArr:=StrSplit(DownloadURLs[A_Index],"/")
		ArrayVal:=whr.ResponseText ;"||" FileNameArr[FileNameArr.MaxIndex()]
		FilesReadFromGitPage[A_Index]:=ArrayVal
	}
	
	return FilesReadFromGitPage
}

f_AssembleDownloadURLs(GitPageURLComponents,ReturnPackage)
{
	DownloadURLs:=[]
	for k,v in ReturnPackage[2]
		DownloadURLs[A_Index]:="https://raw.githubusercontent.com/" GitPageURLComponents[1] "/" GitPageURLComponents[2] "/main/" GitPageURLComponents[5] ReturnPackage[2][A_Index]
	if ReturnPackage[1]
		DownloadURLs.push("https://raw.githubusercontent.com/" GitPageURLComponents[1] "/" GitPageURLComponents[2] "/main/" GitPageURLComponents[3]"")		; figure out if the %20 is valid or f_InformOfNextSteps(
 
	return DownloadURLs
}

f_PullOnlineVersionsFromIniFile(GitPageURLComponents)
{
   	whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
	url:="https://raw.githubusercontent.com/" GitPageURLComponents[1] "/" GitPageURLComponents[2] "/main/" GitPageURLComponents[4]""
	whr.Open("GET",url, true)
	whr.Send()
	; Using 'true' above and the call below allows the script to remain responsive.
	whr.WaitForResponse()
	ReadLine := strsplit(whr.ResponseText,"`r`n")
	vNumel:=ReadLine.length()
 	RunCount:=0
	OnlineVNs:=[]
	lCatchLines:=false
	loop, %vNumel%
	{
		if lCatchLines or lCatchLines=2 ; assuming these 
		{
			lCatchLines:=2
			RunCount++
			; if (substr(vNumel))
			LineReadInd:=A_INdex
			vVNOnline:=ReadLine[LineReadInd]
			; m(vVNOnline,VN)
		 	;d:=SubStr(vVNOnline,1,1)
			;if (d="") 	; this doesn't work, how do I get the fucking string of the thing? ffs. 
			;	MsgBox, hi
			vVNOnline:=StrReplace(vVNOnline," ")
			vVNOnline:=StrReplace(vVNOnline,VersionNumberDefMainScript,"")
			RegExMatch(vVNOnline, "(?<FileName>[a-z A-Z _\- 0-9]+.ahk)(=)(?<VersionNumberOfFileName>[0-9]+.[0-9]+.[0-9]+.[0-9]+)",v)
			; how do I get the contents of vFileName and vVersionNUmberOfFileName into an array?
			OnlineVNs[vFileName]:=vVersionNumberOfFileName
		}
		if Instr(ReadLine[A_Index],"[local]") and ((lCatchLines=false) or (lCatchLines=true))
			lCatchLines:=true
		else if Instr(ReadLine[A_Index] ,"[local end]") and lCatchLines and ((lCatchLines=false) or (lCatchLines=true))		;; remember to edit the ini-write function to add this section at the end as well to signify the end of the include-files-ini-section.
			lCatchLines:=false
		else
			if lCatchLines!=2
				lCatchLines:=false
	}
	return OnlineVNs
}

f_PullLocalVersionsFromIncludeFiles(DirectoryOfIncludeFilesRelativeFromMainFile,VersionNumberDefStringIncludeScripts)
{
 	VNI=1.0.0.1
	FilesOfProject:=f_ListFiles(A_ScriptDir "\" DirectoryOfIncludeFilesRelativeFromMainFile)
 	versions := []
	Paths:=A_ScriptDir "\" DirectoryOfIncludeFilesRelativeFromMainFile "\*.ahk"
	VersionNumberDefStringIncludeScripts:=strreplace(VersionNumberDefStringIncludeScripts,"=","")
	needle:=VersionNumberDefStringIncludeScripts "[^\d]+([\d\.]+)"

	loop files,%Paths% , F ;R
	{
		FileRead buffer, % A_LoopFileFullPath
		RegExMatch(buffer,needle, ReadLine)
			versions[A_LoopFileName] := ReadLine1
	}
	return versions
}

f_CreateBackup(vNumberOfBackups,ExcludeFolders)
{
	global vsdb 
	if vNumberOfBackups>1
	{
		m("finish the multi-backup paths.")
	}
	m("implement logic for number of backups")
	SourceCD:=A_ScriptDir ;"\"
	DestCD:=A_ScriptDir "\UserBackup"
	loop, files, %A_ScriptDir%
	{
		m(A_LoopFileName)
		if !HasVal(ExcludeFolders,A_LoopFileName)
			FileCopyDir, A_LoopFileFullPath, %DestCD%
	}
	if !vsdb
		Notify().AddWindow("Backup completed",{Title:"Updating " A_ScriptName,TitleColor:"0xFFFFFF",Time:1300,Color:"0xFFFFFF",Background:"0x000000",TitleSize:10,Size:10,ShowDelay:0,Radius:15, Flash:1000,FlashColor:0x5555})
}

HasVal(haystack, needle) 
{	; code from jNizM on the ahk forums: https://www.autohotkey.com/boards/viewtopic.php?p=109173&sid=e530e129dcf21e26636fec1865e3ee30#p109173
	if !(IsObject(haystack)) || (haystack.Length() = 0)
		return 0
	for index, value in haystack
		if (value = needle)
			return index
	return 0
}

f_ListFiles(Directory)
{	
	files:=[]
	Loop %Directory%\*.ahk
	{
		files[A_Index]:=A_LoopFileName
	}
	return files
}

f_WriteINI_FileVersions(ByRef Array2D, INI_File,FolderOfVersioningFile)  ; write 2D-array to INI-file
{
	m(INI_File)
	VNI=1.0.0.12
	
	if !FileExist(FolderOfVersioningFile) ; check for ini-files directory
	{
		MsgBox, Creating "%FolderOfVersioningFile%"-directory at Location`n"%A_ScriptDir%", containing an ini-file named "%INI_File%.ini"
		FileCreateDir, %FolderOfVersioningFile%
	}
	OrigWorkDir:=A_WorkingDir
	SetWorkingDir, %FolderOfVersioningFile%
	INI_File:=StrReplace(INI_File,".ahk","")
	for SectionName, Entry in Array2D 
	{
		Pairs := ""
		for Key, Value in Entry
			Pairs .= Key "=" Value "`n"
		IniWrite, %Pairs%, %INI_File%.ini, %SectionName%
	}
	if A_WorkingDir!=OrigWorkDir
		SetWorkingDir, %OrigWorkDir%0
;	/* Original File from https://www.autohotkey.com/boards/viewtopic.php?p=256714#p256714
;		
;	;-------------------------------------------------------------------------------
;		WriteINI(ByRef Array2D, INI_File) { ; write 2D-array to INI-file
;	;-------------------------------------------------------------------------------
;			for SectionName, Entry in Array2D {
;				Pairs := ""
;				for Key, Value in Entry
;					Pairs .= Key "=" Value "`n"
;				IniWrite, %Pairs%, %INI_File%, %SectionName%
;			}
;		}
;	*/
}

f_ReadINI_FileVersions(INI_File,FolderOfVersioningFile) ; return 2D-array from INI-file
{
	VNI=1.0.0.10
	Result := []
	OrigWorkDir:=A_WorkingDir
	SetWorkingDir, %FolderOfVersioningFile%
	INI_File:=StrReplace(INI_File,".ahk",".ini")
	IniRead, SectionNames, %INI_File%
	for each, Section in StrSplit(SectionNames, "`n") {
		IniRead, OutputVar_Section, %INI_File%, %Section%
		for each, Haystack in StrSplit(OutputVar_Section, "`n")
			RegExMatch(Haystack, "(.*?)=(.*)", $)
         , Result[Section, $1] := $2
	}
	if A_WorkingDir!=OrigWorkDir
		SetWorkingDir, %OrigWorkDir%
	return Result
	
;	/* Original File from https://www.autohotkey.com/boards/viewtopic.php?p=256714#p256714
;	;-------------------------------------------------------------------------------
;	ReadINI(INI_File) { ; return 2D-array from INI-file
;	;-------------------------------------------------------------------------------
;		Result := []
;		IniRead, SectionNames, %INI_File%
;		for each, Section in StrSplit(SectionNames, "`n") {
;			IniRead, OutputVar_Section, %INI_File%, %Section%
;			for each, Haystack in StrSplit(OutputVar_Section, "`n")
;				RegExMatch(Haystack, "(.*?)=(.*)", $)
;           , Result[Section, $1] := $2
;		}
;		return Result
;	*/
}

f_Confirm_Question_Updater(Question,AU,VN)
{
	; returns:
	;  0 - answered no
	;  1 - answered yes
	; -1 - user canceled ()
	gui, cQ: new
	gui_control_options := "xm w220 " . cForeground . " -E0x200"  ; remove border around edit field
	gui, cQ: Margin, 16, 16
	gui, cQ: +AlwaysOnTop -SysMenu -ToolWindow -caption +Border
	cBackground := "c" . "1d1f21"
	cCurrentLine := "c" . "282a2e"
	cSelection := "c" . "373b41"
	cForeground := "c" . "c5c8c6"
	cComment := "c" . "969896"
	cRed := "c" . "cc6666"
	cOrange := "c" . "de935f"
	cYellow := "c" . "f0c674"
	cGreen := "c" . "b5bd68"
	cAqua := "c" . "8abeb7"
	cBlue := "c" . "81a2be"
	cPurple := "c" . "b294bb"
	Gui, cQ: Color, 1d1f21, 373b41, 
	Gui, cQ: Font, s11 cWhite, Segoe UI 
	gui, cQ: add, text,xm ym, %Question%
	gui, cQ: add, button, xm+20 ym+50 w30 gConfirmQuestion_f_ConfirmQuestion_Updater, &Yes
	gui, cQ: add, button, xm+170 ym+50 w30 gDenyQuestion_f_ConfirmQuestion_Updater, &No
	Gui, cQ: Font, s7 cWhite, Verdana
	if VN!="" and AU!=""
		Gui, cQ: Add, Text,x25, Version: %VN%
	else if VN!="" and AU=""
		Gui, cQ: Add, Text,x25, Version: %VN%
	else if VN="" and AU!=""
		Gui, cQ: Add, Text,x25, Author: %AU% 
	
	yc:=A_ScreenHeight-200
	xc:=A_ScreenWidth-300
	gui, cQ: show,autosize  x%xc% y%yc%, CQ%A_ThisLabel%
	winactivate, CQ
	WinWaitClose, CQ%A_ThisFun%
	return answer
	
	GuiEscape_ConfirmQuestion_f_ConfirmQuestion_Updater:
	gui, cQ: destroy
	return answer:=-1
	
	ConfirmQuestion_f_ConfirmQuestion_Updater:
	gui, cQ: submit
	gui, cQ: destroy
	return answer:=true
	
	DenyQuestion_f_ConfirmQuestion_Updater:
	gui, cQ: submit
	gui, cQ: destroy
	return answer:=false
	
	
}

f_InformOfNextSteps(H:="No info given for this step.",XtOffset:=300,YtOffset:=400)
{
	global
	x:=A_ScreenWidth-XtOffset
	y:=A_ScreenHeight-YtOffset
	tooltip, % st_wordwrap_Updater(H), x,y
	; 1
}

st_wordwrap_Updater(string, column=56, indentChar="")
{
	indentLength := StrLen(indentChar)
	
	Loop, Parse, string, `n, `rff
	{
		If (StrLen(A_LoopField) > column)
		{
			pos := 1
			Loop, Parse, A_LoopField, %A_Space%
				If (pos + (loopLength := StrLen(A_LoopField)) <= column)
					out .= (A_Index = 1 ? "" : " ") A_LoopField
                    , pos += loopLength + 1
			Else
				pos := loopLength + 1 + indentLength
                    , out .= "`n" indentChar A_LoopField
			
			out .= "`n"
		} Else
			out .= A_LoopField "`n"
	}
	
	Return SubStr(out, 1, -1)
}
