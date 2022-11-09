<#
.SYNOPSIS
   Get-ChilditemEnhanced is am emhanced version of Get-Childitem
.DESCRIPTION
   Get-ChilditemEnhanced adds an additional parameter -StartDepth
.PARAMETER Attributes
   Filter items by attribute
.PARAMETER Depth
   Filter items by depth
.PARAMETER Directory
   Retunr directories only
.PARAMETER Exclude
   Filter items by exclude rules
.PARAMETER File
   Return files only
.PARAMETER Filter
   Define filter for items
.PARAMETER FollowSymlink
   Boolean follow symlinks or not
.PARAMETER Force
   Forcefully working
.PARAMETER Hidden
   Return hidden items only
.PARAMETER Include
   Filter items by include rules
.PARAMETER LiteralPath
   A full path information
.PARAMETER Name
   The part of the name you're looking for - wildscards allowed
.PARAMETER Path
   Where to look for items
.PARAMETER ReadOnly
   Return only ReadOnly items
.PARAMETER Recurse
   Recurse dirs
.PARAMETER System
   Return system files only
.PARAMETER StartDepth
   The depth from where you want to retrieve items
.NOTES
   See for proxy funtions to get more info
.LINK
   Specify a URI to a help page, this will show when Get-Help -Online is used.
.EXAMPLE
   Get-ChilditemEnhanced C:\Temp -StartDepth 3
   Return all items from level 3 down, i.d. C:\Temp\1\2\3
#>
Function Get-ChildItemEnhanced {
   <#
.ForwardHelpTargetName Microsoft.PowerShell.Management\Get-ChildItem
.ForwardHelpCategory Cmdlet

#>
   [CmdletBinding(DefaultParameterSetName = 'Items', HelpUri = 'https://go.microsoft.com/fwlink/?LinkID=2096492')]
   [Alias('GCE')]
   Param(

      [Parameter(ParameterSetName = 'Items', Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
      [string[]]$Path,

      [Parameter(ParameterSetName = 'LiteralItems', Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
      [Alias('PSPath', 'LP')]
      [string[]]$LiteralPath,

      [Parameter(Position = 1)]
      [string]$Filter,

      [string[]]$Include,

      [string[]]$Exclude,

      [Alias('s')]
      [switch]$Recurse,

      [int]$Depth,

      [int]$StartDepth,

      [switch]$Force,

      [switch]$Name,

      [System.Management.Automation.FlagsExpression[System.IO.FileAttributes]]$Attributes,

      [switch]$FollowSymlink,

      [Alias('ad')]
      [switch]$Directory,

      [Alias('af')]
      [switch]$File,

      [Alias('ah', 'h')]
      [switch]$Hidden,

      [Alias('ar')]
      [switch]$ReadOnly,

      [Alias('as')]
      [switch]$System
   )

   Begin {

      Write-Verbose "[BEGIN  ] Starting $($MyInvocation.Mycommand)"
      Write-Verbose "[BEGIN  ] Using parameter set $($PSCmdlet.ParameterSetName)"
      Write-Verbose ($PSBoundParameters | Out-String)

      try {
         $outBuffer = $null
         if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer)) {
            $PSBoundParameters['OutBuffer'] = 1
         }

         $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Microsoft.PowerShell.Management\Get-ChildItem', [System.Management.Automation.CommandTypes]::Cmdlet)
         # Calculate StartDepth only, if recurse is given, too, otherwise it makes no sense
         if ($PSBoundParameters.ContainsKey('StartDepth')) {
            $PSBoundParameters.Remove('StartDepth') | Out-Null
            if (-not $PSBoundParameters.ContainsKey('Recurse')) {
               $PSBoundParameters.Add('Recurse', $true)
            }
            $GivenDepth = ($Path.Split('\')).Count - 1
            $TargetDepth = $GivenDepth + $StartDepth
            $scriptCmd = { & $wrappedCmd @PSBoundParameters | Where-Object { ($_.fullname.Split('\')).Count - 1 -eq $TargetDepth } }
         }
         else {
            $scriptCmd = { & $wrappedCmd @PSBoundParameters }
         }
         $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
         $steppablePipeline.Begin($PSCmdlet)
      }
      catch {
         throw
      }

   } #begin

   Process {


      try {
         $steppablePipeline.Process($_)
      }
      catch {
         throw
      }


   } #process

   End {

      Write-Verbose "[END    ] Ending $($MyInvocation.Mycommand)"

      try {
         $steppablePipeline.End()
      }
      catch {
         throw
      }

   } #end

} #end function Get-ChildItem