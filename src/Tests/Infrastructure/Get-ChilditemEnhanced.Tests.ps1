BeforeAll {
   #-------------------------------------------------------------------------
   Set-Location -Path $PSScriptRoot
   #-------------------------------------------------------------------------
   $ModuleName = 'PSFSPM'
   #-------------------------------------------------------------------------
   #if the module is already in memory, remove it
   Get-Module $ModuleName | Remove-Module -Force
   $PathToManifest = [System.IO.Path]::Combine('..', '..', $ModuleName, "$ModuleName.psd1")
   #$PathToManifest = [System.IO.Path]::Combine('..', '..', 'Artifacts', "$ModuleName.psd1")
   #-------------------------------------------------------------------------
   Import-Module $PathToManifest -Force
   #-------------------------------------------------------------------------
   # import additional test-helpers
   $PathToHelpers = [System.IO.Path]::Combine('..','TestHelpers.psm1')
   Import-Module $PathToHelpers -Force
   $PathToCustoms = [System.IO.Path]::Combine('..','CustomAssertions.psm1')
   Import-Module $PathToCustoms -Force
}
Describe 'Get-ChilditemEnhanced' -Tag Integration {
   Context 'Test additional parameters' -Tag Integration {
      BeforeAll {
         # create directory structure
         $null = New-Item -Path "$TestDrive\Folder1" -Name 'Werver' -ItemType Directory -Force
         $null = New-Item -Path "$TestDrive\Folder1\Folder11" -Name 'F11_SF1' -ItemType Directory -Force
         $null = New-Item -Path "$TestDrive\Folder1\Folder11" -Name 'F11_SF2' -ItemType Directory -Force
         $null = New-Item -Path "$TestDrive\Folder2" -Name 'F2_SF1' -ItemType Directory -Force
         $null = New-Item -Path "$TestDrive\Folder2" -Name 'F2_SF2' -ItemType Directory -Force
         $null = New-Item -Path "$TestDrive\Folder2\F2_SF2" -Name 'Test.txt' -ItemType File -Force
      }
      It 'Should automatically add recurse, when -StartDepth given' -Tag Unit {
         $Result = Get-ChildItemEnhanced -Path $TestDrive -StartDepth 2
         $Result2 = Get-ChildItemEnhanced -Path $TestDrive -StartDepth 2 -Recurse
         ArrayDifferences -actual $result -expected $Result2 | Should -BeNullOrEmpty
      }
      It 'Should contain the hierarchy 1 folders' {
         $Result = Get-ChildItemEnhanced -Path $TestDrive -StartDepth 1
         $Result[0].Name | Should -Be 'Folder1'
         $Result[1].Name | Should -Be 'Folder2'
      }
      It 'Should contain the hierarchy 2 folders' {
         $Result = Get-ChildItemEnhanced -Path $TestDrive -StartDepth 2
         $Result.Name | Should -Contain 'Werver'
         $Result.Name | Should -Contain 'Folder11'
         $Result.Name | Should -Contain 'F2_SF1'
         $Result.Name | Should -Contain 'F2_SF2'
         $Result.Name.Count | Should -Be 4
      }
      It 'Should contain the hierarchy 3 folders and files' {
         $Result = Get-ChildItemEnhanced -Path $TestDrive -MinimumDepth 3
         $Result[0].Name | Should -Be 'F11_SF1'
         $Result[1].Name | Should -Be 'F11_SF2'
         $Result[2].Name | Should -Be 'Test.txt'
         $Result.Name.Count | Should -Be 3
      }
   }
}
