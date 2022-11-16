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
         {New-FMPathPermission -Path C:\Temp -Identity 'foo' -Permission 'Write' -Inheritance 'ThisFolderOnly'}  | Should -Not -Throw
      }
      It 'checks for correct object being returned' {
         (New-FMPathPermission -Path C:\Temp -Identity 'foo' -Permission 'Write' -Inheritance 'ThisFolderOnly').Gettype() | Should -Be 'FMPathPermission'
      }
      It 'checks for correct object being returned - one path' {
         $Result=New-FMPathPermission -Path C:\Temp -Identity 'foo' -Permission 'Write' -Inheritance 'ThisFolderOnly'
         $result.Path | Should -Be 'C:\Temp'
         $result.Permission.Count | Should -be 1
         $result.Permission.Identity | Should -Be "foo"
         $result.Permission.Permission | Should -Be "Write"
         $result.Permission.Inheritance | Should -Be "ThisFolderOnly"
      }
      It 'checks for correct object being returned - two path' {
         $Result=New-FMPathPermission -Path C:\Temp,D:\Temp -Identity foo -Permission Write -Inheritance ThisFolderOnly
         $result.Path | Should -Be ('C:\Temp','D:\Temp')
         $result.Permission.Count | Should -be 1
         $result.Permission.Identity | Should -Be "foo"
         $result.Permission.Permission | Should -Be "Write"
         $result.Permission.Inheritance | Should -Be "ThisFolderOnly"
      }
      It "Should fail if parameter counts don't match" {
{New-FMPathPermission -Path C:\Temp,D:\Temp -Identity foo -Permission Write,Read -Inheritance ThisFolderOnly} | Should -Throw "Counts of identities*"
      }
      It "checks for correct object being returned - two permissions" {
         $Result=New-FMPathPermission -Path C:\Temp -Identity foo,bar -Permission Write,Read -Inheritance ThisFolderFiles,ThisFolderOnly
         $Result.Permission.Count | Should -be 2
         $result.Permission.Identity | Should -Be ('foo', 'bar')
         $result.Permission.Permission | Should -Be ('Write', 'Read')
         $result.Permission.Inheritance | Should -Be ("ThisFolderFiles", "ThisFolderOnly")
      }
      It "checks for correct object being returned - two permissions, two paths" {
         $Result=New-FMPathPermission -Path C:\Temp,D:\Temp -Identity foo,bar -Permission Write,Read -Inheritance ThisFolderFiles,ThisFolderOnly
         $Result.Permission.Count | Should -be 2
         $result.Permission.Identity | Should -Be ('foo', 'bar')
         $result.Permission.Permission | Should -Be ('Write', 'Read')
         $result.Permission.Inheritance | Should -Be ("ThisFolderFiles", "ThisFolderOnly")
      }
   }#end context
}