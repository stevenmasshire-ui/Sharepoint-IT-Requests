# Power Automate Flows

Four flows, built in Power Automate against the same SharePoint site as the two lists. All email actions use the **Office 365 Outlook — Send an email (V2)** connector. Replace `admin1@x.com` / `admin2@x.com` with the same addresses used in `gblAdminEmails` in the app.

## 1. New ticket → notify admin(s)

- **Trigger:** SharePoint — *When an item is created* — List: `IT Requests`
- **Action:** *Send an email (V2)*
  - To: `admin1@x.com; admin2@x.com`
  - Subject: `New IT Request: @{triggerOutputs()?['body/Title']}`
  - Body: include `Description`, `Category`, `Priority`, and a deep link:
    `https://apps.powerapps.com/play/<APP_ID>?ticketId=@{triggerOutputs()?['body/ID']}`
    (grab `<APP_ID>` from the app's Details pane after first publish).

## 2. Status change → notify requester

- **Trigger:** SharePoint — *When an item is modified* — List: `IT Requests`
- **Action:** *Send an HTTP request to SharePoint* / *Get changes for an item or a file (properties only)*, using `Since: triggerOutputs()?['body/{FieldsForModified}']` per the standard "detect field change" pattern, checking whether `Status` appears in the changed-properties list. This avoids firing on unrelated edits (e.g. an admin only changing `Priority`).
- **Condition:** changed properties contains `Status`
- **Action (If yes):** *Send an email (V2)*
  - To: `triggerOutputs()?['body/Author/Email']`
  - Subject: `Your IT request status changed: @{triggerOutputs()?['body/Title']}`
  - Body: `Status is now: @{triggerOutputs()?['body/Status/Value']}` + deep link as above.

## 3. New comment → notify the other party

- **Trigger:** SharePoint — *When an item is created* — List: `IT Request Comments`
- **Condition:** `IsInternalNote` is equal to `false` (internal notes never trigger a notification)
- **Action:** *Get item* on `IT Requests` using the trigger's `RequestID` to fetch the parent ticket (need `Title`, `Author/Email`, `ID`)
- **Condition:** is the commenter (`triggerOutputs()?['body/Author/Email']`) in the admin list?
  - Use a *Compose* with the same hardcoded list as the app, or a simple `or(equals(...), equals(...))` condition per admin address.
  - **If admin commented:** email the parent ticket's `Author/Email` — "IT has replied to your request."
  - **If requester commented:** email the admin address(es) — "New reply on ticket #ID."
  - Both branches include the deep link.

## 4. (Optional) Daily overdue digest

Ties the `DueDate` field to something actionable; skip this one if you don't need SLA reporting yet.

- **Trigger:** Recurrence — once daily (e.g. 8am)
- **Action:** *Get items* on `IT Requests`, filter query:
  `DueDate lt '@{utcNow()}' and Status ne 'Resolved' and Status ne 'Closed'`
- **Condition:** length of results > 0
- **Action:** *Send an email (V2)* to admin(s) with an HTML table (Apply to each → build an HTML list, or use *Create HTML table* action) listing overdue tickets, their `Title`, `DueDate`, and deep links.

## Notes

- All four flows reference the *same* hardcoded admin email list as the app's `gblAdminEmails` — keep them in sync manually when adding/removing an admin.
- If email volume becomes noisy, add a per-flow condition to skip notifying the same person who made the triggering change (e.g. don't email an admin when *they're* the one who changed the status).
