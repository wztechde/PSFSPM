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

Describe 'FMDirectory' -Tag Unit {
   Context 'New-FMDirectory' {
      BeforeAll {
         $TempDir = New-Item -Path $TestDrive -Name "TEST" -ItemType Directory -Force
         $FMPP1 = New-FMPathPermission -Path $TempDir -FileRight 'Read' -Inheritance 'ThisFolderOnly' -Identity 'test'
         $FMPP2 = New-FMPathPermission -Path $TempDir -FileRight 'Read' -Inheritance 'ThisFolderOnly' -Identity 'VORDEFINIERT\Benutzer'
         $FMPP3 = New-FMPathPermission -Path 'Hallo' -FileRight 'Read' -Inheritance 'ThisFolderOnly' -Identity 'VORDEFINIERT\Benutzer'
      }
      It "Function should have parameters 'Root' and 'Child'" {
         Get-Command New-FMDirectory | Should -HaveParameter Root
         Get-Command New-FMDirectory | Should -HaveParameter Child
      }#end it
      It "Should throw for children with full path - children must not contain any drive letters" {
          {New-FMDirectory -Root $FMPP1 -Child $FMPP2 } | should -Throw
          {New-FMDirectory -Root $FMPP1 -Child $FMPP3,$FMPP2 } | should -Throw
      }
      It 'Should return a FMDirectory object - single child' {
         $result = New-FMDirectory -Root $FMPP1 -Child $FMPP3
         $result.Gettype() | Should -Be 'FMDirectory'
      }#end it
      It 'Should return a FMDirectory object - multiple children' {
         $result = New-FMDirectory -Root $FMPP1 -Child $FMPP3,$FMPP3
         $result.Gettype() | Should -Be 'FMDirectory'
         $result = New-FMDirectory -Root $FMPP1 -Child $FMPP3,$FMPP3,$FMPP3,$FMPP3
         $result.Gettype() | Should -Be 'FMDirectory'
      }#end it
   }#end context
   Context 'FMDirectory - Test methods' {
      Context 'Method: Get_ChildFullName(index)' {
         BeforeAll {
            $TempDir = New-Item -Path $TestDrive -Name "TEST" -ItemType Directory -Force
            $FMPP1 = New-FMPathPermission -Path $TempDir -FileRight 'Read' -Inheritance 'ThisFolderOnly' -Identity 'test'
            $FMPP2 = New-FMPathPermission -Path 'Hallo' -FileRight 'Read' -Inheritance 'ThisFolderOnly' -Identity 'VORDEFINIERT\Benutzer'
         }#end it
         It "Should return a concatenated path string" {
            $temp=New-FMDirectory -Root $FMPP1 -Child $FMPP2
            $temp.GetChildFullname(0) | Should -Be "$Tempdir\Hallo"
         }#end it
         It "Should fail returning a concatenated path string - index out of bounds" {
            $temp=New-FMDirectory -Root $FMPP1 -Child $FMPP2
            {$temp.GetChildFullname(1)} | Should -Throw
         }#end it
      }#end context
   }#end context
}#end describe