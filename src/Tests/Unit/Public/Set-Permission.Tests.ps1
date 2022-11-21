#-------------------------------------------------------------------------
Set-Location -Path $PSScriptRoot
#-------------------------------------------------------------------------
$ModuleName = 'PSFSPM'
$PathToManifest = [System.IO.Path]::Combine('..', '..', '..', $ModuleName, "$ModuleName.psd1")
#-------------------------------------------------------------------------
if (Get-Module -Name $ModuleName -ErrorAction 'SilentlyContinue') {
   #if the module is already in memory, remove it
   Remove-Module -Name $ModuleName -Force
}
Import-Module $PathToManifest -Force
# Vars
#-------------------------------------------------------------------------
BeforeAll{
   $PermObject = New-FMPermission -Identity foo -Permission Read -Inheritance ThisFolderOnly
}
Describe 'Set-Permission1' -Tag Unit {
   Context 'Function call' -Tag Unit {
      It 'Checks if function is available after module import' {
         { Set-Permission -Path $TestDrive -PermissionObject $PermObject } | Should -Not -Throw '*is not recognized as the name*'
      }#end it
      It 'Checks if help exists' {
         { Get-Help Set-Permission } | Should -Not -Throw '*in a help file in this session*'
      }
   }#end context function call
   Context 'Parameter check - path' -Tag Unit {
      It 'Should prompt, if path is missing and error when pass is empty' {
         { Set-Permission -Path "" -PermissionObject $PermObject } | Should -Throw "Cannot validate argument on parameter*"
      }
      It 'Should return error, when param is no filesystemobject' {
         { Set-Permission -Path 'Throw' } | Should -Throw "Cannot validate argument on parameter 'Path'*"
      }
      It 'Should not fail if path is filesystemobject' {
         New-Item -Path $TestDrive -Name 'foo.txt' -ItemType File
         { Set-Permission -Path $TestDrive -PermissionObject $PermObject } | Should -Not -Throw
         { Set-Permission -Path "$TestDrive\foo.txt" -PermissionObject $PermObject } | Should -Not -Throw
      }
      It 'Should not fail, if several valid paths are given' {
         New-Item -Path $TestDrive -Name 'foo.txt' -ItemType File -Force
         { Set-Permission -Path $TestDrive, $TestDrive -PermissionObject $PermObject } | Should -Not -Throw
         { Set-Permission -Path $TestDrive, "$TestDrive\foo.txt" -PermissionObject $PermObject } | Should -Not -Throw
      }
      It 'Should fail, if several paths are given and at least one is invalid' {
         { Set-Permission -Path $TestDrive, 'foo' -PermissionObject $PermObject } | Should -Throw '*Path * is not valid'
      }
      It 'Can take parameter from pipeline' {
         { $TestDrive | Set-Permission -PermissionObject $PermObject } | Should -Not -Throw
      }
      It 'Can take several parameter(s) from pipeline' {
         { $TestDrive, "$TestDrive\foo.txt" | Set-Permission -PermissionObject $PermObject } | Should -Not -Throw
      }
      It "Should throw if parameter doesn't fit expected type 'Permission'" {
         { Set-Permission -Path C:\Temp -Identity foo -Permission ready -Inheritance NotGiven } | Should -Throw "Cannot process argument transformation on parameter 'Permission'*"
      }
      It "Should throw if parameter doesn't fit expected type 'Inheritance'" {
         { Set-Permission -Path C:\Temp -Identity foo -Permission read -Inheritance NotGiven } | Should -Throw "Cannot process argument transformation on parameter 'Inheritance'*"
      }
      It "Should throw if parameter doesn't fit expected type 'PermissionObject'" {
         { Set-Permission -Path C:\Temp -PermissionObject "Willi" } | Should -Throw "Cannot process argument transformation on parameter 'PermissionObject'*"
      }
      It "Should allow an array of 'PermissionObject'" {
         { Set-Permission -Path C:\Temp -PermissionObject $PermObject, $PermObject } | Should -Not -Throw
      }
      It "Should throw if parameter doesn't fit expected type 'PathPermissionObject'" {
         { Set-Permission -Path C:\Temp -PathPermissionObject "Willi" } | Should -Throw "Cannot process argument transformation on parameter 'PathPermissionObject'*"
      }
      It "Should allow an array of 'PathPermissionObject'" {
         $FMPP1=New-FMPathPermission -Path C:\Temp -InputObject $PermObject
         $FMPP2=New-FMPathPermission -Path C:\Temp -InputObject $PermObject
         { Set-Permission -PathPermissionObject $FMPP1,$FMPP2 } | Should -Not -Throw
      }

   }#end context param path
   Context 'Parameter check for default parameter set' -Tag Unit {
      It "Check if parameter counts correlate" {
         { Set-Permission -Path $TestDrive -Identity foo, bar -Permission "Modify" -Inheritance "ThisFolderSubfoldersAndFiles" } |
         Should -Throw "Counts of identities*"
      }
   }#end Context

   Context 'check inner parameter transformation to FMPathPermission' -Tag Unit {
      It "Should return a FMPathPermission object, when fed with default data" {
         $result = Set-Permission $Testdrive -Identity foo -Permission Read -Inheritance ThisFolderOnly -PassThru
         $result[1].gettype() | Should -Be "FMPathPermission"
      }
      It "Should return a FMPathPermission object, when fed with Permission" {
         $result = Set-Permission $Testdrive -PermissionObject $PermObject -PassThru
         $result[1].gettype() | Should -Be "FMPathPermission"
      }
      It "Should return a FMPathPermission object, when fed with PathPermission" {
         $FMP = New-FMPathPermission -Path $Testdrive -InputObject $PermObject
         $result = Set-Permission -PathPermissionObject $FMP -PassThru
         $result[1].gettype() | Should -Be "FMPathPermission"
      }
      It "Paramset 'Default' - should return FMPP array when fed with multiple data" {
         $result = Set-Permission $Testdrive -Identity foo, bar -Permission Write, Read -Inheritance ThisFolderOnly, ThisFolderFiles -PassThru
         $result[1].gettype() | Should -Be "FMPathPermission"
         $result[1].Permission.Count | Should -Be 2
      }
   }
   InModuleScope -ModuleName $ModuleName {
      Context "Check calls to private function" -Tag Unit {
         BeforeAll {
            Mock Invoke-SetACL { $null }
            $PermObject = New-FMPermission -Identity foo -Permission Read -Inheritance ThisFolderOnly

         }
         It "Should call invoke-SetACL once" {
            Set-Permission $Testdrive -Identity foo -Permission Read -Inheritance ThisFolderOnly
            Should -Invoke Invoke-SetACL -Times 1
         }
         It "Should call Invoke-SetACL twice - two FSPM objects (like in directory object" {
            $FMP = New-FMPathPermission -Path $Testdrive -InputObject $PermObject
            Set-Permission -PathPermissionObject $FMP, $FMP -PassThru
            Should -Invoke Invoke-SetACL -Times 2
         }
      }#end context
      Context "Check private function 'Invoke-SetACL'" -Tag Unit {
         BeforeAll{
            $PermObject = New-FMPermission -Identity foo -Permission Read -Inheritance ThisFolderOnly

         }
         It "Should throw if path doesn't exists" {
            $FMP = New-FMPathPermission -Path C:\gfhrdd33 -InputObject $PermObject
            { Set-Permission -PathPermissionObject $FMP } | Should -Throw "Cannot find path*"
         }
      }
   }#end inmodulescope
}#end describe set-permission

<#
   - check all parameters
      - parameter set recognition
      - missing params
#>