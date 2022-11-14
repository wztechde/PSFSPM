<#
.SYNOPSIS
   Set-Permission sets permission(s) on one or more paths
.DESCRIPTION
   Set-Permission is used to set permissions on one or more paths (can even by piped in to the function).
   You can set permissions for several users at once given as a list.
.NOTES
   Information or caveats about the function e.g. 'This function is not supported in Linux'
.PARAMETER Path
   One or more paths, where you want to set the permission(s) on.
   The validation, if the path exists may provide wrong results - make sure, that the given path
   is not available in current dir.
.PARAMETER Identity
   One or more identities for which you want to set rights for
.EXAMPLE
   Set-Permission -Path C:\Temp -Identity/Principal foo -Permission Write -Inheritance ThisFolderSubfoldersAndFiles
   Set permission for C:\Temp to 'Write' for user 'foo' with inheritance 'ThisFolderSubfoldersAndFiles'
.EXAMPLE
   Set-Permission -Path C:\Temp -Identity foo,bar -Permission Write,Read -Inheritance ThisFolderSubfoldersAndFiles,ThisFolderOnly
   Set permission for C:\Temp to
      'Write' for user 'foo' with inheritance 'ThisFolderSubfoldersAndFiles'
      'Read' for user 'bar' with inheritance 'ThisFolderOnly' accordingly to the arrays given
.EXAMPLE
   Set-Permission -Path 'C:\Temp','d:\Temp' -Identity foo,bar -Permission 'Write','Read' -Inheritance ThisFolderSubfoldersAndFiles,ThisFolderOnly
   Set Permission for both C:\Temp AND D:\Temp to
      'Write' for user 'foo' with inheritance 'ThisFolderSubfoldersAndFiles'
      'Read' for user 'bar' with inheritance 'ThisFolderOnly' accordingly to the arrays given
.EXAMPLE
   C:\Temp | Set-Permission -Identity foo,bar -Permission 'Write','Read' -Inheritance ThisFolderSubfoldersAndFiles,ThisFolderOnly
   Set permission for C:\Temp to 'Write' for user 'foo' with inheritance 'ThisFolderSubfoldersAndFiles', this time using the pipeline
.EXAMPLE
   'C:\Temp','D:\Temp' | Set-Permission -Identity foo,bar -Permission 'Write','Read' -Inheritance ThisFolderSubfoldersAndFiles,ThisFolderOnly
   Set permission for both C:\Temp AND D:\Temp
      to 'Write' for user 'foo' with inheritance 'ThisFolderSubfoldersAndFiles', this time using the pipeline
.EXAMPLE
   Get-ChilditemEnhanced C:\Temp -StartDepth 2 | Set-Permission -Identity foo,bar -Permission 'Write','Read' -Inheritance ThisFolderSubfoldersAndFiles,ThisFolderOnly
   Set permssions for the result of the GCE call (all items that are two levels from given path) to
      'Write' for user 'foo' with inheritance 'ThisFolderSubfoldersAndFiles'
      'Read' for user 'bar' with inheritance 'ThisFolderOnly' accordingly to the arrays given
      using the pipeline
.EXAMPLE
   Set-Permission C:\Temp -

   #>
function Set-Permission {
   [CmdletBinding(SupportsShouldProcess)]
   param (
      # Path(s) to set permission(s) on
      [Parameter(Position = 0, Mandatory, ValueFromPipeline)]
      [Parameter(ParameterSetName = 'Default')]
      [Parameter(ParameterSetName = 'PermissionObject')]
      [Parameter(ParameterSetName = 'PathPermissionObject')]
      [ValidateScript({
         if (Test-Path $_) { $true }
         else { Throw "Path $_ is not valid" }
      })]
      [String[]]
      $Path,
      # The identity(ies) to set permission for
      [Parameter(ParameterSetName = 'Default')]
      [Alias('Principal')]
      [String[]]$Identity,
      # The permission(s) to set
      [Parameter(ParameterSetName = 'Default')]
      [String]$Permission,
      # The inheritance(s) to set
      [Parameter(ParameterSetName = 'Default')]
      [String]$Inheritance,
      # A permission object with all necessary permissions
      [Parameter(ParameterSetName = 'PermissionObject',DontShow)]
      [String]$PermissionObject,
      [Parameter(ParameterSetName = 'PathPermissionObject',DontShow)]
      [String]$PathPermissionObject
   )

   begin {
      #parameter checks
      if ($PSBoundParameters.ContainsKey('Identity') -or $PSBoundParameters.ContainsKey('Permission') -or $PSBoundParameters.ContainsKey('Inheritance')) {
         If (($Identity.Count -ne $Permission.Count) -or ($Identity.Count -ne $Inheritance.Count)) {
            Throw "Counts of identities, permissions and inheritances don't match - please check"
         }
      }
   }

   process {
      if ($PSCmdlet.ShouldProcess('Target', 'Operation')) {

      }
   }

   end {

   }
}#end Set-Permission

