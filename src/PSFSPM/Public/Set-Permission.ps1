<#
.SYNOPSIS
   Set-Permission sets permission(s) on one or more paths
.DESCRIPTION
   Set-Permission is used to set permissions on one or more paths (can even by piped in to the function).
   You can set permissions for several users at once given as a list.
.NOTES
   Information or caveats about the function e.g. 'This function is not supported in Linux'
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
   [CmdletBinding()]
   param (

   )

   begin {

   }

   process {

   }

   end {

   }
}#end Set-Permission

