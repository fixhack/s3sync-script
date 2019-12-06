# This script synchronizes files from an AWS S3 bucket with a local directory
# After synchronizing, the files are then moved from that 
# S3 bucket folder to another folder in the same bucket

# IMPORTANT: Set the script with a cron property to be executed every 5 minutes

# Directory paths
$awscliDir="c:\\temp\awscli"
$logsDir="c:\\temp\awscli\logs"

# The path to synchorize the folders to (Change to your preferred path)
$path = "c:\\temp\awscli\approved"
# The url of the approved s3 bucket
$s3approved = "s3://csg-cert-zfia-analytics-apdocumentsc789d3eb-npfkuzs07135/invoices/approved"
# The url of the synchronized s3 bucket
$s3synchronized = "s3://csg-cert-zfia-analytics-apdocumentsc789d3eb-npfkuzs07135/invoices/synchronized/"
# Log file (Change to your preferred path)
$log = "c:\\temp\awscli\logs\synchS3.log"

# Check if awscli directory exists and create it if it doesn't
if (!(Test-Path $awscliDir)) {
   md $awscliDir
}

# Check if logs directory exists and create it if it doesn't
if (!(Test-Path $logsDir)) {
   md $logsDir
}

# Check if approved directory exists and create it if it doesn't
if (!(Test-Path $path)) {
   md $path
}

# Test if log file exists. If not, create it
if (!(Test-Path $log)) {
   New-Item -ItemType "file" -Path $log
}

# Save current date and time into a variable
$date = Get-Date -Format "MM/dd/yyyy HH:mm"

# Synchronize(copy) files in bucket to files in local directory
$synchS3 = aws s3 sync $s3approved $path

# Get the file names of the copied objects. If the string is empty, skips synchronization for current pass.
if (-not ([string]::IsNullOrEmpty($synchS3))) {
			
	$synchronized = $synchS3 | Select-String -Pattern 's3:\/\/.[^\s]*' | foreach {$_.Matches.Groups[0].Value}
			
	# Use file names of the synchronized objects to move from approved to synchronized folder within AWS
	$fileCount = 0
	ForEach ($line in $($synchronized -split "`r`n")) {
		if ($line.StartsWith("s3://")) {
			aws s3 mv $line $s3synchronized
			$fileCount++
		}
	}
	# Write performed actions to log file
	Add-Content $log "`n$fileCount file/s synchronized and moved on $date"
} else {
	# Write performed actions to log file
	Add-Content $log "`nNo files synchronized on $date"
}