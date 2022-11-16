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
      It "helper function returns correct object - paramset one FMPermission" {
         $result = New-FMPathPermission -Path C:\Temp -InputObject (New-FMPermission -Id 'foo' -Perm 'Modify' -Inh 'ThisFolderOnly')
         $result.Path | Should -Be "C:\Temp"
         $result.Permission.Identity | Should -Be "foo"
         $result.Permission.Permission | Should -Be "Modify"
         $result.Permission.Inheritance | Should -Be "ThisFolderOnly"
      }
   }#end context
}