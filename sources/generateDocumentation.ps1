# Region Parameters
[CmdLetBinding()]
Param (
    [Parameter(Mandatory = $true)]
    [String]$templateLocation,

    [Parameter(Mandatory = $false)]
    [String]$documentationDestinationPath,

    [Parameter(Mandatory = $false)]
    [Array]$filter   
)

#region Output Preference
$DebugPreference = 'SilentlyContinue'
$VerbosePreference = "Continue"

# Checking the filter and retrieving the template information
if (!$filter) {
    # Getting all templates available in the catalog (without a filter)
    $allTemplates = Get-ChildItem $templateLocation -Recurse -File -Exclude $filter | Select-Object Name, Directory
}
else {
    # Getting all templates available in the catalog (with a filter)
    $allTemplates = Get-ChildItem $templateLocation -Recurse -File -Exclude $filter | Select-Object Name, Directory

}

# Checking if the location specified in var documentationDestinationPath exists
if($documentationDestinationPath -notlike $null){
    $testResult = Test-Path -Path $documentationDestinationPath
    if($testResult -like "False"){
        $null = New-Item -Path $documentationDestinationPath -ItemType Directory
    }
}

foreach ($template in $allTemplates) {
    #Getting template specific vars
    $templateContent = Get-Content -Path (($template | Select-Object -ExpandProperty Directory | Select-Object -expandProperty FullName) + "\" + ($template | Select-Object -ExpandProperty Name)) | ConvertFrom-Json
    $templateparameters = $templateContent.parameters.psobject.properties | Where-Object MemberType -eq NoteProperty | Select-Object -ExpandProperty Name
    $resourceType = $templateContent.resources | Select-Object -First 1 | Select-Object -ExpandProperty Type | Split-Path -Leaf
    $resourceProvider = $templateContent.resources | Select-Object -First 1 | Select-Object -ExpandProperty Type | Split-Path -Parent
    $templateDocName = ($template | Select-Object -ExpandProperty Name).Split('.json')[0]
    if(!$documentationDestinationPath){
        $templateDocLocation = (($template | Select-Object -ExpandProperty Directory | Select-Object -expandProperty FullName) + "\" + $templateDocName + ".documentation.md")

    }else {
        $templateDocLocation = ($documentationDestinationPath + "\" + $templateDocName + ".documentation.md")
    }
    $documentationTemplateLocation = ($PSScriptRoot + "\" + "template.documentation.md")

    #Check if template is accessible
    $templateDocContent = Get-Content -Path $documentationTemplateLocation -ErrorAction SilentlyContinue
    if (!$templateDocContent) {
        throw "Documentation template is not accessible at the following path: $documentationTemplateLocation"
    }
    
    #Initializing markdown tables
    $TemplateParameterTable = @()
    $TemplateParameterTable += "| Name | Description | Type | Example | Required |"
    $TemplateParameterTable += "`r`n| --- | --- | --- | --- | --- |"

    $TemplateOutputTable = @()
    $TemplateOutputTable += "| Name | Description | Type | Example |"
    $TemplateOutputTable += "`r`n| --- | --- | --- | --- |"

    #Check existing template documentaiton
    $currentDoc = Get-Content -Path $templateDocLocation -ErrorAction SilentlyContinue
    if (!$currentDoc) {
        Write-Host "Template documentation for $resourceType not found. Start creation." -ForegroundColor Green
    }
    else {
        Write-Host "Template documentation for $resourcetype found. Start updating." -ForegroundColor Green
    }

    #Copy documentation file
    Copy-Item -Path $documentationTemplateLocation -Destination $templateDocLocation

    #Setting resource type and resource provider value in documentation file
    (Get-Content -Path $templateDocLocation) -replace "#Resource#", ("``" + $resourceType + "``") | Set-Content -Path $templateDocLocation
    (Get-Content -Path $templateDocLocation) -replace "#ResourceProvider#", ("``" + $resourceProvider + "``") | Set-Content -Path $templateDocLocation
    (Get-Content -Path $templateDocLocation) -replace "#ResourceProviderUrl#", $resourceProvider | Set-Content -Path $templateDocLocation

    #Check for parameters and write to documentation
    if (!$templateparameters) {
        Write-Host "No template parameters found for $resourceType" -ForegroundColor Yellow
        (Get-Content -Path $templateDocLocation) -replace "#inputTabePlaceHolder#", "No template parameters found." | Set-Content -Path $templateDocLocation

    }
    else {
        foreach ($templateparameter in $templateparameters) {
            $name = $templateparameter
            $description = $templateContent.parameters.$name.metadata.description
            $type = $templateContent.parameters.$name.Type
            $example = $templateContent.parameters.$name.metadata.example
            $required = $templatecontent.parameters.$name.metadata.required
            $TemplateParameterTable += "`r`n| ``$name`` | $description | $type | $example | $required |"
        }
        (Get-Content -Path $templateDocLocation) -replace "#inputTabePlaceHolder#", $TemplateParameterTable | Set-Content -Path $templateDocLocation
    }
    

    #Check for outputs and write to documentation
    if (($templateContent.outputs) -like $null) {
        Write-Host "No outputs found for $resourcetype" -ForegroundColor Yellow
        (Get-Content -Path $templateDocLocation) -replace "#outputTablePlaceHolder#", "No template outputs found." | Set-Content -path $templateDocLocation

    }
    else {
        $templateOutputs = $templateContent.outputs.psobject.properties | Where-Object MemberType -eq NoteProperty | Select-Object -ExpandProperty Name
        foreach ($templateOutput in $templateOutputs) {
            $name = $templateOutput
            $TemplateOutputTable += "`r`n| ``$name`` | --- | --- | --- |"
            (Get-Content -Path $templateDocLocation) -replace "#outputTablePlaceHolder#", $TemplateOutputTable | Set-Content -path $templateDocLocation
        }
    }
}