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
   Context 'New-FMPathPermission - Test methods' {
      Context 'Get_FileSystemAccessRule' {
         BeforeAll {
            $PM1=New-FMPermission -Identity Pester1 -FileRight 'Modify' -Inheritance ThisFolderAndFiles
            $PM2=New-FMPermission -Identity Pester1 -FileRight 'Modify' -Inheritance ThisFolderAndFiles
            $FMPP1=New-FMPathPermission -Path C:\Temp -InputObject $PM1
            $FMPP2=New-FMPathPermission -Path C:\Temp -InputObject $PM1,$PM2
         }
         It 'Should return the correct object' {
            $FMPP1.Get_FileSystemAccessRule() | Should -BeOfType [System.Security.AccessControl.FileSystemAccessRule]
         }
         It 'Should return an array of FileSystemRight' {
            $result=$FMPP2.Get_FileSystemAccessRule()
            $result -is [array] | Should -BeTrue
            $result.count | Should -be 2
            $result[0] |Should -BeOfType [System.Security.AccessControl.FileSystemAccessRule]
            $result[1] |Should -BeOfType [System.Security.AccessControl.FileSystemAccessRule]
         }
      }
   }
}#end describe