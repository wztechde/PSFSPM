#requires -RunAsAdministrator
#Requires -Modules Carbon
Set-Location -Path $PSScriptRoot
#-------------------------------------------------------------------------
$ModuleName = 'PSFSPM'
$PathToManifest = [System.IO.Path]::Combine('..', '..', $ModuleName, "$ModuleName.psd1")
#-------------------------------------------------------------------------
if (Get-Module -Name $ModuleName -ErrorAction 'SilentlyContinue') {
    #if the module is already in memory, remove it
    Remove-Module -Name $ModuleName -Force
}
Import-Module $PathToManifest -Force
BeforeDiscovery {
    # build environment
    $Tmp=New-TempDir
    $Script:F_Foo = mkdir "$Tmp\foo" -Force
    $Script:F_Foo_txt = New-Item -Path "$($F_Foo)\test.txt" -ItemType File -Force
    $Script:F_Bar = mkdir "$Tmp\foo\bar" -Force
    $Script:F_Bar_txt = New-Item -Path "$($F_Bar)\test.txt" -ItemType File -Force
    $Script:F_Clara = mkdir "$Tmp\foo\bar\clara" -Force
    $Script:F_Donna = mkdir "$Tmp\foo\bar\clara\donna" -Force


}
# create test structure


Describe 'Set-Permission - data driven' -Tag Integration {
    BeforeAll {
        New-LocalUser Pester1 -NoPassword
        New-LocalUser Pester2 -NoPassword
        New-LocalUser Pester3 -NoPassword
        New-LocalGroup GPester1 -Description 'Pester Group 1'
        New-LocalGroup GPester2 -Description 'Pester Group 2'
        Add-LocalGroupMember -Group GPester1 -Member Pester1
        Add-LocalGroupMember -Group GPester2 -Member Pester2
        # Create folder strukture
    }
    AfterAll {
        Remove-LocalUser Pester1, Pester2, Pester3
        Remove-LocalGroup Gpester1, GPester2
    }
    Context 'ThisFoldersubfoldersAndFiles - only pester1' {
        BeforeAll {
            $FPM = New-FMPathPermission -Path $F_Foo -Identity Pester1 -Permission Write -Inheritance ThisFolderSubfoldersAndFiles
            $Result = Set-Permission -PathPermissionObject $FPM
        }
        It 'ThisFolderSubfoldersAndFiles <Path> with <User>' -ForEach @(
            @{Path = $Script:F_Foo; User = 'Pester1' }
            @{Path = $Script:F_Bar; User = 'Pester1' }
            @{Path = $Script:F_Clara; User = 'Pester1' }
            @{Path = $Script:F_Bar_txt; User = 'Pester1' }
        ) {
            $Access = (Get-Acl $Path).Access
            $Access.IdentityReference -match $User | Should -Not -BeNullOrEmpty
        }
    }
    Context 'ThisFolderAndsubfolders - only pester1' {
        BeforeAll {
            $FPM = New-FMPathPermission -Path $F_Foo -Identity Pester1 -Permission Write -Inheritance ThisFolderAndSubfolders
            $Result = Set-Permission -PathPermissionObject $FPM
        }
        It 'ThisFolderAndSubfolders <Path> with <User>. <Exist>' -ForEach @(
            @{Path = $F_Foo; User = 'Pester1'; Exist = $true }
            @{Path = $F_Bar; User = 'Pester1'; Exist = $true }
            @{Path = $F_Clara; User = 'Pester1'; Exist = $true }
            @{Path = $F_Foo_txt; User = 'Pester1'; Exist = $False }
        ) {
            $Access = (Get-Acl $Path).Access
            if ($Exist) {
                $Access.IdentityReference -match $User | Should -Not -BeNullOrEmpty
            }
            else {
                $Access.IdentityReference -match $User | Should -BeNullOrEmpty
            }
        }
    }
}#e