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
Describe 'Set-Permission' -Tag Unit {
   Context 'Function call' -Tag Unit {
      It "Checks if function is available after module import" {
          {Set-Permission} | Should -Not -Throw "*wurde nicht als Name*"
      }
      It "Checks if help exists" {
          {Get-Help Set-Permission} | Should -Not -Throw "*in dieser Sitzung von Get-Help nicht gefunden*"
      }
   }#end context function call
}#end describe set-permission