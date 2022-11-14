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
   #init dummy vars
   $PermObject = "foo"
   #-------------------------------------------------------------------------
}

Describe 'Set-Permission' -Tag Unit {
   Context 'Function call' -Tag Unit {
      It 'Checks if function is available after module import' {
         { Set-Permission -Path $TestDrive -PermissionObject $PermObject } | Should -Not -Throw '*is not recognized as the name*'
      }#end it
      It 'Checks if help exists' {
         { Get-Help Set-Permission } | Should -Not -Throw '*in a help file in this session*'
      }
   }#end context function call
   Context 'Parameter check - path' -Tag Unit {
      It 'Should prompt, if path is missing and error when pass is empty' {
         { Set-Permission -Path "" -PermissionObject $PermObject } | Should -Throw "* Cannot bind argument to parameter 'Path'*"
      }
      It 'Should return error, when param is no filesystemobject' {
         { Set-Permission -Path 'Throw' } | Should -Throw "Cannot validate argument on parameter 'Path'*"
      }
      It 'Should not fail if path is filesystemobject' {
         New-Item -Path $TestDrive -Name 'foo.txt' -ItemType File
         { Set-Permission -Path $TestDrive -PermissionObject $PermObject} | Should -Not -Throw
         { Set-Permission -Path "$TestDrive\foo.txt" -PermissionObject $PermObject} | Should -Not -Throw
      }
      It 'Should not fail, if several valid paths are given' {
         New-Item -Path $TestDrive -Name 'foo.txt' -ItemType File -Force
         { Set-Permission -Path $TestDrive, $TestDrive -PermissionObject $PermObject} | Should -Not -Throw
         { Set-Permission -Path $TestDrive, "$TestDrive\foo.txt" -PermissionObject $PermObject} | Should -Not -Throw
      }
      It 'Should fail, if several paths are given and at least one is invalid' {
         { Set-Permission -Path $TestDrive, 'foo' -PermissionObject $PermObject} | Should -Throw '*Path * is not valid'
      }
      It 'Can take parameter from pipeline' {
         {$TestDrive | Set-Permission -PermissionObject $PermObject} | Should -Not -Throw
      }
      It 'Can take several parameter(s) from pipeline' {
         {$TestDrive,"$TestDrive\foo.txt" | Set-Permission -PermissionObject $PermObject} | Should -Not -Throw
      }

   }#end context param path
   Context 'Parameter check for default parameter set' -Tag Unit {
      It "Check if parameter counts correlate" {
         {Set-Permission -Path $TestDrive -Identity $PermObject,"bar" -Permission "Modify" -Inheritance "ThisFolderSubfoldersAndFiles"} |
         Should -Throw "Counts of identities*"
      }
   }#end Context
}#end describe set-permission