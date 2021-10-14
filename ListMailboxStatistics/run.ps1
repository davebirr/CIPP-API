using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

# Interact with query parameters or the body of the request.
$TenantFilter = $Request.Query.TenantFilter
$GraphRequest = New-GraphGetRequest -uri "https://graph.microsoft.com/beta/reports/getMailboxUsageDetail(period='D7')" -tenantid $TenantFilter | convertfrom-csv | select-object @{ Name = 'UPN'; Expression = { $_.'User Principal Name' } },
@{ Name = 'displayName'; Expression = { $_.'Display Name' } },
@{ Name = 'LastActive'; Expression = { $_.'Last Activity Date' } },
@{ Name = 'UsedGB'; Expression = { [math]::round($_.'Storage Used (Byte)' / 1GB, 0) } },
@{ Name = 'ItemCount'; Expression = { $_.'Item Count' } },
@{ Name = 'HasArchive'; Expression = { $_.'Has Archive' } }

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body       = @($GraphRequest)
    })
