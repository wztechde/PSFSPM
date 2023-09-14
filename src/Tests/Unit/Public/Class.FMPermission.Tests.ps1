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
}
Describe 'FMPermission' -Tag Unit {
   Context 'New-FMPermission' {
      It "Should have Parameters 'Identity', 'FileRight', and 'Inheritance'" {
         Get-Command New-FMPermission | Should -HaveParameter Identity
         Get-Command New-FMPermission | Should -HaveParameter FileRight
         Get-Command New-FMPermission | Should -HaveParameter Inheritance
      }
      It "Should throw on wrong FileRight" {
         { New-FMPermission -Identity 'test' -FileRight 'test' -Inheritance 'ThisFolderOnly' } | Should -Throw "Cannot process argument transformation on parameter 'FileRight'*"
      }
      It "Should throw on wrong Inheritance" {
         { New-FMPermission -Identity 'test' -FileRight 'Read' -Inheritance 'Fishnet' } | Should -Throw "Cannot process argument transformation on parameter 'Inheritance'*"
      }
      It 'Should return a FMPermission object' {
         $result = New-FMPermission -Identity 'test' -FileRight 'Read' -Inheritance 'ThisFolderOnly'
         $result.Gettype() | Should -Be 'FMPermission'
      }
   }#end context
   Context 'New-FMPermission - Test methods' {
      Context "method: 'GetDetailedInheritance'" {
         BeforeAll {
            $result = New-FMPermission -Identity 'test' -FileRight 'Read' -Inheritance 'ThisFolderOnly'
         }
         It 'Should return a hashtable' {
            $result.GetDetailedInheritance() | Should -BeOfType 'System.Collections.Hashtable'
         }#end it
         It "Should have members 'Propagate' and 'Inherit'" {
            $rs1 = ($result.GetDetailedInheritance()).keys
            $rs1 | Should -Contain 'Propagate'
            $rs1 | Should -Contain 'Inherit'
         }#end it
         It 'Should return correct values for different inheritances - current:  <Inheritance>' -ForEach @(
            @{Inheritance = 'ThisFolderSubfoldersAndFiles'; Propagate = 'None'; Inherit = 'ContainerInherit, ObjectInherit' },
            @{Inheritance = 'ThisFolderAndSubfolders'; Propagate = 'None'; Inherit = 'ContainerInherit' },
            @{Inheritance = 'ThisFolderOnly'; Propagate = 'None'; Inherit = 'None' },
            @{Inheritance = 'ThisFolderAndFiles'; Propagate = 'None'; Inherit = 'ObjectInherit' },
            @{Inheritance = 'SubfoldersAndFilesOnly'; Propagate = 'InheritOnly'; Inherit = 'ContainerInherit, ObjectInherit' },
            @{Inheritance = 'SubfoldersOnly'; Propagate = 'InheritOnly'; Inherit = 'ContainerInherit' },
            @{Inheritance = 'FilesOnly'; Propagate = 'InheritOnly'; Inherit = 'ObjectInherit' },
            @{Inheritance = 'File'; Propagate = 'None'; Inherit = 'None' }
         ) {
            $result = New-FMPermission -Identity 'test' -FileRight 'Read' -Inheritance $Inheritance
            $rs1 = $result.GetDetailedInheritance()
            $rs1.Propagate | Should -Be $Propagate
            $rs1.Inherit | Should -Be $Inherit
         }
      }#end context
      Context "method: 'Get_FileSystemAccessRule'" {
         BeforeAll {
            $result = New-FMPermission -Identity 'test' -FileRight 'Read' -Inheritance 'ThisFolderOnly'
         }
         It 'Should return a FileSystemAccessRule object' {
            $result.Get_FileSystemAccessRule() | Should -BeOfType 'System.Security.AccessControl.FileSystemAccessRule'
         }#end it
         It "Object members should have correct values set for different inheritances - current <Inheritance>" -ForEach @(
            @{Inheritance = 'ThisFolderSubfoldersAndFiles'; Propagate = 'None'; Inherit = 'ContainerInherit, ObjectInherit' },
            @{Inheritance = 'ThisFolderAndSubfolders'; Propagate = 'None'; Inherit = 'ContainerInherit' },
            @{Inheritance = 'ThisFolderOnly'; Propagate = 'None'; Inherit = 'None' },
            @{Inheritance = 'ThisFolderAndFiles'; Propagate = 'None'; Inherit = 'ObjectInherit' },
            @{Inheritance = 'SubfoldersAndFilesOnly'; Propagate = 'InheritOnly'; Inherit = 'ContainerInherit, ObjectInherit' },
            @{Inheritance = 'SubfoldersOnly'; Propagate = 'InheritOnly'; Inherit = 'ContainerInherit' },
            @{Inheritance = 'FilesOnly'; Propagate = 'InheritOnly'; Inherit = 'ObjectInherit' },
            @{Inheritance = 'File'; Propagate = 'None'; Inherit = 'None' }
         ) {
            $result = New-FMPermission -Identity 'test' -FileRight 'Read' -Inheritance $Inheritance
            $rs1 = $result.Get_FileSystemAccessRule()
            $($rs1.PropagationFlags) | Should -Be $Propagate
            $($rs1.InheritanceFlags) | Should -Be $Inherit
         }
      }#end context
   }#end contex
}#end describe