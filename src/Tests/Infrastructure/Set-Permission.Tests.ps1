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

InModuleScope -ModuleName $ModuleName {
    Describe "Invoke-Setacl" -Tag Infra {
        # prerequisites
        BeforeAll {
            New-LocalUser Pester1 -NoPassword
            New-LocalUser Pester2 -NoPassword
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
            Remove-LocalUser Pester1, Pester2
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
                $FPM1=New-FMPathPermission -Path $F_foo.FullName -Identity pester1 -Permission Read -Inheritance ThisFolderOnly
                $BeforeACL = Get-Acl $F_Bar.FullName
                $result = Set-Permission -PathPermissionObject $FPM1
                $CurrentACL = Get-Acl $F_Bar.FullName
                $CurrentACL.Access[0].IsInherited | Should -Be $true
            }
            It 'Should remove all inherited acls' {
                $FPM1=New-FMPathPermission -Path $F_Clara.FullName -Identity pester1 -Permission Read -Inheritance ThisFolderSubfoldersAndFiles
                $BeforeACL = Get-Acl $F_Clara.FullName
                $FPM1.ACRule.isProtected = $false
                $result = Set-Permission -PathPermissionObject $FPM1
                $CurrentACL = Get-Acl $F_Clara.FullName
                $CurrentACL.Access[0].IsInherited | Should -Be $false
            }
        }
        Context "AddAccess - correct permissions set ?" {
            It "Should have pester1 read only <bar>, pester2 <clara>, too" {
                $param=@{
                    Path = $F_Bar
                    Identity=@("Pester1","Pester2")
                    Permission=@("Read","Write")
                    Inheritance=@("ThisFolderOnly","ThisFolderSubfoldersAndFiles")
                }
                $FPM1=New-FMPathPermission @param
                $result=Set-Permission -PathPermissionObject $FPM1 -verbose
                $CurrentACL = Get-Acl $F_Bar.FullName
                $Access=$CurrentACL.Access
                $Access.IdentityReference -match "Pester1" | Should -Not -BeNullOrEmpty
                $Access.IdentityReference -match "Pester2" | Should -Not -BeNullOrEmpty
                $CurrentACL = Get-Acl $F_Clara.FullName
                $Access=$CurrentACL.Access
                $Access.IdentityReference -match "Pester1" | Should -BeNullOrEmpty #Pester 1 'ThisFolderOnly'
                $Access.IdentityReference -match "Pester2" | Should -Not -BeNullOrEmpty
            }#it
        }
    }#Describe Get-ChilditemEnhanced
}