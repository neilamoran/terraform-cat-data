If ((Get-Module).Name -notcontains "Az.LogicApp") {
    Import-Module Az.LogicApp
}

try {
    $logapp = Get-AzLogicApp -Name ${logic_app} -ResourceGroupName ${resource_group}
} catch {
    throw "Could not get logic app"
}

If ($logapp) {

    # Get definition file
    $json = (Get-Content ./logicapps/${definition_file}) | ConvertFrom-Json

    # Split into definition and parameters and reserialise (depth of 20 is arbitrary - works for this example, but may need to be greater, depending on your json)
    $definition = $json.definition | ConvertTo-Json -Depth 20

    # Set parameter values
    $parameters = [PSCustomObject]@{
        "`$connections" = [PSCustomObject]@{
            "value" = [PSCustomObject]@{
                "connectionId" = "${connectionId}"
                "id" = "${id}"
                "connectionName" = "${connectionName}"
            }
        }
        "datafactoryId" = [PSCustomObject]@{
            "value" = "${datafactoryId}"  
        } 
    } | ConvertTo-Json

    $parameters

    # Update definition
    Set-AzLogicApp -Definition $definition -Parameters $parameters -Name ${logic_app} -ResourceGroupName ${resource_group} -Force
}
