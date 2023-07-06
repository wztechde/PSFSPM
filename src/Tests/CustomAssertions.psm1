# Description: This file contains custom assertions for Pester tests

# the following function checks if a given FMPermission is within an acl
Function Should-ContainACE ($ActualValue, $ExpectedValue, [Switch]$Negate) {
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

Add-ShouldOperator -Name ContainACE -InternalName 'Should-ContainACE' -Test ${function:Should-ContainACE} -Alias 'CACE'


#$FMPP1 = New-FMPathPermission -Path 'C:\Temp' -FileRight 'Read' -Inheritance FilesOnly -Identity 'VORDEFINIERT\Benutzer'
#$P = Get-Acl C:\Temp
#Should-BeInACL -ActualValue $P -ExpectedValue $FMPP1.Permission



