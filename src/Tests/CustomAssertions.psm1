# Description: This file contains custom assertions for Pester tests

# the following function checks if a given FMPermission is within an acl
<#
.SYNOPSIS
   Should-ContainACE checks if a given ACE ist member of a reference ACL
.DESCRIPTION
   The function takes two aregument, $ActualValue and ExpextedValue.
   The expected value has to be of type FMPermission (typecast not possible, due to class type restrictions - not using 'using'),
   while the actual value is of type FileSystemAccess.
   It first checks if there is at least one ACE with the given permission and fails if not.
   It then checks for the correct FileSystemRight, followed by InheritanceFlags
.EXAMPLE
   Use in pester tests like
   $ACE=New-FMPermission -FileRight 'Read' -Inheritance 'ThisFolderOnly' -Identity 'Test'
   $ACL=Get-ACL C:\Temp
   $ACL | Should -Not -ContainAce $ACE

   Returns 'Succeeded, if there is no ACE in the ACL of C:\Temp matching the params given in $ACE
#>
Function Should-ContainACE ([System.Security.AccessControl.FileSystemSecurity]$ActualValue, $ExpectedValue, [Switch]$Negate) {
   $succeded = $true
   # filter out identity first
   $Filtered = $ActualValue.Access | Where-Object { $_.IdentityReference -like $($ExpectedValue.Identity) }
   If ($null -eq $Filtered) {
      $failureMessage = "The identity $($ExpectedValue.Identity) not found ACL"
      $succeded = $false
   }
   else {
      #end if
      if (($Filtered.FileSystemRights -match $ExpectedValue.FileRight).Count -eq 0) {
         $failureMessage = "Expected [$($ExpectedValue.FileRight)], but only found [$($Filtered.FileSystemRights)]"
         $succeded = $false
      }#end if
      else {
         if (($Filtered.InheritanceFlags -notlike ($ExpectedValue.GetDetailedInheritance()).Inherit) `
               -and ($Filtered.PropagationFlags -notlike ($ExpectedValue.GetDetailedInheritance()).Propagate)) {
            $failureMessage = "Identity: $($ExpectedValue.Identity) .The inheritance $($ExpectedValue.Inheritance) is not in the ACL"
            $succeded = $false
         }#end if
      }
   }#end else
   If ($Negate) {
      $succeded = -not $succeded
      $failureMessage = "Expected not to find $($ExpectedValue.Identity) in the ACL, but it was"
   }#end if
   return [PSCustomObject]@{
      Succeeded      = $succeded
      FailureMessage = $failureMessage
   }#end return
}
Function Should-BeInACL_old ([System.Security.AccessControl.FileSystemSecurity[]]$ActualValue, [System.Security.AccessControl.FileSystemAccessRul]$ExpectedValue, [Switch]$Negate) {
   $succeded = $false
   $failureMessage = "The identity $($ExpectedValue.IdentityReference) is not found in the given ACL"
   $ActualValue.Access | ForEach-Object {
      $result = Compare-Object $_ $ExpectedValue -Property IdentityReference, FileSystemRights, InheritanceFlags, PropagationFlags -ExcludeDifferent
      #$result = Compare-Object $_ $ExpectedMock -Property IdentityReference -IncludeEqual -ExcludeDifferent
      if ($null -ne $result)
      { $succeded = $true }
   }
   If ($Negate) {
      $succeded = -not $succeded
      $failureMessage = "Expected not to find $($ExpectedValue.IdentityReference) in the ACL, but it was"
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
Add-ShouldOperator -Name ContainACE -InternalName 'Should-ContainACE' -Test ${function:Should-ContainACE} -Alias 'CACE'
Add-ShouldOperator -Name BeInACL -InternalName 'Should-BeInACL' -Test ${function:Should-BeInACL} -Alias 'BACL'