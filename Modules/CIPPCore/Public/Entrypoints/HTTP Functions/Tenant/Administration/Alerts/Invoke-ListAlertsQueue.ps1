using namespace System.Net

Function Invoke-ListAlertsQueue {
    <#
    .FUNCTIONALITY
    Entrypoint
    #>
    [CmdletBinding()]
    param($Request, $TriggerMetadata)

    $APIName = $TriggerMetadata.FunctionName
    Write-LogMessage -user $request.headers.'x-ms-client-principal' -API $APINAME -message 'Accessed this API' -Sev 'Debug'


    # Write to the Azure Functions log stream.
    Write-Host 'PowerShell HTTP trigger function processed a request.'
    $WebhookTable = Get-CIPPTable -TableName 'WebhookRules'
    $WebhookRules = Get-CIPPAzDataTableEntity @WebhookTable   

    $ScheduledTasks = Get-CIPPTable -TableName 'ScheduledTasks'
    $ScheduledTasks = Get-CIPPAzDataTableEntity @ScheduledTasks | Where-Object { $_.hidden -eq $true }

    $AllTasksArrayList = [system.collections.generic.list[object]]::new()

    foreach ($Task in $WebhookRules) {
        $Conditions = $Task.Conditions | ConvertFrom-Json -ErrorAction SilentlyContinue
        $TranslatedConditions = $Conditions | ForEach-Object { "When $($_.Property.label) is $($_.Operator.label) to $($_.input.value)" }
        $TranslatedActions = ($Task.Actions | ConvertFrom-Json -ErrorAction SilentlyContinue).label -join ','
        $TaskEntry = [PSCustomObject]@{
            Tenants    = $Task.Tenants | ConvertFrom-Json -ErrorAction SilentlyContinue
            Conditions = $TranslatedConditions
            Actions    = $TranslatedActions 
            LogType    = $Task.type
            EventType  = 'Audit log Alert'
        }
        $AllTasksArrayList.Add($TaskEntry)
    } 

    foreach ($Task in $ScheduledTasks) {
        $TaskEntry = [PSCustomObject]@{
            Tenants    = @(@{
                    fullValue = @{ defaultDomainName = $Task.Tenant }
                })
            Conditions = $Task.Name
            Actions    = $Task.PostExecution
            LogType    = 'Scripted'
            EventType  = 'Scheduled Task'
        }
        $AllTasksArrayList.Add($TaskEntry)
    }
    # Associate values to output bindings by calling 'Push-OutputBinding'.
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::OK
            Body       = @($AllTasksArrayList)
        })

}
