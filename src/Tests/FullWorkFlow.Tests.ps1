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
   $F_Clara = mkdir "$TestDrive\foo\clara" -Force
}

AfterAll {
   Remove-LocalUser Pester1, Pester2
   Remove-LocalGroup Gpester1, GPester2
}

Describe 'test workflows' {
   Context 'ACL Rule Protection' {
      # SetAccessRuleProtection(isProtected,preserveInheritance)
      It 'Should leave ACEs inherited and keep the rest' {
         $ACL = Get-Acl $F_Clara.FullName
         $ACL.SetAccessRuleProtection($false, $true)
         Set-Acl -Path $F_Clara.FullName -AclObject $ACL
         $ACLNew = Get-Acl $F_Clara.FullName
         $($ACLNew.Access[0].isInherited) | Should -Be $true
      }
      It 'Should turn ACEs in explicit and inheritance' {
         $ACL = Get-Acl $F_Clara.FullName
         $ACL.SetAccessRuleProtection($true, $true)
         Set-Acl -Path $F_Clara.FullName -AclObject $ACL
         $ACLNew = Get-Acl $F_Clara.FullName
         $($ACLNew.Access[0].isInherited) | Should -Be $false
      }
      It 'Disable inheritance and remove all inherited' {
         $ACL = Get-Acl $F_Bar.FullName
         $ACL.SetAccessRuleProtection($true, $false)
         Set-Acl -Path $F_Bar.FullName -AclObject $ACL
         $ACLNew = Get-Acl $F_Bar.FullName
         $($ACLNew.Access[0].isInherited) | Should -Be $null
      }
   }
   Context 'AddAccessRule' {
      It "add pester to acl" {
         $ACL = Get-Acl $F_Foo.FullName
         $ACO=New-Object System.Security.AccessControl.FileSystemAccessRule("Pester1", "Read", "ContainerInherit,ObjectInherit",0,"Allow")
         $ACL.AddAccessRule($ACO)
         Set-Acl -Path $F_Foo.FullName -AclObject $ACL
         $ResultACL = (Get-Acl $F_Foo.FullName).Access.IdentityReference
         $ResultACL -match 'Pester1' | Should -Not -BeNullOrEmpty
      }
      It "add pester1 and pester2 to acl" {
         $ACL = Get-Acl $F_Foo.FullName
         $ACO=New-Object System.Security.AccessControl.FileSystemAccessRule("Pester1", "Read", "ContainerInherit,ObjectInherit",0,"Allow")
         $ACL.AddAccessRule($ACO)
         $ACO=New-Object System.Security.AccessControl.FileSystemAccessRule("Pester2", "Read", "ContainerInherit,ObjectInherit",0,"Allow")
         $ACL.AddAccessRule($ACO)
         Set-Acl -Path $F_Foo.FullName -AclObject $ACL
         $ResultACL = (Get-Acl $F_Foo.FullName).Access.IdentityReference
         $ResultACL -match 'Pester1' | Should -Not -BeNullOrEmpty
         $ResultACL -match 'Pester2' | Should -Not -BeNullOrEmpty
      }
      It "add pester2 to acl WITHOUT any inherited ace's" {
         $ACL = Get-Acl $F_Bar.FullName
         $ACL.SetAccessRuleProtection($true,$false)
         Set-Acl -Path $F_Bar -AclObject $ACL
         $ACO=New-Object System.Security.AccessControl.FileSystemAccessRule("Pester2", "Full", "ContainerInherit,ObjectInherit",0,"Allow")
         $ACL.AddAccessRule($ACO)
         Set-Acl -Path $F_Bar.FullName -AclObject $ACL
         $ResultACL = (Get-Acl $F_Bar.FullName).Access
         $ResultACL.IdentityReference -match 'Pester2' | Should -Not -BeNullOrEmpty
         $resultACL.Count | Should -be 1
      }
      It "add pester1 and pester2 to acl WITHOUT any inherited ace's" {
         $ACL = Get-Acl $F_Bar.FullName
         $ACL.SetAccessRuleProtection($true,$false)
         Set-Acl -Path $F_Bar -AclObject $ACL
         $ACO=New-Object System.Security.AccessControl.FileSystemAccessRule("Pester2", "Full", "ContainerInherit,ObjectInherit",0,"Allow")
         $ACL.AddAccessRule($ACO)
         $ACO=New-Object System.Security.AccessControl.FileSystemAccessRule("Pester1", "Read", "ContainerInherit,ObjectInherit",0,"Allow")
         $ACL.AddAccessRule($ACO)
         Set-Acl -Path $F_Bar.FullName -AclObject $ACL
         $ResultACL = (Get-Acl $F_Bar.FullName).Access
         $ResultACL.IdentityReference -match 'Pester2' | Should -Not -BeNullOrEmpty
         $ResultACL.IdentityReference -match 'Pester1' | Should -Not -BeNullOrEmpty
         $resultACL.Count | Should -be 2
      }
   }# context
}