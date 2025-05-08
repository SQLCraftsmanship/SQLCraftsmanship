
<# #################################################################################################
# Date: 11/05/2023
# Author: LLI
# Function Create the basic structure for a Python project
# What to do:
        Create folder [backend]
            Inside [backend] Create [classes] Sub-folder
            Inside [backend] Create [main.py] file
        Create folder [frontend]
            Inside [frontend] Create [assets] folder
                Inside [assets] Create [gifts] Sub-folder
                Inside [assets] Create [images] Sub-folder
            Inside [frontend] Create [src] folder
                Inside [src] Create [screens] Sub-folder and separate in folders [main] and [login]
                Inside [src] Create [test] Sub-folder
        Create folder [db]
            Inside [db] Create [scripts] and [test] Sub-folders
        Create folder [libs]
        Create folder [docs]
        Create README file
        Create LICENSE file
# #################################################################################################>

# Step 1: Function to get Server Name and Virtual Environment Path from Prompt.
$ServerName = Read-Host "Enter Server Name"
$VirtualEnvPath = Read-Host "Enter the path for the virtual environment"

# Step 2: Function to check if Python and Pip are installed
function CheckPythonAndPipInstalled {
    param (
        [string]$ServerName
    )

    $pythonInstalled = Test-Connection -ComputerName $ServerName -Quiet -Count 1 -ErrorAction SilentlyContinue
    # $pipInstalled = Test-Path "\\$ServerName\c$\Python\Scripts\pip.exe"
    $pipInstalled = Test-Path "C:\Users\lliberatori\AppData\Local\Programs\Python\Python312\Lib\site-packages\pip"

    if ($pythonInstalled -and $pipInstalled) {
        return $true
        Write-Host "### Python and PIP are installed on '[$parServerName]' ###" -ForegroundColor Green
    } else {
        return $false
        Write-Host "### Python and PIP are not installed on '[$parServerName]' ###" -ForegroundColor red
    }
}

# Step 3: Function to create and activate the virtual environment
function CreateAndActivateVirtualEnv {
    param (
        [string]$VirtualEnvPath
    )

    # if (-not (Test-Path $VirtualEnvPath)) {
    #    Write-Host "### Virtual environment path does not exist. Aborting.### " -ForegroundColor red
    #    return
    #}

    # Create the virtual environment
    python -m venv $VirtualEnvPath

    # Activate the virtual environment
    & "$VirtualEnvPath\Scripts\Activate"
}

# Step 4: Function to create the folder and file structure inside the virtual environment
function CreateFolderAndFileStructure {
    param (
        [string]$VirtualEnvPath
    )

    $FoldersToCreate = @("frontend\classes", "frontend\main", "backend\assets\gifts", "backend\assets\images", "backend\src\screens", "backend\src\test", "db", "db\scripts", "db\test", "db\connection", "libs", "docs")

    foreach ($folder in $FoldersToCreate) {
        $fullPath = Join-Path $VirtualEnvPath $folder
        New-Item -Path $fullPath -ItemType Directory
    }

    # Create README.txt and LICENSE.txt
    $ReadMePath = Join-Path $VirtualEnvPath "README.txt"
    $LicensePath = Join-Path $VirtualEnvPath "LICENSE.txt"
    New-Item -Path $ReadMePath -ItemType File
    New-Item -Path $LicensePath -ItemType File
}

# Step 5: Check if Python and Pip are installed
if (CheckPythonAndPipInstalled -ServerName $ServerName) {
    # Python and Pip are installed, proceed to create the virtual environment
    CreateAndActivateVirtualEnv -VirtualEnvPath $VirtualEnvPath

    # Create the folder and file structure inside the virtual environment
    CreateFolderAndFileStructure -VirtualEnvPath $VirtualEnvPath
} else {
    Write-Host "### Python and/or Pip are not installed on the specified server. Aborting. ###" -ForegroundColor red
}
