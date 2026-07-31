# Build Guide

Step-by-step order for standing up the whole app. See `data-model.md`, `app-design.md`, and `power-automate-flows.md` for the details behind each step.

## 1. Provision the SharePoint lists

**No local installs needed (recommended for a locked-down work PC):** follow [`docs/manual-list-setup.md`](manual-list-setup.md) to create both lists by hand in the SharePoint browser UI.

**Alternative, if you can run PowerShell somewhere** (a personal machine, or Azure Cloud Shell in the browser at [shell.azure.com](https://shell.azure.com), which needs no local install since it runs server-side):
```powershell
Install-Module PnP.PowerShell -Scope CurrentUser   # first time only
./provisioning/New-ITRequestLists.ps1 -SiteUrl "https://<yourtenant>.sharepoint.com/sites/<yoursite>"
```

Either way, confirm in the SharePoint site: two lists, `IT Requests` and `IT Request Comments`, with the columns described in `data-model.md`.

## 2. Create the canvas app

1. In Power Apps Studio: **Create → Blank canvas app** (Tablet format recommended).
2. **Data → Add data** → connect the SharePoint connector to your site → add both `IT Requests` and `IT Request Comments` as data sources.

## 3. Set the admin list and role check

In the **App** object's `OnStart`, paste the formula from `app-design.md` ("Role model" section), replacing the placeholder email with your real admin address(es).

## 4. Build the screens

Follow `app-design.md` in order:
1. **Home** — My Requests gallery, All Requests admin gallery + filters, "+ New Request" button.
2. **New Request** — form bound to `IT Requests`, Status defaulted to `New` on submit.
3. **Request Detail** — read-only header, conversation gallery + reply box, admin-only edit controls and Internal Notes panel.
4. Wire up navigation (`Navigate(...)` calls) between all three screens.
5. Add the deep-link `Param()` handling to `App.OnStart`.

## 5. Publish once to get the App ID

Publish the app, then open **App details** (the "..." menu on the app in Power Apps) to copy its **Web link** — you need the `<APP_ID>` portion for the deep links used in the flows.

## 6. Build the Power Automate flows

Create each flow described in `power-automate-flows.md`, in this order (Comments flow depends on being able to look up the parent ticket, so build after Requests exists — order doesn't strictly matter, but build 1–3 first, then the optional daily digest):
1. New ticket → notify admin(s)
2. Status change → notify requester
3. New comment → notify the other party
4. *(Optional)* Daily overdue digest

Paste the real `<APP_ID>` from step 5 into every deep link.

## 7. Test as both roles

- Sign in (or use **Play** with a different account) as a non-admin: confirm you only see your own tickets, can submit a new one, and can reply on the thread — and that you cannot see the Internal Notes panel or Status/Priority editors.
- Sign in as an admin email: confirm the All Requests tab, filters, Status/Priority/DueDate editing, and Internal Notes panel all appear, and that saved changes trigger the expected email.

## 8. Share the app

In Power Apps Studio, **Share** the app with the staff who should submit tickets (view/use access), and make sure they also have at least **Contribute** permission on the underlying SharePoint site/lists (app sharing alone doesn't grant list permissions).
