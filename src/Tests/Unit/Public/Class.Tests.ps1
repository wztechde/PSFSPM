BeforeAll {
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
   #-------------------------------------------------------------------------
}
Describe 'Class-Tests' -Tag Unit {
   Context 'Class FMPermission' -Tag Unit {
      It 'verify that helper function exists' {
         { New-FMPermission -identity 'foo' -permi 'Modify' -inh 'ThisFolderOnly' } | Should -Not -Throw "*is not recognized"
      }
      It 'checks for correct object being returned' {
        (New-FMPermission -ide 'foo' -perm 'Modify' -inh 'ThisFolderOnly').GetType() | Should -Be 'FMPermission'
      }
   }#end Context
   Context 'Class FMPermission - helper function' -Tag Unit {
      It 'checks for members of returned object' {
         $result = New-FMPermission -Identity 'foo' -Permission 'Modify' -Inheritance 'ThisFolderOnly'
         $result.Identity | Should -Be 'foo'
         $result.Permission | Should -Be 'Modify'
         $result.Inheritance | Should -Be 'ThisFolderOnly'
         $result.GetInheritance().Propagate | Should -Be 'None'
         $result.GetInheritance().Inherit | Should -Be 'None'
      }
   }#end context
   Context "Class FMPathPermission" -Tag Unit {
      It "verify that helper function exists" {
         { New-FMPathPermission -Path C:\Temp -InputObject (New-FMPermission -Id 'foo' -Perm 'Modify' -Inh 'ThisFolderOnly') } | Should -Not -Throw "*is not recognized"
      }
      It 'checks for correct object being returned' {
         (New-FMPathPermission -Path C:\Temp -InputObject (New-FMPermission -Id 'foo' -Perm 'Modify' -Inh 'ThisFolderOnly')).Gettype() | Should -Be 'FMPathPermission'
      }
   }#end Context
   Context 'Class FMPathPermission - helper function - paramset [InputObject]' -Tag Unit {
      It "checks correct object being returned - one FMPermission" {
         $Permission = New-FMPermission -Id 'foo' -Perm 'Modify' -Inh 'ThisFolderOnly'
         $result = New-FMPathPermission -Path C:\Temp -InputObject $Permission
         $result.Path | Should -Be "C:\Temp"
         $result.Permission.Count | Should -be 1
         $result.Permission.Identity | Should -Be "foo"
         $result.Permission.Permission | Should -Be "Modify"
         $result.Permission.Inheritance | Should -Be "ThisFolderOnly"
      }
      It "checks correct object being returned - two FMPermission" {
         $Permission = (New-FMPermission -Id 'foo' -Perm 'Modify' -Inh 'ThisFolderOnly'),
         (New-FMPermission -Id 'bar' -Perm 'Write' -Inh 'ThisFolderSubfoldersAndFiles')
         $result = New-FMPathPermission -Path C:\Temp -InputObject $Permission
         $result.Path | Should -Be "C:\Temp"
         $result.Permission.Count | Should -be 2
         $result.Permission.Identity | Should -Be ('foo', 'bar')
         $result.Permission.Permission | Should -Be ('Modify', 'Write')
         $result.Permission.Inheritance | Should -Be ("ThisFolderOnly", "ThisFolderSubfoldersAndFiles")
      }
   }#end context
   Context 'Class FMPathPermission - helper function - paramset [Default]' -Tag Unit {
      It "verify that helper funtion parameterset 'default' exists" {
         { New-FMPathPermission -Path C:\Temp -Identity 'foo' -Permission 'Write' -Inheritance 'ThisFolderOnly' }  | Should -Not -Throw
      }
      It 'checks for correct object being returned' {
         (New-FMPathPermission -Path C:\Temp -Identity 'foo' -Permission 'Write' -Inheritance 'ThisFolderOnly').Gettype() | Should -Be 'FMPathPermission'
      }
      It 'checks for correct object being returned - one path' {
         $Result = New-FMPathPermission -Path C:\Temp -Identity 'foo' -Permission 'Write' -Inheritance 'ThisFolderOnly'
         $result.Path | Should -Be 'C:\Temp'
         $result.Permission.Count | Should -be 1
         $result.Permission.Identity | Should -Be "foo"
         $result.Permission.Permission | Should -Be "Write"
         $result.Permission.Inheritance | Should -Be "ThisFolderOnly"
      }
      It 'checks for correct object being returned - two path' {
         $Result = New-FMPathPermission -Path C:\Temp, D:\Temp -Identity foo -Permission Write -Inheritance ThisFolderOnly
         $result.Path | Should -Be ('C:\Temp', 'D:\Temp')
         $result.Permission.Count | Should -be 1
         $result.Permission.Identity | Should -Be "foo"
         $result.Permission.Permission | Should -Be "Write"
         $result.Permission.Inheritance | Should -Be "ThisFolderOnly"
      }
      It "Should fail if parameter counts don't match" {
         { New-FMPathPermission -Path C:\Temp, D:\Temp -Identity foo -Permission Write, Read -Inheritance ThisFolderOnly } | Should -Throw "Counts of identities*"
      }
      It "checks for correct object being returned - two permissions" {
         $Result = New-FMPathPermission -Path C:\Temp -Identity foo, bar -Permission Write, Read -Inheritance ThisFolderAndFiles, ThisFolderOnly
         $Result.Permission.Count | Should -be 2
         $result.Permission.Identity | Should -Be ('foo', 'bar')
         $result.Permission.Permission | Should -Be ('Write', 'Read')
         $result.Permission.Inheritance | Should -Be ("ThisFolderAndFiles", "ThisFolderOnly")
      }
      It "checks for correct object being returned - two permissions, two paths" {
         $Result = New-FMPathPermission -Path C:\Temp, D:\Temp -Identity foo, bar -Permission Write, Read -Inheritance ThisFolderAndFiles, ThisFolderOnly
         $Result.Permission.Count | Should -be 2
         $result.Permission.Identity | Should -Be ('foo', 'bar')
         $result.Permission.Permission | Should -Be ('Write', 'Read')
         $result.Permission.Inheritance | Should -Be ("ThisFolderAndFiles", "ThisFolderOnly")
      }
   }#end context
   Context "Class FMPathPermission - method GFSAR" -Tag Unit {
      BeforeAll {
         $FMPP1 = New-FMPathPermission -Path C:\Temp -Identity foo -Permission Write -Inheritance ThisFolderAndFiles
         $FMPP2 = New-FMPathPermission -Path C:\Temp -Identity bar -Permission Read -Inheritance ThisFolderOnly
         $FMPP3 = New-FMPathPermission -Path C:\Temp -Identity foo, bar -Permission Write, Read -Inheritance ThisFolderAndFiles, OnlySubfolders
      }
      It "checks, that method is accessible" {
         { $FMPP1.GetFileSystemAccessRule() } | Should -Not -Throw
      }
      It "checks for correct object being returned FMPP1" {
         $result = $FMPP1.GetFileSystemAccessRule()
         $result.count | Should -Be 1
         $result.FileSystemRights | Should -Be "Write, Synchronize"
         $result.IdentityReference | Should -Be "foo"
         $result.InheritanceFlags | Should -Be "ObjectInherit"
         $result.PropagationFlags | Should -Be "None"
      }
      It "checks for correct object being returned FMPP2" {
         $result = $FMPP2.GetFileSystemAccessRule()
         $result.count | Should -Be 1
         $result.FileSystemRights | Should -Be "Read, Synchronize"
         $result.IdentityReference | Should -Be "bar"
         $result.InheritanceFlags | Should -Be "None"
         $result.PropagationFlags | Should -Be "None"
      }
      It "checks for correct object being returned FMPP3 (2 Permissions on path)" {
         $result = $FMPP3.GetFileSystemAccessRule()
         $result.Count | Should -Be 2
         $result[0].FileSystemRights | Should -Be "Write, Synchronize"
         $result[0].IdentityReference | Should -Be "foo"
         $result[0].InheritanceFlags | Should -Be "ObjectInherit"
         $result[0].PropagationFlags | Should -Be "None"
         $result[1].FileSystemRights | Should -Be "Read, Synchronize"
         $result[1].IdentityReference | Should -Be "bar"
         $result[1].InheritanceFlags | Should -Be "ContainerInherit"
         $result[1].PropagationFlags | Should -Be "InheritOnly"
      }
   }#end context
   Context "Class FMDirectory" -Tag Unit {
      BeforeAll {
         $Root = New-FMPathPermission -Path C:\Temp -Identity foo -Permission Write -Inheritance ThisFolderAndFiles
         $Child1 = New-FMPathPermission -Path Foo -Identity foo -Permission Write -Inheritance ThisFolderAndFiles
      }
      It "checks if helper function exists" {
         { New-FMDirectory -Root $Root -Child $Child1 } | Should -Not -Throw "*is not recognized"
      }
      It "checks for correct obejct being returned" {
         (New-FMDirectory -Root $Root -Child $Child1).Gettype() | Should -Be 'FMDirectory'
      }
      It "verifies that child paths with drive information fail" {
         $Child = New-FMPathPermission -Path C:\Foo -Identity foo -Permission Write -Inheritance ThisFolderAndFiles
         { New-FMDirectory -Root $Root -Child $Child } | Should -Throw "FMDirectory - children must not contain drive information"
      }
      It "verifies that child paths with drive information fail - more children" {
         $Child = New-FMPathPermission -Path Foo -Identity foo -Permission Write -Inheritance ThisFolderAndFiles
         $Child2 = New-FMPathPermission -Path C:\Foo -Identity foo -Permission Write -Inheritance ThisFolderAndFiles
         { New-FMDirectory -Root $Root -Child $Child, $Child2 } | Should -Throw "FMDirectory - children must not contain drive information"
      }
      It "return full child path - check for method existing" {
         $Child2 = New-FMPathPermission -Path bar -Identity foo -Permission Write -Inheritance ThisFolderAndFiles
         $TestDir=New-FMDirectory -Root $Root -Child $Child1, $Child2
         { $TestDir.GetChildFullname(0) } | Should -Not -Throw "Method invocation fail*"
      }
      It "return full child path - check for correct information being returned" {
         $Child2 = New-FMPathPermission -Path bar -Identity foo -Permission Write -Inheritance ThisFolderAndFiles
         $TestDir=New-FMDirectory -Root $Root -Child $Child1, $Child2
         $result=$TestDir.GetChildFullname(0)
         $result | Should -Be "C:\Temp\Foo"
         $result=$TestDir.GetChildFullname(1)
         $result | Should -Be "C:\Temp\bar"
      }
   }
}