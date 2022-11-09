function AreArraysEqual([object[]]$a1, [object[]]$a2) {
   return @(Compare-Object $a1 $a2 -SyncWindow 0).Length -eq 0
}


<#
    Report of array differences (order independent).
    Returns an empty string if the arrays match, otherwise enumerates
    differences between the expected and actual results.
    This is handy for unit tests to give meaningful output upon failure, as in
        ArrayDifferences $result $expected | Should BeNullOrEmpty
#>
function ArrayDifferences([object[]]$actual, [object[]]$expected) {
   $result = ''
   $diffs = @(Compare-Object $actual $expected)
   if ($diffs) {
      $surplus = $diffs | Where-Object SideIndicator -EQ '<='
      $missing = $diffs | Where-Object SideIndicator -EQ '=>'
      if ($surplus) {
         $result += 'Surplus: ' + ($surplus.InputObject -join ',')
      }
      if ($missing) {
         if ($result) { $result += ' && ' }
         $result += 'Missing: ' + ($missing.InputObject -join ',')
      }
   }
   $result
}
Function Copy-TSTFiles {

}

Function Copy-TSTFileStructure {

}
<#
.Synopsis
   Create a random folder structure
.DESCRIPTION
   Create a random folder structure for test purposes
.EXAMPLE
   New-FolderStructure -Path C:\Temp -FolderCount 20 -MaxFolderDepth 5

.EXAMPLE
   New-FolderStructure -Path TempDrive: -FolderCount 20 -MaxFolderDepth 5 -MaxFolderNameLength 10
#>
function New-FolderStructure {
   [CmdletBinding(SupportsShouldProcess = $True)]
   [OutputType([PSCustomObject])]
   Param
   (
      # Basepath for folder-creation
      [Parameter(Mandatory = $true,
         Position = 0)]
      [Alias('BasePath')]
      $Path,

      # Maximum number of folders
      [Parameter(Mandatory = $false)]
      [Alias('Count')]
      [uint32]$FolderCount = 20,

      # Maximum depth of folder structure
      [Parameter(Mandatory = $false)]
      [Alias('Depth')]
      [uint32]$MaxFolderDepth = 5,

      # Maximum count of characters for random folder names, minimum is set to 2
      [Parameter(Mandatory = $false)]
      [uint32]$MaxFolderNameLength = 6
   )

   $names = @()
   #create a list of random foldernames first
   for ($i = 1; ($i -lt $(Get-Random ($FolderCount * 10))); $i++) {
      $tempname = -join ([Char[]]'abcdefghijklmnopqrstuvwABCDEFGHIJKLMNOPQRSTUVWXYZ23456789' | Get-Random -Count (Get-Random $($MaxFolderNameLength + 1) -Minimum 3))
      $names += $tempname
   }
   $folderlist = @()
   #create a list of folders to create, make sure to only get unique paths
   do {
      $folder = $Path
      for ($j = 2; $j -lt $(Get-Random ($MaxFolderDepth + 1) -Minimum 3); $j++) {
         $folder += '\' + $(Get-Random -InputObject $names)
      }
      $folderlist += $folder
      $folderlist = @($folderlist | Sort-Object | Get-Unique)
      Write-Verbose "Anzahl: $($folderlist.Count)"

   }
   until ($folderlist.count -eq $FolderCount)
   #prepare output
   $Depth = @{
      Name       = 'Depth'
      Expression = { (($_ -split '\\').length - 1) - (($path -split '\\').Length - 1) }
   }
   #endregion
   #region collect directory structure
   if ($pscmdlet.ShouldProcess("$Path", 'Create random folder structure')) {
      $folderlist | ForEach-Object { mkdir $_ }
   }
   Write-Output ($folderlist | Select-Object @{Name = 'Fullname'; Expression = { $_ } }, $Depth)
}#end function

Function New-TestDriveFolderStructure {
   Param
   (
      # Basepath for folder-creation
      [Parameter(Mandatory = $true,
         Position = 0)]
      [Alias('BasePath')]
      $Path,

      # Maximum number of folders
      [Parameter(Mandatory = $false)]
      [Alias('Count')]
      [uint32]$FolderCount = 20,

      # Maximum depth of folder structure
      [Parameter(Mandatory = $false)]
      [Alias('Depth')]
      [uint32]$MaxFolderDepth = 5,
      [Parameter(Mandatory = $false)]
      [switch]$Passthru
   )
   <#
.SYNOPSIS
   Create a random folder structure
.DESCRIPTION
   Create a random folder structure with a maximum of folders and a maximum given depth
   If -Passthru is given it returns an object containing the path information and depth for each folder created
.EXAMPLE
   PS C:\> New-TestDriveFolderStructure -FolderCount 30 -MaxFolderDepth 5
   Creates a folder structure with a maximum of 30 folders deeping maximum 5 stages in the Pester $TestDrive, i.e. $TestDrive\BRITAIN\LONDON\DEPTH3\DEPTH4\DEPTH5

.EXAMPLE
   PS C:> New-TestDriveFolderStructure -Path C:\Temp -FolderCount 15 -MaxFolderDepth 3
   Creates a folder structure with a maximum of 15 folders deeping maximum 3 stages in the path c:\temp, i.e. C:\Temp\BRITAIN\LONDON\DEPTH3\DEPTH4\DEPTH5

.INPUTS
   string,uint32,unit32
.OUTPUTS
   customobject
.NOTES
   General notes
#>
   $PAth = $null
   $FolderCount = $null
   $MaxFolderDepth = $null
   $Passthru = $null
}

Function Get-83Path {
   Param (
      [String]$Path
   )
   # signature of internal API call
   $signature = '[DllImport("kernel32.dll", SetLastError=true)]
public static extern int GetShortPathName(String pathName, StringBuilder shortName, int cbShortName);'
   # turn signature into .NET type
   $type = Add-Type -MemberDefinition $signature -Namespace Tools -Name Path -UsingNamespace System.Text

   # create empty string builder with 300-character capacity
   $sb = [System.Text.StringBuilder]::new(300)
   # ask Windows to convert long path to short path with a max of 300 characters
   $rv = [Tools.Path]::GetShortPathName($path, $sb, 300)

   # output result
   if ($rv -ne 0) {
      $shortPath = $sb.ToString()
   }
   else {
      $shortPath = $null
      Write-Warning "Shoot. Could not convert $path"
   }
   $shortPath
}

<#
   Returns a temporary directory (like $Tempdrive)
   Used, because $tempdrive doesn't exist in BeforeAll{}, but is needed for later test cases
#>
function New-TemporaryDirectory {
   $parent = [System.IO.Path]::GetTempPath()
   [string] $name = [System.Guid]::NewGuid()
   New-Item -ItemType Directory -Path (Join-Path $parent $name)
}