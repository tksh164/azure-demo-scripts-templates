# Change the Windows language options and regional settings using the DSC extension

This template demonstrates that change the Windows language options and region settings using the DSC extension.

You can use non-English language options and region settings since first login even if use the Azure Marketplace image because the DSC extension changes the Windows language options and region settings for the default user account and system account. It's meaning the new user's language and welcome screen language are changed.

Simple PowerShell script version is [here](https://github.com/tksh164/change-windows-language-regional-settings).

## Deploy to Azure

| Deployment UI language | Deploy to Azure |
| ---- | ---- |
| English | [![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#view/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2Ftksh164%2Fazure-demo-scripts-templates%2Fmaster%2Farm-templates%2Fwin-lang-region-config%2Ftemplate.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2Ftksh164%2Fazure-demo-scripts-templates%2Fmaster%2Farm-templates%2Fwin-lang-region-config%2Fuiform.json) |
| Japanese (日本語) | [![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#view/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2Ftksh164%2Fazure-demo-scripts-templates%2Fmaster%2Farm-templates%2Fwin-lang-region-config%2Ftemplate.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2Ftksh164%2Fazure-demo-scripts-templates%2Fmaster%2Farm-templates%2Fwin-lang-region-config%2Fuiform-jajp.json) |

## Notes

- Currently supported operating systems are Windows Server 2022 and Windows Server 2019.
- Currently supported languages are Japanese (ja-JP), English (en-US), French (fr-FR) and Korean (ko-KR).
- The deploy.ps1 script needs [Az module](https://www.powershellgallery.com/packages/Az/).
