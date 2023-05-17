Set-Location -Path $PSScriptRoot
#-------------------------------------------------------------------------
$ModuleName = 'PSFSPM'
$PathToManifest = [System.IO.Path]::Combine('..', '..', $ModuleName, "$ModuleName.psd1")
#-------------------------------------------------------------------------
if (Get-Module -Name $ModuleName -ErrorAction 'SilentlyContinue') {
    #if the module is already in memory, remove it
    Remove-Module -Name $ModuleName -Force
}
Import-Module $PathToManifest -Force

Describe "Set-Permission" -Tag Infrastructure {
    # prerequisites
    BeforeAll {
        New-LocalUser Pester1 -NoPassword
        New-LocalUser Pester2 -NoPassword
        New-LocalUser Pester3 -NoPassword
        New-LocalGroup GPester1 -Description 'Pester Group 1'
        New-LocalGroup GPester2 -Description 'Pester Group 2'
        Add-LocalGroupMember -Group GPester1 -Member Pester1
        Add-LocalGroupMember -Group GPester2 -Member Pester2
        # Create folder strukture
        $F_Foo = mkdir "$TestDrive\foo" -Force
        $F_Bar = mkdir "$TestDrive\foo\bar" -Force
        $F_Clara = mkdir "$TestDrive\foo\bar\clara" -Force
    }

    AfterAll {
        Remove-LocalUser Pester1, Pester2, Pester3
        Remove-LocalGroup Gpester1, GPester2
    }
    Context 'Test SetAccessRuleProtetion' {
        # see https://stackoverflow.com/questions/31787843/explain-for-beginners-the-acl-object-property-setaccessruleprotection-in-power
        <#
        Add the new user and preserve all current permissions: SetAccessRuleProtection(False, X)
        Add the new user and remove all inherited permissions: SetAccessRuleProtection(True, False)
        Add the new user and convert all inherited permissions to explicit permissions: SetAccessRuleProtection(True, True)
        #>
        It 'Should change acls to explicit' {
            $FPM1 = New-FMPathPermission -Path $F_foo.FullName -Identity pester1 -Permission Read -Inheritance ThisFolderOnly
            $BeforeACL = Get-Acl $F_Bar.FullName
            $result = Set-Permission -PathPermissionObject $FPM1
            $CurrentACL = Get-Acl $F_Bar.FullName
            $CurrentACL.Access[0].IsInherited | Should -Be $true
        }
        It 'Should remove all inherited acls' {
            $FPM1 = New-FMPathPermission -Path $F_Clara.FullName -Identity pester1 -Permission Read -Inheritance ThisFolderSubfoldersAndFiles
            $BeforeACL = Get-Acl $F_Clara.FullName
            $FPM1.ACRule.isProtected = $false
            $result = Set-Permission -PathPermissionObject $FPM1
            $CurrentACL = Get-Acl $F_Clara.FullName
            $CurrentACL.Access[0].IsInherited | Should -Be $false
        }
    }
    Context "AddAccess - correct permissions set ?" {
        BeforeEach {
            $FI_Foo = mkdir "$TestDrive\FIfoo" -Force
            $FI_Bar = mkdir "$TestDrive\FIfoo\bar" -Force
            $FI_Clara = mkdir "$TestDrive\FIfoo\bar\clara" -Force
            $FI_donna = mkdir "$TestDrive\FIfoo\bar\clara\donna" -Force
        }
        It "Should have pester1 read only <bar>, pester2 <clara>, too" {
            $param = @{
                Path        = $FI_Bar
                Identity    = @("Pester1", "Pester2")
                Permission  = @("Read", "Write")
                Inheritance = @("ThisFolderOnly", "ThisFolderSubfoldersAndFiles")
            }
            $FPM1 = New-FMPathPermission @param
            $result = Set-Permission -PathPermissionObject $FPM1
            $CurrentACL = Get-Acl $FI_Bar.FullName
            $Access = $CurrentACL.Access
            $Access.IdentityReference -match "Pester1" | Should -Not -BeNullOrEmpty
            $Access.IdentityReference -match "Pester2" | Should -Not -BeNullOrEmpty
            $CurrentACL = Get-Acl $FI_Clara.FullName
            $Access = $CurrentACL.Access
            $Access.IdentityReference -match "Pester1" | Should -BeNullOrEmpty #Pester 1 'ThisFolderOnly'
            $Access.IdentityReference -match "Pester2" | Should -Not -BeNullOrEmpty
        }#it
        IT "Should Pester1 RO <bar>, Pester 2 RW TFSF <clara>, Pester 3 <donna>" {
            $param = @{
                Path        = $FI_Bar
                Identity    = @("Pester1", "Pester2", "Pester3")
                Permission  = @("Read", "Write", "Full")
                Inheritance = @("ThisFolderOnly", "SubfoldersAndFilesOnly", "ThisFolderSubfoldersAndFiles")
            }
            $FPM1 = New-FMPathPermission @param
            $result = Set-Permission -PathPermissionObject $FPM1
            $Access = $CurrentACL.Access
            $Access.IdentityReference -match "Pester1" | Should -Not -BeNullOrEmpty
            $Access.IdentityReference -match "Pester2" | Should -Not -BeNullOrEmpty
            $Access.IdentityReference -match "Pester3" | Should -Not -BeNullOrEmpty
            $CurrentACL = Get-Acl $FI_Clara.FullName
            $Access = $CurrentACL.Access
            $Access.IdentityReference -match "Pester1" | Should -BeNullOrEmpty #Pester 1 'ThisFolderOnly'
            $Access.IdentityReference -match "Pester2" | Should -Not -BeNullOrEmpty
            $Access.IdentityReference -match "Pester3" | Should -Not -BeNullOrEmpty
            $CurrentACL = Get-Acl $FI_Donna.FullName
            $Access = $CurrentACL.Access
            $Access.IdentityReference -match "Pester1" | Should -BeNullOrEmpty #Pester 1 'ThisFolderOnly'
            $Access.IdentityReference -match "Pester2" | Should -not -BeNullOrEmpty
            $Access.IdentityReference -match "Pester3" | Should -Not -BeNullOrEmpty

        }
    }#context
    Context "Systematically test all inheritances" {
        BeforeEach {
            Remove-item -Path "$TestDrive\FI_Foo" -Recurse -Force -ErrorAction SilentlyContinue
            $FI_Foo = mkdir "$TestDrive\FI_foo" -Force
            $FI_Bar = mkdir "$TestDrive\FI_foo\bar" -Force
            $FI_Clara = mkdir "$TestDrive\FI_foo\bar\clara" -Force
            $FI_donna = mkdir "$TestDrive\FI_foo\bar\clara\donna" -Force
            New-Item -Path $FI_Foo -Name "test_foo.txt" -ItemType File -Force
            New-Item -Path $FI_Bar -Name "test_bar.txt" -ItemType File -Force
            New-Item -Path $FI_Clara -Name "test_clara.txt" -ItemType File -Force
            New-Item -Path $FI_Donna -Name "test_donna.txt" -ItemType File -Force
        }
        It "'ThisFolderSubfoldersAndFiles'" {
            $param = @{
                Path        = $FI_Foo
                Identity    = @("Pester1")
                Permission  = @("Write")
                Inheritance = @("ThisFolderSubFoldersAndFiles")
            }
            $FPM1 = New-FMPathPermission @param
            Set-Permission -PathPermissionObject $FPM1
            $Access = (Get-ACL $FI_Foo.fullname).Access
            $Access.IdentityReference -match "Pester1" | Should -Not -BeNullOrEmpty #folder has identity
            $Access = (Get-ACL "$($FI_Foo.Fullname)\test_foo.txt").Access
            $Access.IdentityReference -match "Pester1" | Should -Not -BeNullOrEmpty #file has
            $Access = (Get-ACL "$($FI_Bar.Fullname)").Access
            $Access.IdentityReference -match "Pester1" | Should -Not -BeNullOrEmpty #and subfolder, too
            $Access = (Get-ACL "$($FI_Donna.Fullname)").Access
            $Access.IdentityReference -match "Pester1" | Should -Not -BeNullOrEmpty #and subfolder, too
            $Access = (Get-ACL "$($FI_donna.Fullname)\test_donna.txt").Access
            $Access.IdentityReference -match "Pester1" | Should -Not -BeNullOrEmpty #file has
        }
        It "'ThisFolderAndSubfolders'" {
            $param = @{
                Path        = $FI_bar
                Identity    = @("Pester1")
                Permission  = @("Write")
                Inheritance = @("ThisFolderAndSubFolders")
            }
            $FPM1 = New-FMPathPermission @param
            Set-Permission -PathPermissionObject $FPM1
            $Access = (Get-ACL $FI_bar.fullname).Access
            $Access.IdentityReference -match "Pester1" | Should -Not -BeNullOrEmpty #folder has identity
            $Access = (Get-ACL "$($FI_bar.Fullname)\test_bar.txt").Access
            $Access.IdentityReference -match "Pester1" | Should -BeNullOrEmpty #file has not
            $Access = (Get-ACL "$($FI_Clara.Fullname)").Access
            $Access.IdentityReference -match "Pester1" | Should -Not -BeNullOrEmpty #and subfolder has
            $Access = (Get-ACL "$($FI_Donna.Fullname)").Access
            $Access.IdentityReference -match "Pester1" | Should -Not -BeNullOrEmpty #and subfolder has
            $Access = (Get-ACL "$($FI_donna.Fullname)\test_donna.txt").Access
            $Access.IdentityReference -match "Pester1" | Should -BeNullOrEmpty #file has not
        }
        It "'ThisFolderOnly'" {
            $param = @{
                Path        = $FI_Foo
                Identity    = @("Pester1")
                Permission  = @("Write")
                Inheritance = @("ThisFolderOnly")
            }
            $FPM1 = New-FMPathPermission @param
            Set-Permission -PathPermissionObject $FPM1
            $Access = (Get-ACL $FI_Foo.fullname).Access
            $Access.IdentityReference -match "Pester1" | Should -Not -BeNullOrEmpty #only folder has identity
            $Access = (Get-ACL "$($FI_Foo.Fullname)\test_foo.txt").Access
            $Access.IdentityReference -match "Pester1" | Should -BeNullOrEmpty #not file
            $Access = (Get-ACL "$($FI_Bar.Fullname)").Access
            $Access.IdentityReference -match "Pester1" | Should -BeNullOrEmpty #nor subfolder
        }
        It "'ThisFolderAndFiles'" {
            $param = @{
                Path        = $FI_Bar
                Identity    = @("Pester1")
                Permission  = @("Write")
                Inheritance = @("ThisFolderAndFiles")
            }
            $FPM1 = New-FMPathPermission @param
            Set-Permission -PathPermissionObject $FPM1
            $Access = (Get-ACL $FI_Bar.fullname).Access
            $FilterUser = $access | Where-Object { $_.IdentityReference -match "Pester1" }
            $FilterUser.InheritanceFlags | Should -be "ObjectInherit"
            $FilterUser.PropagationFlags | Should -be "None"

            $Access.IdentityReference -match "Pester1" | Should -Not -BeNullOrEmpty #only folder has identity
            $Access = (Get-ACL "$($FI_Bar.Fullname)\test_Bar.txt").Access
            $Access.IdentityReference -match "Pester1" | Should -Not -BeNullOrEmpty #not file
            $Access = (Get-ACL "$($FI_Clara.Fullname)").Access
            <#
            $Access.IdentityReference -match "Pester1" | Should -BeNullOrEmpty #nor subfolder
            $Access = (Get-ACL "$($FI_Clara.Fullname)").Access
            $Access.IdentityReference -match "Pester1" | Should -BeNullOrEmpty #nor subfolder
            $Access = (Get-ACL "$($FI_Donna.Fullname)").Access
            $Access.IdentityReference -match "Pester1" | Should -BeNullOrEmpty #nor subfolder
            #>
        }
        It "'SubFoldersAndFilesOnly'" {
            $param = @{
                Path        = $FI_Bar
                Identity    = @("Pester1")
                Permission  = @("Write")
                Inheritance = @("SubFoldersAndFilesOnly")
            }
            $FPM1 = New-FMPathPermission @param
            Set-Permission -PathPermissionObject $FPM1
            $Access = (Get-ACL $FI_Bar.fullname).Access
            $FilterUser = $access | Where-Object { $_.IdentityReference -match "Pester1" }
            $FilterUser.InheritanceFlags | Should -be "ContainerInherit, ObjectInherit"
            $FilterUser.PropagationFlags | Should -be "InheritOnly"
            $Access.IdentityReference -match "Pester1" | Should -Not -BeNullOrEmpty #only folder has identity
            $Access = (Get-ACL "$($FI_Bar.Fullname)\test_bar.txt").Access
            $Access.IdentityReference -match "Pester1" | Should -Not -BeNullOrEmpty #not file
        }
        It "'SubFoldersOnly'" {
            $param = @{
                Path        = $FI_Bar
                Identity    = @("Pester2")
                Permission  = @("Write")
                Inheritance = @("SubFoldersOnly")
            }
            $FPM1 = New-FMPathPermission @param
            Set-Permission -PathPermissionObject $FPM1
            $Access = (Get-ACL $FI_Bar.fullname).Access
            $FilterUser=$access | Where-Object {$_.IdentityReference -match "Pester2"}
            $FilterUser.InheritanceFlags | Should -be "ContainerInherit"
            $FilterUser.PropagationFlags | Should -be "InheritOnly"
            $Access = (Get-ACL "$($FI_Bar.Fullname)\test_bar.txt").Access
            $Access.IdentityReference -match "Pester2" | Should -BeNullOrEmpty #not file
            $Access = (Get-ACL "$($FI_Clara.Fullname)").Access
            $Access.IdentityReference -match "Pester2" | Should -Not -BeNullOrEmpty #nor subfolder
        }
        It "'FilesOnly'" {
            $param = @{
                Path        = $FI_Bar
                Identity    = @("Pester2")
                Permission  = @("Write")
                Inheritance = @("FilesOnly")
            }
            $FPM1 = New-FMPathPermission @param
            Set-Permission -PathPermissionObject $FPM1
            $Access = (Get-ACL $FI_Bar.fullname).Access
            $FilterUser=$access | Where-Object {$_.IdentityReference -match "Pester2"}
            $FilterUser.InheritanceFlags | Should -be "ObjectInherit"
            $FilterUser.PropagationFlags | Should -be "InheritOnly"
            $Access = (Get-ACL "$($FI_Bar.Fullname)\test_bar.txt").Access
            $Access.IdentityReference -match "Pester2" | Should -not -BeNullOrEmpty #not file
        }
        It "Tests using"

    }
}#Describe Set-Permission
