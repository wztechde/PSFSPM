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
Describe "Import-Tests" -Tag Unit {
   Context "Class FMPermission" -Tag Unit {
      It "creates new object using constructor" {
        {New-FMPermission -id "foo" -pm "Modify" -inh "ThisFolderOnly"} | Should -Not -Throw
      }
      It "checks for correct object being returned" {
        (New-FMPermission -id "foo" -pm "Modify" -inh "ThisFolderOnly").GetType() | Should -Be "FMPermission"
      }
      It "checks for members of returned object" {
         $result =  New-FMPermission -id "foo" -pm "Modify" -inh "ThisFolderOnly"
         $result.Identity| Should -Be "foo"
         $result.Permission| Should -Be "Modify"
         $result.Inheritance| Should -Be "ThisFolderOnly"
         $result.GetInheritance().Propagate | Should -Be "None"
         $result.GetInheritance().Inherit | Should -Be "None"
    }
   }
}