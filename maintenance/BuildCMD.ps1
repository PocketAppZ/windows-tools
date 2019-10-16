###########################################################################################################
#
# Run-script autobuilder 
# v3.0
#
##############################
#
# This script requires PowerShell 5.1 or higher.  
# Its result is CMD files, which require PowerShell 3.0 or higher.
#
# Github stores its files with history.
# 
# $githubURL = "https://raw.githubusercontent.com/jebofponderworthy/windows-tools/a8e7b0635851d32f534b6b947830872e6ab6efa2/tools/CATE.ps1"
#
# brings up removeGhosts.ps1 as it was at a certain time, September 13, 2018.  Such
# a URL can be had from any file page in the repository.  To get such a URL:
#
# 1. Open a file that has been updated on a day whose snapshot you want to see, by clicking its link.
# 2. Click on History.
# 3. In the rightmost column on the History page, there are links marked "<>" for each snapshot.
#    If you hover over one of these, it will say "Browse the repository in this point in the history."
#    Click the appropriate one.
# 4. Github sends you to browse the root of the snapshot.  Browse to and open the file again, within
#    the snapshot.
# 5. Right-click the "Raw" button and copy to the clipboard.  That is the working snapshot URL for
#    that file.  Take off the filename, and you get the operative URL for this script.
#
# This file builds RUNALL.CMD, DOWNLOAD.CMD, and RUNMOST.CMD.

# These encoding settings appear to result in UTF-8.  Don't ask me why, there might be some screaming involved.
$OutputEncoding = [console]::InputEncoding = [console]::OutputEncoding =
                    New-Object System.Text.ASCIIEncoding
$PSDefaultParameterValues['*:Encoding'] = 'ascii'


$githubURL = "https://raw.githubusercontent.com/jebofponderworthy/windows-tools/21a7e833167151d1e23fedefe14665876bd1f645"

$RUNALLps1List = @(
	"Win10Perf.ps1",
	"RunDevNodeClean.ps1",
	"wt_removeGhosts.ps1",
	"TweakNTFS.ps1",
	"OWTAS.ps1",
	"TOSC.ps1",
	"OVSS.ps1",
	"CATE.ps1"
	)

$RUNMOSTps1List = @(
	"Win10Perf.ps1",
	"RunDevNodeClean.ps1",
	"wt_removeGhosts.ps1",
	"TweakNTFS.ps1",
	"OWTAS.ps1",
	"OVSS.ps1",
	"CATE.ps1"
	)

ForEach ($cmd in @('RUNALL.CMD', 'DOWNLOAD.CMD', 'RUNMOST.CMD', 'GETREDISTS.CMD')) {
	Remove-Item "..\RUN\$cmd" -Force -ErrorAction SilentlyContinue > $null
	New-Item -Name "..\RUN\$cmd" -ItemType File -Force > $null
	echo '@echo off' > ..\RUN\$cmd
	echo '' >> ..\RUN\$cmd
	}

$WebClientObj = (New-Object System.Net.WebClient)
$WebClientObj.Encoding = [System.Text.Encoding]::UTF8

function ProcessPSScript {
	param( [string]$ps1, [string]$CMD, [string]$usermessage, [int]$lastline )
	
	"Processing $ps1 for $CMD ..."
	
	$DownloadURL = "$githubURL/tools/$ps1"
	"Downloading $DownloadURL ..."
	$WebClientObj.DownloadString("$DownloadURL") > "..\tools\$ps1"
	
	# First get hash for the ps1 in study
	$ps1Hash = (certutil -hashfile "..\tools\$ps1" SHA256)[1] -replace '\s',''
	
	# First operative line in RUNALL.CMD, RUNMOST, and DOWNLOAD.CMD for this ps1 file
	$line1 = '@"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command ^' 
	# Second operative line.  Substitutions necessary, which means double quotes.  Singles within doubles are marked single, double within doubles marked double.
	$line2 = (	'"$wco = (New-Object System.Net.WebClient); $wco.Encoding = [System.Text.Encoding]::UTF8; $wco.DownloadString(''' +
				$DownloadURL + ''') > ' + $ps1 + '"' 	) 
				
	# Third.
	$line3 = '@"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command ^'
	# Fourth.  Substitutions necessary.  Within single-quoted strings, one embeds single quotes by doubling them.
	$line4 = (	 '"$certrpt = (certutil -hashfile ' +
				$ps1 + ' SHA256)[1] -replace ''\s'','''' ; If ($certrpt -eq ''' +
				$ps1Hash + ''') { iex .\' + $ps1 + ' } Else { ''Hash fail on ' + $ps1 + '!'' }"' 	)
				
	# Fifth.
	$line5 = "@del $ps1"

	echo 'echo:' >> ..\RUN\$CMD
	echo $usermessage >> ..\RUN\$CMD
	echo 'echo ---' >> ..\RUN\$CMD
	echo 'echo:' >> ..\RUN\$CMD
	echo $line1 >> ..\RUN\$CMD
	If ($lastline -lt 2) { return }
	echo $line2 >> ..\RUN\$CMD
	echo "" >> ..\RUN\$CMD
	If ($lastline -lt 3) { return }
	echo $line3 >> ..\RUN\$CMD
	If ($lastline -lt 4) { return }
	echo $line4 >> ..\RUN\$CMD
	echo "" >> ..\RUN\$CMD
	If ($lastline -lt 5) { return }
	echo $line5 >> ..\RUN\$CMD
	echo "" >> ..\RUN\$CMD

	Remove-Item $ps1 -ErrorAction SilentlyContinue > $null
    }
	
ForEach ($ps1 in $RUNALLps1List) {
	ProcessPSScript $ps1 "RUNALL.CMD" "echo Downloading, verifying, and running $ps1 ..." 5
	}
	
ForEach ($ps1 in $RUNMOSTps1List) {
	ProcessPSScript $ps1 "RUNMOST.CMD" "echo Downloading, verifying, and running $ps1 ..." 5
	}
	
ForEach ($ps1 in $DDOWNLOADps1List) {
	ProcessPSScript $ps1 "DOWNLOAD.CMD" "echo Downloading $ps1 ..." 2
	}

ProcessPSScript "GetRedists.ps1" "GETREDISTS.CMD" "echo Processing..." 5




