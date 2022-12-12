---
external help file: PSFSPM-help.xml
Module Name: PSFSPM
online version:
schema: 2.0.0
---

# New-FMDirectory

## SYNOPSIS
New-FMDirectory creates a FMDirectory from the given root and child objects

## SYNTAX

```
New-FMDirectory [[-Root] <FMPathPermission>] [[-Child] <FMPathPermission[]>]
```

## DESCRIPTION
New-FMDirectory takes a root FMPathPermission and one or more child FMPathPermission(s).
It guarantees, that all inherited permissions will be inherited down the root
path and NOT being changed to explicit permissions.
The children instead WILL break inheritance, change all inherited permssions to explicit ones.
This all is metaphorical for the function itself does not permission handling but
only keeps the information in the described way.

## EXAMPLES

### EXAMPLE 1
```
New-FMDirectory -Root $Root -Child $Child1,$Child2
Get's the root and two children
```

## PARAMETERS

### -Root
A FMPathPermission object defining the root element for an explicit permission structure

```yaml
Type: FMPathPermission
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Child
One or more FMPathPermission object to define subfolders of the root element, where different
permission are to be set.
Only folder names for the path element of the FMPathPermission are allowed here

```yaml
Type: FMPathPermission[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

## OUTPUTS

## NOTES
Information or caveats about the function e.g.
'This function is not supported in Linux'

## RELATED LINKS
