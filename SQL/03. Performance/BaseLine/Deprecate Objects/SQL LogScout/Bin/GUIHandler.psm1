
#=======================================Handle the GUI..
[Collections.Generic.List[GenericModel]]$global:list = New-Object Collections.Generic.List[GenericModel]
[Collections.Generic.List[GenericModel]]$global:XeventsList_general = New-Object Collections.Generic.List[GenericModel]
[Collections.Generic.List[GenericModel]]$global:XeventsList_AlwaysOn = New-Object Collections.Generic.List[GenericModel]
[Collections.Generic.List[GenericModel]]$global:XeventsList_core = New-Object Collections.Generic.List[GenericModel]
[Collections.Generic.List[GenericModel]]$global:XeventsList_detailed = New-Object Collections.Generic.List[GenericModel]
[Collections.Generic.List[GenericModel]]$global:XeventsList_servicebroker_dbmail = New-Object Collections.Generic.List[GenericModel]
[Collections.Generic.List[ServiceState]]$global:List_service_name_status = New-Object Collections.Generic.List[ServiceState]

[String[]]$global:varXevents = "xevent_AlwaysOn_Data_Movement", "xevent_core", "xevent_detailed" , "xevent_general", "xevent_servicebroker_dbmail"
class GenericModel {
    [String]$Caption
    [String]$Value
    [bool]$State
}

class ServiceState {
    [String]$Name
    [String]$Status
}

function InitializeGUIComponent() {
    Write-LogDebug "inside" $MyInvocation.MyCommand

    try {
        Add-Type -AssemblyName PresentationCore, PresentationFramework, WindowsBase
        [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
        [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
        
        #Fetch current directory
        $CurrentDirectory = Convert-Path -Path "."
        
        #Build files name, with fully qualified path.
        $ConfigPath = $CurrentDirectory + '\Config.xml'
        $XAMLPath = $CurrentDirectory + '\SQLLogScoutView.xaml'
        
        $Launch_XAML = [XML](Get-Content $XAMLPath) 
        $xamlReader_Launch = New-Object System.Xml.XmlNodeReader $Launch_XAML
        $Global:Window = [Windows.Markup.XamlReader]::Load($xamlReader_Launch)
        $Global:txtPresentDirectory = $Global:Window.FindName("txtPresentDirectory") 
        $Global:okButton = $Global:Window.FindName("okButton")

        $Global:XmlDataProviderName = $Global:Window.FindName("XmlDataProviderName")
    

        #create CheckBoxes globals.
        $Global:basicPerfCheckBox = $Global:Window.FindName("basicPerfCheckBox")
        $Global:generalPerfCheckBox = $Global:Window.FindName("generalPerfCheckBox")
        $Global:LightPerfCheckBox = $Global:Window.FindName("LightPerfCheckBox")
        $Global:DetailedPerfCheckBox = $Global:Window.FindName("DetailedPerfCheckBox")
        $Global:replicationPerfCheckBox = $Global:Window.FindName("replicationPerfCheckBox")
        $Global:alwaysOnPerfCheckBox = $Global:Window.FindName("alwaysOnPerfCheckBox")
        $Global:networkTraceCheckBox = $Global:Window.FindName("networkTraceCheckBox")
        $Global:memoryCheckBox = $Global:Window.FindName("memoryCheckBox")
        $Global:dumpMemoryCheckBox = $Global:Window.FindName("dumpMemoryCheckBox")
        $Global:WPRCheckBox = $Global:Window.FindName("WPRCheckBox")
        $Global:SetupCheckBox = $Global:Window.FindName("SetupCheckBox")
        $Global:BackupRestoreCheckBox = $Global:Window.FindName("BackupRestoreCheckBox")
        $Global:IOCheckBox = $Global:Window.FindName("IOCheckBox")
        $Global:ServiceBrokerDbMailCheckBox = $Global:Window.FindName("ServiceBrokerDbMailCheckBox")
        $Global:NeverEndingQueryCheckBox = $Global:window.FindName("NeverEndingQueryCheckBox")
        $Global:NoBasicCheckBox = $Global:Window.FindName("NoBasicCheckBox")
        $Global:overrideExistingCheckBox = $Global:Window.FindName("overrideExistingCheckBox")
        
        $Global:ComboBoxInstanceName = $Global:Window.FindName("ComboBoxInstanceName")
        $Global:ButtonPresentDirectory = $Global:Window.FindName("ButtonPresentDirectory")
        
        $Global:listExtraSkills = $Global:Window.FindName("listExtraSkills")
        $Global:listXevnets = $Global:Window.FindName("listXevnets")
        $Global:list_xevent_detailed = $Global:Window.FindName("list_xevent_detailed")
        $Global:list_xevent_core = $Global:Window.FindName("list_xevent_core")
        $Global:list_xevent_AlwaysOn = $Global:Window.FindName("list_xevent_AlwaysOn")
        $Global:list_xevent_servicebroker_dbmail = $Global:Window.FindName("list_xevent_servicebroker_dbmail")

        $Global:TVI_xevent_general = $Global:Window.FindName("TVI_xevent_general")
        $Global:TVI_xevent_detailed = $Global:Window.FindName("TVI_xevent_detailed")
        $Global:TVI_xevent_core = $Global:Window.FindName("TVI_xevent_core")
        $Global:TVI_xevent_AlwaysOn = $Global:Window.FindName("TVI_xevent_AlwaysOn")
        $Global:TVI_xevent_servicebroker_dbmail = $Global:Window.FindName("TVI_xevent_servicebroker_dbmail")
        
        $Global:xeventcore_CheckBox = $Global:Window.FindName("xeventcore_CheckBox")
        $Global:XeventAlwaysOn_CheckBox = $Global:Window.FindName("XeventAlwaysOn_CheckBox")
        $Global:XeventGeneral_CheckBox = $Global:Window.FindName("XeventGeneral_CheckBox")
        $Global:XeventDetailed_CheckBox = $Global:Window.FindName("XeventDetailed_CheckBox")
        $Global:XeventServiceBrokerDbMail_CheckBox = $Global:Window.FindName("XeventServiceBrokerDbMail_CheckBox")


        #set the output folder to be parent of folder where execution files reside
        $Global:txtPresentDirectory.Text = (Get-Item $CurrentDirectory).Parent.FullName
        #Read current config.
        $Global:XmlDataProviderName.Source = $ConfigPath
        
        #Setting the item source for various lists.
        $Global:listExtraSkills.ItemsSource = $Global:list      
        $Global:listXevnets.ItemsSource = $Global:XeventsList_general
        $Global:list_xevent_detailed.ItemsSource = $Global:XeventsList_detailed
        $Global:list_xevent_core.ItemsSource = $Global:XeventsList_core
        $Global:list_xevent_AlwaysOn.ItemsSource = $Global:XeventsList_AlwaysOn
        $Global:list_xevent_servicebroker_dbmail.ItemsSource = $Global:XeventsList_servicebroker_dbmail
        
        RegisterEvents
        Set-PresentDirectory

        Set-OverrideExistingCheckBoxVisibility $Global:txtPresentDirectory.Text
        $Global:txtPresentDirectory.Add_TextChanged({
                Set-OverrideExistingCheckBoxVisibility $Global:txtPresentDirectory.Text
            })
        $Global:Window.Title = $Global:Window.Title + $global:app_version
        $global:gui_Result = $Global:Window.ShowDialog()

    }
    catch {
        HandleCatchBlock -function_name $($MyInvocation.MyCommand) -err_rec $PSItem
    }
}
function Set-OverrideExistingCheckBoxVisibility([String]$path) {
    $path = $path + "\output"
    if (Test-Path $path) {
        $Global:overrideExistingCheckBox.Visibility = "visible"
    }
    else {
        $Global:overrideExistingCheckBox.Visibility = "hidden"
        $Global:overrideExistingCheckBox.IsChecked = $true
    }
}
function RegisterEvents() {
    $Global:ButtonPresentDirectory.Add_Click({ ButtonPresentDirectory_EventHandler })
    $Global:okButton.Add_Click({ $Global:Window.DialogResult = $true })
    $Global:WPRCheckBox.Add_Click({ DisableAll $Global:WPRCheckBox.IsChecked })
    $Global:Window.Add_Loaded({ Window_Loaded_EventHandler })  
    $Global:DetailedPerfCheckBox.Add_Click({ DetailedPerfCheckBox_Click_EventHandler $Global:DetailedPerfCheckBox.IsChecked })
    $Global:generalPerfCheckBox.Add_Click({ generalPerfCheckBox_Click_EventHandler $Global:generalPerfCheckBox.IsChecked })
    $Global:LightPerfCheckBox.Add_Click({ LightPerfCheckBox_Click_EventHandler $Global:LightPerfCheckBox.IsChecked })
    $Global:alwaysOnPerfCheckBox.Add_Click({ alwaysOnPerfCheckBox_Click_EventHandler $Global:alwaysOnPerfCheckBox.IsChecked })
    $Global:ServiceBrokerDbMailCheckBox.Add_Click({ ServiceBrokerDbMailCheckBox_Click_EventHandler $Global:ServiceBrokerDbMailCheckBox.IsChecked })

    #perfmon counters
    $Global:memoryCheckBox.Add_Click({ Manage_PerfmonCounters $Global:memoryCheckBox.IsChecked })
    $Global:BackupRestoreCheckBox.Add_Click({ Manage_PerfmonCounters $Global:BackupRestoreCheckBox.IsChecked })
    $Global:IOCheckBox.Add_Click({ Manage_PerfmonCounters $Global:IOCheckBox.IsChecked })
    $Global:basicPerfCheckBox.Add_Click({ Manage_PerfmonCounters $Global:basicPerfCheckBox.IsChecked })
    $Global:NoBasicCheckBox.Add_Click({ Manage_PerfmonCounters $Global:NoBasicCheckBox.IsChecked })

    #xevents
    $Global:xeventcore_CheckBox.Add_Click({ HandleCeventcore_CheckBoxClick $Global:xeventcore_CheckBox.IsChecked })
    $Global:XeventAlwaysOn_CheckBox.Add_Click({ AlwaysOn_CheckBoxClick $Global:XeventAlwaysOn_CheckBox.IsChecked })
    $Global:XeventGeneral_CheckBox.Add_Click({ XeventGeneral_CheckBoxClick $Global:XeventGeneral_CheckBox.IsChecked })
    $Global:XeventDetailed_CheckBox.Add_Click({ XeventDetailed_CheckBoxClick $Global:XeventDetailed_CheckBox.IsChecked })
    $Global:NeverEndingQueryCheckBox.Add_Click({ Manage_PerfmonCounters $Global:NeverEndingQueryCheckBox.IsChecked })

}
function HandleCeventcore_CheckBoxClick([bool] $state) {
    

        foreach ($item in $Global:XeventsList_core) {
            [GenericModel] $item = $item
            
            if ($item.Caption -like "*existing_connection*" ) {
                #This should remain always seleted because core xevents is needed to create the main event
                $item.State = $true
            } else {
                $item.State = $state
            }
        }
        $Global:list_xevent_core.ItemsSource = $null
        $Global:list_xevent_core.ItemsSource = $Global:XeventsList_core
        #Core xevent collection is needed because it is the one that creates xevent_SQLLogScout session
        $Global:xeventcore_CheckBox.IsChecked = $Global:TVI_xevent_core.IsEnabled  #$state
}
function AlwaysOn_CheckBoxClick([bool] $state) {
    

        foreach ($item in $Global:XeventsList_AlwaysOn) {
            $item.State = $state
        }
        $Global:XeventAlwaysOn_CheckBox.IsChecked = $state
        $Global:list_xevent_AlwaysOn.ItemsSource = $null
        $Global:list_xevent_AlwaysOn.ItemsSource = $Global:XeventsList_AlwaysOn
    
}

function XeventGeneral_CheckBoxClick([bool] $state) {
    

        foreach ($item in $Global:XeventsList_general) {
            $item.State = $state
        }
        $Global:listXevnets.ItemsSource = $null
        $Global:listXevnets.ItemsSource = $Global:XeventsList_general
        $Global:XeventGeneral_CheckBox.IsChecked = $state

    
}

function XeventDetailed_CheckBoxClick([bool] $state) {
    

        foreach ($item in $Global:XeventsList_detailed) {
            $item.State = $state
        }
        $Global:XeventDetailed_CheckBox.IsChecked = $state
        $Global:list_xevent_detailed.ItemsSource = $null
        $Global:list_xevent_detailed.ItemsSource = $Global:XeventsList_detailed
    
}

function XeventServiceBrokerDbMail_CheckBoxClick([bool] $state) {
    

    foreach ($item in $Global:XeventsList_servicebroker_dbmail) {
        $item.State = $state
    }

    $Global:XeventServiceBrokerDbMail_CheckBox.IsChecked = $state
    $Global:list_xevent_servicebroker_dbmail.ItemsSource = $null
    $Global:list_xevent_servicebroker_dbmail.ItemsSource = $Global:XeventsList_servicebroker_dbmail
}

function ButtonPresentDirectory_EventHandler() {
    $objForm = New-Object System.Windows.Forms.FolderBrowserDialog
    $Show = $objForm.ShowDialog()
    if ($Show -eq "OK") {
        $Global:txtPresentDirectory.Text = $objForm.SelectedPath;
    }
}

function Window_Loaded_EventHandler() {

    BuildServiceNameStatusModel
    BuildPermonModel
    BuildXEventsModel
    BuildXEventsModel_core
    BuildXEventsModel_detailed
    BuildXEventsModel_AlwaysOn
    BuildXEventsModel_servicebroker_dbmail


    Manage_PerfmonCounters($false)
    HandleCeventcore_CheckBoxClick($false)
    AlwaysOn_CheckBoxClick($false)
    XeventGeneral_CheckBoxClick($false)
    XeventDetailed_CheckBoxClick($false)
    XeventServiceBrokerDbMail_CheckBoxClick($false)

}
function Manage_PerfmonCounters([bool] $state) {
    if ($Global:DetailedPerfCheckBox.IsChecked -or
        $Global:generalPerfCheckBox.IsChecked -or
        $Global:LightPerfCheckBox.IsChecked -or
        $Global:alwaysOnPerfCheckBox.IsChecked -or
        $Global:memoryCheckBox.IsChecked -or
        $Global:BackupRestoreCheckBox.IsChecked -or
        $Global:IOCheckBox.IsChecked -or
        $Global:basicPerfCheckBox.IsChecked -or
        $Global:NeverEndingQueryCheckBox.IsChecked -or
        $Global:ServiceBrokerDbMailCheckBox.IsChecked -or
        $Global:basicPerfCheckBox.IsChecked) {
        $Global:listExtraSkills.IsEnabled = $true
        foreach ($item in $Global:list) {
            $item.State = $true
        }
        $Global:listExtraSkills.ItemsSource = $null
        $Global:listExtraSkills.ItemsSource = $Global:list
    }
    else {
        $Global:listExtraSkills.IsEnabled = $false

        foreach ($item in $Global:list) {
            $item.State = $false
        }
        $Global:listExtraSkills.ItemsSource = $null
        $Global:listExtraSkills.ItemsSource = $Global:list
    }
}
function DetailedPerfCheckBox_Click_EventHandler([bool] $state) {
    #$Global:basicPerfCheckBox.IsChecked = $false
    #$Global:basicPerfCheckBox.IsEnabled = !$state
    
    $Global:generalPerfCheckBox.IsChecked = $false
    $Global:LightPerfCheckBox.IsChecked = $false
    
    $Global:generalPerfCheckBox.IsEnabled = !$state
    $Global:LightPerfCheckBox.IsEnabled = !$state

    $Global:TVI_xevent_general.IsEnabled = $false
    $Global:TVI_xevent_detailed.IsEnabled = $state
    $Global:TVI_xevent_core.IsEnabled = $state
    HandleCeventcore_CheckBoxClick($state)
    XeventGeneral_CheckBoxClick($false)
    XeventDetailed_CheckBoxClick($state)
    Manage_PerfmonCounters($state)
}

function LightPerfCheckBox_Click_EventHandler([bool] $state) {
    $Global:TVI_xevent_general.IsEnabled = $false
    $Global:TVI_xevent_detailed.IsEnabled = $false
    $Global:TVI_xevent_core.IsEnabled = $false
    XeventGeneral_CheckBoxClick($false)
    XeventDetailed_CheckBoxClick($false)
    HandleCeventcore_CheckBoxClick($false)
    Manage_PerfmonCounters($state)
}

function generalPerfCheckBox_Click_EventHandler([bool] $state) {
    $Global:LightPerfCheckBox.IsChecked = $false
    $Global:LightPerfCheckBox.IsEnabled = !$state
    $Global:TVI_xevent_general.IsEnabled = $state
    $Global:TVI_xevent_general.IsEnabled = $state
    $Global:TVI_xevent_detailed.IsEnabled = $false
    $Global:TVI_xevent_core.IsEnabled = $state
    XeventDetailed_CheckBoxClick($false)
    XeventGeneral_CheckBoxClick($state)
    HandleCeventcore_CheckBoxClick($state)
    Manage_PerfmonCounters(!$state)
    
    
}

function alwaysOnPerfCheckBox_Click_EventHandler([bool] $state) {
    $Global:TVI_xevent_AlwaysOn.IsEnabled = $state 
    $Global:TVI_xevent_core.IsEnabled = $state
    HandleCeventcore_CheckBoxClick($state)
    AlwaysOn_CheckBoxClick($state)
    Manage_PerfmonCounters($state)
    if(!$state)
    {
       if($Global:generalPerfCheckBox.IsChecked)
        {
          generalPerfCheckBox_Click_EventHandler $Global:generalPerfCheckBox.IsChecked
        }
           if($Global:DetailedPerfCheckBox.IsChecked)
        {
               DetailedPerfCheckBox_Click_EventHandler $Global:DetailedPerfCheckBox.IsChecked
        }
    }
}

function ServiceBrokerDbMailCheckBox_Click_EventHandler([bool] $state) {

    $Global:TVI_xevent_core.IsEnabled = $state
    $Global:TVI_xevent_servicebroker_dbmail.IsEnabled = $state

    XeventServiceBrokerDbMail_CheckBoxClick($state)
    HandleCeventcore_CheckBoxClick($state)
    Manage_PerfmonCounters($state)

}


function Set-Mode() {

    try {

        # if Scenario, ServerName, CustomOutputPath and DeleteExistingOrCreateNew parameters are not null, no need to offer GUI
        if (($true -ne [String]::IsNullOrWhiteSpace($global:custom_user_directory)) `
                -and ($true -ne [String]::IsNullOrWhiteSpace($global:gDeleteExistingOrCreateNew)) `
                -and ($true -ne [String]::IsNullOrWhiteSpace($global:gServerName)) `
                -and ($true -ne [String]::IsNullOrWhiteSpace($global:gScenario)) 
        ) { 
            $global:gui_mode = $false; 
            return 
        }

        Write-LogDebug "inside" $MyInvocation.MyCommand
       
        $userlogfolder = Read-Host "Would you like to use GUI mode ?> (Y/N)" -CustomLogMessage "Prompt GUI mode Input:"
        $HelpMessage = "Please enter a valid input (Y or N)"

        $ValidInput = "Y", "N"
        $AllInput = @()
        $AllInput += , $ValidInput
        $AllInput += , $userlogfolder
        $AllInput += , $HelpMessage

        $YNselected = validateUserInput($AllInput)
            

        if ($YNselected -eq "Y") {
            $global:gui_mode = $true;
        }


    }
    catch {
        HandleCatchBlock -function_name $($MyInvocation.MyCommand) -err_rec $PSItem
        exit
    }

}

function EnableScenarioFromGUI {
    #Note: this required big time optimization is just for testing purpose.
    if ($Global:basicPerfCheckBox.IsChecked) {
        $global:gScenario += "Basic+"
    }
    if ($Global:generalPerfCheckBox.IsChecked) {
        $global:gScenario += "GeneralPerf+"
    }
    if ($Global:DetailedPerfCheckBox.IsChecked) {
        $global:gScenario += "DetailedPerf+"
    }
    if ($Global:LightPerfCheckBox.IsChecked) {
        $global:gScenario += "LightPerf+"
    }
    if ($Global:replicationPerfCheckBox.IsChecked) {
        $global:gScenario += "Replication+"
    }
    if ($Global:alwaysOnPerfCheckBox.IsChecked) {
        $global:gScenario += "AlwaysOn+"
    }
    if ($Global:networkTraceCheckBox.IsChecked) {
        $global:gScenario += "NetworkTrace+"
    }
    if ($Global:memoryCheckBox.IsChecked) {
        $global:gScenario += "Memory+"
    }
    if ($Global:dumpMemoryCheckBox.IsChecked) {
        $global:gScenario += "DumpMemory+"
    }
    if ($Global:WPRCheckBox.IsChecked) {
        $global:gScenario += "WPR+"
    }
    if ($Global:SetupCheckBox.IsChecked) {
        $global:gScenario += "Setup+"
    }
    if ($Global:BackupRestoreCheckBox.IsChecked) {
        $global:gScenario += "BackupRestore+"
    }
    if ($Global:IOCheckBox.IsChecked) { 
        $global:gScenario += "IO+"
    }
    if ($Global:NeverEndingQueryCheckBox.IsChecked) {
        $global:gScenario += "NeverEndingQuery+"
    }
    if ($Global:ServiceBrokerDbMailCheckBox.IsChecked) { 
        $global:gScenario += "ServiceBrokerDbMail+"
    }
    if ($Global:NoBasicCheckBox.IsChecked) { 
        $global:gScenario += "NoBasic+"
    }
}

function BuildPermonModel() {
    try {
        Write-LogDebug "inside -BuildPermonModel method"   
        #Read LogmanConfig and fill the UI model. 
        foreach ($line in Get-Content .\LogmanConfig.txt) {
            $PerfmonModelobj = New-Object GenericModel
            $PerfmonModelobj.Value = $line
            $PerfmonModelobj.Caption = $line.split('\')[1]
            $PerfmonModelobj.State = $false
            $Global:list.Add($PerfmonModelobj)
        }
    }
    catch {
        HandleCatchBlock -function_name
        exit
    }

}

function DisableAll([bool] $state) {
    #$Global:basicPerfCheckBox.IsChecked = $false
    # $Global:basicPerfCheckBox.IsEnabled = !$state

    $Global:generalPerfCheckBox.IsChecked = $false
    $Global:DetailedPerfCheckBox.IsChecked = $false
    $Global:LightPerfCheckBox.IsChecked = $false
    $Global:replicationPerfCheckBox.IsChecked = $false
    $Global:alwaysOnPerfCheckBox.IsChecked = $false
    $Global:networkTraceCheckBox.IsChecked = $false
    $Global:memoryCheckBox.IsChecked = $false
    $Global:dumpMemoryCheckBox.IsChecked = $false
    $Global:SetupCheckBox.IsChecked = $false
    $Global:BackupRestoreCheckBox.IsChecked = $false
    $Global:IOCheckBox.IsChecked = $false
    $Global:NeverEndingQueryCheckBox.IsChecked = $false
    $Global:ServiceBrokerDbMailCheckBox.IsChecked = $false
    $Global:generalPerfCheckBox.IsEnabled = !$state
    $Global:DetailedPerfCheckBox.IsEnabled = !$state
    $Global:LightPerfCheckBox.IsEnabled = !$state
    $Global:replicationPerfCheckBox.IsEnabled = !$state
    $Global:alwaysOnPerfCheckBox.IsEnabled = !$state
    $Global:networkTraceCheckBox.IsEnabled = !$state
    $Global:memoryCheckBox.IsEnabled = !$state
    $Global:dumpMemoryCheckBox.IsEnabled = !$state
    $Global:SetupCheckBox.IsEnabled = !$state
    $Global:BackupRestoreCheckBox.IsEnabled = !$state
    $Global:IOCheckBox.IsEnabled = !$state
    $Global:NeverEndingQueryCheckBox.IsEnabled = !$state
    $Global:ServiceBrokerDbMailCheckBox.IsEnabled = !$state
}

function GenerateXeventFileFromGUI {
    Write-LogDebug "inside" $MyInvocation.MyCommand  
    try {
        CreateFile -mylist $Global:XeventsList_general -fileName "xevent_general.sql"
        MakeSureCreateBeforeAlterEvent -mylist $Global:XeventsList_core -pattern "EVENT SESSION [xevent_SQLLogScout] ON SERVER  ADD EVENT"
        CreateFile -mylist $Global:XeventsList_core -fileName 'xevent_core.sql'
        CreateFile -mylist $Global:XeventsList_detailed -fileName 'xevent_detailed.sql'

        CreateFile -mylist $Global:XeventsList_servicebroker_dbmail -fileName 'xevent_servicebroker_dbmail.sql'

        MakeSureCreateBeforeAlterEvent -mylist $Global:XeventsList_AlwaysOn -pattern " EVENT SESSION [SQLLogScout_AlwaysOn_Data_Movement] ON SERVER"
        CreateFile -mylist $Global:XeventsList_AlwaysOn -fileName 'xevent_AlwaysOn_Data_Movement.sql'
    }
    catch {
        HandleCatchBlock -function_name $($MyInvocation.MyCommand) -err_rec $PSItem  
    }
    
}

function MakeSureCreateBeforeAlterEvent($myList, [String]$pattern) {
    $flag = $true
    $patternToBeReplaced = "ALTER " + $pattern
    $patternToBeReplacedWith = "CREATE " + $pattern
    foreach ($item in $myList) {
        if ($item.State -eq $true) { 
            if ($flag -and $item.Value.Contains($pattern)) {
                $item.Value = $item.Value.Replace($patternToBeReplaced, $patternToBeReplacedWith)
                $flag = $false
            }
        }
    }
}


function CreateFile($myList, [string]$fileName) {
    Write-LogDebug "inside" $MyInvocation.MyCommand  
    try {
        $internal_path = $global:internal_output_folder
        $destinationFile = $internal_path + $fileName
        foreach ($item in $myList) {
            if ($item.State -eq $true) { 
                Add-Content $destinationFile $item.Value
            }
        }
        Add-Content $destinationFile "GO"    
    }
    catch {
        HandleCatchBlock -function_name $($MyInvocation.MyCommand) -err_rec $PSItem  
    }
}
function BuildXEventsModel() {
    try {
        Write-LogDebug "inside" $MyInvocation.MyCommand  
        Write-LogDebug "BuildXEventsModel...."
        $xevent_string = New-Object -TypeName System.Text.StringBuilder
        $GenericModelobj = New-Object GenericModel
        foreach ($element in Get-Content .\xevent_general.sql) {
            if ($element -eq "GO") { 
                $GenericModelobj.Value = $xevent_string
                $GenericModelobj.State = $true
                $Global:XeventsList_general.Add($GenericModelobj)
                $GenericModelobj = New-Object GenericModel
                $xevent_string = New-Object -TypeName System.Text.StringBuilder
                [void]$xevent_string.Append("GO `r`n")
            }
            else {
                [void]$xevent_string.Append($element)
                [void]$xevent_string.Append("`r`n")
                
                #$GenericModelobj.Value = $line
                if ($element.contains("[xevent_SQLLogScout]")) {
                    $temp = $element.split('(')[0].split('.')
                    if ($temp.count -eq 2) {
                        $GenericModelobj.Caption = $temp[1]
                    }

                }
            }
        }
    }
    catch {
        HandleCatchBlock -function_name $($MyInvocation.MyCommand) -err_rec $PSItem  
        exit
    }
}

function BuildXEventsModel_core() {
    try {
        Write-LogDebug "inside" $MyInvocation.MyCommand  
        $xevent_string = New-Object -TypeName System.Text.StringBuilder
        $GenericModelobj = New-Object GenericModel
        foreach ($element in Get-Content .\xevent_core.sql) {
            if ($element -eq "GO") { 
                $GenericModelobj.Value = $xevent_string
                $GenericModelobj.State = $true
                $Global:XeventsList_core.Add($GenericModelobj)
                 
                $GenericModelobj = New-Object GenericModel
                $xevent_string = New-Object -TypeName System.Text.StringBuilder
                [void]$xevent_string.Append("GO `r`n")
            }
            else {
                [void]$xevent_string.Append($element)
                [void]$xevent_string.Append("`r`n")
                
                #$GenericModelobj.Value = $line
                if ($element.contains("[xevent_SQLLogScout]")) {
                    $temp = $element.split('(')[0].split('.')
                    if ($temp.count -eq 2) {
                        $GenericModelobj.Caption = $temp[1]
                    }

                }
            }
        }
    }
    catch {
        HandleCatchBlock -function_name $($MyInvocation.MyCommand) -err_rec $PSItem  
        exit
    }

}

function BuildXEventsModel_detailed() {
    try {
        Write-LogDebug "inside" $MyInvocation.MyCommand  
        $xevent_string = New-Object -TypeName System.Text.StringBuilder
        $GenericModelobj = New-Object GenericModel
        foreach ($element in Get-Content .\xevent_detailed.sql) {
            if ($element -eq "GO") { 
                $GenericModelobj.Value = $xevent_string
                $GenericModelobj.State = $true
                $Global:XeventsList_detailed.Add($GenericModelobj)
                 
                $GenericModelobj = New-Object GenericModel
                $xevent_string = New-Object -TypeName System.Text.StringBuilder
                [void]$xevent_string.Append("GO `r`n")
            }
            else {
                [void]$xevent_string.Append($element)
                [void]$xevent_string.Append("`r`n")
                
                #$GenericModelobj.Value = $line
                if ($element.contains("[xevent_SQLLogScout]")) {
                    $temp = $element.split('(')[0].split('.')
                    if ($temp.count -eq 2) {
                        $GenericModelobj.Caption = $temp[1]
                    }

                }
            }
        }
    }
    catch {
        HandleCatchBlock -function_name $($MyInvocation.MyCommand) -err_rec $PSItem  
        exit
    }

}

function BuildXEventsModel_AlwaysOn() {
    try {
        Write-LogDebug "inside" $MyInvocation.MyCommand  
        $xevent_string = New-Object -TypeName System.Text.StringBuilder
        $GenericModelobj = New-Object GenericModel
        foreach ($element in Get-Content .\xevent_AlwaysOn_Data_Movement.sql) {
            if ($element -eq "GO") { 
                $GenericModelobj.Value = $xevent_string
                $GenericModelobj.State = $true
                $Global:XeventsList_AlwaysOn.Add($GenericModelobj)
                 
                $GenericModelobj = New-Object GenericModel
                $xevent_string = New-Object -TypeName System.Text.StringBuilder
                [void]$xevent_string.Append("GO `r`n")
            }
            else {
                [void]$xevent_string.Append($element)
                [void]$xevent_string.Append("`r`n")
                #ADD EVENT sqlserver.
                #if ($element.contains("AlwaysOn_Data_Movement")) {
                if ($element.contains("ADD EVENT sqlserver.")) {

                    $temp = $element.split('(')[0].split('.')
                    if ($temp.count -eq 2) {
                        $GenericModelobj.Caption = $temp[1]
                    }

                }
            }
        }
    }
    catch {
        HandleCatchBlock -function_name $($MyInvocation.MyCommand) -err_rec $PSItem  
        exit
    }

}


function BuildXEventsModel_servicebroker_dbmail() {
    try {
        Write-LogDebug "inside" $MyInvocation.MyCommand  
        $xevent_string = New-Object -TypeName System.Text.StringBuilder
        $GenericModelobj = New-Object GenericModel
        foreach ($element in Get-Content .\xevent_servicebroker_dbmail.sql) {
            if ($element -eq "GO") { 
                $GenericModelobj.Value = $xevent_string
                $GenericModelobj.State = $true
                $global:XeventsList_servicebroker_dbmail.Add($GenericModelobj)
                 
                # reset the object and string builder
                $GenericModelobj = New-Object GenericModel
                $xevent_string = New-Object -TypeName System.Text.StringBuilder
                [void]$xevent_string.Append("GO `r`n")
            }
            else {
                [void]$xevent_string.Append($element)
                [void]$xevent_string.Append("`r`n")
                
                #$GenericModelobj.Value = $line
                # get the event name from the event session and add it to the model
                if ($element.contains("[xevent_SQLLogScout]")) {
                    $temp = $element.split('(')[0].split('.')
                    if ($temp.count -eq 2) {
                        $GenericModelobj.Caption = $temp[1]
                    }

                }
            }
        }
    }
    catch {
        HandleCatchBlock -function_name $($MyInvocation.MyCommand) -err_rec $PSItem  
        exit
    }

}

function BuildServiceNameStatusModel() {

    try 
    {
        foreach ($Instance in Get-NetNameMatchingInstance) 
        { 
            $global:List_service_name_status.Add((New-Object ServiceState -Property @{Name=$Instance.Name; Status=$Instance.Status}))
            
        }   
        
        $ComboBoxInstanceName.ItemsSource = $global:List_service_name_status 
    }
    
    catch 
    {
        HandleCatchBlock -function_name $($MyInvocation.MyCommand) -err_rec $PSItem  
        exit
    }
}

# SIG # Begin signature block
# MIIoOgYJKoZIhvcNAQcCoIIoKzCCKCcCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCkvmgDM46UNRy0
# If22MdhZv49uY0RmHKlY8ppibHshyqCCDYUwggYDMIID66ADAgECAhMzAAADri01
# UchTj1UdAAAAAAOuMA0GCSqGSIb3DQEBCwUAMH4xCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNpZ25p
# bmcgUENBIDIwMTEwHhcNMjMxMTE2MTkwODU5WhcNMjQxMTE0MTkwODU5WjB0MQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMR4wHAYDVQQDExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
# AQD0IPymNjfDEKg+YyE6SjDvJwKW1+pieqTjAY0CnOHZ1Nj5irGjNZPMlQ4HfxXG
# yAVCZcEWE4x2sZgam872R1s0+TAelOtbqFmoW4suJHAYoTHhkznNVKpscm5fZ899
# QnReZv5WtWwbD8HAFXbPPStW2JKCqPcZ54Y6wbuWV9bKtKPImqbkMcTejTgEAj82
# 6GQc6/Th66Koka8cUIvz59e/IP04DGrh9wkq2jIFvQ8EDegw1B4KyJTIs76+hmpV
# M5SwBZjRs3liOQrierkNVo11WuujB3kBf2CbPoP9MlOyyezqkMIbTRj4OHeKlamd
# WaSFhwHLJRIQpfc8sLwOSIBBAgMBAAGjggGCMIIBfjAfBgNVHSUEGDAWBgorBgEE
# AYI3TAgBBggrBgEFBQcDAzAdBgNVHQ4EFgQUhx/vdKmXhwc4WiWXbsf0I53h8T8w
# VAYDVR0RBE0wS6RJMEcxLTArBgNVBAsTJE1pY3Jvc29mdCBJcmVsYW5kIE9wZXJh
# dGlvbnMgTGltaXRlZDEWMBQGA1UEBRMNMjMwMDEyKzUwMTgzNjAfBgNVHSMEGDAW
# gBRIbmTlUAXTgqoXNzcitW2oynUClTBUBgNVHR8ETTBLMEmgR6BFhkNodHRwOi8v
# d3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2NybC9NaWNDb2RTaWdQQ0EyMDExXzIw
# MTEtMDctMDguY3JsMGEGCCsGAQUFBwEBBFUwUzBRBggrBgEFBQcwAoZFaHR0cDov
# L3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jZXJ0cy9NaWNDb2RTaWdQQ0EyMDEx
# XzIwMTEtMDctMDguY3J0MAwGA1UdEwEB/wQCMAAwDQYJKoZIhvcNAQELBQADggIB
# AGrJYDUS7s8o0yNprGXRXuAnRcHKxSjFmW4wclcUTYsQZkhnbMwthWM6cAYb/h2W
# 5GNKtlmj/y/CThe3y/o0EH2h+jwfU/9eJ0fK1ZO/2WD0xi777qU+a7l8KjMPdwjY
# 0tk9bYEGEZfYPRHy1AGPQVuZlG4i5ymJDsMrcIcqV8pxzsw/yk/O4y/nlOjHz4oV
# APU0br5t9tgD8E08GSDi3I6H57Ftod9w26h0MlQiOr10Xqhr5iPLS7SlQwj8HW37
# ybqsmjQpKhmWul6xiXSNGGm36GarHy4Q1egYlxhlUnk3ZKSr3QtWIo1GGL03hT57
# xzjL25fKiZQX/q+II8nuG5M0Qmjvl6Egltr4hZ3e3FQRzRHfLoNPq3ELpxbWdH8t
# Nuj0j/x9Crnfwbki8n57mJKI5JVWRWTSLmbTcDDLkTZlJLg9V1BIJwXGY3i2kR9i
# 5HsADL8YlW0gMWVSlKB1eiSlK6LmFi0rVH16dde+j5T/EaQtFz6qngN7d1lvO7uk
# 6rtX+MLKG4LDRsQgBTi6sIYiKntMjoYFHMPvI/OMUip5ljtLitVbkFGfagSqmbxK
# 7rJMhC8wiTzHanBg1Rrbff1niBbnFbbV4UDmYumjs1FIpFCazk6AADXxoKCo5TsO
# zSHqr9gHgGYQC2hMyX9MGLIpowYCURx3L7kUiGbOiMwaMIIHejCCBWKgAwIBAgIK
# YQ6Q0gAAAAAAAzANBgkqhkiG9w0BAQsFADCBiDELMAkGA1UEBhMCVVMxEzARBgNV
# BAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jv
# c29mdCBDb3Jwb3JhdGlvbjEyMDAGA1UEAxMpTWljcm9zb2Z0IFJvb3QgQ2VydGlm
# aWNhdGUgQXV0aG9yaXR5IDIwMTEwHhcNMTEwNzA4MjA1OTA5WhcNMjYwNzA4MjEw
# OTA5WjB+MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UE
# BxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSgwJgYD
# VQQDEx9NaWNyb3NvZnQgQ29kZSBTaWduaW5nIFBDQSAyMDExMIICIjANBgkqhkiG
# 9w0BAQEFAAOCAg8AMIICCgKCAgEAq/D6chAcLq3YbqqCEE00uvK2WCGfQhsqa+la
# UKq4BjgaBEm6f8MMHt03a8YS2AvwOMKZBrDIOdUBFDFC04kNeWSHfpRgJGyvnkmc
# 6Whe0t+bU7IKLMOv2akrrnoJr9eWWcpgGgXpZnboMlImEi/nqwhQz7NEt13YxC4D
# dato88tt8zpcoRb0RrrgOGSsbmQ1eKagYw8t00CT+OPeBw3VXHmlSSnnDb6gE3e+
# lD3v++MrWhAfTVYoonpy4BI6t0le2O3tQ5GD2Xuye4Yb2T6xjF3oiU+EGvKhL1nk
# kDstrjNYxbc+/jLTswM9sbKvkjh+0p2ALPVOVpEhNSXDOW5kf1O6nA+tGSOEy/S6
# A4aN91/w0FK/jJSHvMAhdCVfGCi2zCcoOCWYOUo2z3yxkq4cI6epZuxhH2rhKEmd
# X4jiJV3TIUs+UsS1Vz8kA/DRelsv1SPjcF0PUUZ3s/gA4bysAoJf28AVs70b1FVL
# 5zmhD+kjSbwYuER8ReTBw3J64HLnJN+/RpnF78IcV9uDjexNSTCnq47f7Fufr/zd
# sGbiwZeBe+3W7UvnSSmnEyimp31ngOaKYnhfsi+E11ecXL93KCjx7W3DKI8sj0A3
# T8HhhUSJxAlMxdSlQy90lfdu+HggWCwTXWCVmj5PM4TasIgX3p5O9JawvEagbJjS
# 4NaIjAsCAwEAAaOCAe0wggHpMBAGCSsGAQQBgjcVAQQDAgEAMB0GA1UdDgQWBBRI
# bmTlUAXTgqoXNzcitW2oynUClTAZBgkrBgEEAYI3FAIEDB4KAFMAdQBiAEMAQTAL
# BgNVHQ8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB/zAfBgNVHSMEGDAWgBRyLToCMZBD
# uRQFTuHqp8cx0SOJNDBaBgNVHR8EUzBRME+gTaBLhklodHRwOi8vY3JsLm1pY3Jv
# c29mdC5jb20vcGtpL2NybC9wcm9kdWN0cy9NaWNSb29DZXJBdXQyMDExXzIwMTFf
# MDNfMjIuY3JsMF4GCCsGAQUFBwEBBFIwUDBOBggrBgEFBQcwAoZCaHR0cDovL3d3
# dy5taWNyb3NvZnQuY29tL3BraS9jZXJ0cy9NaWNSb29DZXJBdXQyMDExXzIwMTFf
# MDNfMjIuY3J0MIGfBgNVHSAEgZcwgZQwgZEGCSsGAQQBgjcuAzCBgzA/BggrBgEF
# BQcCARYzaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9kb2NzL3ByaW1h
# cnljcHMuaHRtMEAGCCsGAQUFBwICMDQeMiAdAEwAZQBnAGEAbABfAHAAbwBsAGkA
# YwB5AF8AcwB0AGEAdABlAG0AZQBuAHQALiAdMA0GCSqGSIb3DQEBCwUAA4ICAQBn
# 8oalmOBUeRou09h0ZyKbC5YR4WOSmUKWfdJ5DJDBZV8uLD74w3LRbYP+vj/oCso7
# v0epo/Np22O/IjWll11lhJB9i0ZQVdgMknzSGksc8zxCi1LQsP1r4z4HLimb5j0b
# pdS1HXeUOeLpZMlEPXh6I/MTfaaQdION9MsmAkYqwooQu6SpBQyb7Wj6aC6VoCo/
# KmtYSWMfCWluWpiW5IP0wI/zRive/DvQvTXvbiWu5a8n7dDd8w6vmSiXmE0OPQvy
# CInWH8MyGOLwxS3OW560STkKxgrCxq2u5bLZ2xWIUUVYODJxJxp/sfQn+N4sOiBp
# mLJZiWhub6e3dMNABQamASooPoI/E01mC8CzTfXhj38cbxV9Rad25UAqZaPDXVJi
# hsMdYzaXht/a8/jyFqGaJ+HNpZfQ7l1jQeNbB5yHPgZ3BtEGsXUfFL5hYbXw3MYb
# BL7fQccOKO7eZS/sl/ahXJbYANahRr1Z85elCUtIEJmAH9AAKcWxm6U/RXceNcbS
# oqKfenoi+kiVH6v7RyOA9Z74v2u3S5fi63V4GuzqN5l5GEv/1rMjaHXmr/r8i+sL
# gOppO6/8MO0ETI7f33VtY5E90Z1WTk+/gFcioXgRMiF670EKsT/7qMykXcGhiJtX
# cVZOSEXAQsmbdlsKgEhr/Xmfwb1tbWrJUnMTDXpQzTGCGgswghoHAgEBMIGVMH4x
# CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
# b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01p
# Y3Jvc29mdCBDb2RlIFNpZ25pbmcgUENBIDIwMTECEzMAAAOuLTVRyFOPVR0AAAAA
# A64wDQYJYIZIAWUDBAIBBQCggbAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQw
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIGqD
# FSU0P/AI1rmu4EjNETa0ZaPrIgRaOSGaotV2rZb0MEQGCisGAQQBgjcCAQwxNjA0
# oBSAEgBNAGkAYwByAG8AcwBvAGYAdKEcgBpodHRwczovL3d3d3cubWljcm9zb2Z0
# LmNvbTANBgkqhkiG9w0BAQEFAASCAQCg78UTLm4alkJTsLywsJOxmefr4VzAlkCC
# yIilubNoJ1ATCkW5rUMTLxaQqOiLGBmOrIfkY83BAVHKlrew1xK6Zn/YRZ0kSQma
# RxntyMIrroMfklxtYTgLTbdXtvzmNi7mX++7GrHkBKZar7bQvXZYIUIpWkKLfWNV
# NlKeQGQF6dHGBp3WKQVRxpcgtxkcPDtUdA+E47Irw9AbQBoxPPU7Ph/No8LcJQ1f
# ZkG1ttpt8bFvf1yIunHguATBNOcz+ajStK6je436sGLklFAM1lPN2sznMAOsyqFx
# 3eBk7jtrJBpx27sK/lpoWepTBZ8hu/TUhFIk5bbs0u/Knsqr6cK7oYIXkzCCF48G
# CisGAQQBgjcDAwExghd/MIIXewYJKoZIhvcNAQcCoIIXbDCCF2gCAQMxDzANBglg
# hkgBZQMEAgEFADCCAVEGCyqGSIb3DQEJEAEEoIIBQASCATwwggE4AgEBBgorBgEE
# AYRZCgMBMDEwDQYJYIZIAWUDBAIBBQAEIGr5cKCnL0cIxddDpaLdMkI6OGz0GnpU
# mT5ijK5a3RcsAgZlzg2aFwUYEjIwMjQwMjE2MDkwMDM1LjY1WjAEgAIB9KCB0aSB
# zjCByzELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcT
# B1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjElMCMGA1UE
# CxMcTWljcm9zb2Z0IEFtZXJpY2EgT3BlcmF0aW9uczEnMCUGA1UECxMeblNoaWVs
# ZCBUU1MgRVNOOjhEMDAtMDVFMC1EOTQ3MSUwIwYDVQQDExxNaWNyb3NvZnQgVGlt
# ZS1TdGFtcCBTZXJ2aWNloIIR6jCCByAwggUIoAMCAQICEzMAAAHzxQpDrgPMHTEA
# AQAAAfMwDQYJKoZIhvcNAQELBQAwfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldh
# c2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBD
# b3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIw
# MTAwHhcNMjMxMjA2MTg0NjAyWhcNMjUwMzA1MTg0NjAyWjCByzELMAkGA1UEBhMC
# VVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNV
# BAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjElMCMGA1UECxMcTWljcm9zb2Z0IEFt
# ZXJpY2EgT3BlcmF0aW9uczEnMCUGA1UECxMeblNoaWVsZCBUU1MgRVNOOjhEMDAt
# MDVFMC1EOTQ3MSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBTZXJ2aWNl
# MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA/p+m2uErgfYkjuVjIW54
# KmAG/s9yH8zaWSFkv7IH14ZS2Jhp7FLaxl9zlXIPvJKyXYsbjVDDu2QDqgmbF1Iz
# s/M3J9WlA+Q9q9j4c1Sox7Yr1hoBo+MecKlntUKL97zM/Fh7CrH2nSJVo3wTJ1Sl
# aJjsm0O/to3OGn849lyUEEphPY0EaAaIA8JqmWpHmJyMdBJjrrnD6+u+E+v2Gkz4
# iGJRn/l1druqEBwJDBuesWD0IpIrUI4zVhwA3wamwRGqqaWrLcaUTXOIndktcVUM
# XEBl45wIHnlW2z2wKBC4W8Ps91XrUcLhBSUc0+oW1hIL8/SzGD0m4qBy/MPmYlqN
# 8bsN0e3ybKnu6arJ48L54j+7HxNbrX4u5NDUGTKb4jrP/9t/R+ngOiDlbRfMOuoq
# RO9RGK3EjazhpU5ubqqvrMjtbnWTnijNMWO9vDXBgxap47hT2xBJuvnrWSn7VPY8
# Swks6lzlTs3agPDuV2txONY97OzJUxeEOwWK0Jm6caoU737iJWMCNgM3jtzor3Hs
# ycAY9hUIE4lR2nLzEA4EgOxOb8rWpNPjCwZtAHFuCD3q/AOIDhg/aEqa5sgLtSes
# BZAa39ko5/onjauhcdLVo/CKYN7kL3LoN+40mnReqta1BGqDyGo2QhlZPqOcJ+q7
# fnMHSd/URFON2lgsJ9Avl8cCAwEAAaOCAUkwggFFMB0GA1UdDgQWBBTDZBX2pRFR
# DIwNwKaFMfag6w0KJDAfBgNVHSMEGDAWgBSfpxVdAF5iXYP05dJlpxtTNRnpcjBf
# BgNVHR8EWDBWMFSgUqBQhk5odHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3Bz
# L2NybC9NaWNyb3NvZnQlMjBUaW1lLVN0YW1wJTIwUENBJTIwMjAxMCgxKS5jcmww
# bAYIKwYBBQUHAQEEYDBeMFwGCCsGAQUFBzAChlBodHRwOi8vd3d3Lm1pY3Jvc29m
# dC5jb20vcGtpb3BzL2NlcnRzL01pY3Jvc29mdCUyMFRpbWUtU3RhbXAlMjBQQ0El
# MjAyMDEwKDEpLmNydDAMBgNVHRMBAf8EAjAAMBYGA1UdJQEB/wQMMAoGCCsGAQUF
# BwMIMA4GA1UdDwEB/wQEAwIHgDANBgkqhkiG9w0BAQsFAAOCAgEA38Qcj/zR/u/b
# 3N5YjuHO51zP1ChXAJucOtRcUcT8Ql0V5YjY2e7A6jT9A81EwVPbUuQ6pKkUoiFd
# eY+6vHunpYPP3A9279LFuBqPQDC+JYQOTAYN8MynYoXydBPxyKnB19dZsLW6U4gt
# rIAFIe/jmZ2/U8CRO6WxATyUFMcbgokuf69LNkFYqQZov/DBFtniIuJifrxyOQwm
# gBqKE+ANef+6DY/c8s0QAU1CAjTa0tfSn68hDeXYeZKjhuEIHGvcOi+wi/krrk2Y
# tEmfGauuYitoUPCDADlcXsAqQ+JWS+jQ7FTUsATVzlJbMTgDtxtMDU/nAboPxw+N
# wexNqHVX7Oh9hGAmcVEta4EXhndrqkMYENsKzLk2+cpDvqnfuJ4Wn//Ujd4HraJr
# UJ+SM4XwpK2k9Sp2RfEyN8ntWd6Z3q9Ap/6deR+8DcA5AQImftos/TVBHmC3zBpv
# bxKw1QQ0TIxrBPx6qmO0E0k7Q71O/s2cETxo4mGFBV0/lYJH3R4haSsONl7JtDHy
# +Wjmt9RcgjNe/6T0yCk0YirAxd+9EsCMGQI1c4g//UIRBQbvaaIxVCzmb87i+Ykh
# CSHKqKVQMHWzXa6GYthzfJ3w48yWvAjE5EHkn0LEKSq/NzoQZhNzBdrM/IKnt5aH
# NOQ1vCTb2d9vCabNyyQgC7dK0DyWJzswggdxMIIFWaADAgECAhMzAAAAFcXna54C
# m0mZAAAAAAAVMA0GCSqGSIb3DQEBCwUAMIGIMQswCQYDVQQGEwJVUzETMBEGA1UE
# CBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9z
# b2Z0IENvcnBvcmF0aW9uMTIwMAYDVQQDEylNaWNyb3NvZnQgUm9vdCBDZXJ0aWZp
# Y2F0ZSBBdXRob3JpdHkgMjAxMDAeFw0yMTA5MzAxODIyMjVaFw0zMDA5MzAxODMy
# MjVaMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQH
# EwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNV
# BAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwMIICIjANBgkqhkiG9w0B
# AQEFAAOCAg8AMIICCgKCAgEA5OGmTOe0ciELeaLL1yR5vQ7VgtP97pwHB9KpbE51
# yMo1V/YBf2xK4OK9uT4XYDP/XE/HZveVU3Fa4n5KWv64NmeFRiMMtY0Tz3cywBAY
# 6GB9alKDRLemjkZrBxTzxXb1hlDcwUTIcVxRMTegCjhuje3XD9gmU3w5YQJ6xKr9
# cmmvHaus9ja+NSZk2pg7uhp7M62AW36MEBydUv626GIl3GoPz130/o5Tz9bshVZN
# 7928jaTjkY+yOSxRnOlwaQ3KNi1wjjHINSi947SHJMPgyY9+tVSP3PoFVZhtaDua
# Rr3tpK56KTesy+uDRedGbsoy1cCGMFxPLOJiss254o2I5JasAUq7vnGpF1tnYN74
# kpEeHT39IM9zfUGaRnXNxF803RKJ1v2lIH1+/NmeRd+2ci/bfV+AutuqfjbsNkz2
# K26oElHovwUDo9Fzpk03dJQcNIIP8BDyt0cY7afomXw/TNuvXsLz1dhzPUNOwTM5
# TI4CvEJoLhDqhFFG4tG9ahhaYQFzymeiXtcodgLiMxhy16cg8ML6EgrXY28MyTZk
# i1ugpoMhXV8wdJGUlNi5UPkLiWHzNgY1GIRH29wb0f2y1BzFa/ZcUlFdEtsluq9Q
# BXpsxREdcu+N+VLEhReTwDwV2xo3xwgVGD94q0W29R6HXtqPnhZyacaue7e3Pmri
# Lq0CAwEAAaOCAd0wggHZMBIGCSsGAQQBgjcVAQQFAgMBAAEwIwYJKwYBBAGCNxUC
# BBYEFCqnUv5kxJq+gpE8RjUpzxD/LwTuMB0GA1UdDgQWBBSfpxVdAF5iXYP05dJl
# pxtTNRnpcjBcBgNVHSAEVTBTMFEGDCsGAQQBgjdMg30BATBBMD8GCCsGAQUFBwIB
# FjNodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL0RvY3MvUmVwb3NpdG9y
# eS5odG0wEwYDVR0lBAwwCgYIKwYBBQUHAwgwGQYJKwYBBAGCNxQCBAweCgBTAHUA
# YgBDAEEwCwYDVR0PBAQDAgGGMA8GA1UdEwEB/wQFMAMBAf8wHwYDVR0jBBgwFoAU
# 1fZWy4/oolxiaNE9lJBb186aGMQwVgYDVR0fBE8wTTBLoEmgR4ZFaHR0cDovL2Ny
# bC5taWNyb3NvZnQuY29tL3BraS9jcmwvcHJvZHVjdHMvTWljUm9vQ2VyQXV0XzIw
# MTAtMDYtMjMuY3JsMFoGCCsGAQUFBwEBBE4wTDBKBggrBgEFBQcwAoY+aHR0cDov
# L3d3dy5taWNyb3NvZnQuY29tL3BraS9jZXJ0cy9NaWNSb29DZXJBdXRfMjAxMC0w
# Ni0yMy5jcnQwDQYJKoZIhvcNAQELBQADggIBAJ1VffwqreEsH2cBMSRb4Z5yS/yp
# b+pcFLY+TkdkeLEGk5c9MTO1OdfCcTY/2mRsfNB1OW27DzHkwo/7bNGhlBgi7ulm
# ZzpTTd2YurYeeNg2LpypglYAA7AFvonoaeC6Ce5732pvvinLbtg/SHUB2RjebYIM
# 9W0jVOR4U3UkV7ndn/OOPcbzaN9l9qRWqveVtihVJ9AkvUCgvxm2EhIRXT0n4ECW
# OKz3+SmJw7wXsFSFQrP8DJ6LGYnn8AtqgcKBGUIZUnWKNsIdw2FzLixre24/LAl4
# FOmRsqlb30mjdAy87JGA0j3mSj5mO0+7hvoyGtmW9I/2kQH2zsZ0/fZMcm8Qq3Uw
# xTSwethQ/gpY3UA8x1RtnWN0SCyxTkctwRQEcb9k+SS+c23Kjgm9swFXSVRk2XPX
# fx5bRAGOWhmRaw2fpCjcZxkoJLo4S5pu+yFUa2pFEUep8beuyOiJXk+d0tBMdrVX
# VAmxaQFEfnyhYWxz/gq77EFmPWn9y8FBSX5+k77L+DvktxW/tM4+pTFRhLy/AsGC
# onsXHRWJjXD+57XQKBqJC4822rpM+Zv/Cuk0+CQ1ZyvgDbjmjJnW4SLq8CdCPSWU
# 5nR0W2rRnj7tfqAxM328y+l7vzhwRNGQ8cirOoo6CGJ/2XBjU02N7oJtpQUQwXEG
# ahC0HVUzWLOhcGbyoYIDTTCCAjUCAQEwgfmhgdGkgc4wgcsxCzAJBgNVBAYTAlVT
# MRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQK
# ExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJTAjBgNVBAsTHE1pY3Jvc29mdCBBbWVy
# aWNhIE9wZXJhdGlvbnMxJzAlBgNVBAsTHm5TaGllbGQgVFNTIEVTTjo4RDAwLTA1
# RTAtRDk0NzElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2VydmljZaIj
# CgEBMAcGBSsOAwIaAxUAbvoGLNi0YWuaRTu/YNy5H8CkZyiggYMwgYCkfjB8MQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNy
# b3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMDANBgkqhkiG9w0BAQsFAAIFAOl5NMYw
# IhgPMjAyNDAyMTYwMTExMzRaGA8yMDI0MDIxNzAxMTEzNFowdDA6BgorBgEEAYRZ
# CgQBMSwwKjAKAgUA6Xk0xgIBADAHAgEAAgIJIDAHAgEAAgITVjAKAgUA6XqGRgIB
# ADA2BgorBgEEAYRZCgQCMSgwJjAMBgorBgEEAYRZCgMCoAowCAIBAAIDB6EgoQow
# CAIBAAIDAYagMA0GCSqGSIb3DQEBCwUAA4IBAQBmGha+ADlzgjqjizPI9YbZ1pzp
# t81gtzUHdmCPVhGsR8wolfkaL7x8M/6lbeA+IG2Y8oYAXLBYCgqwpRyq7z8HqmoP
# VqQd6CSzHvxZBd+hajo36OCzA8cfalkceNGaLtZhqgAmsAvqgI/Yn7WA3pN5l4Y1
# EwDsv+cqeN598kVuYeche2bHbE88mxcOngQ3CTRRl2bAejnyyxg6CVZk21qPX2Su
# hljFtVF7w53giwRCTb2E0iSTpu33/iDivVAXmbIxYml1vBa9jpX3MymQAm9VKXy/
# G2Shu0tPrLI7NV6vFi92j6aq1cYW8DRK9nrYpTGq9WDmyhjn0xJUXXJTCOnqMYIE
# DTCCBAkCAQEwgZMwfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24x
# EDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlv
# bjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTACEzMAAAHz
# xQpDrgPMHTEAAQAAAfMwDQYJYIZIAWUDBAIBBQCgggFKMBoGCSqGSIb3DQEJAzEN
# BgsqhkiG9w0BCRABBDAvBgkqhkiG9w0BCQQxIgQgB6nwE4HMETZhD1jcpMdDQUR8
# YyFyhK4+ke4gMcbEDFowgfoGCyqGSIb3DQEJEAIvMYHqMIHnMIHkMIG9BCAYvNk0
# i7bhuFZKfMAZiZP0/kQIfONbBv2gzsMYOjti6DCBmDCBgKR+MHwxCzAJBgNVBAYT
# AlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBU
# aW1lLVN0YW1wIFBDQSAyMDEwAhMzAAAB88UKQ64DzB0xAAEAAAHzMCIEIBGr8x7z
# 8UlAXUA/nVIwRQaIZI0QsfJkb5WI7khytzkrMA0GCSqGSIb3DQEBCwUABIICAAeQ
# ckOSNe/9EeabBSfoCPBVx1WnJWQHDj0SAhebMo4ifp8rRHGkjzTOonY8owdLRc11
# cVn6KLm0AP2eMFQkjnX7i5boXPo5SlKUrrjyJTkM7P+qABbQ5LnrnIU5og2pX63u
# DJ3QsAsKTl58icX8R4ZDMqHAT1/dACK2xByNB2nfedNSzHLi129aFE1A8WD07JsB
# MQaJ0ezcp9rEy6WjnRVRI6Kq5Xcit6yYapGHHt/+kmvSW9zXC/BryDuaGQSweh5H
# N1U8kyZQWFPoyVSSCkRLh/T6d7tZ6SAz84LNtg92SFGL+CL17MBLIWOTossM5ByS
# jpIIkhg/Qe+noKElPrWw4qI733ClBl8/FCBWUWO9iiBt5NGQB/FNCL2SpLM65mT8
# VyEGuem4WM0fF4RCCUIPkfoMubSZchddiUr9gfbOP283BSLKMocByc+Y4p+9AK1j
# DdO2A9cufK9Byx/gkGpcNBnKIwGBHYRHdNhvEg/n6QhwT+FE/jnGFotz+IeuTo41
# JknNC7GkuKNlbcX87OwncdhruDGhU43959LwJctorYGGFzgSHkyiqOlVaBhTMpLf
# xta8AC4F8miVYYY3NPW9C0NWXfagNunrRmge+lh1TXye2wLZlaYoPLT8CbasOseX
# v03ruVlYK3H2lK8PqcqOFi+DkR64cSqR8Ggon+OV
# SIG # End signature block
