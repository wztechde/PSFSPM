---
external help file: PSFSPM-help.xml
Module Name: PSFSPM
online version:
schema: 2.0.0
---

# Get-ChildItemEnhanced

## SYNOPSIS
Get-ChilditemEnhanced is am enhanced version of Get-Childitem

## SYNTAX

### Items (Default)
```
Get-ChildItemEnhanced [[-Path] <String[]>] [[-Filter] <String>] [-Include <String[]>] [-Exclude <String[]>]
 [-Recurse] [-Depth <Int32>] [-StartDepth <Int32>] [-Force] [-Name]
 [-Attributes <System.Management.Automation.FlagsExpression`1[System.IO.FileAttributes]>] [-FollowSymlink]
 [-Directory] [-File] [-Hidden] [-ReadOnly] [-System] [<CommonParameters>]
```

### LiteralItems
```
Get-ChildItemEnhanced -LiteralPath <String[]> [[-Filter] <String>] [-Include <String[]>] [-Exclude <String[]>]
 [-Recurse] [-Depth <Int32>] [-StartDepth <Int32>] [-Force] [-Name]
 [-Attributes <System.Management.Automation.FlagsExpression`1[System.IO.FileAttributes]>] [-FollowSymlink]
 [-Directory] [-File] [-Hidden] [-ReadOnly] [-System] [<CommonParameters>]
```

## DESCRIPTION
Get-ChilditemEnhanced adds an additional parameter -StartDepth

## EXAMPLES

### EXAMPLE 1
```
Get-ChilditemEnhanced C:\Temp -StartDepth 3
Return all items from level 3 down, i.d. C:\Temp\1\2\3
```

## PARAMETERS

### -Path
Where to look for items

```yaml
Type: String[]
Parameter Sets: Items
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -LiteralPath
A full path information

```yaml
Type: String[]
Parameter Sets: LiteralItems
Aliases: PSPath, LP

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Filter
Define filter for items

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Include
Filter items by include rules

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Exclude
Filter items by exclude rules

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Recurse
Recurse dirs

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: s

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Depth
Filter items by depth

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -StartDepth
The depth from where you want to retrieve items

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force
Forcefully working

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Name
The part of the name you're looking for - wildscards allowed

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Attributes
Filter items by attribute

```yaml
Type: System.Management.Automation.FlagsExpression`1[System.IO.FileAttributes]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FollowSymlink
Boolean follow symlinks or not

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Directory
Retunr directories only

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: ad

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -File
Return files only

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: af

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Hidden
Return hidden items only

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: ah, h

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ReadOnly
Return only ReadOnly items

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: ar

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -System
Return system files only

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: as

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
See for proxy funtions to get more info

## RELATED LINKS

[Specify a URI to a help page, this will show when Get-Help -Online is used.]()

