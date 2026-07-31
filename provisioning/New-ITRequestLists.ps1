<#
.SYNOPSIS
    Provisions the SharePoint lists backing the IT Request Tracker Power App.

.DESCRIPTION
    Creates two lists on the target SharePoint site if they don't already exist:
      - "IT Requests"         : the ticket queue
      - "IT Request Comments" : conversation thread + admin-only internal notes

    Safe to re-run — each list/field is created only if missing.

.PARAMETER SiteUrl
    Full URL of the target SharePoint site, e.g. https://contoso.sharepoint.com/sites/ITHelp

.EXAMPLE
    ./New-ITRequestLists.ps1 -SiteUrl "https://contoso.sharepoint.com/sites/ITHelp"

.NOTES
    Requires the PnP.PowerShell module: Install-Module PnP.PowerShell -Scope CurrentUser
    See docs/data-model.md for the schema this script implements.
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$SiteUrl
)

$ErrorActionPreference = "Stop"

Import-Module PnP.PowerShell -ErrorAction Stop

Write-Host "Connecting to $SiteUrl ..."
Connect-PnPOnline -Url $SiteUrl -Interactive

function Ensure-List {
    param(
        [string]$Title,
        [string]$Description
    )
    $list = Get-PnPList -Identity $Title -ErrorAction SilentlyContinue
    if ($null -eq $list) {
        Write-Host "Creating list '$Title' ..."
        $list = New-PnPList -Title $Title -Template GenericList -OnQuickLaunch
        if ($Description) {
            Set-PnPList -Identity $Title -Description $Description | Out-Null
        }
    }
    else {
        Write-Host "List '$Title' already exists, skipping creation."
    }
    return $list
}

function Ensure-Field {
    param(
        [string]$ListTitle,
        [string]$InternalName,
        [string]$DisplayName,
        [string]$Type,
        [string[]]$Choices,
        [string]$LookupList,
        [string]$LookupField = "Title",
        [bool]$AddToDefaultView = $true
    )
    $existing = Get-PnPField -List $ListTitle -Identity $InternalName -ErrorAction SilentlyContinue
    if ($null -ne $existing) {
        Write-Host "  Field '$InternalName' already exists on '$ListTitle', skipping."
        return
    }

    Write-Host "  Adding field '$InternalName' ($Type) to '$ListTitle' ..."

    switch ($Type) {
        "Choice" {
            Add-PnPField -List $ListTitle -DisplayName $DisplayName -InternalName $InternalName `
                -Type Choice -Choices $Choices -AddToDefaultView:$AddToDefaultView | Out-Null
        }
        "Lookup" {
            Add-PnPField -List $ListTitle -DisplayName $DisplayName -InternalName $InternalName `
                -Type Lookup -LookupList $LookupList -LookupField $LookupField `
                -AddToDefaultView:$AddToDefaultView | Out-Null
        }
        default {
            Add-PnPField -List $ListTitle -DisplayName $DisplayName -InternalName $InternalName `
                -Type $Type -AddToDefaultView:$AddToDefaultView | Out-Null
        }
    }
}

# ---------------------------------------------------------------------------
# 1. IT Requests
# ---------------------------------------------------------------------------
$requestsListTitle = "IT Requests"
Ensure-List -Title $requestsListTitle -Description "IT support ticket queue" | Out-Null

Ensure-Field -ListTitle $requestsListTitle -InternalName "Description" -DisplayName "Description" -Type "Note"

Ensure-Field -ListTitle $requestsListTitle -InternalName "Category" -DisplayName "Category" -Type "Choice" `
    -Choices @("Hardware", "Software", "Access/Account", "Network", "Other")

Ensure-Field -ListTitle $requestsListTitle -InternalName "Priority" -DisplayName "Priority" -Type "Choice" `
    -Choices @("Low", "Medium", "High", "Urgent")

Ensure-Field -ListTitle $requestsListTitle -InternalName "Status" -DisplayName "Status" -Type "Choice" `
    -Choices @("New", "In Progress", "Waiting on Requester", "Resolved", "Closed")

Ensure-Field -ListTitle $requestsListTitle -InternalName "DueDate" -DisplayName "Due Date" -Type "DateTime"

# Default new items to Status = "New"
$statusField = Get-PnPField -List $requestsListTitle -Identity "Status"
if ($statusField.DefaultValue -ne "New") {
    Set-PnPField -List $requestsListTitle -Identity "Status" -Values @{ DefaultValue = "New" } | Out-Null
}

# Attachments are enabled on every list by default — no field to add.

# ---------------------------------------------------------------------------
# 2. IT Request Comments (created after IT Requests so the Lookup can target it)
# ---------------------------------------------------------------------------
$commentsListTitle = "IT Request Comments"
Ensure-List -Title $commentsListTitle -Description "Conversation thread and internal notes for IT Requests" | Out-Null

Ensure-Field -ListTitle $commentsListTitle -InternalName "RequestID" -DisplayName "Request" -Type "Lookup" `
    -LookupList $requestsListTitle -LookupField "Title"

Ensure-Field -ListTitle $commentsListTitle -InternalName "CommentText" -DisplayName "Comment" -Type "Note"

Ensure-Field -ListTitle $commentsListTitle -InternalName "IsInternalNote" -DisplayName "Internal Note" -Type "Boolean"

Write-Host "Done. Lists '$requestsListTitle' and '$commentsListTitle' are ready."
