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
   Context 'New-FMPathPermission' {
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
      Context "method: 'SetAccess'" {
         BeforeAll {
            $TempDir=New-Item -Path $TestDrive -Name "TEST" -ItemType Directory -Force
            $TempFile=New-Item -Path "$TestDrive\TEST" -Name "TEST.txt" -ItemType File -Force
            $FMPP1 = New-FMPathPermission -Path $TempDir -FileRight 'Read' -Inheritance 'ThisFolderOnly' -Identity 'test'
            $FMPP2 = New-FMPathPermission -Path $TempDir -FileRight 'Read' -Inheritance 'ThisFolderOnly' -Identity 'VORDEFINIERT\Benutzer'
            $FMPP3 = New-FMPathPermission -Path $TempDir -FileRight 'DeleteFromACL' -Inheritance 'ThisFolderOnly' -Identity 'VORDEFINIERT\Benutzer'
            Mock Set-ACL { $ACL }
         }
         It "Should throw, if identity doesn't exist" {
            { $FMPP1.SetAccess() } | Should -Throw 'Exception calling "AddAccessRule" with "1" argument(s): "Some or all identity references could not be translated."'
         }#end it
         It "Should filter out the private 'DeleteFromACL' FileRight, i.e. no reference to the given identity should be found" {
            $result = $FMPP3.SetAccess()
            $result | Should -Not -ContainACE $FMPP3.Permission
         }#end it
         It "Should have added the correct access rule to ACL" {
            $result = $FMPP2.SetAccess()
            $result | Should -ContainACE $FMPP2.Permission
         }#end it
         It "Should have added the correct access rule to ACL (file): None, None" {
            $FMPP3 = New-FMPathPermission -Path $TempFile -FileRight 'Read' -Inheritance 'ThisFolderOnly' -Identity 'VORDEFINIERT\Benutzer'
            $FMPP4 = New-FMPathPermission -Path $TempFile -FileRight 'Read' -Inheritance 'File' -Identity 'VORDEFINIERT\Benutzer'
            $result = $FMPP3.SetAccess()
            $result | Should -ContainACE $FMPP4.Permission
         }#end it
         It "Should comtain ACE" {
            $result = $FMPP2.SetAccess()
            $result | Should -Not -ContainACE $FMPP1.Permission
         }#end it
         It "Should BeInACL" {
            $result = $FMPP2.SetAccess()
            #"Wolle" | Should -BeInACL "Werner"
            $FMPP2.Permission.GetFileSystemAccessRule() | Should -BeInACL $result
            #$result.Gettype() | Should -Be 'System.Security.AccessControl.DirectorySecurity'
         }#end it
      }#end context
   }#end context
   Context 'Test' {

   }#end context
}#end describe