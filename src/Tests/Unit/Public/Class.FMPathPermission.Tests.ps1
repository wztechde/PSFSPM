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
   # Import custom assertions
   $Temp = "$PSScriptRoot\..\.."
   $PathToCustomAssertions = Resolve-Path "$temp\CustomAssertions.psm1"
   Remove-Module $PathToCustomAssertions -Force -ErrorAction SilentlyContinue
   Import-Module $PathToCustomAssertions -Force
   #-------------------------------------------------------------------------
}
Describe 'FMPathPermission' -Tag Unit {
   Context 'New-FMPathPermission - basic class checks' {
      It "Should have parameters 'Path' and 'InputObject', 'Inheritance', 'FileRight', and 'Identity'" {
         Get-Command New-FMPathPermission | Should -HaveParameter Path
         Get-Command New-FMPathPermission | Should -HaveParameter InputObject
         Get-Command New-FMPathPermission | Should -HaveParameter Inheritance
         Get-Command New-FMPathPermission | Should -HaveParameter FileRight
         Get-Command New-FMPathPermission | Should -HaveParameter Identity
      }#end it
      It "Should throw if parameter sets don't match: Parameterset 'Default'" {
         $test = New-FMPermission -Identity 'test' -FileRight 'Read' -Inheritance 'ThisFolderOnly'
         { New-FMPathPermission -Path 'C:\Temp' -FileRight 'Read' -Inheritance 'ThisFolderOnly' -Identity 'test' -InputObject $test } | Should -Throw "Parameter set cannot be resolved using the specified named parameters*"
      }#end it
      It 'Should return a FMPathPermission object' {
         $result = New-FMPathPermission -Path 'C:\Temp' -FileRight 'Read' -Inheritance 'ThisFolderOnly' -Identity 'test'
         $result.Gettype() | Should -Be 'FMPathPermission'
      }#end it
   }#end context
}#end describe