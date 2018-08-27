# Copyright (c) 2018 Microsoft
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

<#
 .SYNOPSIS
    Deploys a template to Azure

 .DESCRIPTION
    Deploys an Azure Resource Manager template

 .PARAMETER subscriptionId
    The subscription id where the template will be deployed.

 .PARAMETER resourceGroupName
    The resource group where the template will be deployed. Can be the name of an existing or a new resource group.

 .PARAMETER resourceGroupLocation
    Optional, a resource group location. If specified, will try to create a new resource group in this location. If not specified, assumes resource group is existing.

 .PARAMETER deploymentName
    The deployment name.

 .PARAMETER templateFilePath
    Optional, path to the template file. Defaults to template.json.

 .PARAMETER parametersFilePath
    Optional, path to the parameters file. Defaults to parameters.json. If file is not found, will prompt for parameter values based on template.
#>

param(
 [Parameter(Mandatory=$True)]
 [string]
 $subscriptionId,

 [Parameter(Mandatory=$True)]
 [string]
 $resourceGroupName,

 [string]
 $resourceGroupLocation,

 [Parameter(Mandatory=$True)]
 [string]
 $deploymentName,
 
 [string]
 $environmentName = "AzureCloud",

 [string]
 $templateFilePath = "template.json",

 [string]
 $parametersFilePath = "parameters.json"
)

<#
.SYNOPSIS
    Registers RPs
#>
Function RegisterRP {
    Param(
        [string]$ResourceProviderNamespace
    )

    Write-Host "Registering resource provider '$ResourceProviderNamespace'";
    Register-AzureRmResourceProvider -ProviderNamespace $ResourceProviderNamespace;
}

#******************************************************************************
# Script body
# Execution begins here
#******************************************************************************
$ErrorActionPreference = "Stop"

# Sign in to the Azure US Government Environment
Write-Host "************************"
Write-Host "*    Login to Azure    *"
Write-Host "************************"

$Environment = "AzureUSGovernment"
Write-Host "Logging in...";
$login = Login-AzureRmAccount -Environment $Environment;
$azureEnv = $login.Context.Environment.Name
$azureAcct = $login.Context.Account.Id

Write-Host "Logged into '$azureEnv' with '$azureAcct'"

Write-Host ""
Write-Host "************************"
Write-Host "*  Azure Subscription  *"
Write-Host "************************"
# Select Subscription specified in parameter
Write-Host "Selecting subscription '$subscriptionId'";
$subscription = Select-AzureRmSubscription -SubscriptionID $subscriptionId;

Write-Host ""
Write-Host "************************"
Write-Host "*  Resource Providers  *"
Write-Host "************************"

# Register Resource Providers
$resourceProviders = @("microsoft.logic","microsoft.storage","microsoft.web");
if($resourceProviders.length) {
    Write-Host "Registering resource providers"
    foreach($resourceProvider in $resourceProviders) {
        $_ = RegisterRP($resourceProvider);
    }
}

Write-Host ""
Write-Host "************************"
Write-Host "* Azure Resource Group *"
Write-Host "************************"

#Create or check for existing resource group
$resourceGroup = Get-AzureRmResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
if(!$resourceGroup)
{
    if(!$resourceGroupLocation) {
        Write-Host "Resource group '$resourceGroupName' does not exist. To create a new resource group, please enter a location.";
        $resourceGroupLocation = Read-Host "resourceGroupLocation";
    }
    Write-Host "Creating resource group '$resourceGroupName' in location '$resourceGroupLocation'";
    $resourceGroup = New-AzureRmResourceGroup -Name $resourceGroupName -Location $resourceGroupLocation
}
else{
    Write-Host "Using existing resource group '$resourceGroupName'";
}

Write-Host ""
Write-Host "************************"
Write-Host "*      Deployment      *"
Write-Host "************************"

# Start the deployment
Write-Host "Starting deployment...";
if(Test-Path $parametersFilePath) {
    $deployment = New-AzureRmResourceGroupDeployment -Name $deploymentName -ResourceGroupName $resourceGroupName -TemplateFile $templateFilePath -TemplateParameterFile $parametersFilePath;
} else {
    $deployment = New-AzureRmResourceGroupDeployment -Name $deploymentName -ResourceGroupName $resourceGroupName -TemplateFile $templateFilePath;
}
Write-Host "Deployment Succeeded"

Write-Host ""
Write-Host "************************"
Write-Host "*  Storage Container   *"
Write-Host "************************"

# Determine storage account name and container name from deployment
$storageAccountName = $deployment.Outputs.storageAccountName.Value
$containerName = $deployment.Outputs.containerName.Value

# Create the required storage container if it doesn't exist
$_ = Set-AzureRmCurrentStorageAccount -Name $storageAccountName -ResourceGroupName $resourceGroupName
$container = Get-AzureStorageContainer -Name $containerName -ErrorAction SilentlyContinue

if(!$container)
{
    Write-Host "Creating Storage Account Container '$containerName' in Storage Account '$storageAccountName'"
    New-AzureStorageContainer -Name $containerName -Permission Off
} else {
    Write-Host "Container '$containerName' in '$storageAccountName' already exists"
}
Write-Host ""
Write-Host ""
