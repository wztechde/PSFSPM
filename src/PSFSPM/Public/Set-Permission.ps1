<#
.SYNOPSIS
   Set-Permission sets permission(s) on one or more paths
.DESCRIPTION
   Set-Permission is used to set permissions on one or more paths (can even by piped in to the function).
   You can set permissions for several users at once given as a list.
   The function also takes several combinations of parameters to perform it's magic
   Path + PermissionObject allows to give a path in combination with one or more permission objects
   PathPermissionObject allows to give a full path permission objct to process (path with permissions)
   DirectoryObject takes a complete directory permission object to process (root / child model)
.PARAMETER Path
   One or more paths, where you want to set the permission(s) on.
   The validation, if the path exists may provide wrong results - make sure, that the given path
   is not available in current dir.
.PARAMETER Identity
   One or more identities for which you want to set rights for
.PARAMETER Permission
   One or more permissions to set for the according identity(ies)
.PARAMETER Inheritance
   One or more inheritances to set for the according identity(ies)
.PARAMETER PermissionObject
   One or more PermissionObjects to apply to the given path
.PARAMETER PathPermissionObject
   One or more PathPermissionObjects to process
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
   [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'Default')]
   param (
      # Path(s) to set permission(s) on
      [Parameter(Position = 0, Mandatory, ValueFromPipeline, ParameterSetName = 'Default')]
      [Parameter(Position = 0, Mandatory, ValueFromPipeline, ParameterSetName = 'PermissionObject')]
      [ValidateScript({
            if (-not(Test-Path $_ -PathType 'Container') -and -not(Test-Path $_ -PathType 'Leaf')) {
               throw "$_ is not a valid file or folder path."
            }
            $true
         })]
      [string]$Path,
      # The identity(ies) to set permission for
      [Parameter(ParameterSetName = 'Default')]
      [Alias('Principal')]
      [String[]]$Identity,
      # The permission(s) to set
      [Parameter(ParameterSetName = 'Default')]
      [FMFileRights[]]$FileRight,
      # The inheritance(s) to set
      [Parameter(ParameterSetName = 'Default')]
      [IMInheritance[]]$Inheritance,
      # A permission object with all necessary permissions
      [Parameter(ParameterSetName = 'PermissionObject', DontShow)]
      [FMPermission[]]$PermissionObject,
      # A path permission object that also contains path information
      [Parameter(ParameterSetName = 'PathPermissionObject', DontShow)]
      [FMPathPermission[]]$PathPermissionObject,
      # primarily for testing purposes
      [Switch]$PassThru
   )

   begin {
      #parameter checks
      if ($PSBoundParameters.ContainsKey('Identity') -or $PSBoundParameters.ContainsKey('FileRight') -or $PSBoundParameters.ContainsKey('Inheritance')) {
         If (($Identity.Count -ne $FileRight.Count) -or ($Identity.Count -ne $Inheritance.Count)) {
            Throw "Counts of identities, permissions and inheritances don't match - please check"
         }
      }
      $Output = @()
   }

   process {
      # convert Default paramset to FMPathParameter
      if ($PSBoundParameters.ContainsKey('Identity')) {
         Write-Verbose "$((Get-Date).TimeofDay) Parameterset: Default"
         $TempPermission = @()
         for ($i = 0; $i -lt $Identity.Count; $i++) {
            $TempPermission += New-FMPermission -Identity $Identity[$i] -FileRight $FileRight[$i] -Inheritance $Inheritance[$i]
         }#end for
         $TempFMPP = New-FMPathPermission -Path $Path -InputObject $TempPermission
      }
      elseif ($PSBoundParameters.ContainsKey('PermissionObject')) {
         Write-Verbose "$((Get-Date).TimeofDay) Parameterset: PermissionObject"
         $TempFMPP = New-FMPathPermission -Path $Path -InputObject $PermissionObject
      }
      else {
         #PathPermissionObject
         Write-Verbose "$((Get-Date).TimeofDay) Parameterset: PathPermissionObject"
         $TempFMPP = $PathPermissionObject
      }
      $TempFMPP | ForEach-Object {
         if ($PSCmdlet.ShouldProcess("$_.Path)", 'Set_Access')) {
            $output += $_.SetAccess()
         }
      }
   }

   end {
      if ($PassThru) {
         Return $TempFMPP
      }
      $Output
   }
}#end Set-Permission