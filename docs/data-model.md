# Data Model

Two SharePoint lists back the app. Create them with `provisioning/New-ITRequestLists.ps1`, or by hand following the tables below.

## List: `IT Requests`

The ticket queue. One item per request.

| Column (internal name) | Type | Choices / Notes |
|---|---|---|
| `Title` | Single line of text | Short subject line, e.g. "Laptop won't connect to VPN" |
| `Description` | Multiple lines of text (plain) | Full detail from the requester |
| `Category` | Choice | `Hardware`, `Software`, `Access/Account`, `Network`, `Other` |
| `Priority` | Choice | `Low`, `Medium`, `High`, `Urgent` |
| `Status` | Choice | `New`, `In Progress`, `Waiting on Requester`, `Resolved`, `Closed` — default `New` |
| `DueDate` | Date only | Optional; admin sets a target resolution date for SLA tracking |
| *Attachments* | native list feature | No column needed — every SharePoint list supports attachments unless explicitly disabled. Bind the Power Apps `Attachments` control straight to the form/record. |
| *Author*, *Created*, *Modified* | native columns | Used instead of a custom "Requested By" person field. "My Requests" filters on `Author().Email = User().Email`; sort screens use `Modified` descending. |

## List: `IT Request Comments`

The conversation thread **and** admin-only internal notes live in the same list, split by the `IsInternalNote` flag. This gives you "ask follow-up questions" (visible thread) and "add notes" (private) without two separate lists to keep in sync.

| Column (internal name) | Type | Choices / Notes |
|---|---|---|
| `Title` | Single line of text | Not shown in the UI; can auto-fill with `"Comment"` on create |
| `RequestID` | Lookup → `IT Requests` (show `ID` or `Title`) | Ties the comment to its parent ticket. Requires the `IT Requests` list to already exist. |
| `CommentText` | Multiple lines of text (plain) | The message body |
| `IsInternalNote` | Yes/No | Default `No`. Staff replies are always `No`. Admin sets `Yes` for private notes-to-self that the requester never sees. |
| *Author*, *Created* | native columns | Drives thread ordering (`Created` ascending) and "who said this" display |

## Relationships & filtering rules

- A ticket's visible conversation = `Filter('IT Request Comments', RequestID.Id = ThisTicket.ID, IsInternalNote = false)`, sorted by `Created` ascending.
- A ticket's internal notes (admin view only) = same filter with `IsInternalNote = true`.
- Staff never query `IT Request Comments` with `IsInternalNote = true` in any screen — this is the entire enforcement mechanism, so **do not build a "show all notes" screen accessible to non-admins**.
- No custom "Requested By" or "Commented By" person fields are needed anywhere — native `Author`/`Created By` covers both lists.
