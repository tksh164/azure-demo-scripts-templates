# Logic app to collect Azure updates 

## Template overview

This template deploys two Logic apps to collect [Azure updates](https://azure.microsoft.com/updates/) into Excel workbook on Excel online (OneDrive/OneDrive Business).

## Deployment

- azupdates-rss-initial-logic (Logic app)
- azupdates-rss-append-logic (Logic app)
- rss (API connection)
- excelonlinebusiness (API connection)

## Usage

1. Place the **azure-update-rss-logicapp.xlsx** file to any location on OneDrive.
2. Deploy this template to your Azure subscription.
3. Authorize API connection to Excel Online in the **excelonlinebusiness** API connection resource.
4. Restore the Logic app's configuration in the **azupdates-rss-initial-logic** Logic app.
   - Restore configuration in the **Add a row into a table** action. Location, Document Library, File, Table, add new parameters.
5. Enable to the **azupdates-rss-initial-logic** Logic app then run trigger.
   - When the Logic app finishes running, the specified Excel workbook is filled with Azure updates.
6. Disable to the **azupdates-rss-initial-logic** Logic app.
7. Restore the Logic app's configuration in the **azupdates-rss-append-logic** Logic app.
   - Restore configuration in the **Add a row into a table** action. Location, Document Library, File, Table, add new parameters.
8. Enable to the **azupdates-rss-append-logic** Logic app.
   - When updated the Azure updates, the Logic app retrieves and appends it into the specified Excel workbook.
