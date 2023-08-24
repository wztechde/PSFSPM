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
Describe 'Set-Permission' -Tag Unit {
   BeforeAll {
      New-LocalUser Pester1 -NoPassword
      New-LocalUser Pester2 -NoPassword
      New-LocalUser Pester3 -NoPassword
      New-LocalGroup GPester1 -Description 'Pester Group 1'
      New-LocalGroup GPester2 -Description 'Pester Group 2'
      Add-LocalGroupMember -Group GPester1 -Member Pester1
      Add-LocalGroupMember -Group GPester2 -Member Pester2
      # Create folder strukture
      $F_Foo = mkdir "$TestDrive\foo" -Force
      New-Item -Path $F_Foo -Name 'Testfile.txt' -ItemType File
      $F_Bar = mkdir "$TestDrive\foo\bar" -Force
      $F_Clara = mkdir "$TestDrive\foo\bar\clara" -Force
      $Perm1 = New-FMPermission -Identity pester1 -FileRight Read -Inheritance ThisFolderSubfoldersAndFiles
   }# BeforeAll

   AfterAll {
      Remove-LocalUser Pester1, Pester2, Pester3
      Remove-LocalGroup Gpester1, GPester2
   }# AfterAll

   Context 'Function call' -Tag Unit {
      It 'Checks if function is available after module import' {
         { Set-Permission -Path $F_Foo -PermissionObject $Perm1 } | Should -Not -Throw '*is not recognized as the name*'
      }#end it
      It 'Checks if help exists' {
         { Get-Help Set-Permission } | Should -Not -Throw '*in a help file in this session*'
      }
   }#end context function call
   Context 'Parameter check - path' -Tag Unit {
      It 'Should prompt, if path is missing and error when pass is empty' {
         { Set-Permission -Path $F_Foo -PermissionObject $PermObject } | Should -Throw 'Cannot validate argument on parameter*'
      }
      It 'Should return error, when param is no filesystemobject' {
         { Set-Permission -Path 'Throw' } | Should -Throw "Cannot validate argument on parameter 'Path'*"
      }
      It 'Should not fail if path is filesystemobject' {
         { Set-Permission -Path $F_Foo -PermissionObject $Perm1 } | Should -Not -Throw
         { Set-Permission -Path "$F_Foo\Testfile.txt" -PermissionObject $Perm1 } | Should -Not -Throw
      }
      It 'Can take parameter from pipeline' {
         { $TestDrive | Set-Permission -PermissionObject $Perm1 } | Should -Not -Throw
      }
      It 'Can take several parameter(s) from pipeline' {
         { "$F_Foo\Testfile.txt" | Set-Permission -PermissionObject $Perm1 } | Should -Not -Throw
      }
      It "Should throw if parameter doesn't fit expected type 'FileRight'" {
         { Set-Permission -Path $TestDrive -Identity foo -FileRight ready -Inheritance NotGiven -Verbose} | Should -Throw "Cannot process argument transformation on parameter 'FileRight'*"
      }
      It "Should throw if parameter doesn't fit expected type 'Inheritance'" {
         { Set-Permission -Path $TestDrive -Identity foo -FileRight read -Inheritance NotGiven -Verbose } | Should -Throw "Cannot process argument transformation on parameter 'Inheritance'*"
      }
      It "Should throw if parameter doesn't fit expected type 'PermissionObject'" {
         { Set-Permission -Path $TestDrive -PermissionObject 'Willi' } | Should -Throw "Cannot process argument transformation on parameter 'PermissionObject'*"
      }
      It "Should allow an array of 'PermissionObject'" {
         { Set-Permission -Path $TestDrive -PermissionObject $Perm1, $Perm1 } | Should -Not -Throw
      }
      It "Should throw if parameter doesn't fit expected type 'PathPermissionObject'" {
         { Set-Permission -Path $TestDrive -PathPermissionObject 'Willi' } | Should -Throw "Cannot process argument transformation on parameter 'PathPermissionObject'*"
      }
      It "Should allow an array of 'PathPermissionObject'" {
         $FMPP1 = New-FMPathPermission -Path $TestDrive -InputObject $Perm1
         $FMPP2 = New-FMPathPermission -Path $TestDrive -InputObject $Perm1
         { Set-Permission -PathPermissionObject $FMPP1, $FMPP2 } | Should -Not -Throw
      }
   }#end context param path
   Context 'Parameter check for default parameter set' -Tag Unit {
      It 'Check if parameter counts correlate' {
         { Set-Permission -Path $TestDrive -Identity foo,bar -FileRight 'Modify' -Inheritance 'ThisFolderSubfoldersAndFiles' } |
            Should -Throw 'Counts of identities*'
      }
   }#end Context
   Context 'check inner parameter transformation to FMPathPermission' -Tag Unit {
      It 'Should return a FMPathPermission object, when fed with default data' {
         $result = Set-Permission $Testdrive -Identity pester1 -FileRight 'Read' -Inheritance ThisFolderOnly -Passthru
         $result[0].gettype() | Should -Be 'FMPathPermission'
      }
      It 'Should return a FMPathPermission object, when fed with Permission' {
         $result = Set-Permission $Testdrive -PermissionObject $Perm1 -PassThru
         $result[0].gettype() | Should -Be 'FMPathPermission'
      }
      It 'Should return a FMPathPermission object, when fed with PathPermission' {
         $FMP = New-FMPathPermission -Path $F_Foo -InputObject $Perm1
         $result = Set-Permission -PathPermissionObject $FMP -PassThru
         $result[0].gettype() | Should -Be 'FMPathPermission'
      }
      It "Paramset 'Default' - should return FMPP array when fed with multiple data" {
         $result = Set-Permission $Testdrive -Identity pester1, pester2 -FileRight 'Write','Read' -Inheritance ThisFolderOnly, ThisFolderAndFiles -PassThru
         $result[0].gettype() | Should -Be 'FMPathPermission'
         $result[0].Permission.Count | Should -Be 2
      }
   }
}#end describe set-permission
