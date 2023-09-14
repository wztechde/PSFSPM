#-------------------------------------------------------------------------
Set-Location -Path $PSScriptRoot
#Write-Host $PSScriptRoot
#-------------------------------------------------------------------------
$ModuleName = 'PSFSPM'
$PathToManifest = [System.IO.Path]::Combine('..', $ModuleName, "$ModuleName.psd1")
#-------------------------------------------------------------------------
if (Get-Module -Name $ModuleName -ErrorAction 'SilentlyContinue') {
   #if the module is already in memory, remove it
   Remove-Module -Name $ModuleName -Force
}
Import-Module $PathToManifest -Force
#-------------------------------------------------------------------------
# Import custom assertions
$Temp = "$PSScriptRoot\..\Tests"
$PathToCustomAssertions = Resolve-Path "$temp\CustomAssertions.psm1"
Remove-Module $PathToCustomAssertions -Force -ErrorAction SilentlyContinue
Import-Module $PathToCustomAssertions -Force
#-------------------------------------------------------------------------


Function Should-BeInACLOld ($ActualValue, $ExpectedValue, [Switch]$Negate) {
   $succeded = $false
   $failureMessage = "The identity $($ExpectedValue.Identity) not found ACL"
   # mock filesystemaccessrule
   $ExpectedMock = New-MockObject -Type System.Security.AccessControl.FileSystemAccessRule -Properties @{
      IdentityReference = $ExpectedValue.Identity
      FileSystemRights  = "$($ExpectedValue.FileRight), Synchronize"
      InheritanceFlags  = $ExpectedValue.GetDetailedInheritance().Inherit
      PropagationFlags  = $ExpectedValue.GetDetailedInheritance().Propagate
   }
   $ActualValue.Access | ForEach-Object {
      $result = Compare-Object $_ $ExpectedMock -Property IdentityReference, FileSystemRights, InheritanceFlags, PropagationFlags -ExcludeDifferent
      #$result = Compare-Object $_ $ExpectedMock -Property IdentityReference -IncludeEqual -ExcludeDifferent
      if ($null -ne $result)
      { $succeded = $true }
   }
   If ($Negate) {
      $succeded = -not $succeded
      $failureMessage = "Expected not to find $($ExpectedValue.Identity) in the ACL, but it was"
   }#end if

   return [PSCustomObject]@{
      Succeeded      = $succeded
      FailureMessage = $failureMessage
   }#end r
}
function Should-BeInACL (
   [System.Security.AccessControl.FileSystemAccessRule[]]$ActualValue,
   [System.Security.AccessControl.FileSystemSecurity]$ExpectedValue,
   [Switch]$Negate
) {
   <#
.SYNOPSIS
   Checks if a given FileSystemAccessRule is within an acl
.DESCRIPTION
   Checks if  the given FileSystemAccessRule (ExpectedValue) is within the given acl (ActualValue)
.PARAMETER ActualValue
   The FileSystemAccessRule to check
.parameter ExpectedValue
   The acl to check against
.PARAMETER Negate
   Support -Not
.EXAMPLE
   $ACL = Get-Acl -Path 'C:\Temp'
   # $FP is a FMPermission object
   $FP.GetFileSystemAccessRule() | Should -BeInACL $ACL
#>
   $succeeded = $false
   $failureMessage = "Expected to find $($ActualValue.IdentityReference) in the ACL, but it wasn't"

   # iterate
   $ExpectedValue.Access | ForEach-Object {
      $result = Compare-Object $_ $ActualValue -Property IdentityReference, FileSystemRights, InheritanceFlags, PropagationFlags -ExcludeDifferent -IncludeEqual
      if ($null -ne $result) {
         $succeeded = $true
         $failureMessage = ""
      }
   }
   if ($Negate) {
      $succeeded = -not $succeeded
      $failureMessage = "Expected not to find $($ActualValue.IdentityReference) in the ACL, but it was"
   }#end if
   #return result
   return [PSCustomObject]@{
      Succeeded      = $succeeded
      FailureMessage = $failureMessage
   }#end return

}#end Should-BeInACL

$FMPP1 = New-FMPermission -FileRight 'Read' -Inheritance File -Identity 'VORDEFINIERT\Benutzer'
$P = Get-Acl C:\Temp
Should-BeInACL -ActualValue $FMPP1.GetFileSystemAccessRule() -ExpectedValue $P

$FP = New-FMPermission -FileRight 'Read' -Inheritance File -Identity 'VORDEFINIERT\Benutzer'
$FP1 = New-FMPermission -FileRight 'Read' -Inheritance File -Identity 'VORDEFINIE\Test'
$AC = $p.Access
$FPS = @()
$FPS += $Fp.GetFileSystemAccessRule()
Compare-Object $AC $FPS -ExcludeDifferent -IncludeEqual -Property IdentityReference, FileSystemRight

Describe "Test new assertion" {
   BeforeAll {
      $FP = New-FMPermission -FileRight 'Read' -Inheritance File -Identity 'VORDEFINIERT\Benutzer'
      $FP1 = New-FMPermission -FileRight 'Read' -Inheritance File -Identity 'VORDEFINIE\Test'
      $ac = Get-Acl c:\temp
   }
   It "Should be in acl" {
      $FP.GetFileSystemAccessRule() | Should -BeInACL $ac
   }
   It "Should be in acl2" {
      $FP1.GetFileSystemAccessRule() | Should -BeInACL $ac
   }
   It "Should not be in acl" {
      $FP1.GetFileSystemAccessRule() | Should -Not -BeInACL $ac
   }
   It "Should not be in acl 2" {
      $FP.GetFileSystemAccessRule() | Should -Not -BeInACL $ac
   }
}