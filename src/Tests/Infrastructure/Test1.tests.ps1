Function CreateDirs {
   $Global:F_Foo = "$TestDrive"
   MKdir "$Global:F_Foo\Foo" -force
   mkdir "$Global:F_Foo\Bas" -Force
}

Describe 'Voller Kram' {
   Context "Neue Runde" {
      BeforeEach {
         CreateDirs
      }
      It "Testet Alles \$F_Foo\\<pth>: <user>" -ForEach @(
         @{Pth="Foo";User="wzimmerm"},
         @{Pth="Bar";User="wzimmerm"}
      ){
         $pth2=Join-Path $Global:F_Foo -ChildPath $PTH
         $Access = (Get-Acl $Pth2).Access
         $Mt=$Access.IdentityReference -match $User
         $Mt | Should -Be "Wolfram"

      }
      It "Testet den Kram danach <pth>: <user>" -TestCases @(
         @{Pth=$Global:F_Foo;User="Pester1"},
         @{Pth=$Global:F_Foo_txt;User="Pester1"}
      ){
         $Global:FPM.Permission.Identity
      }
   }
}

# write pester tests for Set-Permission using the classes from this module
