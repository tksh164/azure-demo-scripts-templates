# AAHC Emulated On-premises Environment

This template deploys the emulated an on-premises environment for AAHC. You can easily deploy through the following **Deploy to Azure** button.

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Ftksh164%2Fazure-demo-scripts-templates%2Fmaster%2Farm-templates%2Faahc-emulated-on-premises-env%2Ftemplate.json)

## Parameters

| Name | Description |
| ---- | ---- |
| Number Of Attendees | Number of attendees. |
| Deploy Emulated On Premises Environment | To deploy the emulated on-premises environment, select <strong>true</strong>. If you do not deploy the emulated on-premises environment, select <strong>false</strong>. |
| Deploy Jumpbox Vm | To deploy the jumpbox VMs for attendees, select <strong>true</strong>. If you do not deploy the jumpbox VMs, select <strong>false</strong> and input the dummy parameters to the following. |
| Username | The administrator username for the jumpbox VMs. |
| Password | The administrator password for the jumpbox VMs. |
| Vm Os Image | The operating system image for the jumpbox VMs. |
| Vm Size | The virtual machine size of the jumpbox VMs. [Learn more about Virtual Machine sizes](http://go.microsoft.com/fwlink/?LinkId=2079859) |
| Vm Os Disk Type | The OS disk storage type of the jumpbox VMs. [Learn more about disk types](http://go.microsoft.com/fwlink/?LinkId=2077396) |
| Daily Autoshutdown Time | The time of day the auto-shutdown of the jumpbox VM will occur. |
| Autoshutdown Time Zone | The time zone ID for auto-shutdown time. |
