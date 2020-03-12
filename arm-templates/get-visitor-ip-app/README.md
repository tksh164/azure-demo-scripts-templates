# Access source IP response app

This template deploys the access source information respond app as a function app.

Response example:

```
--- $Request.Headers ---
Client IP: 203.0.113.10:53483
x-forwarded-for: 203.0.113.10:53483
user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.132 Safari/537.36

--- $TriggerMetadata.Request.Headers ---
Client IP: 203.0.113.10:53483
x-forwarded-for: 203.0.113.10:53483
user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.132 Safari/537.36

--- $TriggerMetadata.$request.Headers ---
Client IP: 203.0.113.10:53483
x-forwarded-for: 203.0.113.10:53483
user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.132 Safari/537.36
```

## Template overview

### Deployments

All the below names are the default value.

- Resource group: `lab-myip`
- Function App (App Service): `myip-####-funcapp`
- App Service Plan: `myip-####-plan`
- Storage account: `myip####`
    - A storage account for the Azure Web Jobs storage of the function app.

### Non-deployments

- App's contents.
    - App's contents are located under the `app-contents` folder.

## Notes

- The deploy.ps1 script needs [Az module](https://www.powershellgallery.com/packages/Az/).
