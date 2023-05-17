BeforeAll {
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

   # Create temporary users
   New-LocalUser Pester1 -NoPassword
   New-LocalUser Pester2 -NoPassword
   New-LocalUser Pester3 -NoPassword
   New-LocalGroup GPester1 -Description 'Pester Group 1'
   New-LocalGroup GPester2 -Description 'Pester Group 2'
   Add-LocalGroupMember -Group GPester1 -Member Pester1
   Add-LocalGroupMember -Group GPester2 -Member Pester2
}

AfterAll {
   Remove-LocalUser Pester1, Pester2, Pester3
   Remove-LocalGroup Gpester1, GPester2
   Remove-Item C:\tmp\foo\ -Recurse
}
Function CreateDirectories {
   Remove-Item C:\tmp\foo\ -Recurse -ErrorAction SilentlyContinue
   $Global:F_Foo = mkdir "C:\tmp\foo" -Force
   $F_Foo_txt = New-Item -Path "$($F_Foo)\test.txt" -ItemType File -Force
   $F_Bar = mkdir "$F_Foo\bar" -Force
   $F_Bar_txt = New-Item -Path "$($F_Bar)\test.txt" -ItemType File -Force
   $F_Clara = mkdir "$F_Foo\bar\clara" -Force
   $F_Donna = mkdir "$F_Foo\bar\clara\donna" -Force
}
Describe 'Set-Permission Integration testing' -Tag Integration {
   Context 'simple 1: 1 user TFSFF' {
      BeforeAll {
         CreateDirectories
         $FPM = New-FMPathPermission -Path $F_Foo -Identity Pester1 -Permission Write -Inheritance ThisFolderSubfoldersAndFiles
         $Result = Set-Permission -PathPermissionObject $FPM
         $CPath = "$F_Foo\Test"
         $ACLP = @{
            fsr = 'FileSystemRights'
            act = 'AccessControlType'
            idr = 'IdentityReference'
            ish = 'IsInherited'
            ihf = 'InheritanceFlags'
            ppf = 'PropagationFlags'
         }
      }
      It "Checks for user <user> on <path> - should <is> member of acl" -ForEach @(
         @{path = ''; user = 'pester1'; is = 'be' }
         @{path = 'test.txt'; user = 'pester1' ; is = 'be' }
         @{path = 'test.txt'; user = 'pester2' ; is = 'not be' }
      ) {
         $CPath = Join-Path $Global:F_Foo -ChildPath $Path
         $ACL = Get-Acl $CPath
         if ($is -eq 'be') {
            $ACL.Access.IdentityReference -match $User | Should -Not -BeNullOrEmpty
         }
         else {
            $ACL.Access.IdentityReference -match $User | Should -BeNullOrEmpty
         }
      }# end it
      It "Checks on c:\tmp\<path> for flag <filterflag> on <filtervalue> - <flag> is <value>" -ForEach @(
         @{path = ''; filterflag = 'idr'; filtervalue = 'pester1'; flag = 'ish'; value = $false }
         @{path = ''; filterflag = 'idr'; filtervalue = 'pester1'; flag = 'fsr'; value = "Write, Synchronize" }
         @{path = ''; filterflag = 'idr'; filtervalue = 'pester1'; flag = 'ihf'; value = "ContainerInherit, ObjectInherit" }
         @{path = 'test.txt'; filterflag = 'idr'; filtervalue = 'pester1'; flag = 'ish'; value = $true }
         @{path = 'test.txt'; filterflag = 'idr'; filtervalue = 'pester1'; flag = 'fsr'; value = "Write, Synchronize" }
         @{path = 'test.txt'; filterflag = 'idr'; filtervalue = 'pester1'; flag = 'ihf'; value = "None" }
         @{path = 'bar'; filterflag = 'idr'; filtervalue = 'pester1'; flag = 'ish'; value = $true }
         @{path = 'bar'; filterflag = 'idr'; filtervalue = 'pester1'; flag = 'fsr'; value = "Write, Synchronize" }
         @{path = 'bar'; filterflag = 'idr'; filtervalue = 'pester1'; flag = 'ihf'; value = "ContainerInherit, ObjectInherit" }
      ) {
         $CPath = Join-Path $Global:F_Foo -ChildPath $Path
         $ACL = Get-Acl $CPath
         # filter ouut ace
         $filter = $ACLP.$($Filterflag)
         $Filtered = $acl.access | Where-Object { $_.$filter -match $filtervalue }
         $flg = $ACLP.$($flag)
         $filtered.$($flg) | Should -Be $Value
      }# end it
   }#end context
   Context 'a little more complex: 2 users, TFO and TFSFF' {
      BeforeAll {
         CreateDirectories
         $FPM = New-FMPathPermission -Path $F_Foo -Identity Pester1, Pester2 -Permission Read, Modify -Inheritance ThisFolderOnly, ThisFolderSubfoldersAndFiles
         $Result = Set-Permission -PathPermissionObject $FPM
         $ACLP = @{
            fsr = 'FileSystemRights'
            act = 'AccessControlType'
            idr = 'IdentityReference'
            ish = 'IsInherited'
            ihf = 'InheritanceFlags'
            ppf = 'PropagationFlags'
         }
      }
      It "Checks for user <user> on <path> - should <is> member of acl" -ForEach @(
         @{path = ''; user = 'pester1'; is = 'be' }
         @{path = ''; user = 'pester2'; is = 'be' }
         @{path = 'test.txt'; user = 'pester1' ; is = 'not be' }
         @{path = 'test.txt'; user = 'pester2' ; is = 'be' }
         @{path = 'bar'; user = 'pester2' ; is = 'be' }
         @{path = 'bar\clara'; user = 'pester1' ; is = 'not be' }
         @{path = 'bar\clara'; user = 'pester2' ; is = 'be' }

      ) {
         $CPath = Join-Path $Global:F_Foo -ChildPath $Path
         $ACL = Get-Acl $CPath
         if ($is -eq 'be') {
            $ACL.Access.IdentityReference -match $User | Should -Not -BeNullOrEmpty
         }
         else {
            $ACL.Access.IdentityReference -match $User | Should -BeNullOrEmpty
         }
      }# end it
      It "Checks on c:\tmp\<path> for flag <filterflag> on <filtervalue> - <flag> is <value>" -ForEach @(
         @{path = ''; filterflag = 'idr'; filtervalue = 'pester1'; flag = 'ish'; value = $false }
         @{path = ''; filterflag = 'idr'; filtervalue = 'pester1'; flag = 'fsr'; value = "Read, Synchronize" }
         @{path = ''; filterflag = 'idr'; filtervalue = 'pester1'; flag = 'ihf'; value = "None" }
         @{path = 'test.txt'; filterflag = 'idr'; filtervalue = 'pester2'; flag = 'ish'; value = $true }
         @{path = 'test.txt'; filterflag = 'idr'; filtervalue = 'pester2'; flag = 'fsr'; value = "Modify, Synchronize" }
         @{path = 'test.txt'; filterflag = 'idr'; filtervalue = 'pester2'; flag = 'ihf'; value = "None" }
         @{path = 'bar'; filterflag = 'idr'; filtervalue = 'pester2'; flag = 'ish'; value = $true }
         @{path = 'bar'; filterflag = 'idr'; filtervalue = 'pester2'; flag = 'fsr'; value = "Modify, Synchronize" }
         @{path = 'bar'; filterflag = 'idr'; filtervalue = 'pester2'; flag = 'ihf'; value = "ContainerInherit, ObjectInherit" }
      ) {
         $CPath = Join-Path $Global:F_Foo -ChildPath $Path
         $ACL = Get-Acl $CPath
         # filter ouut ace
         $filter = $ACLP.$($Filterflag)
         $Filtered = $acl.access | Where-Object { $_.$filter -match $filtervalue }
         $flg = $ACLP.$($flag)
         $filtered.$($flg) | Should -Be $Value
      }# end it

   }# end context
   Describe 'some more power: 3 users, TFSF,TFSFF,SF' -Tag Integration {
      BeforeAll {
         CreateDirectories
         $FPM = New-FMPathPermission -Path $F_Foo -Identity Pester1, Pester2, Pester3 -Permission Read, Modify, Write -Inheritance ThisFolderAndSubfolders, ThisFolderSubfoldersAndFiles, SubfoldersOnly
         $Result = Set-Permission -PathPermissionObject $FPM
         $ACLP = @{
            fsr = 'FileSystemRights'
            act = 'AccessControlType'
            idr = 'IdentityReference'
            ish = 'IsInherited'
            ihf = 'InheritanceFlags'
            ppf = 'PropagationFlags'
         }
      }# end BeforeAll
      Context 'Base permissions' {
         It "Checks for user <user> on <path> - should <is> member of acl" -ForEach @(
            @{path = ''; user = 'pester1'; is = 'be' }
            @{path = ''; user = 'pester2'; is = 'be' }
            @{path = ''; user = 'pester3'; is = 'be' }
            @{path = 'test.txt'; user = 'pester1' ; is = 'not be' }
            @{path = 'test.txt'; user = 'pester2' ; is = 'be' }
            @{path = 'test.txt'; user = 'pester3' ; is = 'not be' }
            @{path = 'bar'; user = 'pester1' ; is = 'be' }
            @{path = 'bar'; user = 'pester2' ; is = 'be' }
            @{path = 'bar'; user = 'pester3' ; is = 'be' }
            @{path = 'bar\clara'; user = 'pester1' ; is = 'be' }
            @{path = 'bar\clara'; user = 'pester2' ; is = 'be' }
            @{path = 'bar\clara'; user = 'pester3' ; is = 'be' }

         ) {
            $CPath = Join-Path $Global:F_Foo -ChildPath $Path
            $ACL = Get-Acl $CPath
            if ($is -eq 'be') {
               $ACL.Access.IdentityReference -match $User | Should -Not -BeNullOrEmpty
            }
            else {
               $ACL.Access.IdentityReference -match $User | Should -BeNullOrEmpty
            }
         }# end it
      }# end Context
      Context 'Deep folder checks' {
         It "Checks on c:\tmp\<path> for flag <filterflag> on <filtervalue> - <flag> is <value>" -ForEach @(
            @{path = ''; filterflag = 'idr'; filtervalue = 'pester1'; flag = 'ish'; value = $false }
            @{path = ''; filterflag = 'idr'; filtervalue = 'pester1'; flag = 'fsr'; value = "Read, Synchronize" }
            @{path = ''; filterflag = 'idr'; filtervalue = 'pester1'; flag = 'ihf'; value = "ContainerInherit" }
            @{path = ''; filterflag = 'idr'; filtervalue = 'pester2'; flag = 'ish'; value = $false }
            @{path = ''; filterflag = 'idr'; filtervalue = 'pester2'; flag = 'fsr'; value = "Modify, Synchronize" }
            @{path = ''; filterflag = 'idr'; filtervalue = 'pester2'; flag = 'ihf'; value = "ContainerInherit, ObjectInherit" }
            @{path = 'test.txt'; filterflag = 'idr'; filtervalue = 'pester2'; flag = 'ish'; value = $true }
            @{path = 'test.txt'; filterflag = 'idr'; filtervalue = 'pester2'; flag = 'fsr'; value = "Modify, Synchronize" }
            @{path = 'test.txt'; filterflag = 'idr'; filtervalue = 'pester2'; flag = 'ihf'; value = "None" }
            @{path = 'bar'; filterflag = 'idr'; filtervalue = 'pester2'; flag = 'ish'; value = $true }
            @{path = 'bar'; filterflag = 'idr'; filtervalue = 'pester2'; flag = 'fsr'; value = "Modify, Synchronize" }
            @{path = 'bar'; filterflag = 'idr'; filtervalue = 'pester2'; flag = 'ihf'; value = "ContainerInherit, ObjectInherit" }
            @{path = ''; filterflag = 'idr'; filtervalue = 'pester3'; flag = 'ish'; value = $false }
            @{path = ''; filterflag = 'idr'; filtervalue = 'pester3'; flag = 'fsr'; value = "Write, Synchronize" }
            @{path = ''; filterflag = 'idr'; filtervalue = 'pester3'; flag = 'ihf'; value = "ContainerInherit" }
         ) {
            $CPath = Join-Path $Global:F_Foo -ChildPath $Path
            $ACL = Get-Acl $CPath
            # filter ouut ace
            $filter = $ACLP.$($Filterflag)
            $Filtered = $acl.access | Where-Object { $_.$filter -match $filtervalue }
            $flg = $ACLP.$($flag)
            $filtered.$($flg) | Should -Be $Value
         }# end it
      }#end context
   }# end context
}#end describe
