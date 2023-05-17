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

Describe "Test class methods with impact" -Tag Infrastructure {
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
    }# BeforeAll

    AfterAll {
        Remove-LocalUser Pester1, Pester2, Pester3
        Remove-LocalGroup Gpester1, GPester2
    }# AfterAll

    Context 'FMPathPermission - method Set_Access' {
        It 'Should add pester1 to ACL' {
            $FMPP = New-FMPathPermission -Path $Testdrive -Identity pester1 -Permission 'Write' -Inheritance 'ThisFolderOnly'
            $result = $FMPP.Set_Access()
            $ID = $result.Access | Where-Object { $_.IdentityReference -match 'pester1' }
            $ID.FileSystemRights | Should -Be 'Write, Synchronize'
            $ID.AccessControlType | Should -Be 'Allow'
        }
        It 'Should add pester1 and pester2 to ACL' {
            $FMPP = New-FMPathPermission -Path $Testdrive -Identity pester1, pester2 -Permission 'Write', 'Read' -Inheritance 'ThisFolderOnly', 'ThisFolderSubfoldersAndFiles'
            $result = $FMPP.Set_Access()
            $ID = $result.Access | Where-Object { $_.IdentityReference -match 'pester1' }
            $ID.FileSystemRights | Should -Be 'Write, Synchronize'
            $ID.AccessControlType | Should -Be 'Allow'
            $ID.InheritanceFlags | Should -Be 'None'
            $ID.PropagationFlags | Should -Be 'None'
            $ID = $result.Access | Where-Object { $_.IdentityReference -match 'pester2' }
            $ID.FileSystemRights | Should -Be 'Read, Synchronize'
            $ID.AccessControlType | Should -Be 'Allow'
            $ID.InheritanceFlags | Should -Be 'ContainerInherit, ObjectInherit'
            $ID.PropagationFlags | Should -Be 'None'
        }
        It 'Should remove pester 2 from ACL' {
            $FMPP = New-FMPathPermission -Path $Testdrive -Identity pester1, pester2 -Permission 'Write', 'Read' -Inheritance 'ThisFolderOnly', 'ThisFolderSubfoldersAndFiles'
            $result = $FMPP.Set_Access()
            $FMPP2 = New-FMPathPermission -Path $Testdrive -Identity pester2 -Permission 'DeleteFromACL' -Inheritance "ThisFolderOnly"
            $result2 = $Fmpp2.Set_Access()
            $id=$result2.Access | Where-Object { $_.IdentityReference -match 'pester2' }
             $id | Should -BeNullOrEmpty
        }
    }# end