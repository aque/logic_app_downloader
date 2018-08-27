<!---
 Copyright (c) 2018 Microsoft
 
 This software is released under the MIT License.
 https://opensource.org/licenses/MIT
-->

# Logic App Downloader
This will deploy 3 resources to your Azure environment:
1. An Azure Storage Account (V2)
    * Also creates a blob container in the new storage account.
1. A Microsoft connector to connect Azure Storage and the Logic App
1. A Logic App that pulls from a specified HTTP endpoint on a set interval.

To deploy this to your subscription, you can specify the parameters in the parameters.json file. In the example parameters file, Bing.com will be downloaded by Logic App every 5 minutes.

You can execute this script from PowerShell to deploy.
```powershell
.\deploy.ps1 -subscriptionId "a*******-****-****-****-*********bcd" -resourceGroupName "bing_downloader_test" -resourceGroupLocation "eastus2" -deploymentName "Bing_Data_Downloader" -parametersFilePath ".\parameters.json"
```

You can also run in an Azure Government Cloud by passing the `-environmentName` parameter.
```powershell
.\deploy.ps1 -subscriptionId "a*******-****-****-****-*********bcd" -resourceGroupName "bing_downloader_test" -environmentName "AzureUSGovernment" -resourceGroupLocation "usgovtexas" -deploymentName "Bing_Data_Downloader" -parametersFilePath ".\parameters.json"
```


 _Note: As of August 27th, 2018, Logic Apps are currently only available in US Gov Texas region_