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
   Context 'Class FMPermission - method Get_ExplicitInheritance' -Tag Unit {
      It 'checks for members of returned object' {
         $result = New-FMPermission -Identity 'foo' -Permission 'Modify' -Inheritance 'ThisFolderOnly'
         $result.Identity | Should -Be 'foo'
         $result.Permission | Should -Be 'Modify'
         $result.Inheritance | Should -Be 'ThisFolderOnly'
         $result.Get_ExplicitInheritance().Propagate | Should -Be 'None'
         $result.Get_ExplicitInheritance().Inherit | Should -Be 'None'
      }
   }#end context
   Context "Class FMPermission - method Get_FileSystemAccessRule" -Tag Unit {
      BeforeAll {
         $FMP1 = New-FMPermission -Identity foo -Permission Write -Inheritance ThisFolderAndFiles
         $FMP2 = New-FMPermission -Identity bar -Permission Read -Inheritance ThisFolderOnly
      }
      It "checks, that method is accessible" {
         { $FMP1.Get_FileSystemAccessRule() } | Should -Not -Throw
      }
      It "checks for correct object being returned FMP1" {
         $result = $FMP1.Get_FileSystemAccessRule()
         $result.count | Should -Be 1
         $result.FileSystemRights | Should -Be "Write, Synchronize"
         $result.IdentityReference | Should -Be "foo"
         $result.InheritanceFlags | Should -Be "ObjectInherit"
         $result.PropagationFlags | Should -Be "None"
      }
      It "checks for correct object being returned FMP2" {
         $result = $FMP2.Get_FileSystemAccessRule()
         $result.count | Should -Be 1
         $result.FileSystemRights | Should -Be "Read, Synchronize"
         $result.IdentityReference | Should -Be "bar"
         $result.InheritanceFlags | Should -Be "None"
         $result.PropagationFlags | Should -Be "None"
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
   Context 'Class FMPathPermission - paramset [InputObject]' -Tag Unit {
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
         $pm1 = New-FMPermission -Id 'foo' -Perm 'Modify' -Inh 'ThisFolderOnly'
         $pm2 = New-FMPermission -Id 'bar' -Perm 'Read' -Inh 'File'
         $result = New-FMPathPermission -Path C:\Temp -InputObject $pm1, $pm2
         $result.Path | Should -Be "C:\Temp"
         $result.Permission.Count | Should -be 2
         $result.Permission[0].Identity | Should -Be "foo"
         $result.Permission[0].Permission | Should -Be "Modify"
         $result.Permission[0].Inheritance | Should -Be "ThisFolderOnly"
         $result.Permission[1].Identity | Should -Be "bar"
         $result.Permission[1].Permission | Should -Be "Read"
         $result.Permission[1].Inheritance | Should -Be "File"
      }
   }#end context
   Context 'Class FMPathPermission - paramset [Default]' -Tag Unit {
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
      It "checks for correct object being returned - two permissions" {
         $Result = New-FMPathPermission -Path C:\Temp -Identity foo, bar -Permission Write, Read -Inheritance ThisFolderAndFiles, ThisFolderOnly
         $Result.Permission.Count | Should -be 2
         $result.Permission.Identity | Should -Be ('foo', 'bar')
         $result.Permission.Permission | Should -Be ('Write', 'Read')
         $result.Permission.Inheritance | Should -Be ("ThisFolderAndFiles", "ThisFolderOnly")
      }
   }#end context
   Context 'Class FMPathPermission - method Get_FileSystemAccessRule' -Tag Unit {
      It 'checks that method is available' {
         $FMPP = New-FMPathPermission -Path C:\Temp -Identity 'foo' -Permission 'Write' -Inheritance 'ThisFolderOnly'
         { $FMPP.Get_FileSystemAccessRule() } | Should -Not -Throw
      }

      It 'Checks for correct result with one permission object' {
         $FMPP = New-FMPathPermission -Path C:\Temp -Identity 'foo' -Permission 'Write' -Inheritance 'ThisFolderOnly'
         $result = $FMPP.Get_FileSystemAccessRule()
         $result.count | Should -Be 1
         $result.FilesystemRights | Should -be "Write, Synchronize"
         $result.IdentityReference | Should -Be "foo"
         $result.InheritanceFlags | Should -Be "None"
         $result.PropagationFlags | Should -Be "None"
      }
      It 'Checks for correct result with one permission object' {
         $FMPP = New-FMPathPermission -Path C:\Temp -Identity 'foo', 'bar' -Permission 'Write', 'read' -Inheritance 'ThisFolderOnly', 'FilesOnly'
         $result = $FMPP.Get_FileSystemAccessRule()
         $result.count | Should -Be 2
         $result[0].FilesystemRights | Should -be "Write, Synchronize"
         $result[0].IdentityReference | Should -Be "foo"
         $result[0].InheritanceFlags | Should -Be "None"
         $result[0].PropagationFlags | Should -Be "None"
         $result[1].FilesystemRights | Should -be "Read, Synchronize"
         $result[1].IdentityReference | Should -Be "bar"
         $result[1].InheritanceFlags | Should -Be "ObjectInherit"
         $result[1].PropagationFlags | Should -Be "InheritOnly"
      }
   }
   Context 'Class FMPathPerimssion - method Set_Access' -Tag Unit {
      # prerequisites
      BeforeAll {
         New-LocalUser Pester1 -NoPassword
         New-LocalGroup GPester1 -Description 'Pester Group 1'
         Add-LocalGroupMember -Group GPester1 -Member Pester1
         # Create folder strukture
         $F_Foo = mkdir "$TestDrive\foo" -Force
         $F_Bar = mkdir "$TestDrive\foo\bar" -Force
         $F_Clara = mkdir "$TestDrive\foo\bar\clara" -Force
      }

      AfterAll {
         Remove-LocalUser Pester1
         Remove-LocalGroup Gpester1
      }

      It 'Should return correct object - test1' {
         Mock Set-Acl { Get-Acl }
         $FMPP = New-FMPathPermission -Path $Testdrive -Identity pester1 -Permission 'Write' -Inheritance 'ThisFolderOnly'
         $result = $FMPP.Set_Access()
         $ID = $result.Access | Where-Object { $_.IdentityReference -match 'pester1'}
         $ID.FileSystemRights | Should -Be 'Write, Synchronize'
         $ID.AccessControlType | Should -Be 'Allow'
      }
   }
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
         $TestDir = New-FMDirectory -Root $Root -Child $Child1, $Child2
         { $TestDir.GetChildFullname(0) } | Should -Not -Throw "Method invocation fail*"
      }
      It "return full child path - check for correct information being returned" {
         $Child2 = New-FMPathPermission -Path bar -Identity foo -Permission Write -Inheritance ThisFolderAndFiles
         $TestDir = New-FMDirectory -Root $Root -Child $Child1, $Child2
         $result = $TestDir.GetChildFullname(0)
         $result | Should -Be "C:\Temp\Foo"
         $result = $TestDir.GetChildFullname(1)
         $result | Should -Be "C:\Temp\bar"
      }
   }
}