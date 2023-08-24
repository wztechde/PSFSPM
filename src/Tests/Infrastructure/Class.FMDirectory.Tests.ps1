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
Describe 'Class FMDirectory' -Tag Integration {
   Context 'Method: SetAccess()' {
      BeforeAll {
         New-LocalUser Pester1 -NoPassword -Description "Pester1"
         New-LocalUser Pester2 -NoPassword -Description "Pester2"
         # create directory structure
         $BaseDir = New-Item -Path $TestDrive -Name "Test" -ItemType Directory -Force
         $Name_Folder1 = "Folder1"
         $Name_Folder2 = "Folder2"
         $Folder1 = New-Item -Path $BaseDir -Name $Name_Folder1 -ItemType Directory -Force
         $Folder2 = New-Item -Path $BaseDir -Name $Name_Folder2 -ItemType Directory -Force
         $Name_SubFolder1 = "Subfolder1"
         $Name_SubFolder2 = "Subfolder2"
         $Folder1_SF1 = New-Item -Path $Folder1 -Name $Name_SubFolder1 -ItemType Directory -Force
         $Folder1_SF2 = New-Item -Path $Folder1 -Name $Name_SubFolder2 -ItemType Directory -Force
         $Folder2_SF1 = New-Item -Path $Folder2 -Name $Name_SubFolder1 -ItemType Directory -Force
         $Folder2_SF2 = New-Item -Path $Folder2 -Name $Name_SubFolder2 -ItemType Directory -Force
      }
      AfterAll {
         Remove-LocalUser Pester1
         Remove-LocalUser Pester2
      }
      Context "Check Scene1 one root, two folder with two subfolders respectively - subfolder1 ist childly modified" {
         BeforeAll {
            # objects
            $RootPM = @{
               Identity    = 'Pester1', 'Pester2'
               FileRight   = 'Read', 'Read'
               Inheritance = 'ThisFolderSubfoldersAndFiles', 'ThisFolderAndSubfolders'
            }
            $RootPathPM = New-FMPathPermission -Path $BaseDir @RootPM
            $Cld1_PM = New-FMPermission -Identity Pester1 -FileRight Modify -Inheritance ThisFolderSubfoldersAndFiles
            $Cld1_PathPM = New-FMPathPermission -Path "$Name_Folder1\$Name_SubFolder1" -InputObject $Cld1_PM
            $Cld2_PM = New-FMPermission -Identity Pester2 -FileRight Write -Inheritance ThisFolderSubfoldersAndFiles
            $CLD2_PathPM = New-FMPathPermission -Path "$Name_Folder1\$Name_SubFolder1" -InputObject $Cld2_PM
            $DIR = New-FMDirectory -Root $RootPathPM -Child $Cld1_PathPM, $CLD2_PathPM

            $Result = $DIR.SetAccess()
         }
         It "Checks for correct base rights in main folder and not changed subfolders" {
            Get-Acl -Path $Folder1 | Should -ContainACE (New-FMPermission -Identity Pester1 -FileRight Read -Inheritance ThisFolderSubfoldersAndFiles)
            Get-Acl -Path $Folder1 | Should -ContainACE (New-FMPermission -Identity Pester1 -FileRight Read -Inheritance ThisFolderSubfoldersAndFiles)
            Get-Acl -Path $Folder1_SF2 | Should -ContainACE (New-FMPermission -Identity Pester1 -FileRight Read -Inheritance ThisFolderSubfoldersAndFiles)
            Get-Acl -Path $Folder1_SF2 | Should -ContainACE (New-FMPermission -Identity Pester2 -FileRight Read -Inheritance ThisFolderOnly)
         }
         It "Checks for correct rights in CHANGED subfolders" {
            Get-Acl -Path $Folder1_SF1 | Should -ContainACE $Cld1_PM
            Get-Acl -Path $Folder1_SF1 | Should -ContainACE $Cld2_PM
         }
         It "Checks for inherintance correctly set" {
            ((Get-Acl -Path $Folder1).Access | Where {$_.IdentityReference -like "*pester1"}).IsInherited | Should -BeTrue
            ((Get-Acl -Path $Folder1_sf2).Access | Where {$_.IdentityReference -like "*pester1"}).IsInherited | Should -BeTrue
            # subfolder breaks inheritance
            ((Get-Acl -Path $Folder1_sf1).Access | Where {$_.IdentityReference -like "*pester1"}).IsInherited | Should -BeFalse
         }
      }
   }#end context
}#end describe