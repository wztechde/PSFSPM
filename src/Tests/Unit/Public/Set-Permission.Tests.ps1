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
InModuleScope -ModuleName $ModuleName {
   Describe 'Set-Permission1' -Tag Unit {
      BeforeAll {
         Mock AddAccess -MockWith { Get-ACL $TestDrive }
         $PermObject = New-FMPermission -Identity foo -Permission Read -Inheritance ThisFolderOnly
      }
      Context 'Function call' -Tag Unit {
         It 'Checks if function is available after module import' {
            Mock AddAccess {}
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
            New-Item -Path $TestDrive -Name 'foo.txt' -ItemType File -Force -ErrorAction SilentlyContinue
            { Set-Permission -Path $TestDrive -PermissionObject $PermObject } | Should -Not -Throw
            { Set-Permission -Path "$TestDrive\foo.txt" -PermissionObject $PermObject } | Should -Not -Throw
         }
         It 'Should not fail, if several valid paths are given' {
            Mock Set-ACL {} -ModuleName $ModuleName
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
            { Set-Permission -Path $TestDrive -Identity foo -Permission ready -Inheritance NotGiven } | Should -Throw "Cannot process argument transformation on parameter 'Permission'*"
         }
         It "Should throw if parameter doesn't fit expected type 'Inheritance'" {
            { Set-Permission -Path $TestDrive -Identity foo -Permission read -Inheritance NotGiven } | Should -Throw "Cannot process argument transformation on parameter 'Inheritance'*"
         }
         It "Should throw if parameter doesn't fit expected type 'PermissionObject'" {
            { Set-Permission -Path $TestDrive -PermissionObject "Willi" } | Should -Throw "Cannot process argument transformation on parameter 'PermissionObject'*"
         }
         It "Should allow an array of 'PermissionObject'" {
            { Set-Permission -Path $TestDrive -PermissionObject $PermObject, $PermObject } | Should -Not -Throw
         }
         It "Should throw if parameter doesn't fit expected type 'PathPermissionObject'" {
            { Set-Permission -Path $TestDrive -PathPermissionObject "Willi" } | Should -Throw "Cannot process argument transformation on parameter 'PathPermissionObject'*"
         }
         It "Should allow an array of 'PathPermissionObject'" {
            $FMPP1 = New-FMPathPermission -Path $TestDrive -InputObject $PermObject
            $FMPP2 = New-FMPathPermission -Path $TestDrive -InputObject $PermObject
            { Set-Permission -PathPermissionObject $FMPP1, $FMPP2 } | Should -Not -Throw
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
            $result[0].gettype() | Should -Be "FMPathPermission"
         }
         It "Should return a FMPathPermission object, when fed with Permission" {
            $result = Set-Permission $Testdrive -PermissionObject $PermObject -PassThru
            $result[0].gettype() | Should -Be "FMPathPermission"
         }
         It "Should return a FMPathPermission object, when fed with PathPermission" {
            $FMP = New-FMPathPermission -Path $Testdrive -InputObject $PermObject
            $result = Set-Permission -PathPermissionObject $FMP -PassThru
            $result[0].gettype() | Should -Be "FMPathPermission"
         }
         It "Paramset 'Default' - should return FMPP array when fed with multiple data" {
            $result = Set-Permission $Testdrive -Identity foo, bar -Permission Write, Read -Inheritance ThisFolderOnly, ThisFolderAndFiles -PassThru
            $result[0].gettype() | Should -Be "FMPathPermission"
            $result[0].Permission.Count | Should -Be 2
         }
      }
      Context "Check calls to private function" -Tag Unit {
         BeforeAll {
            Mock Invoke-SetACL { $null }
            $PermObject = New-FMPermission -Identity foo -Permission Read -Inheritance ThisFolderOnly

         }
         It "Should call invoke-SetACL once" {
            Set-Permission $Testdrive -Identity foo -Permission Read -Inheritance ThisFolderOnly
            Should -Invoke Invoke-SetACL -Times 1
         }
         It "Should call Invoke-SetACL twice - two FSPM objects (like in directory object)" {
            $FMP = New-FMPathPermission -Path $Testdrive -InputObject $PermObject
            Set-Permission -PathPermissionObject $FMP, $FMP -PassThru
            Should -Invoke Invoke-SetACL -Times 2
         }
      }#end context
      Context "Check private function 'Invoke-SetACL'" -Tag Unit {
         BeforeAll {
            $PermObject = New-FMPermission -Identity foo -Permission Read -Inheritance ThisFolderOnly

         }
         It "Should throw if path doesn't exists" {
            $FMP = New-FMPathPermission -Path C:\gfhrdd33 -InputObject $PermObject
            { Set-Permission -PathPermissionObject $FMP } | Should -Throw "Cannot find path*"
         }
         It "Test whatif functionnality by measuring private function calls - invoke-setacl" {
            Mock Invoke-SetACL {}
            $FMP = New-FMPathPermission -Path $TestDrive -InputObject $PermObject
            Set-Permission -PathPermissionObject $FMP -WhatIf
            Should -Invoke -CommandName Invoke-SetACL -Times 1
         }
         It "checks if wrapper function for SetAccessRule is called" {
            Mock SetAccessRuleProtection { Get-ACL $TestDrive }
            Mock Set-ACL {}
            $FMP = New-FMPathPermission -Path $TestDrive -InputObject $PermObject
            Set-Permission -PathPermissionObject $FMP
            Should -Invoke -CommandName SetAccessRuleProtection -Times 1
         }
         It "checks if AddAccess is called " {
            $DBG_SAVE=$DebugPreference
            $DebugPreference="Continue"
            Mock -CommandName "AddAccess" {}
            Mock SetAccessRuleProtection { Get-ACL $testDrive }
            $FMP = New-FMPathPermission -Path $TestDrive -InputObject $PermObject
            Set-Permission -PathPermissionObject $FMP -verbose
            Should -Invoke -CommandName AddAccess -Times 1
            $DebugPreference=$DBG_SAVE
         }
         It "checks if Set-ACL is NOT called when '-Whatif' is given" {
            Mock -CommandName "Set-ACL" {}
            Mock SetAccessRuleProtection { Get-ACL $testDrive }
            $FMP = New-FMPathPermission -Path $TestDrive -InputObject $PermObject
            Set-Permission -PathPermissionObject $FMP -whatif
            Should -Invoke -CommandName Set-ACL -Times 0
         }
      }
   }#end describe set-permission
}#inModuleScope
<#
   - check all parameters
      - parameter set recognition
      - missing params
#>