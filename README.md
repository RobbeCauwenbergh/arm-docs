# arm-docs

&nbsp; 

## About arm-docs
---
arm-docs is fundamentally an automatic way to generate documentation for your ARM templates. The documentation is generated in markdown for the ease of use and wide supportability.
The idea for this project came when I was working at a customer that was building out an Azure "catalog". This catalog was made up of standardized ARM templates to be then reused by other internal customers for deployments.
Those internal customers/people were sometimes new to Azure and thus ARM templates could be a little bit confusing. To support and help them getting up and running with those standardized templates I created this automation which tells them what kind of inputs and outputs the templates has.

> All information that is in the output comes from within the templates. To get the best outcome make sure that all input and output parameters are documented by using the "metadata" property. Within the metadata property their should be a "description" and "required" property.

Check the sample-output folder for an example.

&nbsp;
## What's up with arm-docs
---
At the current stage, arm-docs is still pretty limited but a lot of new ideas are making their way to the project.

What is currently working/supported:
- Using the initial version of the script locally or in build/release pipelines.
- Using filters in the script
- Using a different path to store the documentation files
- Using ARM templates that only has 1 resource defined

What am I currently working on:
- Supportability for ARM templates with multiple resources/nested resources
- Supportability for ARM templates with linked templates
- Supportability to expose this automation via a web API

&nbsp;
## Examples
---
## Running the script locally
At the moment the `generateDocumentation.ps1` script has 3 parameters:

&nbsp;

| Name | Description | Type | Example | Required |
| --- | --- | --- | --- | ---|
| templateLocation | Path to the root folder which contains the ARM templates | string | "c:\temp\ARMTemplates\" | Yes |
| filter | May contain filter(s) to exclude files from the templateLocation | Array | "*.md", "*.ps1" | No |
| documentationDestinationPath | By default the documentation files are placed together with templates, by using this you can change that | string | "c:\temp\ARMDocumentation\" | No |

