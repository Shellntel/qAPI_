# This module is designed to interface with the Qualsy API for ticketing and provide the user with the ability to manage remediation.
# REQUIRES -Version 3.0
#defaults - set these below
#
#$cred = "yourAPI_CREDS"
#$server = "qualysapi.qualys.com"
# be sure to read code for environment specific configurable variables

function Write-Log {

Param ([Parameter(Mandatory=$True)][string]$filePath,
[Parameter(Mandatory=$True)][string]$outPut)

$timeStamp = Get-Date -UFormat "%Y%m%d-%H%M%S"
$user = $env:USERNAME

$outPut = $user + " " + $timeStamp + " " + $outPut
$outPut |Out-File -FilePath $filePath -Append

}

function Get-qAPI {

<#  
.SYNOPSIS  
    This cmdlet establishes the connectionto the Qualys API 
.DESCRIPTION  
    Connects to the Qualys api and handles passing parameters to the correct api endpoint
.NOTES  
    File Name      : qAPI.psm1 
    Author         : johnny_DEP
    Prerequisite   : PowerShell V3
    
.EXAMPLE  
    Get-qAPI -api_endpoint "ticket_list.php" -TicketNumbers "123"
#>


# ticket API parameters

Param ([string]$api_endpoint,
#[ValidateCount(1,1000)]
[string[]]$TicketNumbers,
[string]$SinceTicketNumber,
[string]$UntilTicketNumber,
[string]$TicketAssignee,
#[ValidateSet("0","1")]
[string]$Overdue,
#[ValidateSet("0","1")]
[string]$Invalid,
#[ValidateSet("OPEN","RESOLVED","CLOSED","IGNORED")] 
[string[]]$States,
[string]$ModifiedSinceDateTime,
[string]$UnModifiedSinceDateTime,
[string[]]$IPs,
[string[]]$AssetGroups,
#[ValidateLength(1,100)]
[string]$DNSContains,
#[ValidateLength(1,100)]
[string]$NetbiosContains,
#[ValidateSet("1","2","3","4","5")]
[string[]]$VulnSevereties,
#[ValidateSet("1","2","3","4","5")]
[string[]]$PotVulnSevereties,
#[ValidateCount(1,10)]
[string[]]$QIDs,
#[ValidateLength(1,100)]
[string]$VulnTitleContains,
#[ValidateLength(1,100)]
[string]$VulnDetailsContains,
#[ValidateLength(1,100)]
[string]$VendorRefContains,
[string]$ChangeAssignee,
#[ValidateSet("OPEN","RESOLVED","IGNORED")] 
[string]$ChangeState,
#[ValidateLength(1,2000)]
[string]$AddComment,
#[ValidateSet("0","1")]
[string]$show_vuln_details
)

#defaults

$cred = "yourAPI_CREDS"
$server = "qualysapi.qualys.com"

#build api params
# Set the parameters to be passed to the function if they are specified as script parameters.
### Ticket Selection parameters ###

If ($ticketNumbers -ne $null) { $paramTicketNumbers = "&ticket_numbers="+($ticketNumbers -join ",") }
If ($sinceTicketNumber -ne "") { $paramSinceTicketNumber = "&since_ticket_number="+$sinceTicketNumber }
If ($untilticketNumber -ne "") { $paramUntilticketNumber = "&since_ticket_number="+$untilticketNumber }
If ($overdue -ne "") { $paramOverdue = "&overdue="+$overdue }
If ($invalid -ne "") { $paramInvalid = "&overdue="+$invalid }
If ($ticketAssignee -ne "") { $paramAssignee = "&ticket_assignee="+$ticketAssignee }
If ($states -ne $null) { $paramStates = "&states="+($states -join ",") }
If ($modifiedSinceDateTime -ne "") { $parammodifiedSinceDateTime = "&modified_since_datetime="+$modifiedSinceDateTime }
If ($unmodifiedSinceDateTime -ne "") { $paramUnmodifiedSinceDateTime = "&unmodified_since_datetime="+$unmodifiedSinceDateTime }
If ($ips -ne $null) { $paramIps = "&ips="+($ips -join ",") }
If ($assetGroups -ne $null) { $paramAssetGroups = "&asset_groups="+($assetGroups -join ",") }
If ($dnsContains -ne "") { $paramDnsContains = "&dns_contains="+$dnsContains }
If ($netbiosContains -ne "") { $paramNetbiosContains = "&netbios_contains="+$netbiosContains }
If ($vulnSevereties -ne $null) { $paramVulnSevereties = "&vuln_severities="+($vulnSevereties -join ",") }
If ($potVulnSevereties -ne $null) { $paramPotVulnSevereties = "&potential_vuln_severities="+($potVulnSevereties -join ",") }
If ($qids -ne $null) { $paramQids = "&qids="+($qids -join ",") }
If ($vulnTitleContains -ne "") { $paramVulnTitleContains = "&vuln_title_contains="+$vulnTitleContains }
If ($vulnDetailsContains -ne "") { $paramVulnDetailsContains = "&vuln_details_contains="+$vulnDetailsContains }
If ($vendorRefContains -ne "") { $paramVendorRefContains = "&vendor_ref_contains="+$vendorRefContains }
### Ticket Action parameters ###
If ($changeAssignee -ne "") { $paramChangeAssignee = "&change_assignee="+$changeAssignee }
If ($changeState -ne "") { $paramChangeState = "&change_state="+$changeState }
If ($addComment -ne "") { $paramAddComment = "&add_comment="+$addComment }
### List ticket specific params ###
If ($show_vuln_details -ne "") {$paramshow_vuln_details = "&show_vuln_details="+$show_vuln_details}

$api_params = $api_endpoint + $paramTicketNumbers+$paramSinceTicketNumber+$paramUntilticketNumber+$paramOverdue+$paramInvalid+$parammodifiedSinceDateTime+$paramUnmodifiedSinceDateTime+$paramIps+$paramAssignee+$paramStates+$paramAssetGroups+$paramDnsContains+$paramNetbiosContains+$paramVulnSevereties+$paramPotVulnSevereties+$paramQids+$paramVulnTitleContains+$paramVulnDetailsContains+$paramVendorRefContains+$paramChangeAssignee+$paramChangeState+$paramAddComment +$paramshow_vuln_details


#For Debug show what is being passed - start log
$log_path = "\\somenetworkstorage\Vulnerability Management\Logs\"
$log_file = $timeStamp = Get-Date -UFormat "%Y%m%d"
$log_file += ".log"
$log_path += $log_file

Write-Host "Logging API connections to:" $log_path
Write-Log -filePath $log_path -outPut "--connected to Qualys API--"
$log_out = " passing these params " + $api_params + "`n https://$server/msp/$api_params"
Write-Log -filePath $log_path -outPut $log_out

if ($api_params -ne $null){
	#build web request
	$r = Invoke-WebRequest -URI "https://$server/msp/$api_params"  -Credential $cred
	#return web content
	$r.content
}
	else {
		Write-Log -filePath $log_path -outPut "Parameters cannot be null"
	}
}

function List-qTickets {

<#  
.SYNOPSIS  
    Cmdlet to list current tickets
.DESCRIPTION  
    Makes call to api with specific parameters to list tickets that match the query.  
.NOTES  
    File Name      : qAPI.psm1 
    Author         : johnny_dep
    Prerequisite   : PowerShell V3
    
.SYNTAX 

.EXAMPLE  
    List-qTickets -State "OPEN"
	
#>

Param (
#[ValidateCount(1,1000)]
[string[]]$TicketNumbers,
[string]$SinceTicketNumber,
[string]$UntilTicketNumber,
[string]$TicketAssignee,
#[ValidateSet("0","1")]
[string]$Overdue,
#[ValidateSet("0","1")]
[string]$Invalid,
#[ValidateSet("OPEN","RESOLVED","CLOSED","IGNORED")] 
[string[]]$States,
[string]$ModifiedSinceDateTime,
[string]$UnModifiedSinceDateTime,
[string[]]$IPs,
[string[]]$AssetGroups,
#[ValidateLength(1,100)]
[string]$DNSContains,
#[ValidateLength(1,100)]
[string]$NetbiosContains,
#[ValidateSet("1","2","3","4","5")]
[string[]]$VulnSevereties,
#[ValidateSet("1","2","3","4","5")]
[string[]]$PotVulnSevereties,
#[ValidateCount(1,10)]
[string[]]$QIDs,
#[ValidateLength(1,100)]
[string]$VulnTitleContains,
#[ValidateLength(1,100)]
[string]$VulnDetailsContains,
#[ValidateLength(1,100)]
[string]$VendorRefContains,
#[ValidateSet("0","1")]
[string]$show_vuln_details
)

#setup logging
$log_path = "\\somenetworkstorage\Vulnerability Management\Logs\"
$log_file = $timeStamp = Get-Date -UFormat "%Y%m%d"
$log_file += ".log"
$log_path += $log_file



#list specific api endpoint
$api_endpoint = "ticket_list.php?"

#make web call
Get-qAPI -api_endpoint $api_endpoint -TicketNumbers $TicketNumbers -SinceTicketNumber $SinceTicketNumber -UntilTicketNumber $UntilTicketNumber -TicketAssignee $TicketAssignee -Overdue $Overdue -Invalid $Invalid -States $States  -ModifiedSinceDateTime $ModifiedSinceDateTime -IPs $IPs -AssetGroups $AssetGroups -DNSContains $DNSContains -NetbiosContains $NetbiosContains -VulnSevereties $VulnSevereties -PotVulnSevereties $PotVulnSevereties -QIDs $QIDs -VulnTitleContains $VulnTitleContains -VulnDetailsContains $VulnDetailsContains -VendorRefContains $VendorRefContains  -show_vuln_details $show_vuln_details
}

function Set-qTickets {

<#  
.SYNOPSIS  
    Change state of current ticket that matches critieria.
.DESCRIPTION  
    Invoke this cmdlet with specific parameters to edit the owner/status of a ticket within qualys.
.NOTES  
    File Name      : qAPI.psm1 
    Author         : johnny_dep
    Prerequisite   : PowerShell V3
    
.SYNTAX 

.EXAMPLE  
    Set-qTickets -Overdue "1" -TicketAssignee "user_id" -ChangeState "CLOSED"
#>

Param ([string]$api_endpoint,
#[ValidateCount(1,1000)]
[string[]]$TicketNumbers,
[string]$SinceTicketNumber,
[string]$UntilTicketNumber,
[string]$TicketAssignee,
#[ValidateSet("0","1")]
[string]$Overdue,
#[ValidateSet("0","1")]
[string]$Invalid,
#[ValidateSet("OPEN","RESOLVED","CLOSED","IGNORED")] 
[string[]]$States,
[string]$ModifiedSinceDateTime,
[string]$UnModifiedSinceDateTime,
[string[]]$IPs,
[string[]]$AssetGroups,
#[ValidateLength(1,100)]
[string]$DNSContains,
#[ValidateLength(1,100)]
[string]$NetbiosContains,
#[ValidateSet("1","2","3","4","5")]
[string[]]$VulnSevereties,
#[ValidateSet("1","2","3","4","5")]
[string[]]$PotVulnSevereties,
#[ValidateCount(1,10)]
[string[]]$QIDs,
#[ValidateLength(1,100)]
[string]$VulnTitleContains,
#[ValidateLength(1,100)]
[string]$VulnDetailsContains,
#[ValidateLength(1,100)]
[string]$VendorRefContains,
[string]$ChangeAssignee,
#[ValidateSet("OPEN","RESOLVED","IGNORED")] 
[string]$ChangeState,
#[ValidateLength(1,2000)]
[string]$AddComment,
#[ValidateSet("0","1")]
[string]$show_vuln_details
)

#setup logging
$log_path = "\\somenetworkstorage\Vulnerability Management\Logs\"
$log_file = $timeStamp = Get-Date -UFormat "%Y%m%d"
$log_file += ".log"
$log_path += $log_file

#list specific api endpoint
$api_endpoint = "ticket_edit.php?"

#make web call
Get-qAPI -api_endpoint $api_endpoint -TicketNumbers $TicketNumbers -SinceTicketNumber $SinceTicketNumber -UntilTicketNumber $UntilTicketNumber -TicketAssignee $TicketAssignee -Overdue $Overdue -Invalid $Invalid -States $States  -ModifiedSinceDateTime $ModifiedSinceDateTime -IPs $IPs -AssetGroups $AssetGroups -DNSContains $DNSContains -NetbiosContains $NetbiosContains -VulnSevereties $VulnSevereties -PotVulnSevereties $PotVulnSevereties -QIDs $QIDs -VulnTitleContains $VulnTitleContains -VulnDetailsContains $VulnDetailsContains -VendorRefContains $VendorRefContains -ChangeAssignee $ChangeAssignee -ChangeState $ChangeState -UnModifiedSinceDateTime $UnModifiedSinceDateTime -AddComment $AddComment  -show_vuln_details $show_vuln_details

}

function Delete-qTickets {

<#  
.SYNOPSIS  
    Delets tickets that match critieria.
.DESCRIPTION  
    Connects to Qualys api and deletes tickets that match a given critieria that is passed via parameters.
.NOTES  
    File Name      : qAPI.psm1 
    Author         : johnny_DEP
    Prerequisite   : PowerShell V3
    
.SYNTAX 

.EXAMPLE  
    Delete-qTickets -TicketNumbers "123" 
#>

Param ([string]$api_endpoint,
#[ValidateCount(1,1000)]
[string[]]$TicketNumbers,
[string]$SinceTicketNumber,
[string]$UntilTicketNumber,
[string]$TicketAssignee,
#[ValidateSet("0","1")]
[string]$Overdue,
#[ValidateSet("0","1")]
[string]$Invalid,
#[ValidateSet("OPEN","RESOLVED","CLOSED","IGNORED")] 
[string[]]$States,
[string]$ModifiedSinceDateTime,
[string]$UnModifiedSinceDateTime,
[string[]]$IPs,
[string[]]$AssetGroups,
#[ValidateLength(1,100)]
[string]$DNSContains,
#[ValidateLength(1,100)]
[string]$NetbiosContains,
#[ValidateSet("1","2","3","4","5")]
[string[]]$VulnSevereties,
#[ValidateSet("1","2","3","4","5")]
[string[]]$PotVulnSevereties,
#[ValidateCount(1,10)]
[string[]]$QIDs,
#[ValidateLength(1,100)]
[string]$VulnTitleContains,
#[ValidateLength(1,100)]
[string]$VulnDetailsContains,
#[ValidateLength(1,100)]
[string]$VendorRefContains,
[string]$ChangeAssignee,
#[ValidateSet("OPEN","RESOLVED","IGNORED")] 
[string]$ChangeState,
#[ValidateLength(1,2000)]
[string]$AddComment,
#[ValidateSet("0","1")]
[string]$show_vuln_details
)

#setup logging
$log_path = "\\somenetworkstorage\Vulnerability Management\Logs\"
$log_file = $timeStamp = Get-Date -UFormat "%Y%m%d"
$log_file += ".log"
$log_path += $log_file

#list specific api endpoint
$api_endpoint = "ticket_delete.php?"

#make web call
Get-qAPI -api_endpoint $api_endpoint -TicketNumbers $TicketNumbers -SinceTicketNumber $SinceTicketNumber -UntilTicketNumber $UntilTicketNumber -TicketAssignee $TicketAssignee -Overdue $Overdue -Invalid $Invalid -States $States  -ModifiedSinceDateTime $ModifiedSinceDateTime -IPs $IPs -AssetGroups $AssetGroups -DNSContains $DNSContains -NetbiosContains $NetbiosContains -VulnSevereties $VulnSevereties -PotVulnSevereties $PotVulnSevereties -QIDs $QIDs -VulnTitleContains $VulnTitleContains -VulnDetailsContains $VulnDetailsContains -VendorRefContains $VendorRefContains -ChangeAssignee $ChangeAssignee -ChangeState $ChangeState -UnModifiedSinceDateTime $UnModifiedSinceDateTime -AddComment $AddComment  -show_vuln_details $show_vuln_details

}

function create-qTicket {

<#  
.SYNOPSIS  
    Creates CASD ticket based on Qualys Tickets
.DESCRIPTION  
    Parses tickets automatically created via Qualys and sends an email to the mail eater service from CASD to create an incident for the appropriate area, areas have to be configured and match the CASD DB in order for the ticket creation to work
.NOTES  
    File Name      : qAPI.psm1 
    Author         : johnny_dep
    Prerequisite   : PowerShell V3
    
.SYNTAX  

.EXAMPLE  
    list-qTickets| create-qTicket -dstEmail "derp@vulns.com" -group "Temp" -smtpserver "10.0.0.1"
	
#>


<#

Email format for CASD

%DESCRIPTION=

----------------------------------------------------------------
Vulnerability Description:

----------------------------------------------------------------
Affected Assets:

----------------------------------------------------------------
Suggested Remedation:

----------------------------------------------------------------
Vulnerailty Information is Confidential

Please contact security@temp.com with questions or if more info
rmation is needed.
----------------------------------------------------------------

%FROM_USERID= 'User ID'
%LOG_AGENT= 'Vulnerability Mangement Process'
%CATEGORY= Configure
%GROUP= 'Area reference from User ID'
%IMPACT= 'Calculated from number of vulnerable assets'
%URGENCY= 'Calculated from Severity'

#>

Param ([string]$smtpserver, #server to relay email message
[string]$group,# assigned to group
[Parameter(Mandatory=$false)][string]$dstEmail, # target email address 
[Parameter(Mandatory=$True,ValueFromPipeline=$True)][PSObject]$apiOut # object returned from api call
)

#setup logging
$log_path = "\\someserver\Vulnerability Management\Logs\"
$log_file = $timeStamp = Get-Date -UFormat "%Y%m%d"
$log_file += ".log"
$log_path += $log_file

Write-Host "Logging tickets functions to:" $log_path

#convert psobject to xml
[xml]$xml= $apiOut
#[xml]$xml = Get-Content "C:\windows\temp\tix.xml"

#print total number of tickets
$numTickets = $xml.REMEDIATION_TICKETS.TICKET_LIST.TICKET.NUMBER.count
$log_out = "Total number of Qualys tickets being processed:" + $numTickets 
Write-log -filePath $log_path -outPut $log_out

#get unique QIDs

$QIDs = $xml.REMEDIATION_TICKETS.TICKET_LIST.TICKET.VULNINFO.QID
$QIDs = $QIDs | sort -Unique
$log_out = "Total Unique QIDS(Numerber of CASD tickets to be created):" + $QIDs.count
Write-log -filePath $log_path -outPut $log_out
$ticketsCursor = $QIDs.count

#test dstemail
if ($dstEmail.length -lt 1){
# change this to match your CASD mail eater service account
$dstEmail = "casdhelpdeskd@casd.com"
}

#for each QID process ticket

$interator = 0

foreach ($i in $QIDs)
	
	{$log_out =  "Processing QID:" +$i
	Write-Log -filePath $log_path -outPut $log_out
	#build ticket email body for each QID
	$xPathBase = "/REMEDIATION_TICKETS/TICKET_LIST/TICKET/"
		
	#description
	$xPathQry = $xPathBase + 'VULNINFO/QID[text() = "' + $i + '"]'
	#Write-Host "xpath:" $xPathQry
	
	$cursor = $xml.SelectNodes($xPathQry)
	$description = "%description=`n"
	$tixEmail += "-----------------------------------------------------`n`n"
	$description += $cursor|%{$_.ParentNode.TITLE.InnerText} | sort -Unique
	$tixEmail = $description + "`n"
	$tixEmail += "-----------------------------------------------------`n`n"
	$tixEmail += "Related CVE(s):`n"
	$cves = $cursor|%{$_.ParentNode.CVE_ID_LIST.CVE_ID.InnerText} | sort -Unique
	[string]$cves = $cves
	$cveArray = $cves -split " "
	$cves = $cves -replace " ","`n"
	$tixEmail += $cves + "`n`n"
	
	#affected assets	
	$assetsNodes = $cursor|%{$_.ParentNode.ParentNode.DETECTION.DNSNAME.InnerText} | sort -Unique
	[string]$assets = $assetsNodes
	$assets = $assets -replace " ","`n"
	$tixEmail += "-----------------------------------------------------`n`n"
	$tixEmail += "Affected Assets:`n"
	$tixEmail += $assets + "`n`n"
	
	
	#remediation 
	$tixEmail += "-----------------------------------------------------`n`n"
	$tixEmail += "Suggested Remediation:`n"
	$tixEmail += "These link(s) provide the information that is available for how this vulnerabilty can be remediated.`n"
	foreach ($z in $cveArray)
		{	$fixUrl = "http://cve.mitre.org/cgi-bin/cvename.cgi?name=" + $z 
			$tixEmail += $fixUrl + "`n"		
		}
	
	$tixEmail += "`nIf the above links do not provide clear remediation steps please contact security for assistance`n"
	$tixEmail += "-----------------------------------------------------`n`n"
	$tixEmail += "In an effort to streamline our vulnerability management process, remediation activities will now be`n" 
	$tixEmail += "communicated via a CASD ticket.  Please work thru the suggested remediation within the ticket or comments.`n"
	$tixEmail += "If you cannot fix the vulnerability please provide a business justification and transfer the ticket back `n"
	$tixEmail += "to the security group to begin the variance process.`n`n"
	$tixEmail += "Vulnerability Information is Confidential`n"

	#$tixEmail += "%FROM_USERID=" + "`n"# 'User ID looked up from Teamtrack'
	#$tixEmail += "%LOG_AGENT=" + "`n"#'Vulnerability Mangement Process'
	$tixEmail += "%CATEGORY=Other.Temp`n" #assign to whoever you want - configurable
		if($group -eq ""){ 
			$tixEmail += "%GROUP=Temp" + "`n" #'Area reference from User ID' just whoever for testing - configurable
		} else {$tixEmail += "%GROUP=Security"+ $group + "`n" #'Area reference from User ID' just security for testing
		}
		if($assetsNodes.Count -gt 1){
			$tixEmail += "%IMPACT=5-One Person" + "`n" #'Calculated from number of vulnerable assets' 5 if 1, 4 if > 1
		} else {$tixEmail += "%IMPACT=5-One Person" + "`n" #'Calculated from number of vulnerable assets' 5 if 1, 4 if > 1
		}
		
	$severity = $cursor|%{$_.ParentNode.SEVERITY} | sort -Unique
		if($severity -eq "5"){
			$tixEmail += "%URGENCY=1-Primary Tool - Completely down" + "`n" #'Calculated from Severity' 3 if 4, 1 if 5
		} else {$tixEmail += "%URGENCY=3-Primary Tool - Partial functionality" + "`n" #'Calculated from Severity' 3 if 4, 1 if 5
		}
	$log_out = "EMAIL for Ticket "+$i+" Created:`n"
	Write-log -filePath $log_path -outPut $log_out
	#Write-Host $tixEmail
	
	Send-MailMessage -Body $tixEmail -SmtpServer $smtpserver -From "VulnMGMT@security.com" -To $dstEmail -Subject "Vuln Ticket:$i"
	$log_out = "Ticket for QID "+$i+" created, with priority:" + $severity
	Write-log -filePath $log_path -outPut $log_out
	}
	
# uncomment if you want to use assignedment to manage which ones you processed already
#$cleanup = Set-qTickets -TicketAssignee "unprocessed" -ChangeAssignee "processed"
$log_out = "Set "+$numTickets+" to assignee _enter_yourself_here_ in Qualys"
Write-log -filePath $log_path -outPut $log_out
}



Export-ModuleMember Write-Log
Export-ModuleMember create-qTicket
Export-ModuleMember Get-qAPI
Export-ModuleMember List-qTickets
Export-ModuleMember Set-qTickets
Export-ModuleMember Delete-qTickets