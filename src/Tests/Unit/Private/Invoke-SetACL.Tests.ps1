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

InModuleScope -ModuleName $ModuleName {
    BeforeAll {
        $PPM1 = New-FMPathPermission -Path $TestDrive -Identity 'foo', 'bar' -FileRight Read, Write -Inheritance ThisFolderOnly, ThisFolderSubfoldersAndFiles
        $PPM2 = New-FMPathPermission -Path "$TestDrive\foo" -Identity 'foo', 'bar' -FileRight Read, Write -Inheritance ThisFolderOnly, ThisFolderSubfoldersAndFiles
        $PPM3 = New-FMPathPermission -Path $TestDrive -Identity 'foo', 'bar' -FileRight Read, Write -Inheritance ThisFolderOnly, ThisFolderSubfoldersAndFiles
        $PPM4 = New-FMPathPermission -Path "$TestDrive" -Identity 'foo', 'bar' -FileRight Delete, Write -Inheritance ThisFolderOnly, ThisFolderSubfoldersAndFiles
    }
    Context "Check function parameter" {
        It "Should throw, if path doesn't exist" {
            $PPMTest = $PPM2
            { Invoke-SetACL -InputObject $PPMTest } | Should -Throw "Cannot find path*"
        }
    }#Context
    Context "Check inner function call" {
        It "Should call SetAccessRuleProtection - once" {
            Mock SetAccessRuleProtection { Get-Acl $TestDrive }
            Mock SetAccess { Get-Acl $TestDrive }
            Mock Set-ACL {}
            Invoke-setACL -InputObject $PPM1
            Should -Invoke SetAccessRuleProtection -Times 1
            Should -Invoke SetAccess -Times 1
        }
        # The FMPathPermissionObjhect can hold more than one path to apply permissions to
        # Helps to easily assign a permission construct to a bunch of path (i.e. child in DirectoryObject)
        It "Should call SetAccessRuleProtection - twice (two paths given)" {
            Mock SetAccessRuleProtection { Get-Acl $TestDrive }
            Mock SetAccess { Get-Acl $TestDrive }
            Mock Set-ACL {}
            Invoke-setACL -InputObject $PPM3
            Should -Invoke SetAccessRuleProtection -Times 1
            Should -Invoke SetAccess -Times 1
        }
        It "Should call SetAccess" {
            Mock SetAccessRuleProtection { Get-Acl $TestDrive }
            Mock SetAccess { Get-Acl $TestDrive }
            mock Set-ACL {}
            $Result=Invoke-SetACL -InputObject $PPM4
            Should -Invoke SetAccessRuleProtection -Times 1
            Should -Invoke SetAccess -Times 1
        }
    }
}