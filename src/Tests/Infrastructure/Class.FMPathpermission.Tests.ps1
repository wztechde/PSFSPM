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
   $PathToHelpers = [System.IO.Path]::Combine('..', 'TestHelpers.psm1')
   Import-Module $PathToHelpers -Force
   $PathToCustoms = [System.IO.Path]::Combine('..', 'CustomAssertions.psm1')
   Import-Module $PathToCustoms -Force
}
Describe 'Class FMPathPermission' -Tag Integration {
   Context 'FMPathPermission - test methods' {
      Context "method: 'SetAccess'" {
         BeforeAll {
            # create local users
            New-LocalUser Pester1 -NoPassword -Description "Pester1"
            New-LocalUser Pester2 -NoPassword -Description "Pester2"
            # create directory structure
            $TempDir = New-Item -Path $TestDrive -Name "Test" -ItemType Directory -Force        # C:\Test
            $TempDir1 = New-Item -Path $TempDir -Name "Dir1" -ItemType Directory -Force         # C:\Test\Dir1
            $TempDir2 = New-Item -Path $TempDir -Name "Dir2" -ItemType Directory -Force         # C:\Test\Dir2
            $SubDir1 = New-Item -Path $TempDir1 -Name "SubDir1" -ItemType Directory -Force      # C:\Test\Dir1\SubDir1
            $SubDir2 = New-Item -Path $TempDir1 -Name "SubDir2" -ItemType Directory -Force      # C:\Test\Dir1\SubDir2
            $TempFile1 = New-Item -Path $TempDir1 -Name "TEST1.txt" -ItemType File -Force       # C:\Test\Dir1\TEST1.txt
            $TempFile2 = New-Item -Path $TempDir1 -Name "TEST2.txt" -ItemType File -Force       # C:\Test\Dir1\TEST2.txt
            Mock Set-ACL { $ACL }
         }
         AfterAll {
            Remove-LocalUser Pester1, Pester2
         }
         Context "Single permission tests" {
            It "Should throw, if identity doesn't exist" {
               $FMPP1 = New-FMPathPermission -Path $TempDir -FileRight 'Read' -Inheritance 'ThisFolderOnly' -Identity Test
               { $FMPP1.SetAccess() } | Should -Throw 'Exception calling "AddAccessRule" with "1" argument(s): "Some or all identity references could not be translated."'
            }#end it
            It 'Should set basic permissions, pester1 and pester2 "Read" ' {
               $FMPP1 = New-FMPathPermission -Path $TempDir -FileRight 'Read' -Inheritance 'ThisFolderSubfoldersAndFiles' -Identity 'Pester1'
               $FMPP2 = New-FMPathPermission -Path $TempDir -FileRight 'Read' -Inheritance 'ThisFolderSubfoldersAndFiles' -Identity 'Pester2'
               $result = $FMPP1.SetAccess()
            (Get-Acl $TempDir) | Should -ContainACE $FMPP1.Permission
            (Get-Acl $TempDir1) | Should -ContainACE $FMPP1.Permission
            (Get-Acl $TempDir2) | Should -ContainACE $FMPP1.Permission
            (Get-Acl $SubDir1) | Should -ContainACE $FMPP1.Permission
               $result = $FMPP2.SetAccess()
            (Get-Acl $TempDir) | Should -ContainACE $FMPP2.Permission
            (Get-Acl $TempDir1) | Should -ContainACE $FMPP2.Permission
            (Get-Acl $TempDir2) | Should -ContainACE $FMPP2.Permission
            (Get-Acl $SubDir1) | Should -ContainACE $FMPP2.Permission
            }
            It "Should remove ACE completely from ACL on 'DeleteFromACL' FileRight, on 'TempFile2'" {
               $FMPP1 = New-FMPathPermission -Path $Tempfile2 -FileRight 'DeleteFromACL' -Inheritance File -Identity 'Pester1'
               #ACRule $true,$true Remove inheritance and change all rights to explicit rights
               #$FMPP1.ACRule.isProtected=$true
               #$FMPP1.ACRule.preserveInheritance=$true
               $Pester1_Permission = New-FMPermission -Identity Pester1 -FileRight Read -Inheritance ThisFolderSubfoldersAndFiles
               $result = $FMPP1.SetAccess()
               $result | Should -Not -ContainACE $Pester1_Permission
            }#end it
            It "Should grant 'modify' on 'Subfolder2' - No change to explicit -> adds 'modify'" {
               $FMPP2 = New-FMPathPermission -Path $SubDir2 -FileRight 'Modify' -Inheritance ThisFolderSubfoldersAndFiles -Identity 'Pester2'
               $BasePermission = New-FMPermission -Identity Pester2 -FileRight Read -Inheritance ThisFolderSubfoldersAndFiles
               #$FMPP2.ACRule.isProtected = $true
               #$FMPP2.ACRule.preserveInheritance = $true
               $result = $FMPP2.SetAccess()
               $result | Should -ContainACE $FMPP2.Permission
               $result | Should -ContainACE $BasePermission
            }#end it
            It "Should grant 'modify' on 'Subfolder2' - Change to explicit -> replaces with 'modify'" {
               $FMPP2 = New-FMPathPermission -Path $SubDir2 -FileRight 'Modify' -Inheritance ThisFolderSubfoldersAndFiles -Identity 'Pester2'
               $BasePermission = New-FMPermission -Identity Pester2 -FileRight Read -Inheritance ThisFolderSubfoldersAndFiles
               $FMPP2.ACRule.isProtected = $true
               $FMPP2.ACRule.preserveInheritance = $true
               $result = $FMPP2.SetAccess()
               $result | Should -ContainACE $FMPP2.Permission
               $result | Should -Not -ContainACE $BasePermission
            }#end it
         }#end context
         Context "Multiple permissions tests" {
            It "Should set rights for two users simultaniously on 'Subfolder1' - No change to explicit adds permissions" {
               $Permission1 = New-FMPermission -Identity Pester1 -FileRight Modify -Inheritance ThisFolderOnly
               $Permission2 = New-FMPermission -Identity Pester2 -FileRight Write -Inheritance ThisFolderSubfoldersAndFiles
               $Permission3 = New-FMPermission -Identity Pester1 -FileRight Read -Inheritance ThisFolderSubfoldersAndFiles
               $Permission4 = New-FMPermission -Identity Pester2 -FileRight Read -Inheritance ThisFolderSubfoldersAndFiles
               $FMPP = New-FMPathPermission -Path $SubDir1 -InputObject $Permission1, $Permission2
               $result = $FMPP.SetAccess()
               $result | Should -ContainACE $Permission1
               $result | Should -ContainACE $Permission2
               $result | Should -ContainACE $Permission3
               $result | Should -ContainACE $Permission4
            }
            It "Should set rights for two users simultaniously on 'Subfolder1' - No change to explicit adds permissions" {
               $Permission1 = New-FMPermission -Identity Pester1 -FileRight Modify -Inheritance ThisFolderOnly
               $Permission2 = New-FMPermission -Identity Pester2 -FileRight Write -Inheritance ThisFolderSubfoldersAndFiles
               $Permission4 = New-FMPermission -Identity Pester2 -FileRight Read -Inheritance ThisFolderSubfoldersAndFiles
               $FMPP = New-FMPathPermission -Path $SubDir1 -InputObject $Permission1, $Permission2
               $FMPP.ACRule.isProtected = $true
               $FMPP.ACRule.preserveInheritance = $true
               $result = $FMPP.SetAccess()
               $result | Should -ContainACE $Permission1
               $result | Should -ContainACE $Permission2
               $result | Should -Not -ContainACE $Permission4
            }
         }#end context
      }#end context
   }#end context
}#end describe