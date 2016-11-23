### opsview-add-host.ps1
# Based on knowledge from http://damirkasper.blogspot.de/2011/04/opsview-and-adding-hosts-through-rest.html

### URLs for authentication and config
$urlauth = "https://opsviewserver.domain.de/rest/login"
$urlconfig = "https://opsviewserver.domain.de/rest/config/host"

### REST-API user
$user="autoadduser"
$pass="password"

### JSON formated body string with credentials
$creds = '{"username":"' + $user + '","password":"' + $pass + '"}'

### Get auth token
$bytes1 = [System.Text.Encoding]::ASCII.GetBytes($creds)
$web1 = [System.Net.WebRequest]::Create($urlauth)
$web1.Method = "POST"
$web1.ContentLength = $bytes1.Length
$web1.ContentType = "application/json"
$web1.ServicePoint.Expect100Continue = $false
$stream1 = $web1.GetRequestStream()
$stream1.Write($bytes1,0,$bytes1.Length)
$stream1.Close()

$reader1 = New-Object System.IO.Streamreader -ArgumentList $web1.GetResponse().GetResponseStream()
$token1 = $reader1.ReadToEnd()
$reader1.Close()

### Parse Token for follwoing sessions
$token1=$token1.Replace("{`"token`":`"", "")
$token1=$token1.Replace("`"}", "")

### System variables
$hostname = $env:COMPUTERNAME
$hostip = ((ipconfig | findstr [0-9].\.)[0]).Split()[-1]
$osversion = (Get-WmiObject Win32_OperatingSystem).Caption
Write-Host $osversion

### JSON format hostdata like hosttemplate, servicechecks etc.
if ($osversion -like "*2008*") {
    $hostdata = '{"object":{"hosttemplates":[{"ref":"/rest/config/hosttemplate/1","name":"OS - Windows Server 2008 WMI - Base"}],"flap_detection_enabled":"1","keywords":[],"check_period":{"ref":"/rest/config/timeperiod/1","name":"24x7"},"hostattributes":[{"arg1":null,"arg4":null,"value":"wincreds","arg3":null,"name":"WINCREDENTIALS","id":"1389"}],"notification_period":{"ref":"/rest/config/timeperiod/1","name":"24x7"},"notification_options":"u,d,r","tidy_ifdescr_level":"0","name":"' + $hostname + '","hostgroup":{"ref":"/rest/config/hostgroup/85","name":"AutoAdd"},"monitored_by":{"ref":"/rest/config/monitoringserver/1","name":"Master Monitoring Server"},"alias":"","parents":[],"uncommitted":"0","icon":{"name":"LOGO - Windows","path":"/images/logos/windows_small.png"},"retry_check_interval":"10","ip":"' + $hostip + '","servicechecks":[],"check_command":{"ref":"/rest/config/hostcheckcommand/15","name":"ping"},"check_attempts":"3","check_interval":"300","notification_interval":"3600","other_addresses":""}}'
}
elseif ($osversion -like "*2012*") {
    $hostdata = '{"object":{"hosttemplates":[{"ref":"/rest/config/hosttemplate/95","name":"OS - Windows Server 2012 WMI - Base"}],"flap_detection_enabled":"1","keywords":[],"check_period":{"ref":"/rest/config/timeperiod/1","name":"24x7"},"hostattributes":[{"arg1":null,"arg4":null,"value":"wincreds","arg3":null,"name":"WINCREDENTIALS","id":"1389"}],"notification_period":{"ref":"/rest/config/timeperiod/1","name":"24x7"},"notification_options":"u,d,r","tidy_ifdescr_level":"0","name":"' + $hostname + '","hostgroup":{"ref":"/rest/config/hostgroup/85","name":"AutoAdd"},"monitored_by":{"ref":"/rest/config/monitoringserver/1","name":"Master Monitoring Server"},"alias":"","parents":[],"uncommitted":"0","icon":{"name":"LOGO - Windows","path":"/images/logos/windows_small.png"},"retry_check_interval":"10","ip":"' + $hostip + '","servicechecks":[],"check_command":{"ref":"/rest/config/hostcheckcommand/15","name":"ping"},"check_attempts":"3","check_interval":"300","notification_interval":"3600","other_addresses":""}}'
}
else {
    Write-Host "Unsupported OS! - Now exiting"
    exit 1
}

### Use token and add host to Opsview
$bytes2 = [System.Text.Encoding]::ASCII.GetBytes($hostdata)
$web2 = [System.Net.WebRequest]::Create($urlconfig)
$web2.Method = "PUT"
$web2.ContentLength = $bytes2.Length
$web2.ContentType = "application/json"
$web2.ServicePoint.Expect100Continue = $false
$web2.Headers.Add("X-Opsview-Username","$user")
$web2.Headers.Add("X-Opsview-Token",$token1);
$stream2 = $web2.GetRequestStream()
$stream2.Write($bytes2,0,$bytes2.Length)
$stream2.Close()

$reader2 = New-Object System.IO.Streamreader -ArgumentList $web2.GetResponse().GetResponseStream()
$output2 = $reader2.ReadToEnd()
$reader2.Close()

Write-Host $output2