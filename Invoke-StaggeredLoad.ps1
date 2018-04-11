[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True)]
    [string] $LocalPath,

    [Parameter(Mandatory=$True)]
    [string] $Filter,

    [Parameter(Mandatory=$True)]
    [string] $StorageAccountResourceGroup,

    [Parameter(Mandatory=$True)]
    [string] $StorageAccountName,

    [Parameter(Mandatory=$True)]
    [string] $BlobContainerName,

    [Parameter(Mandatory=$True)]
    [string] $DataFactoryResourceGroup,

    [Parameter(Mandatory=$True)]
    [string] $DataFactoryName,

    [Parameter(Mandatory=$True)]
    [string] $PipelineName,

    [int16] $FilesPerPipelineRun = 15
)

$Files = Get-ChildItem -Path $LocalPath -Filter $Filter -File
$NumberOfFiles = ($Files | Measure-Object).Count
Write-Output "Loading local files from: $LocalPath of type: $Filter. Total number of files to load: $NumberOfFiles."

Set-AzureRmCurrentStorageAccount -ResourceGroupName $StorageAccountResourceGroup -Name  $StorageAccountName
Write-Output "Files being copied to staging blob storage: $StorageAccountName\$BlobContainerName"

$Counter = 0
$Files | ForEach-Object {
    Set-AzureStorageBlobContent -Container $BlobContainerName -File $_.FullName -Blob $_.Name
    $Counter = $Counter + 1
    Write-Output "Copied: $_, Counter = $Counter"
    If (($Counter % $FilesPerPipelineRun -eq 0) -or ($Counter -ge $NumberOfFiles)) {
        Write-Output "Invoking Data Factory: $DataFactoryName with pipeline: $PipelineName at file number: $Counter"
        $PipelineRunId = Invoke-AzureRmDataFactoryV2Pipeline -ResourceGroupName $DataFactoryResourceGroup -DataFactoryName $DataFactoryName -PipelineName $PipelineName
        $PipelineRunInfo = Get-AzureRmDataFactoryV2PipelineRun -ResourceGroupName $DataFactoryResourceGroup -DataFactoryName $DataFactoryName -PipelineRunId $PipelineRunId
        While (-not (($PipelineRunInfo.Status -eq "Succeeded") -or ($PipelineRunInfo.Status -eq "Failed"))) {
            Write-Output "Waiting ... Pipeline status: $($PipelineRunInfo.Status)"
            Start-Sleep -Seconds 10
            $PipelineRunInfo = Get-AzureRmDataFactoryV2PipelineRun -ResourceGroupName $DataFactoryResourceGroup -DataFactoryName $DataFactoryName -PipelineRunId $PipelineRunId
        }
        If ($PipelineRunInfo.Status -eq "Succeeded") {
            Write-Output "Pipline run complete"
            #Start-Sleep -Seconds 30  # Let the DB cool down
        } Else {
            Write-Output "ERROR: Pipeline run failed. Exiting script."
            $PipelineRunInfo
            Exit
        }
    }
}

Write-Output "Script completed, $Counter files loaded"

